SET @tableName = 'tblMatches';

-- Team1 column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Team1 BIGINT NULL;',
        'ALTER TABLE tblMatches MODIFY COLUMN Team1 BIGINT NULL;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Team1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Team2 column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Team2 BIGINT NULL;',
        'ALTER TABLE tblMatches MODIFY COLUMN Team2 BIGINT NULL;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Team2'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ScheduledDate column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN ScheduledDate DATE NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'ScheduledDate'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Duration column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Duration INT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Duration'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Extra column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Extra INT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Extra'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- GoldenStrike column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN GoldenStrike BIT NOT NULL DEFAULT 0;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'GoldenStrike'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Category column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Category TINYINT NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Category'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Status column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Status TINYINT NOT NULL DEFAULT 1;',
        'DO 0;' 
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Status'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Order column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN `Order` TINYINT NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Order'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- SeasonId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN SeasonId BIGINT NOT NULL;',
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

-- NetPoints column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN NetPoints TINYINT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'NetPoints'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Outcome column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN Outcome TINYINT DEFAULT 3;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Outcome'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- TossOutcome column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatches ADD COLUMN TossOutcome TINYINT DEFAULT 3;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'TossOutcome'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

