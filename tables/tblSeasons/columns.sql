IF COL_LENGTH('dbo.tblSeasons', 'Name') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblSeasons]
    ADD [Name] NVARCHAR(255) NOT NULL;
END
GO

IF COL_LENGTH('dbo.tblSeasons', 'StartDate') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblSeasons]
    ADD [StartDate] DATE;
END
GO

IF COL_LENGTH('dbo.tblSeasons', 'EndDate') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblSeasons]
    ADD [EndDate] DATE;
END
GO

IF COL_LENGTH('dbo.tblSeasons', 'LogoUrl') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblSeasons]
    ADD [LogoUrl] NVARCHAR(2048);
END
GO
