DELIMITER $$

DROP PROCEDURE IF EXISTS usp_GetLeagueTable$$

CREATE PROCEDURE usp_GetLeagueTable(IN p_SeasonId BIGINT)
BEGIN
    DECLARE v_SeasonStatus TINYINT DEFAULT 1;
    DECLARE v_WinnerTeamId BIGINT DEFAULT NULL;
    DECLARE v_TotalMatches INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_TotalMatches
    FROM tblMatches
    WHERE SeasonId = p_SeasonId
      AND Void = 0;

    IF v_TotalMatches = 0 THEN
        SET v_SeasonStatus = 1;

    ELSEIF EXISTS (
        SELECT 1 FROM tblMatches
        WHERE SeasonId = p_SeasonId
          AND Status = 2
          AND Void = 0
    ) THEN
        SET v_SeasonStatus = 2;

    ELSEIF NOT EXISTS (
        SELECT 1 FROM tblMatches
        WHERE SeasonId = p_SeasonId
          AND Status <> 3
          AND Void = 0
    ) THEN
        SET v_SeasonStatus = 3;

    ELSE
        SET v_SeasonStatus = 1;
    END IF;

    IF v_SeasonStatus = 3 THEN
        SELECT
            CASE Outcome
                WHEN 1 THEN Team1
                ELSE Team2
            END
        INTO v_WinnerTeamId
        FROM tblMatches
        WHERE SeasonId = p_SeasonId
          AND Category = 2
          AND Status = 3
          AND Void = 0
        ORDER BY ScheduledDate DESC
        LIMIT 1;
    END IF;

    WITH LeagueMatches AS (
        SELECT *
        FROM tblMatches
        WHERE SeasonId = p_SeasonId
          AND Category = 1
          AND Status = 3
          AND Void = 0
    ),

    TeamStats AS (
        SELECT
            t.Id AS TeamId,
            t.Name AS TeamName,

            COUNT(lm.Id) AS MatchesPlayed,

            SUM(
                CASE 
                    WHEN (lm.Team1 = t.Id AND lm.Outcome = 1)
                      OR (lm.Team2 = t.Id AND lm.Outcome = 2)
                    THEN 1 ELSE 0
                END
            ) AS Wins,

            SUM(
                CASE 
                    WHEN (lm.Team1 = t.Id AND lm.Outcome = 1)
                      OR (lm.Team2 = t.Id AND lm.Outcome = 2)
                    THEN 2 ELSE 0
                END
            ) AS Points,

            SUM(
                CASE
                    WHEN lm.Team1 = t.Id AND lm.Outcome = 1 
                        THEN IFNULL(lm.NetPoints,0)
                    WHEN lm.Team2 = t.Id AND lm.Outcome = 2 
                        THEN IFNULL(lm.NetPoints,0)
                    ELSE 0
                END
            ) AS TotalNetPoints

        FROM tblTeams t
        LEFT JOIN LeagueMatches lm
            ON t.Id IN (lm.Team1, lm.Team2)
        WHERE t.Void = 0
        GROUP BY t.Id, t.Name
    )

    SELECT 
        ts.*,

        (
            SELECT COUNT(*)
            FROM LeagueMatches lm
            WHERE
                (
                    (lm.Team1 = ts.TeamId AND lm.Outcome = 1)
                    OR
                    (lm.Team2 = ts.TeamId AND lm.Outcome = 2)
                )
                AND (
                    SELECT Points FROM TeamStats
                    WHERE TeamId =
                        CASE 
                            WHEN lm.Team1 = ts.TeamId THEN lm.Team2
                            ELSE lm.Team1
                        END
                ) = ts.Points
                AND (
                    SELECT TotalNetPoints FROM TeamStats
                    WHERE TeamId =
                        CASE 
                            WHEN lm.Team1 = ts.TeamId THEN lm.Team2
                            ELSE lm.Team1
                        END
                ) = ts.TotalNetPoints
        ) AS HeadToHeadWins,

        CASE 
            WHEN ts.TeamId = v_WinnerTeamId THEN 1
            ELSE 0
        END AS IsWinner

    FROM TeamStats ts
    ORDER BY 
        Points DESC,
        TotalNetPoints DESC,
        HeadToHeadWins DESC;

    SELECT v_SeasonStatus AS SeasonStatus;

END$$

DELIMITER ;
