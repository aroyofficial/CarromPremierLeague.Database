SET @pk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblCountries'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@pk_exists = 0,
    'ALTER TABLE tblCountries ADD CONSTRAINT PK_tblCountries PRIMARY KEY (Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
