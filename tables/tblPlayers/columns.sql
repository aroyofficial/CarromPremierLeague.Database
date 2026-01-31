SET @tableName = 'tblPlayers';

-- FirstName column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayers ADD COLUMN FirstName VARCHAR(255) NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'FirstName'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- LastName column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayers ADD COLUMN LastName VARCHAR(255) NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'LastName'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- DateOfBirth column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayers ADD COLUMN DateOfBirth DATE;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'DateOfBirth'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- AvatarUrl column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayers ADD COLUMN AvatarUrl VARCHAR(2048);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'AvatarUrl'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- NationalityId column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayers ADD COLUMN NationalityId BIGINT;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND COLUMN_NAME = 'NationalityId'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
