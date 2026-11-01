INSERT INTO tblSeasonsTeams (Id, SeasonId, TeamId, Void)
VALUES
    (1, 3, 1, 0),
    (2, 3, 2, 0),
    (3, 3, 3, 0),
    (4, 3, 4, 0),
    (5, 3, 5, 0),
    (6, 3, 6, 0)
ON DUPLICATE KEY UPDATE
    SeasonId = VALUES(SeasonId),
    TeamId = VALUES(TeamId),
    Void = VALUES(Void);
