INSERT INTO tblPlayersSeasonsTeams (Id, PlayerId, SeasonId, TeamId, Void)
VALUES
    (17, 13, 3, 1, 0),
    (18, 3, 3, 1, 0),
    (19, 8, 3, 2, 0),
    (20, 12, 3, 2, 0),
    (21, 6, 3, 3, 0),
    (22, 2, 3, 3, 0),
    (23, 1, 3, 4, 0),
    (24, 7, 3, 4, 0),
    (25, 5, 3, 5, 0),
    (26, 11, 3, 5, 0),
    (27, 14, 3, 6, 0),
    (28, 15, 3, 6, 0)
ON DUPLICATE KEY UPDATE
    PlayerId = VALUES(PlayerId),
    SeasonId = VALUES(SeasonId),
    TeamId = VALUES(TeamId),
    Void = VALUES(Void);