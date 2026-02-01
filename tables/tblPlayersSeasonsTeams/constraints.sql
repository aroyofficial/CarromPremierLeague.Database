SET @pk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblPlayersSeasonsTeams'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@pk_exists = 0,
    'ALTER TABLE tblPlayersSeasonsTeams ADD CONSTRAINT PK_tblPlayersSeasonsTeams PRIMARY KEY (Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


SET @tableName = 'tblPlayersSeasonsTeams';
SET @constraintName = 'UC_Player_Season';

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE tblPlayersSeasonsTeams ADD CONSTRAINT UC_Player_Season UNIQUE (PlayerId, SeasonId);',
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
