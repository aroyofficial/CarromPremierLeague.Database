DELIMITER $$

DROP PROCEDURE IF EXISTS usp_GetLifetimeHeadToHead$$

CREATE PROCEDURE usp_GetLifetimeHeadToHead(
    IN p_TeamA BIGINT,
    IN p_TeamB BIGINT
)
BEGIN

    SELECT
        p_TeamA AS TeamAId,
        p_TeamB AS TeamBId,

        COUNT(*) AS TotalMatches,

        SUM(
            CASE 
                WHEN (Team1 = p_TeamA AND Outcome = 1)
                  OR (Team2 = p_TeamA AND Outcome = 2)
                THEN 1 ELSE 0
            END
        ) AS TeamAWins,

        SUM(
            CASE 
                WHEN (Team1 = p_TeamB AND Outcome = 1)
                  OR (Team2 = p_TeamB AND Outcome = 2)
                THEN 1 ELSE 0
            END
        ) AS TeamBWins,

        SUM(
            CASE
                WHEN (Team1 = p_TeamA AND Outcome = 1)
                  OR (Team2 = p_TeamA AND Outcome = 2)
                THEN IFNULL(NetPoints,0)
                ELSE 0
            END
        ) AS TeamANetPoints,

        SUM(
            CASE
                WHEN (Team1 = p_TeamB AND Outcome = 1)
                  OR (Team2 = p_TeamB AND Outcome = 2)
                THEN IFNULL(NetPoints,0)
                ELSE 0
            END
        ) AS TeamBNetPoints,

        MAX(ScheduledDate) AS LastMatchDate

    FROM tblMatches
    WHERE Status = 3
      AND Void = 0
      AND (
            (Team1 = p_TeamA AND Team2 = p_TeamB)
         OR (Team1 = p_TeamB AND Team2 = p_TeamA)
      );

END$$

DELIMITER ;
