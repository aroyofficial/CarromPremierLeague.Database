SET @tableName = 'tblCountries';

-- Unique index for Name
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD UNIQUE (Name);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND INDEX_NAME = 'Name'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Unique index for IsoCode2
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD UNIQUE (IsoCode2);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND INDEX_NAME = 'IsoCode2'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Unique index for IsoCode3
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblCountries ADD UNIQUE (IsoCode3);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tableName AND INDEX_NAME = 'IsoCode3'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;