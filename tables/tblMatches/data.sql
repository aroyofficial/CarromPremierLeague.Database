INSERT INTO tblMatches (Id, Team1, Team2, ScheduledDate, Duration, Extra, GoldenStrike, Category, Status, `Order`, SeasonId, NetPoints, Outcome, TossOutcome)
VALUES
    (1, 1, 4, '2026-01-25', NULL, NULL, 0, 1, 3, 1, 1, 4, 1, 2),
    (2, 3, 2, '2026-01-25', NULL, NULL, 0, 1, 3, 2, 1, 2, 2, 1),
    (3, 1, 3, '2026-01-25', NULL, NULL, 0, 1, 3, 3, 1, 2, 1, 2),
    (4, 4, 2, '2026-01-25', NULL, NULL, 0, 1, 3, 4, 1, 6, 1, 2),
    (5, 1, 2, '2026-01-25', NULL, NULL, 0, 1, 3, 5, 1, 4, 2, 2),
    (6, 4, 3, '2026-01-25', NULL, NULL, 0, 1, 3, 6, 1, 2, 1, 1),
    (7, 4, 2, '2026-01-25', 900, 212, 0, 2, 3, 7, 1, 4, 2, 1)
ON DUPLICATE KEY UPDATE
    Team1 = VALUES(Team1),
    Team2 = VALUES(Team2),
    ScheduledDate = VALUES(ScheduledDate),
    Duration = VALUES(Duration),
    Extra = VALUES(Extra),
    GoldenStrike = VALUES(GoldenStrike),
    Category = VALUES(Category),
    Status = VALUES(Status),
    `Order` = VALUES(`Order`),
    SeasonId = VALUES(SeasonId),
    NetPoints = VALUES(NetPoints),
    Outcome = VALUES(Outcome),
    TossOutcome = VALUES(TossOutcome);
