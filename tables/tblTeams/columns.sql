SET @tableName = 'tblTeams';

-- Name column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblTeams ADD COLUMN Name VARCHAR(255) NOT NULL;',
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


-- Slogan column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblTeams ADD COLUMN Slogan VARCHAR(500);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'Slogan'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- LogoUrl column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblTeams ADD COLUMN LogoUrl VARCHAR(2048);',
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
