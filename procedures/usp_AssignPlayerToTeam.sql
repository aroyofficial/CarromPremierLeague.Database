DELIMITER $$

DROP PROCEDURE IF EXISTS usp_AssignPlayerToTeam$$

CREATE PROCEDURE usp_AssignPlayerToTeam(
    IN p_SeasonId BIGINT,
    IN p_TeamId BIGINT,
    IN p_PlayerId BIGINT
)
BEGIN

    DECLARE v_PlayerExists INT DEFAULT 0;
    DECLARE v_TeamExists INT DEFAULT 0;
    DECLARE v_SeasonExists INT DEFAULT 0;

    -- Validate Player
    SELECT COUNT(*) INTO v_PlayerExists
    FROM tblPlayers
    WHERE Id = p_PlayerId AND Void = 0;

    IF v_PlayerExists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid PlayerId';
    END IF;

    -- Validate Team
    SELECT COUNT(*) INTO v_TeamExists
    FROM tblTeams
    WHERE Id = p_TeamId AND Void = 0;

    IF v_TeamExists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid TeamId';
    END IF;

    -- Validate Season
    SELECT COUNT(*) INTO v_SeasonExists
    FROM tblSeasons
    WHERE Id = p_SeasonId AND Void = 0;

    IF v_SeasonExists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid SeasonId';
    END IF;

    -- Insert or Update (transfer logic)
    INSERT INTO tblPlayersSeasonsTeams (PlayerId, SeasonId, TeamId)
    VALUES (p_PlayerId, p_SeasonId, p_TeamId)
    ON DUPLICATE KEY UPDATE
        TeamId = VALUES(TeamId),
        UpdatedAt = CURRENT_TIMESTAMP(6);

END$$

DELIMITER ;
