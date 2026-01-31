SET @tableName = 'tblCountries';

-- Name column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD COLUMN Name VARCHAR(255) NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND COLUMN_NAME = 'Name'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- IsoCode2 column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD COLUMN IsoCode2 VARCHAR(2) NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND COLUMN_NAME = 'IsoCode2'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- IsoCode3 column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD COLUMN IsoCode3 VARCHAR(3) NOT NULL;',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND COLUMN_NAME = 'IsoCode3'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Capital column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD COLUMN Capital VARCHAR(255);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND COLUMN_NAME = 'Capital'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- PhoneCode column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD COLUMN PhoneCode VARCHAR(20);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND COLUMN_NAME = 'PhoneCode'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Continent column
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD COLUMN Continent VARCHAR(255);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND COLUMN_NAME = 'Continent'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
