INSERT INTO tblMatches (Id, Team1, Team2, ScheduledDate, Duration, Extra, GoldenStrike, Category, Status, `Order`, SeasonId, NetPoints, Outcome, TossOutcome)
VALUES
    (8, 1, 2, '2026-12-27', NULL, NULL, 0, 1, 1, 1, 3, NULL, 3, 3),
    (9, 3, 4, '2026-12-27', NULL, NULL, 0, 1, 1, 2, 3, NULL, 3, 3),
    (10, 1, 3, '2026-12-27', NULL, NULL, 0, 1, 1, 3, 3, NULL, 3, 3),
    (11, 2, 5, '2026-12-27', NULL, NULL, 0, 1, 1, 4, 3, NULL, 3, 3),
    (12, 1, 5, '2026-12-27', NULL, NULL, 0, 1, 1, 5, 3, NULL, 3, 3),
    (13, 2, 4, '2026-12-27', NULL, NULL, 0, 1, 1, 6, 3, NULL, 3, 3),
    (14, 1, 4, '2026-12-27', NULL, NULL, 0, 1, 1, 7, 3, NULL, 3, 3),
    (15, 3, 5, '2026-12-27', NULL, NULL, 0, 1, 1, 8, 3, NULL, 3, 3),
    (16, 2, 3, '2026-12-27', NULL, NULL, 0, 1, 1, 9, 3, NULL, 3, 3),
    (17, 4, 5, '2026-12-27', NULL, NULL, 0, 1, 1, 10, 3, NULL, 3, 3)
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
