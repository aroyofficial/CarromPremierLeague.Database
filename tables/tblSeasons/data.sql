INSERT INTO tblSeasons (Id, Name, StartDate, EndDate, LogoUrl)
VALUES
    (1, '2026 Season 1', '2026-01-25', '2026-01-25', 'https://lh3.googleusercontent.com/pw/AP1GczOXO8Z4qtYSjKYoE76HUDevzhXMCBcpb3goSIaOANqZSbrk-a3ebOqVnFRszPxBh9BtAl3PFcToXeFR6OI2psI0oHvipxOvdImx_wuFor1_ToT9uOTNI09-38x80JU9hNK7BMELAj0_HrCPETjyo_8mqA=w346-h346-s-no-gm?authuser=0'),
    (2, '2026 Season 2', NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
    Name = VALUES(Name),
    StartDate = VALUES(StartDate),
    EndDate = VALUES(EndDate),
    LogoUrl = VALUES(LogoUrl);
