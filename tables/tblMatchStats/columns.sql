SET @tableName = 'tblMatchStats';

-- MatchId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD COLUMN MatchId BIGINT NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'MatchId'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- PlayerId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD COLUMN PlayerId BIGINT NOT NULL;',
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

-- CoinsPocketed column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD COLUMN CoinsPocketed TINYINT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'CoinsPocketed'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- StrikersPocketed column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD COLUMN StrikersPocketed TINYINT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'StrikersPocketed'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- CoinsFined column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD COLUMN CoinsFined TINYINT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'CoinsFined'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ShotsTaken column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD COLUMN ShotsTaken TINYINT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'ShotsTaken'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
