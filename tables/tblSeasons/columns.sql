SET @tableName = 'tblSeasons';

-- Name column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblSeasons ADD COLUMN Name VARCHAR(255) NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Name'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- StartDate column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblSeasons ADD COLUMN StartDate DATE;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'StartDate'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- EndDate column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblSeasons ADD COLUMN EndDate DATE;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'EndDate'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- LogoUrl column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblSeasons ADD COLUMN LogoUrl VARCHAR(2048);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'LogoUrl'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblSeasons'
      AND COLUMN_NAME = 'LogoUrl'
);

SET @sql = IF(@column_exists = 1,
    'ALTER TABLE tblSeasons DROP COLUMN LogoUrl;',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- LogoUrl column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblSeasons ADD COLUMN Status TINYINT DEFAULT 1;',
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