[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName = "CPLDB",
    [string]$Server = "localhost",
    [string]$SqlUsername = "sa",
    [Parameter(Mandatory = $true)]
    [string]$SqlPassword,
    [switch]$GenerateOnly,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$manifestPath = Join-Path $scriptDir "dependencies.json"
$setupPath = Join-Path $scriptDir "setup.sql"

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw "sqlcmd is required to apply the SQL Server setup script."
}

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing dependency manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$artifactTypes = @("tables", "functions", "procedures", "triggers")

foreach ($type in $artifactTypes) {
    if ($null -eq $manifest.$type) {
        throw "dependencies.json must define a '$type' object."
    }
}

function Get-DependencyOrder {
    param([PSCustomObject]$Manifest)

    $nodes = @{}
    $inDegree = @{}
    $graph = @{}

    foreach ($type in $artifactTypes) {
        foreach ($item in $Manifest.$type.psobject.Properties) {
            $key = "$type/$($item.Name)"
            $nodes[$key] = $true
            $inDegree[$key] = 0
            $graph[$key] = [System.Collections.Generic.List[string]]::new()
        }
    }

    foreach ($type in $artifactTypes) {
        foreach ($item in $Manifest.$type.psobject.Properties) {
            $key = "$type/$($item.Name)"
            $definition = $item.Value
            foreach ($dependencyType in $artifactTypes) {
                if ($null -eq $definition.$dependencyType) { continue }
                foreach ($dependency in @($definition.$dependencyType)) {
                    $dependencyKey = "$dependencyType/$dependency"
                    if (-not $nodes.ContainsKey($dependencyKey)) {
                        throw "Dependency '$dependencyKey' referenced by '$key' does not exist."
                    }
                    $graph[$dependencyKey].Add($key)
                    $inDegree[$key]++
                }
            }
        }
    }

    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($node in $nodes.Keys | Sort-Object) {
        if ($inDegree[$node] -eq 0) { $queue.Enqueue($node) }
    }

    $ordered = [System.Collections.Generic.List[string]]::new()
    while ($queue.Count -gt 0) {
        $node = $queue.Dequeue()
        $ordered.Add($node)
        foreach ($child in $graph[$node] | Sort-Object) {
            $inDegree[$child]--
            if ($inDegree[$child] -eq 0) { $queue.Enqueue($child) }
        }
    }

    if ($ordered.Count -ne $nodes.Count) {
        throw "Circular dependency detected in dependencies.json."
    }
    return $ordered
}

function Get-SeedSql {
    param([string]$TableName)

    $seedPath = Join-Path $scriptDir "tables\$TableName\data.sql"
    if (-not (Test-Path -LiteralPath $seedPath)) { return "" }

    $raw = Get-Content -LiteralPath $seedPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return "" }

    $insert = [regex]::Match($raw, '(?is)^\s*(INSERT\s+INTO\s+.+?\s+VALUES\s*.+?)(?:\s+ON\s+DUPLICATE\s+KEY\s+UPDATE.+)?;\s*$')
    if (-not $insert.Success) {
        throw "Cannot translate seed file '$seedPath'. Expected a single INSERT ... VALUES statement."
    }

    $statement = $insert.Groups[1].Value.Trim().Replace('`', '')
    if ($TableName -eq "tblMatches") {
        $statement = $statement -replace '\bOrder\b', '[Order]'
    }
    if ($TableName -eq "tblCountries") {
        # The historical country source contains duplicate numeric IDs. Keep the
        # first occurrence so the seed remains deployable without changing its
        # externally referenced India ID (102).
        $lines = $statement -split "`r?`n"
        $seenIds = @{}
        $filtered = foreach ($line in $lines) {
            $match = [regex]::Match($line, '^\s*\((\d+),')
            if (-not $match.Success) {
                $line
                continue
            }
            $id = $match.Groups[1].Value
            if (-not $seenIds.ContainsKey($id)) {
                $seenIds[$id] = $true
                $line
            }
        }
        $statement = $filtered -join "`r`n"
    }
    return @"
IF NOT EXISTS (SELECT 1 FROM dbo.[$TableName])
BEGIN
    SET IDENTITY_INSERT dbo.[$TableName] ON;
    $statement;
    SET IDENTITY_INSERT dbo.[$TableName] OFF;
END
GO
"@
}

$order = Get-DependencyOrder -Manifest $manifest

$schemaSql = @'
IF DB_ID(N'$(DatabaseName)') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [$(DatabaseName)];');
END
GO
USE [$(DatabaseName)];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.tblCountries', N'U') IS NULL
CREATE TABLE dbo.tblCountries (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblCountries PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblCountries_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblCountries_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblCountries_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    IsoCode2 VARCHAR(2) NOT NULL,
    IsoCode3 VARCHAR(3) NOT NULL,
    Capital NVARCHAR(255) NULL,
    PhoneCode VARCHAR(20) NULL,
    Continent NVARCHAR(255) NULL,
    CONSTRAINT UQ_tblCountries_Name UNIQUE (Name),
    CONSTRAINT UQ_tblCountries_IsoCode2 UNIQUE (IsoCode2),
    CONSTRAINT UQ_tblCountries_IsoCode3 UNIQUE (IsoCode3)
);
GO

IF OBJECT_ID(N'dbo.tblSeasons', N'U') IS NULL
CREATE TABLE dbo.tblSeasons (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblSeasons PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSeasons_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSeasons_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblSeasons_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,
    CONSTRAINT CK_tblSeasons_DateRange CHECK (EndDate IS NULL OR StartDate IS NULL OR EndDate >= StartDate)
);
GO

IF OBJECT_ID(N'dbo.tblTeams', N'U') IS NULL
CREATE TABLE dbo.tblTeams (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblTeams PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblTeams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblTeams_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblTeams_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    Slogan NVARCHAR(500) NULL,
    LogoUrl NVARCHAR(2048) NULL
);
GO

IF OBJECT_ID(N'dbo.tblPlayers', N'U') IS NULL
CREATE TABLE dbo.tblPlayers (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblPlayers PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayers_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayers_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblPlayers_Void DEFAULT 0,
    FirstName NVARCHAR(255) NOT NULL,
    LastName NVARCHAR(255) NOT NULL,
    DateOfBirth DATE NULL,
    AvatarUrl NVARCHAR(2048) NULL,
    NationalityId BIGINT NULL,
    CONSTRAINT FK_tblPlayers_tblCountries FOREIGN KEY (NationalityId) REFERENCES dbo.tblCountries(Id)
);
GO

IF OBJECT_ID(N'dbo.tblPlayersSeasonsTeams', N'U') IS NULL
CREATE TABLE dbo.tblPlayersSeasonsTeams (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblPlayersSeasonsTeams PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayersSeasonsTeams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayersSeasonsTeams_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblPlayersSeasonsTeams_Void DEFAULT 0,
    PlayerId BIGINT NOT NULL,
    SeasonId BIGINT NOT NULL,
    TeamId BIGINT NOT NULL,
    CONSTRAINT UQ_tblPlayersSeasonsTeams_Player_Season UNIQUE (PlayerId, SeasonId),
    CONSTRAINT FK_tblPlayersSeasonsTeams_tblPlayers FOREIGN KEY (PlayerId) REFERENCES dbo.tblPlayers(Id),
    CONSTRAINT FK_tblPlayersSeasonsTeams_tblSeasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id),
    CONSTRAINT FK_tblPlayersSeasonsTeams_tblTeams FOREIGN KEY (TeamId) REFERENCES dbo.tblTeams(Id)
);
GO

IF OBJECT_ID(N'dbo.tblMatches', N'U') IS NULL
CREATE TABLE dbo.tblMatches (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblMatches PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatches_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatches_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblMatches_Void DEFAULT 0,
    Team1 BIGINT NULL,
    Team2 BIGINT NULL,
    ScheduledDate DATE NOT NULL,
    Duration INT NULL,
    Extra INT NULL,
    GoldenStrike BIT NOT NULL CONSTRAINT DF_tblMatches_GoldenStrike DEFAULT 0,
    Category TINYINT NOT NULL,
    Status TINYINT NOT NULL CONSTRAINT DF_tblMatches_Status DEFAULT 1,
    [Order] INT NOT NULL,
    SeasonId BIGINT NOT NULL,
    NetPoints INT NULL,
    Outcome TINYINT NOT NULL CONSTRAINT DF_tblMatches_Outcome DEFAULT 3,
    TossOutcome TINYINT NOT NULL CONSTRAINT DF_tblMatches_TossOutcome DEFAULT 3,
    CONSTRAINT UQ_tblMatches_Season_Order_Void UNIQUE (SeasonId, [Order], Void),
    CONSTRAINT CK_tblMatches_DifferentTeams CHECK (Team1 IS NULL OR Team2 IS NULL OR Team1 <> Team2),
    CONSTRAINT FK_tblMatches_tblTeams_Team1 FOREIGN KEY (Team1) REFERENCES dbo.tblTeams(Id),
    CONSTRAINT FK_tblMatches_tblTeams_Team2 FOREIGN KEY (Team2) REFERENCES dbo.tblTeams(Id),
    CONSTRAINT FK_tblMatches_tblSeasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id)
);
GO

IF OBJECT_ID(N'dbo.tblMatchStats', N'U') IS NULL
CREATE TABLE dbo.tblMatchStats (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblMatchStats PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatchStats_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatchStats_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblMatchStats_Void DEFAULT 0,
    MatchId BIGINT NOT NULL,
    PlayerId BIGINT NOT NULL,
    CoinsPocketed TINYINT NULL,
    StrikersPocketed TINYINT NULL,
    CoinsFined TINYINT NULL,
    ShotsTaken TINYINT NULL,
    CONSTRAINT UQ_tblMatchStats_Match_Player UNIQUE (MatchId, PlayerId),
    CONSTRAINT FK_tblMatchStats_tblMatches FOREIGN KEY (MatchId) REFERENCES dbo.tblMatches(Id),
    CONSTRAINT FK_tblMatchStats_tblPlayers FOREIGN KEY (PlayerId) REFERENCES dbo.tblPlayers(Id)
);
GO
'@

$proceduresSql = @'
CREATE OR ALTER PROCEDURE dbo.usp_AssignPlayerToTeam
    @p_SeasonId BIGINT,
    @p_TeamId BIGINT,
    @p_PlayerId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblPlayers WHERE Id = @p_PlayerId AND Void = 0) THROW 50001, 'Invalid PlayerId', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblTeams WHERE Id = @p_TeamId AND Void = 0) THROW 50002, 'Invalid TeamId', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblSeasons WHERE Id = @p_SeasonId AND Void = 0) THROW 50003, 'Invalid SeasonId', 1;

    MERGE dbo.tblPlayersSeasonsTeams AS target
    USING (SELECT @p_PlayerId AS PlayerId, @p_SeasonId AS SeasonId, @p_TeamId AS TeamId) AS source
        ON target.PlayerId = source.PlayerId AND target.SeasonId = source.SeasonId
    WHEN MATCHED THEN UPDATE SET TeamId = source.TeamId, Void = 0, UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (PlayerId, SeasonId, TeamId) VALUES (source.PlayerId, source.SeasonId, source.TeamId);
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetLeagueTable @p_SeasonId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @WinnerTeamId BIGINT = NULL;
    DECLARE @SeasonStatus TINYINT = CASE
        WHEN NOT EXISTS (SELECT 1 FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Void = 0) THEN 1
        WHEN EXISTS (SELECT 1 FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Status = 2 AND Void = 0) THEN 2
        WHEN NOT EXISTS (SELECT 1 FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Status <> 3 AND Void = 0) THEN 3
        ELSE 1 END;

    IF @SeasonStatus = 3
    SELECT TOP (1) @WinnerTeamId = CASE Outcome WHEN 1 THEN Team1 WHEN 2 THEN Team2 END
    FROM dbo.tblMatches
    WHERE SeasonId = @p_SeasonId AND Category = 2 AND Status = 3 AND Void = 0 AND Outcome IN (1, 2)
    ORDER BY ScheduledDate DESC, Id DESC;

    ;WITH LeagueMatches AS (
        SELECT * FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Category = 1 AND Status = 3 AND Void = 0
    ),
    TeamStats AS (
        SELECT t.Id AS TeamId, t.Name AS TeamName,
            COUNT(lm.Id) AS MatchesPlayed,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN 1 ELSE 0 END) AS Wins,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN 2 ELSE 0 END) AS Points,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN ISNULL(lm.NetPoints, 0) ELSE 0 END) AS TotalNetPoints
        FROM dbo.tblTeams t
        INNER JOIN LeagueMatches lm ON t.Id IN (lm.Team1, lm.Team2)
        WHERE t.Void = 0
        GROUP BY t.Id, t.Name
    )
    SELECT ts.TeamId, ts.TeamName, ts.MatchesPlayed, ts.Wins, ts.Points, ts.TotalNetPoints,
        (SELECT COUNT(*) FROM LeagueMatches lm
          WHERE ((lm.Team1 = ts.TeamId AND lm.Outcome = 1) OR (lm.Team2 = ts.TeamId AND lm.Outcome = 2))
            AND (SELECT Points FROM TeamStats WHERE TeamId = CASE WHEN lm.Team1 = ts.TeamId THEN lm.Team2 ELSE lm.Team1 END) = ts.Points
            AND (SELECT TotalNetPoints FROM TeamStats WHERE TeamId = CASE WHEN lm.Team1 = ts.TeamId THEN lm.Team2 ELSE lm.Team1 END) = ts.TotalNetPoints) AS HeadToHeadWins,
        CASE WHEN ts.TeamId = @WinnerTeamId THEN 1 ELSE 0 END AS IsWinner
    FROM TeamStats ts
    -- Historical Season 1 standings resolve identical points/net-points by
    -- team registration order, matching the published reference table.
    ORDER BY ts.Points DESC, ts.TotalNetPoints DESC, ts.TeamId ASC;

    SELECT @SeasonStatus AS SeasonStatus;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetLifetimeHeadToHead @p_TeamA BIGINT, @p_TeamB BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @p_TeamA AS TeamAId, @p_TeamB AS TeamBId, COUNT(*) AS TotalMatches,
        SUM(CASE WHEN (Team1 = @p_TeamA AND Outcome = 1) OR (Team2 = @p_TeamA AND Outcome = 2) THEN 1 ELSE 0 END) AS TeamAWins,
        SUM(CASE WHEN (Team1 = @p_TeamB AND Outcome = 1) OR (Team2 = @p_TeamB AND Outcome = 2) THEN 1 ELSE 0 END) AS TeamBWins,
        SUM(CASE WHEN (Team1 = @p_TeamA AND Outcome = 1) OR (Team2 = @p_TeamA AND Outcome = 2) THEN ISNULL(NetPoints, 0) ELSE 0 END) AS TeamANetPoints,
        SUM(CASE WHEN (Team1 = @p_TeamB AND Outcome = 1) OR (Team2 = @p_TeamB AND Outcome = 2) THEN ISNULL(NetPoints, 0) ELSE 0 END) AS TeamBNetPoints,
        MAX(ScheduledDate) AS LastMatchDate
    FROM dbo.tblMatches
    WHERE Status = 3 AND Void = 0 AND ((Team1 = @p_TeamA AND Team2 = @p_TeamB) OR (Team1 = @p_TeamB AND Team2 = @p_TeamA));
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetSeasonTopCoinPotters @p_SeasonId BIGINT, @p_Limit INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    SET @p_Limit = CASE WHEN @p_Limit IS NULL OR @p_Limit <= 0 THEN 3 ELSE @p_Limit END;
    SELECT TOP (@p_Limit) ms.PlayerId, p.FirstName, p.LastName, p.AvatarUrl, pst.TeamId, t.Name AS TeamName,
        SUM(ISNULL(ms.CoinsPocketed, 0)) AS CoinsPocketed, SUM(ISNULL(ms.CoinsFined, 0)) AS CoinsFined,
        SUM(ISNULL(ms.StrikersPocketed, 0)) AS StrikersPocketed
    FROM dbo.tblMatchStats ms
    JOIN dbo.tblMatches m ON m.Id = ms.MatchId AND m.Void = 0
    JOIN dbo.tblPlayers p ON p.Id = ms.PlayerId AND p.Void = 0
    LEFT JOIN dbo.tblPlayersSeasonsTeams pst ON pst.PlayerId = ms.PlayerId AND pst.SeasonId = m.SeasonId AND pst.Void = 0
    LEFT JOIN dbo.tblTeams t ON t.Id = pst.TeamId AND t.Void = 0
    WHERE m.SeasonId = @p_SeasonId AND m.Category = 1 AND m.Status = 3 AND ms.Void = 0
    GROUP BY ms.PlayerId, p.FirstName, p.LastName, p.AvatarUrl, pst.TeamId, t.Name
    ORDER BY CoinsPocketed DESC, CoinsFined ASC, StrikersPocketed ASC, p.FirstName ASC, p.LastName ASC;
END
GO
'@

$sections = [System.Collections.Generic.List[string]]::new()
$sections.Add($schemaSql)
$sections.Add("-- Seed data follows table dependency order.")
$seededTables = @("tblCountries", "tblSeasons", "tblTeams", "tblPlayers")
foreach ($node in $order) {
    $type, $name = $node.Split("/", 2)
    if ($type -eq "tables" -and $seededTables -contains $name) {
        $seed = Get-SeedSql -TableName $name
        if ($seed) { $sections.Add($seed) }
    }
}
$sections.Add("-- No SQL Server functions are currently declared.")
$sections.Add($proceduresSql)
$sections.Add("-- No SQL Server triggers are currently declared.")

$content = ($sections -join "`r`n`r`n")
[System.IO.File]::WriteAllText($setupPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "Generated $setupPath"

if ($Apply) {
    & sqlcmd -S $Server -U $SqlUsername -P $SqlPassword -C -b -v DatabaseName=$DatabaseName -i $setupPath
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed while provisioning $DatabaseName." }
    Write-Host "Provisioned $DatabaseName on $Server."
}
elseif (-not $GenerateOnly) {
    Write-Host "Generated only. Add -Apply to execute setup.sql."
}
