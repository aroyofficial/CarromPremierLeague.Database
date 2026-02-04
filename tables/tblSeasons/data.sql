INSERT INTO tblSeasons (Id, Name, StartDate, EndDate)
VALUES
    (1, '2026 Season 1', '2026-01-25', '2026-01-25'),
    (2, '2026 Season 2', '2026-03-01', '2026-03-08')
ON DUPLICATE KEY UPDATE
    Name = VALUES(Name),
    StartDate = VALUES(StartDate),
    EndDate = VALUES(EndDate);
