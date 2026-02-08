INSERT INTO tblPlayersSeasonsTeams (Id, PlayerId, SeasonId, TeamId, Void)
VALUES
    (1, 1, 1, 1, 0),
    (2, 2, 1, 1, 0),
    (3, 3, 1, 4, 0),
    (4, 9, 1, 4, 0),
    (5, 5, 1, 2, 0),
    (6, 6, 1, 2, 0),
    (7, 4, 1, 3, 0),
    (8, 10, 1, 3, 0),
    (9, 6, 2, 1, 0),
    (10, 7, 2, 1, 0),
    (11, 11, 2, 2, 0),
    (12, 3, 2, 2, 0),
    (13, 4, 2, 3, 0),
    (14, 1, 2, 3, 0),
    (15, 5, 2, 4, 0),
    (16, 2, 2, 4, 0)
ON DUPLICATE KEY UPDATE
    PlayerId = VALUES(PlayerId),
    SeasonId = VALUES(SeasonId),
    TeamId = VALUES(TeamId),
    Void = VALUES(Void);