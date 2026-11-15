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
    MustChangePassword BIT NOT NULL CONSTRAINT DF_tblAdmins_MustChangePassword DEFAULT 0,
    CONSTRAINT UQ_tblAdmins_Username UNIQUE (Username),
    CONSTRAINT CK_tblAdmins_PasswordIterations CHECK (PasswordIterations >= 100000)
);
GO

IF COL_LENGTH(N'dbo.tblAdmins', N'TokenVersion') IS NULL
    ALTER TABLE dbo.tblAdmins ADD TokenVersion INT NOT NULL CONSTRAINT DF_tblAdmins_TokenVersion DEFAULT 1;
GO

IF COL_LENGTH(N'dbo.tblAdmins', N'FirstName') IS NULL
    ALTER TABLE dbo.tblAdmins ADD FirstName NVARCHAR(100) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'LastName') IS NULL
    ALTER TABLE dbo.tblAdmins ADD LastName NVARCHAR(100) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'DateOfBirth') IS NULL
    ALTER TABLE dbo.tblAdmins ADD DateOfBirth DATE NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'Gender') IS NULL
    ALTER TABLE dbo.tblAdmins ADD Gender VARCHAR(16) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'PhoneCode') IS NULL
    ALTER TABLE dbo.tblAdmins ADD PhoneCode NVARCHAR(8) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'PhoneNumber') IS NULL
    ALTER TABLE dbo.tblAdmins ADD PhoneNumber NVARCHAR(20) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'Email') IS NULL
    ALTER TABLE dbo.tblAdmins ADD Email NVARCHAR(254) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'AvatarUrl') IS NULL
    ALTER TABLE dbo.tblAdmins ADD AvatarUrl NVARCHAR(2048) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'AvatarStorageKey') IS NULL
    ALTER TABLE dbo.tblAdmins ADD AvatarStorageKey NVARCHAR(512) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'MustChangePassword') IS NULL
    ALTER TABLE dbo.tblAdmins ADD MustChangePassword BIT NOT NULL CONSTRAINT DF_tblAdmins_MustChangePassword DEFAULT 0;
GO

IF OBJECT_ID(N'dbo.tblAdminCodes', N'U') IS NULL
CREATE TABLE dbo.tblAdminCodes (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblAdminCodes PRIMARY KEY,
    AdminId BIGINT NOT NULL,
    Purpose VARCHAR(32) NOT NULL,
    Destination NVARCHAR(254) NOT NULL,
    CodeHash VARCHAR(64) NOT NULL,
    CodeSalt VARCHAR(64) NOT NULL,
    Attempts INT NOT NULL CONSTRAINT DF_tblAdminCodes_Attempts DEFAULT 0,
    ExpiresAt DATETIME2(6) NOT NULL,
    ConsumedAt DATETIME2(6) NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdminCodes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_tblAdminCodes_tblAdmins FOREIGN KEY (AdminId) REFERENCES dbo.tblAdmins(Id),
    CONSTRAINT CK_tblAdminCodes_Purpose CHECK (Purpose IN ('email_change', 'password_reset', 'password_change', 'activation', 'login', 'password_ticket'))
);
GO

IF OBJECT_ID(N'dbo.tblAdminSessions', N'U') IS NULL
CREATE TABLE dbo.tblAdminSessions (
    AdminId BIGINT NOT NULL CONSTRAINT PK_tblAdminSessions PRIMARY KEY,
    DeviceId VARCHAR(64) NOT NULL,
    DeviceLabel NVARCHAR(160) NOT NULL,
    ExpiresAt DATETIME2(6) NOT NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdminSessions_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_tblAdminSessions_tblAdmins FOREIGN KEY (AdminId) REFERENCES dbo.tblAdmins(Id)
);
GO

IF OBJECT_ID(N'dbo.tblAdminLoginRequests', N'U') IS NULL
CREATE TABLE dbo.tblAdminLoginRequests (
    Id VARCHAR(64) NOT NULL CONSTRAINT PK_tblAdminLoginRequests PRIMARY KEY,
    AdminId BIGINT NOT NULL,
    DeviceId VARCHAR(64) NOT NULL,
    DeviceLabel NVARCHAR(160) NOT NULL,
    Status VARCHAR(16) NOT NULL,
    AccessToken NVARCHAR(900) NULL,
    ExpiresAt DATETIME2(6) NOT NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdminLoginRequests_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_tblAdminLoginRequests_tblAdmins FOREIGN KEY (AdminId) REFERENCES dbo.tblAdmins(Id),
    CONSTRAINT CK_tblAdminLoginRequests_Status CHECK (Status IN ('pending', 'approved', 'denied', 'claimed', 'expired'))
);
GO

IF OBJECT_ID(N'dbo.CK_tblAdminCodes_Purpose', N'C') IS NOT NULL
    ALTER TABLE dbo.tblAdminCodes DROP CONSTRAINT CK_tblAdminCodes_Purpose;
GO
ALTER TABLE dbo.tblAdminCodes ADD CONSTRAINT CK_tblAdminCodes_Purpose
    CHECK (Purpose IN ('email_change', 'password_reset', 'password_change', 'activation', 'login', 'password_ticket'));
GO

-- When the password last changed, shown on the profile and in the follow-up email. Unknown for older accounts.
IF COL_LENGTH(N'dbo.tblAdmins', N'PasswordChangedAt') IS NULL
    ALTER TABLE dbo.tblAdmins ADD PasswordChangedAt DATETIME2(6) NULL;
GO

IF COL_LENGTH(N'dbo.tblAdmins', N'MfaEmail') IS NULL
    ALTER TABLE dbo.tblAdmins ADD MfaEmail BIT NOT NULL CONSTRAINT DF_tblAdmins_MfaEmail DEFAULT 0;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'TotpSecret') IS NULL
    ALTER TABLE dbo.tblAdmins ADD TotpSecret VARCHAR(255) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'TotpPendingSecret') IS NULL
    ALTER TABLE dbo.tblAdmins ADD TotpPendingSecret VARCHAR(255) NULL;
GO
IF COL_LENGTH(N'dbo.tblAdmins', N'TotpLastStep') IS NULL
    ALTER TABLE dbo.tblAdmins ADD TotpLastStep BIGINT NULL;
GO

IF OBJECT_ID(N'dbo.tblAdminPasskeys', N'U') IS NULL
CREATE TABLE dbo.tblAdminPasskeys (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblAdminPasskeys PRIMARY KEY,
    AdminId BIGINT NOT NULL,
    CredentialId VARCHAR(512) NOT NULL,
    PublicKey VARCHAR(2048) NOT NULL,
    SignCount BIGINT NOT NULL CONSTRAINT DF_tblAdminPasskeys_SignCount DEFAULT 0,
    Label NVARCHAR(100) NOT NULL,
    Transports VARCHAR(200) NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdminPasskeys_CreatedAt DEFAULT SYSUTCDATETIME(),
    LastUsedAt DATETIME2(6) NULL,
    CONSTRAINT FK_tblAdminPasskeys_tblAdmins FOREIGN KEY (AdminId) REFERENCES dbo.tblAdmins(Id),
    CONSTRAINT UQ_tblAdminPasskeys_CredentialId UNIQUE (CredentialId)
);
GO

IF OBJECT_ID(N'dbo.tblAdminMfaChallenges', N'U') IS NULL
CREATE TABLE dbo.tblAdminMfaChallenges (
    Id VARCHAR(64) NOT NULL CONSTRAINT PK_tblAdminMfaChallenges PRIMARY KEY,
    AdminId BIGINT NOT NULL,
    Purpose VARCHAR(16) NOT NULL,
    Challenge VARCHAR(128) NULL,
    DeviceId VARCHAR(64) NULL,
    DeviceLabel NVARCHAR(160) NULL,
    Attempts INT NOT NULL CONSTRAINT DF_tblAdminMfaChallenges_Attempts DEFAULT 0,
    ExpiresAt DATETIME2(6) NOT NULL,
    ConsumedAt DATETIME2(6) NULL,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblAdminMfaChallenges_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_tblAdminMfaChallenges_tblAdmins FOREIGN KEY (AdminId) REFERENCES dbo.tblAdmins(Id),
    CONSTRAINT CK_tblAdminMfaChallenges_Purpose CHECK (Purpose IN ('login', 'passkey'))
);
GO

IF OBJECT_ID(N'dbo.CK_tblAdmins_Gender', N'C') IS NULL
    ALTER TABLE dbo.tblAdmins ADD CONSTRAINT CK_tblAdmins_Gender
        CHECK (Gender IS NULL OR Gender IN ('female', 'male', 'other'));
GO

IF OBJECT_ID(N'dbo.CK_tblAdmins_Phone', N'C') IS NULL
    ALTER TABLE dbo.tblAdmins ADD CONSTRAINT CK_tblAdmins_Phone
        CHECK (
            (PhoneCode IS NULL AND PhoneNumber IS NULL)
            OR (PhoneCode IS NOT NULL AND PhoneNumber IS NOT NULL)
        );
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

IF COL_LENGTH(N'dbo.tblMatches', N'StartedAt') IS NULL
    ALTER TABLE dbo.tblMatches ADD StartedAt DATETIME2(6) NULL;
GO

IF COL_LENGTH(N'dbo.tblMatches', N'ExtraStartedAt') IS NULL
    ALTER TABLE dbo.tblMatches ADD ExtraStartedAt DATETIME2(6) NULL;
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
    OpponentCoinsPocketed TINYINT NULL,
    SingleFines TINYINT NULL,
    DoubleFines TINYINT NULL,
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
    AssistantEnabled BIT NOT NULL CONSTRAINT DF_tblSettings_AssistantEnabled DEFAULT 1,
    AssistantPublicEnabled BIT NOT NULL CONSTRAINT DF_tblSettings_AssistantPublicEnabled DEFAULT 1,
    AssistantAdminEnabled BIT NOT NULL CONSTRAINT DF_tblSettings_AssistantAdminEnabled DEFAULT 1,
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSettings_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_tblSettings_SingleRow CHECK (Id = 1),
    CONSTRAINT CK_tblSettings_RegulationMinutes CHECK (RegulationMinutes BETWEEN 5 AND 30),
    CONSTRAINT CK_tblSettings_ExtraMinutes CHECK (ExtraMinutes BETWEEN 1 AND 10),
    CONSTRAINT CK_tblSettings_QueenCover CHECK (LeagueQueen = 1 OR QueenNeedsCover = 0)
);
GO

IF COL_LENGTH(N'dbo.tblSettings', N'AssistantEnabled') IS NULL
    ALTER TABLE dbo.tblSettings ADD AssistantEnabled BIT NOT NULL CONSTRAINT DF_tblSettings_AssistantEnabled DEFAULT 1;
GO

-- Striker has one switch for the public site and one for the admin console. Existing rows keep what the single switch said.
IF COL_LENGTH(N'dbo.tblSettings', N'AssistantPublicEnabled') IS NULL
BEGIN
    ALTER TABLE dbo.tblSettings ADD AssistantPublicEnabled BIT NOT NULL CONSTRAINT DF_tblSettings_AssistantPublicEnabled DEFAULT 1;
    ALTER TABLE dbo.tblSettings ADD AssistantAdminEnabled BIT NOT NULL CONSTRAINT DF_tblSettings_AssistantAdminEnabled DEFAULT 1;
    EXEC(N'UPDATE dbo.tblSettings SET AssistantPublicEnabled = AssistantEnabled, AssistantAdminEnabled = AssistantEnabled');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.tblSettings WHERE Id = 1)
INSERT INTO dbo.tblSettings (Id, RegulationMinutes, ExtraMinutes, LeagueQueen, QueenNeedsCover, AssistantEnabled, AssistantPublicEnabled, AssistantAdminEnabled)
VALUES (1, 15, 5, 0, 0, 1, 1, 1);
GO


-- Season gallery. A photo can belong to several seasons. New photos stay unpublished until a curator publishes them.
IF OBJECT_ID(N'dbo.tblGalleryItems', N'U') IS NULL
CREATE TABLE dbo.tblGalleryItems (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblGalleryItems PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblGalleryItems_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblGalleryItems_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblGalleryItems_Void DEFAULT 0,
    SourceType VARCHAR(16) NOT NULL,
    MediaType VARCHAR(16) NOT NULL CONSTRAINT DF_tblGalleryItems_MediaType DEFAULT 'image',
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
    CONSTRAINT CK_tblGalleryItems_MediaType CHECK (MediaType IN ('image', 'video')),
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

IF COL_LENGTH(N'dbo.tblGalleryItems', N'MediaType') IS NULL
    ALTER TABLE dbo.tblGalleryItems ADD MediaType VARCHAR(16) NOT NULL CONSTRAINT DF_tblGalleryItems_MediaType DEFAULT 'image';
GO

IF COL_LENGTH(N'dbo.tblGalleryItems', N'SortOrder') IS NULL
    ALTER TABLE dbo.tblGalleryItems ADD SortOrder INT NOT NULL CONSTRAINT DF_tblGalleryItems_SortOrder DEFAULT 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblGalleryItems_LibraryOrder' AND object_id = OBJECT_ID(N'dbo.tblGalleryItems'))
    CREATE INDEX IX_tblGalleryItems_LibraryOrder ON dbo.tblGalleryItems (SortOrder, Id) WHERE Void = 0;
GO

IF OBJECT_ID(N'dbo.CK_tblGalleryItems_MediaType', N'C') IS NULL
    ALTER TABLE dbo.tblGalleryItems ADD CONSTRAINT CK_tblGalleryItems_MediaType CHECK (MediaType IN ('image', 'video'));
GO

-- Gallery deletes remove rows. Clear any rows left voided by the earlier soft delete.
DELETE gis
FROM dbo.tblGalleryItemSeasons gis
JOIN dbo.tblGalleryItems gi ON gi.Id = gis.ItemId
WHERE gi.Void = 1;
DELETE FROM dbo.tblGalleryItems WHERE Void = 1;
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
DECLARE @assistantIsNew BIT = CASE WHEN EXISTS (SELECT 1 FROM dbo.tblPermissions WHERE Code = N'assistant.use') THEN 0 ELSE 1 END;
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
    ('assistant.use', N'Striker assistant', N'Use Striker', N'Open the Striker chat in this console. Striker still follows every other permission you hold.', 910),
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

-- Once, when the permission first appears: admins who manage permissions keep the chat they had and can pass it on.
IF @assistantIsNew = 1
INSERT INTO dbo.tblAdminPermissions (AdminId, PermissionCode)
SELECT DISTINCT ap.AdminId, N'assistant.use'
FROM dbo.tblAdminPermissions ap
WHERE ap.PermissionCode = N'permissions.manage'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.tblAdminPermissions held
      WHERE held.AdminId = ap.AdminId AND held.PermissionCode = N'assistant.use'
  );
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
    ('permissions', 'administration', N'Permissions', N'Granting and removing permissions.', 'Lock', 90),
    ('assistant', 'administration', N'Striker assistant', N'Who may chat with Striker in this console.', 'ChatDotRound', 95)
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
    ('assistant.use', 'assistant', NULL),
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
    ('gallery_curator', N'Gallery curator', N'Adds season photos, edits them and publishes the ones that should be public.', 50),
    ('assistant_user', N'Striker user', N'Can chat with Striker in the admin console.', 60)
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
    ('gallery_curator', 'gallery.delete'),
    ('assistant_user', 'assistant.use')
) AS source (RoleCode, PermissionCode)
    ON target.RoleCode = source.RoleCode AND target.PermissionCode = source.PermissionCode
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RoleCode, PermissionCode) VALUES (source.RoleCode, source.PermissionCode)
WHEN NOT MATCHED BY SOURCE AND target.RoleCode IN ('match_day', 'season_planner', 'content_editor', 'account_manager', 'gallery_curator', 'assistant_user') THEN
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

IF COL_LENGTH(N'dbo.tblMatchStats', N'OpponentCoinsPocketed') IS NULL
    ALTER TABLE dbo.tblMatchStats ADD OpponentCoinsPocketed TINYINT NULL;
GO

IF COL_LENGTH(N'dbo.tblMatchStats', N'SingleFines') IS NULL
    ALTER TABLE dbo.tblMatchStats ADD SingleFines TINYINT NULL;
GO

IF COL_LENGTH(N'dbo.tblMatchStats', N'DoubleFines') IS NULL
    ALTER TABLE dbo.tblMatchStats ADD DoubleFines TINYINT NULL;
GO

-- A fine puts one of the team's pocketed coins back on the board, where it can be pocketed again.
-- A fine the team cannot pay yet is due and returns nothing. So a colour never has more than
-- max(0, own coins - fined coins) + the other team's opponent coins of that colour off the board.
CREATE OR ALTER TRIGGER dbo.TR_tblMatchStats_NineCoins
ON dbo.tblMatchStats
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS entered
        INNER JOIN dbo.tblMatches AS m ON m.Id = entered.MatchId
        LEFT JOIN dbo.tblPlayersSeasonsTeams AS pst
            ON pst.PlayerId = entered.PlayerId
           AND pst.SeasonId = m.SeasonId
           AND pst.Void = 0
           AND pst.TeamId IN (m.Team1, m.Team2)
        WHERE entered.Void = 0
          AND pst.PlayerId IS NULL
    )
    BEGIN
        THROW 50020, 'A scorecard player must belong to one of the two teams in the match.', 1;
    END;

    DECLARE @overflow INT = 0;

    ;WITH sides AS (
        SELECT
            m.Id AS MatchId,
            pst.TeamId,
            SUM(ISNULL(ms.CoinsPocketed, 0)) AS OwnCoins,
            SUM(ISNULL(ms.OpponentCoinsPocketed, 0)) AS OpponentCoins,
            SUM(ISNULL(ms.CoinsFined, 0)) AS FinedCoins
        FROM dbo.tblMatches AS m
        INNER JOIN dbo.tblMatchStats AS ms ON ms.MatchId = m.Id AND ms.Void = 0
        INNER JOIN dbo.tblPlayersSeasonsTeams AS pst
            ON pst.PlayerId = ms.PlayerId
           AND pst.SeasonId = m.SeasonId
           AND pst.Void = 0
        WHERE m.Id IN (SELECT DISTINCT MatchId FROM inserted)
          AND pst.TeamId IN (m.Team1, m.Team2)
        GROUP BY m.Id, pst.TeamId
    )
    SELECT @overflow = COUNT(*)
    FROM sides AS mine
    LEFT JOIN sides AS theirs
        ON theirs.MatchId = mine.MatchId
       AND theirs.TeamId <> mine.TeamId
    WHERE CASE WHEN mine.OwnCoins > mine.FinedCoins THEN mine.OwnCoins - mine.FinedCoins ELSE 0 END
        + ISNULL(theirs.OpponentCoins, 0) > 9;

    IF @overflow > 0
    BEGIN
        THROW 50021, 'Each colour has only 9 coins off the board after fines.', 1;
    END;
END;
GO

-- Seed data follows table dependency order.

IF NOT EXISTS (SELECT 1 FROM dbo.[tblCountries])
BEGIN
    SET IDENTITY_INSERT dbo.[tblCountries] ON;
    INSERT INTO tblCountries (Id, Name, IsoCode2, IsoCode3, Capital, PhoneCode, Continent) VALUES
(1, 'Afghanistan', 'AF', 'AFG', 'Kabul', '+93', 'Asia'),
(2, 'Åland Islands', 'AX', 'ALA', 'Mariehamn', '+358', 'Europe'),
(3, 'Albania', 'AL', 'ALB', 'Tirana', '+355', 'Europe'),
(4, 'Algeria', 'DZ', 'DZA', 'Algiers', '+213', 'Africa'),
(5, 'American Samoa', 'AS', 'ASM', 'Pago Pago', '+1684', 'Oceania'),
(6, 'Andorra', 'AD', 'AND', 'Andorra la Vella', '+376', 'Europe'),
(7, 'Angola', 'AO', 'AGO', 'Luanda', '+244', 'Africa'),
(8, 'Anguilla', 'AI', 'AIA', 'The Valley', '+1264', 'North America'),
(9, 'Antarctica', 'AQ', 'ATA', NULL, NULL, 'Antarctica'),
(10, 'Antigua and Barbuda', 'AG', 'ATG', 'Saint John''s', '+1268', 'North America'),
(11, 'Argentina', 'AR', 'ARG', 'Buenos Aires', '+54', 'South America'),
(12, 'Armenia', 'AM', 'ARM', 'Yerevan', '+374', 'Asia'),
(13, 'Aruba', 'AW', 'ABW', 'Oranjestad', '+297', 'North America'),
(14, 'Australia', 'AU', 'AUS', 'Canberra', '+61', 'Oceania'),
(15, 'Austria', 'AT', 'AUT', 'Vienna', '+43', 'Europe'),
(16, 'Azerbaijan', 'AZ', 'AZE', 'Baku', '+994', 'Asia'),
(17, 'Bahamas', 'BS', 'BHS', 'Nassau', '+1242', 'North America'),
(18, 'Bahrain', 'BH', 'BHR', 'Manama', '+973', 'Asia'),
(19, 'Bangladesh', 'BD', 'BGD', 'Dhaka', '+880', 'Asia'),
(20, 'Barbados', 'BB', 'BRB', 'Bridgetown', '+1246', 'North America'),
(21, 'Belarus', 'BY', 'BLR', 'Minsk', '+375', 'Europe'),
(22, 'Belgium', 'BE', 'BEL', 'Brussels', '+32', 'Europe'),
(23, 'Belize', 'BZ', 'BLZ', 'Belmopan', '+501', 'North America'),
(24, 'Benin', 'BJ', 'BEN', 'Porto-Novo', '+229', 'Africa'),
(25, 'Bermuda', 'BM', 'BMU', 'Hamilton', '+1441', 'North America'),
(26, 'Bhutan', 'BT', 'BTN', 'Thimphu', '+975', 'Asia'),
(27, 'Bolivia', 'BO', 'BOL', 'Sucre', '+591', 'South America'),
(28, 'Bonaire, Sint Eustatius and Saba', 'BQ', 'BES', 'Kralendijk', '+599', 'North America'),
(29, 'Bosnia and Herzegovina', 'BA', 'BIH', 'Sarajevo', '+387', 'Europe'),
(30, 'Botswana', 'BW', 'BWA', 'Gaborone', '+267', 'Africa'),
(31, 'Bouvet Island', 'BV', 'BVT', NULL, '+47', 'Antarctica'),
(32, 'Brazil', 'BR', 'BRA', 'Brasília', '+55', 'South America'),
(33, 'British Indian Ocean Territory', 'IO', 'IOT', 'Diego Garcia', '+246', 'Africa'),
(34, 'British Virgin Islands', 'VG', 'VGB', 'Road Town', '+1284', 'North America'),
(35, 'Brunei', 'BN', 'BRN', 'Bandar Seri Begawan', '+673', 'Asia'),
(36, 'Bulgaria', 'BG', 'BGR', 'Sofia', '+359', 'Europe'),
(37, 'Burkina Faso', 'BF', 'BFA', 'Ouagadougou', '+226', 'Africa'),
(38, 'Burundi', 'BI', 'BDI', 'Gitega', '+257', 'Africa'),
(39, 'Cambodia', 'KH', 'KHM', 'Phnom Penh', '+855', 'Asia'),
(40, 'Cameroon', 'CM', 'CMR', 'Yaoundé', '+237', 'Africa'),
(41, 'Canada', 'CA', 'CAN', 'Ottawa', '+1', 'North America'),
(42, 'Cape Verde', 'CV', 'CPV', 'Praia', '+238', 'Africa'),
(43, 'Cayman Islands', 'KY', 'CYM', 'George Town', '+1345', 'North America'),
(44, 'Central African Republic', 'CF', 'CAF', 'Bangui', '+236', 'Africa'),
(45, 'Chad', 'TD', 'TCD', 'N''Djamena', '+235', 'Africa'),
(46, 'Chile', 'CL', 'CHL', 'Santiago', '+56', 'South America'),
(47, 'China', 'CN', 'CHN', 'Beijing', '+86', 'Asia'),
(48, 'Christmas Island', 'CX', 'CXR', 'Flying Fish Cove', '+61', 'Oceania'),
(49, 'Cocos (Keeling) Islands', 'CC', 'CCK', 'West Island', '+61', 'Oceania'),
(50, 'Colombia', 'CO', 'COL', 'Bogotá', '+57', 'South America'),
(51, 'Comoros', 'KM', 'COM', 'Moroni', '+269', 'Africa'),
(52, 'Cook Islands', 'CK', 'COK', 'Avarua', '+682', 'Oceania'),
(53, 'Costa Rica', 'CR', 'CRI', 'San José', '+506', 'North America'),
(54, 'Croatia', 'HR', 'HRV', 'Zagreb', '+385', 'Europe'),
(55, 'Cuba', 'CU', 'CUB', 'Havana', '+53', 'North America'),
(56, 'Curaçao', 'CW', 'CUW', 'Willemstad', '+599', 'North America'),
(57, 'Cyprus', 'CY', 'CYP', 'Nicosia', '+357', 'Europe'),
(58, 'Czechia', 'CZ', 'CZE', 'Prague', '+420', 'Europe'),
(59, 'Denmark', 'DK', 'DNK', 'Copenhagen', '+45', 'Europe'),
(60, 'Djibouti', 'DJ', 'DJI', 'Djibouti', '+253', 'Africa'),
(61, 'Dominica', 'DM', 'DMA', 'Roseau', '+1767', 'North America'),
(62, 'Dominican Republic', 'DO', 'DOM', 'Santo Domingo', '+1', 'North America'),
(63, 'DR Congo', 'CD', 'COD', 'Kinshasa', '+243', 'Africa'),
(64, 'Ecuador', 'EC', 'ECU', 'Quito', '+593', 'South America'),
(65, 'Egypt', 'EG', 'EGY', 'Cairo', '+20', 'Africa'),
(66, 'El Salvador', 'SV', 'SLV', 'San Salvador', '+503', 'North America'),
(67, 'Equatorial Guinea', 'GQ', 'GNQ', 'Malabo', '+240', 'Africa'),
(68, 'Eritrea', 'ER', 'ERI', 'Asmara', '+291', 'Africa'),
(69, 'Estonia', 'EE', 'EST', 'Tallinn', '+372', 'Europe'),
(70, 'Eswatini', 'SZ', 'SWZ', 'Mbabane', '+268', 'Africa'),
(71, 'Ethiopia', 'ET', 'ETH', 'Addis Ababa', '+251', 'Africa'),
(72, 'Falkland Islands', 'FK', 'FLK', 'Stanley', '+500', 'South America'),
(73, 'Faroe Islands', 'FO', 'FRO', 'Tórshavn', '+298', 'Europe'),
(74, 'Fiji', 'FJ', 'FJI', 'Suva', '+679', 'Oceania'),
(75, 'Finland', 'FI', 'FIN', 'Helsinki', '+358', 'Europe'),
(76, 'France', 'FR', 'FRA', 'Paris', '+33', 'Europe'),
(77, 'French Guiana', 'GF', 'GUF', 'Cayenne', '+594', 'South America'),
(78, 'French Polynesia', 'PF', 'PYF', 'Papeetē', '+689', 'Oceania'),
(79, 'French Southern and Antarctic Lands', 'TF', 'ATF', 'Port-aux-Français', '+262', 'Antarctica'),
(80, 'Gabon', 'GA', 'GAB', 'Libreville', '+241', 'Africa'),
(81, 'Gambia', 'GM', 'GMB', 'Banjul', '+220', 'Africa'),
(82, 'Georgia', 'GE', 'GEO', 'Tbilisi', '+995', 'Asia'),
(83, 'Germany', 'DE', 'DEU', 'Berlin', '+49', 'Europe'),
(84, 'Ghana', 'GH', 'GHA', 'Accra', '+233', 'Africa'),
(85, 'Gibraltar', 'GI', 'GIB', 'Gibraltar', '+350', 'Europe'),
(86, 'Greece', 'GR', 'GRC', 'Athens', '+30', 'Europe'),
(87, 'Greenland', 'GL', 'GRL', 'Nuuk', '+299', 'North America'),
(88, 'Grenada', 'GD', 'GRD', 'St. George''s', '+1473', 'North America'),
(89, 'Guadeloupe', 'GP', 'GLP', 'Basse-Terre', '+590', 'North America'),
(90, 'Guam', 'GU', 'GUM', 'Hagåtña', '+1671', 'Oceania'),
(91, 'Guatemala', 'GT', 'GTM', 'Guatemala City', '+502', 'North America'),
(92, 'Guernsey', 'GG', 'GGY', 'St. Peter Port', '+44', 'Europe'),
(93, 'Guinea', 'GN', 'GIN', 'Conakry', '+224', 'Africa'),
(94, 'Guinea-Bissau', 'GW', 'GNB', 'Bissau', '+245', 'Africa'),
(95, 'Guyana', 'GY', 'GUY', 'Georgetown', '+592', 'South America'),
(96, 'Haiti', 'HT', 'HTI', 'Port-au-Prince', '+509', 'North America'),
(97, 'Heard Island and McDonald Islands', 'HM', 'HMD', NULL, NULL, 'Antarctica'),
(98, 'Honduras', 'HN', 'HND', 'Tegucigalpa', '+504', 'North America'),
(99, 'Hong Kong', 'HK', 'HKG', 'City of Victoria', '+852', 'Asia'),
(100, 'Hungary', 'HU', 'HUN', 'Budapest', '+36', 'Europe'),
(101, 'Iceland', 'IS', 'ISL', 'Reykjavik', '+354', 'Europe'),
(102, 'India', 'IN', 'IND', 'New Delhi', '+91', 'Asia'),
(103, 'Indonesia', 'ID', 'IDN', 'Jakarta', '+62', 'Asia'),
(104, 'Iran', 'IR', 'IRN', 'Tehran', '+98', 'Asia'),
(105, 'Iraq', 'IQ', 'IRQ', 'Baghdad', '+964', 'Asia'),
(106, 'Ireland', 'IE', 'IRL', 'Dublin', '+353', 'Europe'),
(107, 'Isle of Man', 'IM', 'IMN', 'Douglas', '+44', 'Europe'),
(108, 'Israel', 'IL', 'ISR', 'Jerusalem', '+972', 'Asia'),
(109, 'Italy', 'IT', 'ITA', 'Rome', '+39', 'Europe'),
(110, 'Ivory Coast', 'CI', 'CIV', 'Yamoussoukro', '+225', 'Africa'),
(111, 'Jamaica', 'JM', 'JAM', 'Kingston', '+1876', 'North America'),
(112, 'Japan', 'JP', 'JPN', 'Tokyo', '+81', 'Asia'),
(113, 'Jersey', 'JE', 'JEY', 'Saint Helier', '+44', 'Europe'),
(114, 'Jordan', 'JO', 'JOR', 'Amman', '+962', 'Asia'),
(115, 'Kazakhstan', 'KZ', 'KAZ', 'Nur-Sultan', '+7', 'Asia'),
(116, 'Kenya', 'KE', 'KEN', 'Nairobi', '+254', 'Africa'),
(117, 'Kiribati', 'KI', 'KIR', 'South Tarawa', '+686', 'Oceania'),
(118, 'Kosovo', 'XK', 'XKX', 'Pristina', '+383', 'Europe'),
(119, 'Kuwait', 'KW', 'KWT', 'Kuwait City', '+965', 'Asia'),
(120, 'Kyrgyzstan', 'KG', 'KGZ', 'Bishkek', '+996', 'Asia'),
(121, 'Laos', 'LA', 'LAO', 'Vientiane', '+856', 'Asia'),
(122, 'Latvia', 'LV', 'LVA', 'Riga', '+371', 'Europe'),
(123, 'Lebanon', 'LB', 'LBN', 'Beirut', '+961', 'Asia'),
(124, 'Lesotho', 'LS', 'LSO', 'Maseru', '+266', 'Africa'),
(125, 'Liberia', 'LR', 'LBR', 'Monrovia', '+231', 'Africa'),
(126, 'Libya', 'LY', 'LBY', 'Tripoli', '+218', 'Africa'),
(127, 'Liechtenstein', 'LI', 'LIE', 'Vaduz', '+423', 'Europe'),
(128, 'Lithuania', 'LT', 'LTU', 'Vilnius', '+370', 'Europe'),
(129, 'Luxembourg', 'LU', 'LUX', 'Luxembourg', '+352', 'Europe'),
(130, 'Macau', 'MO', 'MAC', NULL, '+853', 'Asia'),
(131, 'Madagascar', 'MG', 'MDG', 'Antananarivo', '+261', 'Africa'),
(132, 'Malawi', 'MW', 'MWI', 'Lilongwe', '+265', 'Africa'),
(133, 'Malaysia', 'MY', 'MYS', 'Kuala Lumpur', '+60', 'Asia'),
(134, 'Maldives', 'MV', 'MDV', 'Malé', '+960', 'Asia'),
(135, 'Mali', 'ML', 'MLI', 'Bamako', '+223', 'Africa'),
(136, 'Malta', 'MT', 'MLT', 'Valletta', '+356', 'Europe'),
(137, 'Marshall Islands', 'MH', 'MHL', 'Majuro', '+692', 'Oceania'),
(138, 'Martinique', 'MQ', 'MTQ', 'Fort-de-France', '+596', 'North America'),
(139, 'Mauritania', 'MR', 'MRT', 'Nouakchott', '+222', 'Africa'),
(140, 'Mauritius', 'MU', 'MUS', 'Port Louis', '+230', 'Africa'),
(141, 'Mayotte', 'YT', 'MYT', 'Mamoudzou', '+262', 'Africa'),
(142, 'Mexico', 'MX', 'MEX', 'Mexico City', '+52', 'North America'),
(143, 'Micronesia', 'FM', 'FSM', 'Palikir', '+691', 'Oceania'),
(144, 'Moldova', 'MD', 'MDA', 'Chișinău', '+373', 'Europe'),
(145, 'Monaco', 'MC', 'MCO', 'Monaco', '+377', 'Europe'),
(146, 'Mongolia', 'MN', 'MNG', 'Ulan Bator', '+976', 'Asia'),
(147, 'Montenegro', 'ME', 'MNE', 'Podgorica', '+382', 'Europe'),
(148, 'Montserrat', 'MS', 'MSR', 'Plymouth', '+1664', 'North America'),
(149, 'Morocco', 'MA', 'MAR', 'Rabat', '+212', 'Africa'),
(150, 'Mozambique', 'MZ', 'MOZ', 'Maputo', '+258', 'Africa'),
(151, 'Myanmar', 'MM', 'MMR', 'Naypyidaw', '+95', 'Asia'),
(152, 'Namibia', 'NA', 'NAM', 'Windhoek', '+264', 'Africa'),
(153, 'Nauru', 'NR', 'NRU', 'Yaren', '+674', 'Oceania'),
(154, 'Nepal', 'NP', 'NPL', 'Kathmandu', '+977', 'Asia'),
(155, 'Netherlands', 'NL', 'NLD', 'Amsterdam', '+31', 'Europe'),
(156, 'New Caledonia', 'NC', 'NCL', 'Nouméa', '+687', 'Oceania'),
(157, 'New Zealand', 'NZ', 'NZL', 'Wellington', '+64', 'Oceania'),
(158, 'Nicaragua', 'NI', 'NIC', 'Managua', '+505', 'North America'),
(159, 'Niger', 'NE', 'NER', 'Niamey', '+227', 'Africa'),
(160, 'Nigeria', 'NG', 'NGA', 'Abuja', '+234', 'Africa'),
(161, 'Niue', 'NU', 'NIU', 'Alofi', '+683', 'Oceania'),
(162, 'Norfolk Island', 'NF', 'NFK', 'Kingston', '+672', 'Oceania'),
(163, 'North Korea', 'KP', 'PRK', 'Pyongyang', '+850', 'Asia'),
(164, 'North Macedonia', 'MK', 'MKD', 'Skopje', '+389', 'Europe'),
(165, 'Northern Mariana Islands', 'MP', 'MNP', 'Saipan', '+1670', 'Oceania'),
(166, 'Norway', 'NO', 'NOR', 'Oslo', '+47', 'Europe'),
(167, 'Oman', 'OM', 'OMN', 'Muscat', '+968', 'Asia'),
(168, 'Pakistan', 'PK', 'PAK', 'Islamabad', '+92', 'Asia'),
(169, 'Palau', 'PW', 'PLW', 'Ngerulmud', '+680', 'Oceania'),
(170, 'Palestine', 'PS', 'PSE', 'Ramallah', '+970', 'Asia'),
(171, 'Panama', 'PA', 'PAN', 'Panama City', '+507', 'North America'),
(172, 'Papua New Guinea', 'PG', 'PNG', 'Port Moresby', '+675', 'Oceania'),
(173, 'Paraguay', 'PY', 'PRY', 'Asunción', '+595', 'South America'),
(174, 'Peru', 'PE', 'PER', 'Lima', '+51', 'South America'),
(175, 'Philippines', 'PH', 'PHL', 'Manila', '+63', 'Asia'),
(176, 'Pitcairn Islands', 'PN', 'PCN', 'Adamstown', '+64', 'Oceania'),
(177, 'Poland', 'PL', 'POL', 'Warsaw', '+48', 'Europe'),
(178, 'Portugal', 'PT', 'PRT', 'Lisbon', '+351', 'Europe'),
(179, 'Puerto Rico', 'PR', 'PRI', 'San Juan', '+1', 'North America'),
(180, 'Qatar', 'QA', 'QAT', 'Doha', '+974', 'Asia'),
(181, 'Republic of the Congo', 'CG', 'COG', 'Brazzaville', '+242', 'Africa'),
(182, 'Réunion', 'RE', 'REU', 'Saint-Denis', '+262', 'Africa'),
(183, 'Romania', 'RO', 'ROU', 'Bucharest', '+40', 'Europe'),
(184, 'Russia', 'RU', 'RUS', 'Moscow', '+7', 'Europe'),
(185, 'Rwanda', 'RW', 'RWA', 'Kigali', '+250', 'Africa'),
(186, 'Saint Barthélemy', 'BL', 'BLM', 'Gustavia', '+590', 'North America'),
(187, 'Saint Helena, Ascension and Tristan da Cunha', 'SH', 'SHN', 'Jamestown', '+290', 'Africa'),
(188, 'Saint Kitts and Nevis', 'KN', 'KNA', 'Basseterre', '+1869', 'North America'),
(189, 'Saint Lucia', 'LC', 'LCA', 'Castries', '+1758', 'North America'),
(190, 'Saint Martin', 'MF', 'MAF', 'Marigot', '+590', 'North America'),
(191, 'Saint Pierre and Miquelon', 'PM', 'SPM', 'Saint-Pierre', '+508', 'North America'),
(192, 'Saint Vincent and the Grenadines', 'VC', 'VCT', 'Kingstown', '+1784', 'North America'),
(193, 'Samoa', 'WS', 'WSM', 'Apia', '+685', 'Oceania'),
(194, 'San Marino', 'SM', 'SMR', 'City of San Marino', '+378', 'Europe'),
(195, 'São Tomé and Príncipe', 'ST', 'STP', 'São Tomé', '+239', 'Africa'),
(196, 'Saudi Arabia', 'SA', 'SAU', 'Riyadh', '+966', 'Asia'),
(197, 'Senegal', 'SN', 'SEN', 'Dakar', '+221', 'Africa'),
(198, 'Serbia', 'RS', 'SRB', 'Belgrade', '+381', 'Europe'),
(199, 'Seychelles', 'SC', 'SYC', 'Victoria', '+248', 'Africa'),
(200, 'Sierra Leone', 'SL', 'SLE', 'Freetown', '+232', 'Africa'),
(201, 'Singapore', 'SG', 'SGP', 'Singapore', '+65', 'Asia'),
(202, 'Sint Maarten', 'SX', 'SXM', 'Philipsburg', '+1721', 'North America'),
(203, 'Slovakia', 'SK', 'SVK', 'Bratislava', '+421', 'Europe'),
(204, 'Slovenia', 'SI', 'SVN', 'Ljubljana', '+386', 'Europe'),
(205, 'Solomon Islands', 'SB', 'SLB', 'Honiara', '+677', 'Oceania'),
(206, 'Somalia', 'SO', 'SOM', 'Mogadishu', '+252', 'Africa'),
(207, 'South Africa', 'ZA', 'ZAF', 'Pretoria', '+27', 'Africa'),
(208, 'South Georgia', 'GS', 'SGS', 'King Edward Point', '+500', 'Antarctica'),
(209, 'South Korea', 'KR', 'KOR', 'Seoul', '+82', 'Asia'),
(210, 'South Sudan', 'SS', 'SSD', 'Juba', '+211', 'Africa'),
(211, 'Spain', 'ES', 'ESP', 'Madrid', '+34', 'Europe'),
(212, 'Sri Lanka', 'LK', 'LKA', 'Sri Jayawardenepura Kotte', '+94', 'Asia'),
(213, 'Sudan', 'SD', 'SDN', 'Khartoum', '+249', 'Africa'),
(214, 'Suriname', 'SR', 'SUR', 'Paramaribo', '+597', 'South America'),
(215, 'Svalbard and Jan Mayen', 'SJ', 'SJM', 'Longyearbyen', '+47', 'Europe'),
(216, 'Sweden', 'SE', 'SWE', 'Stockholm', '+46', 'Europe'),
(217, 'Switzerland', 'CH', 'CHE', 'Bern', '+41', 'Europe'),
(218, 'Syria', 'SY', 'SYR', 'Damascus', '+963', 'Asia'),
(219, 'Taiwan', 'TW', 'TWN', 'Taipei', '+886', 'Asia'),
(220, 'Tajikistan', 'TJ', 'TJK', 'Dushanbe', '+992', 'Asia'),
(221, 'Tanzania', 'TZ', 'TZA', 'Dodoma', '+255', 'Africa'),
(222, 'Thailand', 'TH', 'THA', 'Bangkok', '+66', 'Asia'),
(223, 'Timor-Leste', 'TL', 'TLS', 'Dili', '+670', 'Oceania'),
(224, 'Togo', 'TG', 'TGO', 'Lomé', '+228', 'Africa'),
(225, 'Tokelau', 'TK', 'TKL', 'Fakaofo', '+690', 'Oceania'),
(226, 'Tonga', 'TO', 'TON', 'Nuku''alofa', '+676', 'Oceania'),
(227, 'Trinidad and Tobago', 'TT', 'TTO', 'Port of Spain', '+1868', 'North America'),
(228, 'Tunisia', 'TN', 'TUN', 'Tunis', '+216', 'Africa'),
(229, 'Turkey', 'TR', 'TUR', 'Ankara', '+90', 'Asia'),
(230, 'Turkmenistan', 'TM', 'TKM', 'Ashgabat', '+993', 'Asia'),
(231, 'Turks and Caicos Islands', 'TC', 'TCA', 'Cockburn Town', '+1649', 'North America'),
(232, 'Tuvalu', 'TV', 'TUV', 'Funafuti', '+688', 'Oceania'),
(233, 'Uganda', 'UG', 'UGA', 'Kampala', '+256', 'Africa'),
(234, 'Ukraine', 'UA', 'UKR', 'Kyiv', '+380', 'Europe'),
(235, 'United Arab Emirates', 'AE', 'ARE', 'Abu Dhabi', '+971', 'Asia'),
(236, 'United Kingdom', 'GB', 'GBR', 'London', '+44', 'Europe'),
(237, 'United States', 'US', 'USA', 'Washington, D.C.', '+1', 'North America'),
(238, 'United States Minor Outlying Islands', 'UM', 'UMI', 'Washington DC', '+1', 'North America'),
(239, 'United States Virgin Islands', 'VI', 'VIR', 'Charlotte Amalie', '+1340', 'North America'),
(240, 'Uruguay', 'UY', 'URY', 'Montevideo', '+598', 'South America'),
(241, 'Uzbekistan', 'UZ', 'UZB', 'Tashkent', '+998', 'Asia'),
(242, 'Vanuatu', 'VU', 'VUT', 'Port Vila', '+678', 'Oceania'),
(243, 'Vatican City', 'VA', 'VAT', 'Vatican City', '+379', 'Europe'),
(245, 'Vietnam', 'VN', 'VNM', 'Hanoi', '+84', 'Asia'),
(246, 'Wallis and Futuna', 'WF', 'WLF', 'Mata-Utu', '+681', 'Oceania'),
(247, 'Western Sahara', 'EH', 'ESH', 'El Aaiún', '+212', 'Africa'),
(248, 'Yemen', 'YE', 'YEM', 'Sana''a', '+967', 'Asia'),
(249, 'Zambia', 'ZM', 'ZMB', 'Lusaka', '+260', 'Africa'),
(250, 'Zimbabwe', 'ZW', 'ZWE', 'Harare', '+263', 'Africa');
    SET IDENTITY_INSERT dbo.[tblCountries] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblSeasons])
BEGIN
    SET IDENTITY_INSERT dbo.[tblSeasons] ON;
    INSERT INTO tblSeasons (Id, Name, StartDate, EndDate, Show)
VALUES
    (1, '2026 Season 1', '2026-01-25', '2026-01-25', 0),
    (2, '2026 Season 2', '2026-03-01', '2026-03-08', 0),
    (3, '2026 Season 3', '2026-12-27', '2026-12-27', 1);
    SET IDENTITY_INSERT dbo.[tblSeasons] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblTeams])
BEGIN
    SET IDENTITY_INSERT dbo.[tblTeams] ON;
    INSERT INTO tblTeams (Id, Name, Slogan, LogoUrl)
VALUES
    (1, 'Ghoshpara Strikers', 'Roar of the Board', NULL),
    (2, 'Sasthitala Smashers', 'Power in Every Pocket', NULL),
    (3, 'Santinagar Slayers', 'Strike to Conquer', NULL),
    (4, 'Nischinda Ninjas', 'Silent, Sharp, Superior', NULL),
    (5, 'Kumillapara Kings', 'Crown of the Board', NULL),
    (6, 'Dum Dum Diamonds', 'Brilliance of the Board', NULL);
    SET IDENTITY_INSERT dbo.[tblTeams] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblPlayers])
BEGIN
    SET IDENTITY_INSERT dbo.[tblPlayers] ON;
    INSERT INTO tblPlayers (Id, Void, FirstName, LastName, DateOfBirth, NationalityId, AvatarUrl, DebutSeasonId)
VALUES
    (1, 0, 'Arijit', 'Roy', '2000-07-02', 102, NULL, 3),
    (2, 0, 'Sanchar', 'Bagh', '2001-07-22', 102, NULL, 3),
    (3, 0, 'Avirup', 'Saha', '2005-12-30', 102, NULL, 3),
    (4, 0, 'Tusar', 'Maji', '2006-04-04', 102, NULL, 3),
    (5, 0, 'Tushar', 'Roy', '2006-09-17', 102, NULL, 3),
    (6, 0, 'Debjit', 'Pal', '2005-07-25', 102, NULL, 3),
    (7, 0, 'Sohan', 'Ghosh', '2006-03-15', 102, NULL, 3),
    (8, 0, 'Sisir K', 'Bagh', '1962-09-13', 102, NULL, 3),
    (9, 0, 'Arghya K', 'Mishra', '2001-04-09', 102, NULL, 3),
    (10, 0, 'Ajit', 'Saha', '1972-01-17', 102, NULL, 3),
    (11, 0, 'Priyatosh', 'Das', '2005-09-03', 102, NULL, 3),
    (12, 0, 'Dipankar', 'Das', '2006-04-04', 102, NULL, 3),
    (13, 0, 'Imon', 'Bagh', '1990-08-01', 102, NULL, 3),
    (14, 0, 'Akash', 'Gupta', '2003-08-07', 102, NULL, 3),
    (15, 0, 'Rupankar', 'Das', '2003-09-15', 102, NULL, 3);
    SET IDENTITY_INSERT dbo.[tblPlayers] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblSeasonsTeams])
BEGIN
    SET IDENTITY_INSERT dbo.[tblSeasonsTeams] ON;
    INSERT INTO tblSeasonsTeams (Id, SeasonId, TeamId, Void)
VALUES
    (1, 3, 1, 0),
    (2, 3, 2, 0),
    (3, 3, 3, 0),
    (4, 3, 4, 0),
    (5, 3, 5, 0),
    (6, 3, 6, 0);
    SET IDENTITY_INSERT dbo.[tblSeasonsTeams] OFF;
END
GO

-- No SQL Server functions are currently declared.

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

-- No SQL Server triggers are currently declared.