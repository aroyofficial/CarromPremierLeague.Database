IF COL_LENGTH('dbo.tblTeams', 'Name') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblTeams]
    ADD [Name] NVARCHAR(255) NOT NULL;
END
GO

IF COL_LENGTH('dbo.tblTeams', 'Slogan') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblTeams]
    ADD [Slogan] NVARCHAR(500);
END
GO

IF COL_LENGTH('dbo.tblTeams', 'LogoUrl') IS NULL
BEGIN
    ALTER TABLE [dbo].[tblTeams]
    ADD [LogoUrl] NVARCHAR(2048);
END
GO
