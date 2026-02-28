DELIMITER $$

DROP PROCEDURE IF EXISTS usp_GetSeasonTopCoinPotters$$

CREATE PROCEDURE usp_GetSeasonTopCoinPotters(
    IN p_SeasonId BIGINT,
    IN p_Limit INT
)
BEGIN
    DECLARE v_Limit INT DEFAULT 3;

    SET v_Limit = IFNULL(p_Limit, 3);
    IF v_Limit <= 0 THEN
        SET v_Limit = 3;
    END IF;

    SELECT
        ms.PlayerId,
        p.FirstName,
        p.LastName,
        p.AvatarUrl,
        pst.TeamId,
        t.Name AS TeamName,
        SUM(IFNULL(ms.CoinsPocketed, 0)) AS CoinsPocketed
    FROM tblMatchStats ms
    INNER JOIN tblMatches m
        ON m.Id = ms.MatchId
       AND m.Void = 0
    INNER JOIN tblPlayers p
        ON p.Id = ms.PlayerId
       AND p.Void = 0
    LEFT JOIN tblPlayersSeasonsTeams pst
        ON pst.PlayerId = ms.PlayerId
       AND pst.SeasonId = m.SeasonId
       AND pst.Void = 0
    LEFT JOIN tblTeams t
        ON t.Id = pst.TeamId
       AND t.Void = 0
    WHERE m.SeasonId = p_SeasonId
      AND m.Category = 1
      AND m.Status = 3
    GROUP BY
        ms.PlayerId,
        p.FirstName,
        p.LastName,
        p.AvatarUrl,
        pst.TeamId,
        t.Name
    ORDER BY
        CoinsPocketed DESC,
        p.FirstName ASC,
        p.LastName ASC
    LIMIT v_Limit;
END$$

DELIMITER ;
