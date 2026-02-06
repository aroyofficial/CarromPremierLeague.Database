SET @pk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblMatches'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@pk_exists = 0,
    'ALTER TABLE tblMatches ADD CONSTRAINT PK_tblMatches PRIMARY KEY (Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check if unique constraint already exists
SET @unique_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblMatches'
      AND CONSTRAINT_NAME = 'UQ_tblMatches_Season_Order_Void'
);

-- Create constraint only if not exists
SET @sql = IF(@unique_exists = 0,
    'ALTER TABLE tblMatches 
     ADD CONSTRAINT UQ_tblMatches_Season_Order_Void 
     UNIQUE (SeasonId, `Order`, Void);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
