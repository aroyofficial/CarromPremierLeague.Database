-- SQL Server shape. setup.sql and Setup-Database.ps1 are what get applied.
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
    UpdatedBy BIGINT NULL
);
