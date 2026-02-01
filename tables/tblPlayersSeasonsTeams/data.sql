INSERT INTO tblPlayersSeasonsTeams (Id, PlayerId, SeasonId, TeamId)
VALUES
    (1, 1, 1, 1),
    (2, 2, 1, 1),
    (3, 3, 1, 4),
    (4, 9, 1, 4),
    (5, 5, 1, 2),
    (6, 6, 1, 2),
    (7, 4, 1, 3),
    (8, 10, 1, 3)
ON DUPLICATE KEY UPDATE
    PlayerId = VALUES(PlayerId),
    SeasonId = VALUES(SeasonId),
    TeamId = VALUES(TeamId);