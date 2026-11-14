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

IF OBJECT_ID(N'dbo.tblAdmins', N'U') IS NULL
CREATE TABLE dbo.tblAdmins (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblAdmins PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdmins_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdmins_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblAdmins_Void DEFAULT 0,
    Username NVARCHAR(100) NOT NULL,
    PasswordHash VARCHAR(128) NOT NULL,
    PasswordSalt VARCHAR(128) NOT NULL,
    PasswordIterations INT NOT NULL CONSTRAINT DF_tblAdmins_PasswordIterations DEFAULT 310000,
    TokenVersion INT NOT NULL CONSTRAINT DF_tblAdmins_TokenVersion DEFAULT 1,
    IsActive BIT NOT NULL CONSTRAINT DF_tblAdmins_IsActive DEFAULT 1,
    CONSTRAINT UQ_tblAdmins_Username UNIQUE (Username),
    CONSTRAINT CK_tblAdmins_PasswordIterations CHECK (PasswordIterations >= 100000)
);
GO

IF COL_LENGTH(N'dbo.tblAdmins', N'TokenVersion') IS NULL
    ALTER TABLE dbo.tblAdmins ADD TokenVersion INT NOT NULL CONSTRAINT DF_tblAdmins_TokenVersion DEFAULT 1;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tblAdmins WHERE Username = N'admin')
INSERT INTO dbo.tblAdmins (Username, PasswordHash, PasswordSalt, PasswordIterations, IsActive)
VALUES (
    N'admin',
    N'9jvyAVboxIWN5gPPjt-t019o7lmAK4_d8YEIHzXvIU0dBnSqRrvJz78Q7vAa-A8P74xLMMNJh2hRnso68jAnLA',
    N'X_E-WgD3buk1LMc47qSqV3aUed3o_KQINAlPIhjk9Bk',
    310000,
    1
);
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
    [Show] BIT NOT NULL CONSTRAINT DF_tblSeasons_Show DEFAULT 1,
    CONSTRAINT CK_tblSeasons_DateRange CHECK (EndDate IS NULL OR StartDate IS NULL OR EndDate >= StartDate)
);
GO

IF COL_LENGTH(N'dbo.tblSeasons', N'Show') IS NULL
    ALTER TABLE dbo.tblSeasons ADD [Show] BIT NOT NULL CONSTRAINT DF_tblSeasons_Show DEFAULT 1;
GO

IF OBJECT_ID(N'dbo.tblTeams', N'U') IS NULL
CREATE TABLE dbo.tblTeams (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblTeams PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblTeams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblTeams_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblTeams_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    Slogan NVARCHAR(500) NULL,
    LogoUrl NVARCHAR(2048) NULL,
    LogoStorageKey NVARCHAR(512) NULL
);
GO

IF COL_LENGTH(N'dbo.tblTeams', N'LogoStorageKey') IS NULL
    ALTER TABLE dbo.tblTeams ADD LogoStorageKey NVARCHAR(512) NULL;
GO

IF OBJECT_ID(N'dbo.tblSeasonsTeams', N'U') IS NULL
CREATE TABLE dbo.tblSeasonsTeams (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblSeasonsTeams PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSeasonsTeams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSeasonsTeams_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblSeasonsTeams_Void DEFAULT 0,
    SeasonId BIGINT NOT NULL,
    TeamId BIGINT NOT NULL,
    CONSTRAINT UQ_tblSeasonsTeams_Season_Team UNIQUE (SeasonId, TeamId),
    CONSTRAINT FK_tblSeasonsTeams_tblSeasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id),
    CONSTRAINT FK_tblSeasonsTeams_tblTeams FOREIGN KEY (TeamId) REFERENCES dbo.tblTeams(Id)
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
    AvatarStorageKey NVARCHAR(512) NULL,
    NationalityId BIGINT NULL,
    DebutSeasonId BIGINT NULL,
    CONSTRAINT FK_tblPlayers_tblCountries FOREIGN KEY (NationalityId) REFERENCES dbo.tblCountries(Id),
    CONSTRAINT FK_tblPlayers_tblSeasons_Debut FOREIGN KEY (DebutSeasonId) REFERENCES dbo.tblSeasons(Id)
);
GO

IF COL_LENGTH(N'dbo.tblPlayers', N'DebutSeasonId') IS NULL
    ALTER TABLE dbo.tblPlayers ADD DebutSeasonId BIGINT NULL;
GO

IF COL_LENGTH(N'dbo.tblPlayers', N'AvatarStorageKey') IS NULL
    ALTER TABLE dbo.tblPlayers ADD AvatarStorageKey NVARCHAR(512) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_tblPlayers_tblSeasons_Debut')
    ALTER TABLE dbo.tblPlayers ADD CONSTRAINT FK_tblPlayers_tblSeasons_Debut FOREIGN KEY (DebutSeasonId) REFERENCES dbo.tblSeasons(Id);
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

IF OBJECT_ID(N'dbo.tblSettings', N'U') IS NULL
CREATE TABLE dbo.tblSettings (
    Id TINYINT NOT NULL CONSTRAINT PK_tblSettings PRIMARY KEY,
    RegulationMinutes INT NOT NULL CONSTRAINT DF_tblSettings_RegulationMinutes DEFAULT 15,
    ExtraMinutes INT NOT NULL CONSTRAINT DF_tblSettings_ExtraMinutes DEFAULT 5,
    LeagueQueen BIT NOT NULL CONSTRAINT DF_tblSettings_LeagueQueen DEFAULT 0,
    QueenNeedsCover BIT NOT NULL CONSTRAINT DF_tblSettings_QueenNeedsCover DEFAULT 0,
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSettings_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_tblSettings_SingleRow CHECK (Id = 1),
    CONSTRAINT CK_tblSettings_RegulationMinutes CHECK (RegulationMinutes BETWEEN 5 AND 30),
    CONSTRAINT CK_tblSettings_ExtraMinutes CHECK (ExtraMinutes BETWEEN 1 AND 10),
    CONSTRAINT CK_tblSettings_QueenCover CHECK (LeagueQueen = 1 OR QueenNeedsCover = 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tblSettings WHERE Id = 1)
INSERT INTO dbo.tblSettings (Id, RegulationMinutes, ExtraMinutes, LeagueQueen, QueenNeedsCover)
VALUES (1, 15, 5, 0, 0);
GO


-- Season gallery. A photo can belong to several seasons. New photos stay unpublished until a curator publishes them.
IF OBJECT_ID(N'dbo.tblGalleryItems', N'U') IS NULL
CREATE TABLE dbo.tblGalleryItems (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblGalleryItems PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblGalleryItems_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblGalleryItems_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblGalleryItems_Void DEFAULT 0,
    SourceType VARCHAR(16) NOT NULL,
    Url NVARCHAR(2048) NOT NULL,
    StorageKey NVARCHAR(512) NULL,
    Width INT NOT NULL,
    Height INT NOT NULL,
    Caption NVARCHAR(500) NULL,
    AltText NVARCHAR(300) NULL,
    TakenOn DATE NULL,
    IsPublished BIT NOT NULL CONSTRAINT DF_tblGalleryItems_IsPublished DEFAULT 0,
    CreatedBy BIGINT NULL,
    UpdatedBy BIGINT NULL,
    CONSTRAINT CK_tblGalleryItems_SourceType CHECK (SourceType IN ('upload', 'link')),
    CONSTRAINT CK_tblGalleryItems_Size CHECK (Width > 0 AND Height > 0),
    CONSTRAINT FK_tblGalleryItems_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.tblAdmins(Id),
    CONSTRAINT FK_tblGalleryItems_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.tblAdmins(Id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblGalleryItems_Published' AND object_id = OBJECT_ID(N'dbo.tblGalleryItems'))
    CREATE INDEX IX_tblGalleryItems_Published ON dbo.tblGalleryItems (IsPublished, Void, Id);
GO

IF OBJECT_ID(N'dbo.tblGalleryItemSeasons', N'U') IS NULL
CREATE TABLE dbo.tblGalleryItemSeasons (
    ItemId BIGINT NOT NULL,
    SeasonId BIGINT NOT NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_tblGalleryItemSeasons_SortOrder DEFAULT 0,
    IsCover BIT NOT NULL CONSTRAINT DF_tblGalleryItemSeasons_IsCover DEFAULT 0,
    CONSTRAINT PK_tblGalleryItemSeasons PRIMARY KEY (ItemId, SeasonId),
    CONSTRAINT FK_tblGalleryItemSeasons_Items FOREIGN KEY (ItemId) REFERENCES dbo.tblGalleryItems(Id),
    CONSTRAINT FK_tblGalleryItemSeasons_Seasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_tblGalleryItemSeasons_Cover' AND object_id = OBJECT_ID(N'dbo.tblGalleryItemSeasons'))
    CREATE UNIQUE INDEX UX_tblGalleryItemSeasons_Cover ON dbo.tblGalleryItemSeasons (SeasonId) WHERE IsCover = 1;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblGalleryItemSeasons_SeasonOrder' AND object_id = OBJECT_ID(N'dbo.tblGalleryItemSeasons'))
    CREATE INDEX IX_tblGalleryItemSeasons_SeasonOrder ON dbo.tblGalleryItemSeasons (SeasonId, SortOrder, ItemId);
GO


IF OBJECT_ID(N'dbo.tblPermissions', N'U') IS NULL
CREATE TABLE dbo.tblPermissions (
    Code VARCHAR(64) NOT NULL CONSTRAINT PK_tblPermissions PRIMARY KEY,
    Area NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300) NOT NULL,
    SortOrder INT NOT NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPermissions_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPermissions_UpdatedAt DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID(N'dbo.tblAdminPermissions', N'U') IS NULL
CREATE TABLE dbo.tblAdminPermissions (
    AdminId BIGINT NOT NULL,
    PermissionCode VARCHAR(64) NOT NULL,
    GrantedBy BIGINT NULL,
    GrantedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdminPermissions_GrantedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_tblAdminPermissions PRIMARY KEY (AdminId, PermissionCode),
    CONSTRAINT FK_tblAdminPermissions_tblAdmins FOREIGN KEY (AdminId) REFERENCES dbo.tblAdmins(Id),
    CONSTRAINT FK_tblAdminPermissions_tblPermissions FOREIGN KEY (PermissionCode) REFERENCES dbo.tblPermissions(Code),
    CONSTRAINT FK_tblAdminPermissions_GrantedBy FOREIGN KEY (GrantedBy) REFERENCES dbo.tblAdmins(Id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblAdminPermissions_PermissionCode' AND object_id = OBJECT_ID(N'dbo.tblAdminPermissions'))
    CREATE INDEX IX_tblAdminPermissions_PermissionCode ON dbo.tblAdminPermissions (PermissionCode, AdminId);
GO

-- Keep in step with CarromPremierLeague.API core/permissions.py, which upserts the same rows on startup.
MERGE dbo.tblPermissions AS target
USING (VALUES
    ('seasons.create', N'Seasons', N'Create seasons', N'Add a new season.', 10),
    ('seasons.update', N'Seasons', N'Edit seasons', N'Change season names, dates and public visibility.', 20),
    ('seasons.delete', N'Seasons', N'Delete seasons', N'Remove a season.', 30),
    ('seasons.teams', N'Seasons', N'Choose season teams', N'Add teams to a season or remove them.', 40),
    ('teams.create', N'Teams', N'Create teams', N'Add a new team.', 110),
    ('teams.update', N'Teams', N'Edit teams', N'Change team names, slogans and logos.', 120),
    ('teams.delete', N'Teams', N'Delete teams', N'Remove a team.', 130),
    ('players.create', N'Players', N'Create players', N'Add a new player profile.', 210),
    ('players.update', N'Players', N'Edit players', N'Change player profiles and photos.', 220),
    ('players.delete', N'Players', N'Delete players', N'Remove a player profile.', 230),
    ('countries.create', N'Countries', N'Create countries', N'Add a nationality to the reference list.', 310),
    ('countries.update', N'Countries', N'Edit countries', N'Change a country name or flag.', 320),
    ('countries.delete', N'Countries', N'Delete countries', N'Remove a country.', 330),
    ('rosters.manage', N'Rosters', N'Manage rosters', N'Assign players to teams for a season and remove them.', 410),
    ('matches.create', N'Matches', N'Create matches', N'Schedule new fixtures.', 510),
    ('matches.update', N'Matches', N'Edit and run matches', N'Change fixture details, call the toss and run a match live.', 520),
    ('matches.scorecard', N'Matches', N'Save scorecards', N'Save player statistics for a match.', 530),
    ('matches.reset', N'Matches', N'Reset matches', N'Return a started or played match to scheduled.', 540),
    ('matches.delete', N'Matches', N'Delete matches', N'Remove a fixture.', 550),
    ('settings.update', N'Settings', N'Change competition settings', N'Set the match clock and the Queen rules.', 610),
    ('admins.view', N'Admin users', N'View admin users', N'See the list of admin users and what each can do.', 710),
    ('admins.create', N'Admin users', N'Create admin users', N'Add a new admin user.', 720),
    ('admins.update', N'Admin users', N'Edit admin users', N'Rename other admins, reset their passwords and turn accounts on or off.', 730),
    ('admins.delete', N'Admin users', N'Delete admin users', N'Remove another admin user.', 740),
    ('permissions.manage', N'Permissions', N'Manage permissions', N'Grant and revoke permissions you hold for any admin user.', 810),
    ('gallery.create', N'Gallery', N'Add gallery photos', N'Upload a photo or save a public image link as a draft.', 650),
    ('gallery.update', N'Gallery', N'Edit gallery photos', N'Change captions, seasons, order and covers.', 660),
    ('gallery.publish', N'Gallery', N'Publish gallery photos', N'Make a draft photo visible on the public gallery.', 670),
    ('gallery.delete', N'Gallery', N'Delete gallery photos', N'Remove a photo from the gallery.', 680)
) AS source (Code, Area, Name, Description, SortOrder)
    ON target.Code = source.Code
WHEN MATCHED AND (target.Area <> source.Area OR target.Name <> source.Name OR target.Description <> source.Description OR target.SortOrder <> source.SortOrder) THEN
    UPDATE SET Area = source.Area, Name = source.Name, Description = source.Description, SortOrder = source.SortOrder, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (Code, Area, Name, Description, SortOrder) VALUES (source.Code, source.Area, source.Name, source.Description, source.SortOrder);
GO

-- Bootstrap only: when nobody holds any permission, the seed admin receives all of them.
IF NOT EXISTS (SELECT 1 FROM dbo.tblAdminPermissions)
INSERT INTO dbo.tblAdminPermissions (AdminId, PermissionCode)
SELECT a.Id, p.Code
FROM dbo.tblAdmins a
CROSS JOIN dbo.tblPermissions p
WHERE a.Username = N'admin' AND a.Void = 0;
GO

-- Permission hierarchy: sections hold areas, areas hold permissions, and a child permission needs its parent.
-- Keep in step with CarromPremierLeague.API core/permissions.py, which upserts the same rows on startup.
IF OBJECT_ID(N'dbo.tblPermissionSections', N'U') IS NULL
CREATE TABLE dbo.tblPermissionSections (
    Code VARCHAR(32) NOT NULL CONSTRAINT PK_tblPermissionSections PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300) NOT NULL,
    SortOrder INT NOT NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPermissionSections_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPermissionSections_UpdatedAt DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID(N'dbo.tblPermissionAreas', N'U') IS NULL
CREATE TABLE dbo.tblPermissionAreas (
    Code VARCHAR(32) NOT NULL CONSTRAINT PK_tblPermissionAreas PRIMARY KEY,
    SectionCode VARCHAR(32) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    Description NVARCHAR(300) NOT NULL,
    Icon VARCHAR(40) NOT NULL,
    SortOrder INT NOT NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPermissionAreas_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPermissionAreas_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_tblPermissionAreas_tblPermissionSections FOREIGN KEY (SectionCode) REFERENCES dbo.tblPermissionSections(Code)
);
GO

IF COL_LENGTH(N'dbo.tblPermissions', N'AreaCode') IS NULL
    ALTER TABLE dbo.tblPermissions ADD AreaCode VARCHAR(32) NULL;
GO

IF COL_LENGTH(N'dbo.tblPermissions', N'ParentCode') IS NULL
    ALTER TABLE dbo.tblPermissions ADD ParentCode VARCHAR(64) NULL;
GO

IF OBJECT_ID(N'dbo.FK_tblPermissions_tblPermissionAreas', N'F') IS NULL
    ALTER TABLE dbo.tblPermissions ADD CONSTRAINT FK_tblPermissions_tblPermissionAreas FOREIGN KEY (AreaCode) REFERENCES dbo.tblPermissionAreas(Code);
GO

IF OBJECT_ID(N'dbo.FK_tblPermissions_Parent', N'F') IS NULL
    ALTER TABLE dbo.tblPermissions ADD CONSTRAINT FK_tblPermissions_Parent FOREIGN KEY (ParentCode) REFERENCES dbo.tblPermissions(Code);
GO

-- Roles are ready-made permission sets the console applies in one click. Admins hold permissions, not roles.
IF OBJECT_ID(N'dbo.tblRoles', N'U') IS NULL
CREATE TABLE dbo.tblRoles (
    Code VARCHAR(32) NOT NULL CONSTRAINT PK_tblRoles PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300) NOT NULL,
    SortOrder INT NOT NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblRoles_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblRoles_UpdatedAt DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID(N'dbo.tblRolePermissions', N'U') IS NULL
CREATE TABLE dbo.tblRolePermissions (
    RoleCode VARCHAR(32) NOT NULL,
    PermissionCode VARCHAR(64) NOT NULL,
    CONSTRAINT PK_tblRolePermissions PRIMARY KEY (RoleCode, PermissionCode),
    CONSTRAINT FK_tblRolePermissions_tblRoles FOREIGN KEY (RoleCode) REFERENCES dbo.tblRoles(Code) ON DELETE CASCADE,
    CONSTRAINT FK_tblRolePermissions_tblPermissions FOREIGN KEY (PermissionCode) REFERENCES dbo.tblPermissions(Code)
);
GO

MERGE dbo.tblPermissionSections AS target
USING (VALUES
    ('league', N'League setup', N'Seasons, teams, players and who plays where.', 10),
    ('matchday', N'Match day', N'Fixtures, live scoring and competition rules.', 20),
    ('media', N'Media', N'Season photos shown on the public gallery.', 25),
    ('administration', N'Administration', N'Who can sign in and what they can do.', 30)
) AS source (Code, Name, Description, SortOrder)
    ON target.Code = source.Code
WHEN MATCHED AND (target.Name <> source.Name OR target.Description <> source.Description OR target.SortOrder <> source.SortOrder) THEN
    UPDATE SET Name = source.Name, Description = source.Description, SortOrder = source.SortOrder, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (Code, Name, Description, SortOrder) VALUES (source.Code, source.Name, source.Description, source.SortOrder);
GO

MERGE dbo.tblPermissionAreas AS target
USING (VALUES
    ('seasons', 'league', N'Seasons', N'Season calendar and the teams taking part.', 'Calendar', 10),
    ('teams', 'league', N'Teams', N'Team profiles and logos.', 'Flag', 20),
    ('players', 'league', N'Players', N'Player profiles and photos.', 'User', 30),
    ('countries', 'league', N'Countries', N'Nationalities players can pick from.', 'Location', 40),
    ('rosters', 'league', N'Rosters', N'Which players play for which team each season.', 'List', 50),
    ('matches', 'matchday', N'Matches', N'Fixtures, tosses, live play and scorecards.', 'Trophy', 60),
    ('settings', 'matchday', N'Settings', N'Match clock and Queen rules.', 'Setting', 70),
    ('admins', 'administration', N'Admin users', N'Accounts that can sign in to this console.', 'UserFilled', 80),
    ('gallery', 'media', N'Gallery', N'Season photos.', 'Picture', 55),
    ('permissions', 'administration', N'Permissions', N'Granting and removing permissions.', 'Lock', 90)
) AS source (Code, SectionCode, Name, Description, Icon, SortOrder)
    ON target.Code = source.Code
WHEN MATCHED AND (target.SectionCode <> source.SectionCode OR target.Name <> source.Name OR target.Description <> source.Description OR target.Icon <> source.Icon OR target.SortOrder <> source.SortOrder) THEN
    UPDATE SET SectionCode = source.SectionCode, Name = source.Name, Description = source.Description, Icon = source.Icon, SortOrder = source.SortOrder, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (Code, SectionCode, Name, Description, Icon, SortOrder) VALUES (source.Code, source.SectionCode, source.Name, source.Description, source.Icon, source.SortOrder);
GO

UPDATE p
SET AreaCode = source.AreaCode, ParentCode = source.ParentCode, UpdatedAt = SYSUTCDATETIME()
FROM dbo.tblPermissions p
JOIN (VALUES
    ('seasons.create', 'seasons', NULL),
    ('seasons.update', 'seasons', NULL),
    ('seasons.delete', 'seasons', 'seasons.update'),
    ('seasons.teams', 'seasons', 'seasons.update'),
    ('teams.create', 'teams', NULL),
    ('teams.update', 'teams', NULL),
    ('teams.delete', 'teams', 'teams.update'),
    ('players.create', 'players', NULL),
    ('players.update', 'players', NULL),
    ('players.delete', 'players', 'players.update'),
    ('countries.create', 'countries', NULL),
    ('countries.update', 'countries', NULL),
    ('countries.delete', 'countries', 'countries.update'),
    ('rosters.manage', 'rosters', NULL),
    ('matches.create', 'matches', NULL),
    ('matches.update', 'matches', NULL),
    ('matches.scorecard', 'matches', 'matches.update'),
    ('matches.reset', 'matches', 'matches.update'),
    ('matches.delete', 'matches', 'matches.update'),
    ('settings.update', 'settings', NULL),
    ('admins.view', 'admins', NULL),
    ('admins.create', 'admins', NULL),
    ('admins.update', 'admins', 'admins.view'),
    ('admins.delete', 'admins', 'admins.view'),
    ('permissions.manage', 'permissions', NULL),
    ('gallery.create', 'gallery', NULL),
    ('gallery.update', 'gallery', NULL),
    ('gallery.publish', 'gallery', 'gallery.update'),
    ('gallery.delete', 'gallery', 'gallery.update')
) AS source (Code, AreaCode, ParentCode)
    ON p.Code = source.Code
WHERE ISNULL(p.AreaCode, '') <> source.AreaCode OR ISNULL(p.ParentCode, '') <> ISNULL(source.ParentCode, '');
GO

MERGE dbo.tblRoles AS target
USING (VALUES
    ('match_day', N'Match day operator', N'Runs matches live, saves scorecards and can reset a match.', 10),
    ('season_planner', N'Season planner', N'Sets up seasons, picks their teams, fills rosters and schedules fixtures.', 20),
    ('content_editor', N'League content editor', N'Keeps teams, players, countries and rosters up to date.', 30),
    ('account_manager', N'Account manager', N'Adds admin users and keeps their accounts in order.', 40),
    ('gallery_curator', N'Gallery curator', N'Adds season photos, edits them and publishes the ones that should be public.', 50)
) AS source (Code, Name, Description, SortOrder)
    ON target.Code = source.Code
WHEN MATCHED AND (target.Name <> source.Name OR target.Description <> source.Description OR target.SortOrder <> source.SortOrder) THEN
    UPDATE SET Name = source.Name, Description = source.Description, SortOrder = source.SortOrder, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (Code, Name, Description, SortOrder) VALUES (source.Code, source.Name, source.Description, source.SortOrder);
GO

MERGE dbo.tblRolePermissions AS target
USING (VALUES
    ('match_day', 'matches.update'),
    ('match_day', 'matches.scorecard'),
    ('match_day', 'matches.reset'),
    ('season_planner', 'seasons.create'),
    ('season_planner', 'seasons.update'),
    ('season_planner', 'seasons.teams'),
    ('season_planner', 'rosters.manage'),
    ('season_planner', 'matches.create'),
    ('content_editor', 'teams.create'),
    ('content_editor', 'teams.update'),
    ('content_editor', 'players.create'),
    ('content_editor', 'players.update'),
    ('content_editor', 'countries.create'),
    ('content_editor', 'countries.update'),
    ('content_editor', 'rosters.manage'),
    ('account_manager', 'admins.view'),
    ('account_manager', 'admins.create'),
    ('account_manager', 'admins.update'),
    ('gallery_curator', 'gallery.create'),
    ('gallery_curator', 'gallery.update'),
    ('gallery_curator', 'gallery.publish'),
    ('gallery_curator', 'gallery.delete')
) AS source (RoleCode, PermissionCode)
    ON target.RoleCode = source.RoleCode AND target.PermissionCode = source.PermissionCode
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RoleCode, PermissionCode) VALUES (source.RoleCode, source.PermissionCode)
WHEN NOT MATCHED BY SOURCE AND target.RoleCode IN ('match_day', 'season_planner', 'content_editor', 'account_manager', 'gallery_curator') THEN
    DELETE;
GO

-- A child permission needs its parent: give the parent to anyone who holds a child without it.
INSERT INTO dbo.tblAdminPermissions (AdminId, PermissionCode)
SELECT DISTINCT ap.AdminId, p.ParentCode
FROM dbo.tblAdminPermissions ap
JOIN dbo.tblPermissions p ON p.Code = ap.PermissionCode
WHERE p.ParentCode IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dbo.tblAdminPermissions held
      WHERE held.AdminId = ap.AdminId AND held.PermissionCode = p.ParentCode
  );
GO

-- The seed admin keeps every catalog permission, including ones added after the first bootstrap.
INSERT INTO dbo.tblAdminPermissions (AdminId, PermissionCode)
SELECT a.Id, p.Code
FROM dbo.tblAdmins a
CROSS JOIN dbo.tblPermissions p
WHERE a.Username = N'admin' AND a.Void = 0
  AND NOT EXISTS (
      SELECT 1 FROM dbo.tblAdminPermissions held
      WHERE held.AdminId = a.Id AND held.PermissionCode = p.Code
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
        SUM(ISNULL(ms.CoinsPocketed, 0)) AS CoinsPocketed,
        SUM(ISNULL(ms.OpponentCoinsPocketed, 0)) AS OpponentCoinsPocketed,
        SUM(ISNULL(ms.SingleFines, 0)) AS SingleFines,
        SUM(ISNULL(ms.DoubleFines, 0)) AS DoubleFines,
        SUM(ISNULL(ms.CoinsFined, 0)) AS CoinsFined,
        SUM(ISNULL(ms.CoinsPocketed, 0)) - SUM(ISNULL(ms.CoinsFined, 0)) AS NetCoins,
        SUM(ISNULL(ms.StrikersPocketed, 0)) AS StrikersPocketed
    FROM dbo.tblMatchStats ms
    JOIN dbo.tblMatches m ON m.Id = ms.MatchId AND m.Void = 0
    JOIN dbo.tblPlayers p ON p.Id = ms.PlayerId AND p.Void = 0
    LEFT JOIN dbo.tblPlayersSeasonsTeams pst ON pst.PlayerId = ms.PlayerId AND pst.SeasonId = m.SeasonId AND pst.Void = 0
    LEFT JOIN dbo.tblTeams t ON t.Id = pst.TeamId AND t.Void = 0
    WHERE m.SeasonId = @p_SeasonId AND m.Category = 1 AND m.Status = 3 AND ms.Void = 0
    GROUP BY ms.PlayerId, p.FirstName, p.LastName, p.AvatarUrl, pst.TeamId, t.Name
    ORDER BY NetCoins DESC, CoinsPocketed DESC, DoubleFines ASC, SingleFines ASC, OpponentCoinsPocketed ASC,
        StrikersPocketed ASC, p.FirstName ASC, p.LastName ASC, ms.PlayerId ASC;
END
GO
'@

$sections = [System.Collections.Generic.List[string]]::new()
$sections.Add($schemaSql)
$sections.Add("-- Seed data follows table dependency order.")
$seededTables = @("tblCountries", "tblSeasons", "tblTeams", "tblSeasonsTeams", "tblPlayers")
foreach ($node in $order) {
    $type, $name = $node.Split("/", 2)
    if ($type -eq "tables" -and $seededTables -contains $name) {
        $seed = Get-SeedSql -TableName $name
        if ($seed) { $sections.Add($seed) }
    }
}
$sections.Add("-- No SQL Server functions are currently declared.")
$sections.Add($proceduresSql)
$sections.Add(@'
-- Keep generated setups aligned with the standings tie-break rules.
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
        SELECT * FROM dbo.tblMatches
        WHERE SeasonId = @p_SeasonId AND Category = 1 AND Status = 3 AND Void = 0
    ),
    SeasonTeams AS (
        SELECT TeamId FROM dbo.tblSeasonsTeams WHERE SeasonId = @p_SeasonId AND Void = 0
        UNION SELECT Team1 FROM LeagueMatches WHERE Team1 IS NOT NULL
        UNION SELECT Team2 FROM LeagueMatches WHERE Team2 IS NOT NULL
    ),
    TeamStats AS (
        SELECT t.Id AS TeamId, t.Name AS TeamName, COUNT(lm.Id) AS MatchesPlayed,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN 1 ELSE 0 END) AS Wins,
            SUM(CASE WHEN lm.Id IS NOT NULL AND lm.Outcome = 3 THEN 1 ELSE 0 END) AS Draws,
            SUM(CASE
                WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN 2
                WHEN lm.Id IS NOT NULL AND lm.Outcome = 3 THEN 1
                ELSE 0
            END) AS Points,
            SUM(CASE
                WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN ISNULL(lm.NetPoints, 0)
                WHEN (lm.Team1 = t.Id AND lm.Outcome = 2) OR (lm.Team2 = t.Id AND lm.Outcome = 1) THEN -ISNULL(lm.NetPoints, 0)
                ELSE 0
            END) AS TotalNetPoints
        FROM SeasonTeams st
        JOIN dbo.tblTeams t ON t.Id = st.TeamId AND t.Void = 0
        LEFT JOIN LeagueMatches lm ON t.Id IN (lm.Team1, lm.Team2)
        GROUP BY t.Id, t.Name
    ),
    RankedStats AS (
        SELECT ts.*,
            (SELECT COUNT(*) FROM LeagueMatches lm
             JOIN TeamStats opponent ON opponent.TeamId = CASE WHEN lm.Team1 = ts.TeamId THEN lm.Team2 ELSE lm.Team1 END
             WHERE ((lm.Team1 = ts.TeamId AND lm.Outcome = 1) OR (lm.Team2 = ts.TeamId AND lm.Outcome = 2))
               AND opponent.Points = ts.Points AND opponent.TotalNetPoints = ts.TotalNetPoints) AS HeadToHeadWins,
            (SELECT COUNT(*) FROM dbo.tblMatches gs
             WHERE gs.SeasonId = @p_SeasonId AND gs.Category = 7 AND gs.GoldenStrike = 1 AND gs.Status = 3 AND gs.Void = 0
               AND ((gs.Team1 = ts.TeamId AND gs.Outcome = 1) OR (gs.Team2 = ts.TeamId AND gs.Outcome = 2))
               AND NOT EXISTS (
                   SELECT 1 FROM dbo.tblMatches ko
                   WHERE ko.SeasonId = gs.SeasonId AND ko.Void = 0 AND ko.Status = 3 AND ko.Outcome = 3
                     AND ko.Category IN (2, 3) AND ko.[Order] < gs.[Order]
                     AND ((ko.Team1 = gs.Team1 AND ko.Team2 = gs.Team2) OR (ko.Team1 = gs.Team2 AND ko.Team2 = gs.Team1))
               )) AS GoldenStrikeWins
        FROM TeamStats ts
    )
    SELECT rs.TeamId, rs.TeamName, rs.MatchesPlayed, rs.Wins, rs.Draws, rs.Points, rs.TotalNetPoints,
        rs.HeadToHeadWins, rs.GoldenStrikeWins, CASE WHEN rs.TeamId = @WinnerTeamId THEN 1 ELSE 0 END AS IsWinner
    FROM RankedStats rs
    ORDER BY rs.Points DESC, rs.TotalNetPoints DESC, rs.HeadToHeadWins DESC, rs.GoldenStrikeWins DESC, rs.TeamId ASC;

    SELECT @SeasonStatus AS SeasonStatus;
END
GO
'@)
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
