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

    SeasonTeams AS (
        SELECT TeamId
        FROM tblSeasonsTeams
        WHERE SeasonId = p_SeasonId
          AND Void = 0
        UNION
        SELECT Team1 FROM LeagueMatches WHERE Team1 IS NOT NULL
        UNION
        SELECT Team2 FROM LeagueMatches WHERE Team2 IS NOT NULL
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
                    WHEN lm.Id IS NOT NULL AND lm.Outcome = 3 THEN 1
                    ELSE 0
                END
            ) AS Draws,

            SUM(
                CASE 
                    WHEN (lm.Team1 = t.Id AND lm.Outcome = 1)
                      OR (lm.Team2 = t.Id AND lm.Outcome = 2)
                    THEN 2
                    WHEN lm.Id IS NOT NULL AND lm.Outcome = 3 THEN 1
                    ELSE 0
                END
            ) AS Points,

            SUM(
                CASE
                    WHEN (lm.Team1 = t.Id AND lm.Outcome = 1)
                      OR (lm.Team2 = t.Id AND lm.Outcome = 2)
                        THEN IFNULL(lm.NetPoints,0)
                    WHEN (lm.Team1 = t.Id AND lm.Outcome = 2)
                      OR (lm.Team2 = t.Id AND lm.Outcome = 1)
                        THEN -IFNULL(lm.NetPoints,0)
                    ELSE 0
                END
            ) AS TotalNetPoints

        FROM SeasonTeams st
        INNER JOIN tblTeams t
            ON t.Id = st.TeamId
        LEFT JOIN LeagueMatches lm
            ON t.Id IN (lm.Team1, lm.Team2)
        WHERE t.Void = 0
        GROUP BY t.Id, t.Name
    )

    RankedStats AS (
        SELECT
            ts.*,

            (
                SELECT COUNT(*)
                FROM LeagueMatches lm
                INNER JOIN TeamStats opponent
                    ON opponent.TeamId =
                        CASE
                            WHEN lm.Team1 = ts.TeamId THEN lm.Team2
                            ELSE lm.Team1
                        END
                WHERE
                    (
                        (lm.Team1 = ts.TeamId AND lm.Outcome = 1)
                        OR
                        (lm.Team2 = ts.TeamId AND lm.Outcome = 2)
                    )
                    AND opponent.Points = ts.Points
                    AND opponent.TotalNetPoints = ts.TotalNetPoints
            ) AS HeadToHeadWins,

            (
                SELECT COUNT(*)
                FROM tblMatches gs
                WHERE gs.SeasonId = p_SeasonId
                  AND gs.Category = 7
                  AND gs.GoldenStrike = 1
                  AND gs.Status = 3
                  AND gs.Void = 0
                  AND (
                      (gs.Team1 = ts.TeamId AND gs.Outcome = 1)
                      OR
                      (gs.Team2 = ts.TeamId AND gs.Outcome = 2)
                  )
                  AND NOT EXISTS (
                      SELECT 1
                      FROM tblMatches ko
                      WHERE ko.SeasonId = gs.SeasonId
                        AND ko.Void = 0
                        AND ko.Status = 3
                        AND ko.Outcome = 3
                        AND ko.Category IN (2, 3)
                        AND ko.`Order` < gs.`Order`
                        AND (
                            (ko.Team1 = gs.Team1 AND ko.Team2 = gs.Team2)
                            OR (ko.Team1 = gs.Team2 AND ko.Team2 = gs.Team1)
                        )
                  )
            ) AS GoldenStrikeWins
        FROM TeamStats ts
    )

    SELECT
        rs.*,
        CASE
            WHEN rs.TeamId = v_WinnerTeamId THEN 1
            ELSE 0
        END AS IsWinner
    FROM RankedStats rs
    ORDER BY 
        rs.Points DESC,
        rs.TotalNetPoints DESC,
        rs.HeadToHeadWins DESC,
        rs.GoldenStrikeWins DESC,
        rs.TeamId ASC;

    SELECT v_SeasonStatus AS SeasonStatus;

END$$

DELIMITER ;
