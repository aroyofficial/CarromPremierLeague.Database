SET @pk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblMatchStats'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@pk_exists = 0,
    'ALTER TABLE tblMatchStats ADD CONSTRAINT PK_tblMatchStats PRIMARY KEY (Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


SET @tableName = 'tblMatchStats';
SET @constraintName = 'UC_Match_Player';

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblMatchStats ADD CONSTRAINT UC_Match_Player UNIQUE (MatchId, PlayerId);',
        'DO 0;'
    )
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND CONSTRAINT_NAME = @constraintName
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
