SET IDENTITY_INSERT [dbo].[tblSeasons] ON;
GO

MERGE INTO [dbo].[tblSeasons] AS Target
USING (VALUES
    (1, '2026 Season 1', '2026-01-25', '2026-01-25', 'https://lh3.googleusercontent.com/pw/AP1GczOXO8Z4qtYSjKYoE76HUDevzhXMCBcpb3goSIaOANqZSbrk-a3ebOqVnFRszPxBh9BtAl3PFcToXeFR6OI2psI0oHvipxOvdImx_wuFor1_ToT9uOTNI09-38x80JU9hNK7BMELAj0_HrCPETjyo_8mqA=w346-h346-s-no-gm?authuser=0'),
    (2, '2026 Season 2', NULL, NULL, NULL)
) AS Source ([Id], [Name], [StartDate], [EndDate], [LogoUrl])
ON Target.[Id] = Source.[Id]
WHEN MATCHED THEN
    UPDATE SET
        [Name] = Source.[Name],
        [StartDate] = Source.[StartDate],
        [EndDate] = Source.[EndDate],
        [LogoUrl] = Source.[LogoUrl]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [StartDate], [EndDate])
    VALUES (Source.[Id], Source.[Name], Source.[StartDate], Source.[EndDate]);
GO

SET IDENTITY_INSERT [dbo].[tblSeasons] OFF;
GO
