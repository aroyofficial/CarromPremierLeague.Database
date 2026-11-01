SET @constraint_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblSeasonsTeams'
      AND CONSTRAINT_NAME = 'PK_tblSeasonsTeams'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE tblSeasonsTeams ADD CONSTRAINT PK_tblSeasonsTeams PRIMARY KEY (Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @tableName = 'tblSeasonsTeams';
SET @constraintName = 'UC_Season_Team';

SET @constraint_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = @tableName
      AND CONSTRAINT_NAME = @constraintName
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE tblSeasonsTeams ADD CONSTRAINT UC_Season_Team UNIQUE (SeasonId, TeamId);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
