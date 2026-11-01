INSERT INTO tblSeasons (Id, Name, StartDate, EndDate, `Show`)
VALUES
    (3, '2026 Season 3', '2026-12-27', '2026-12-27', 1)
ON DUPLICATE KEY UPDATE
    Name = VALUES(Name),
    StartDate = VALUES(StartDate),
    EndDate = VALUES(EndDate),
    `Show` = VALUES(`Show`);
