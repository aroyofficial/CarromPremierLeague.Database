SET @tableName = 'tblPlayersSeasonsTeams';

-- PlayerId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayersSeasonsTeams ADD COLUMN PlayerId BIGINT NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'PlayerId'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- SeasonId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayersSeasonsTeams ADD COLUMN SeasonId BIGINT NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'SeasonId'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- TeamId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayersSeasonsTeams ADD COLUMN TeamId BIGINT NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'TeamId'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
