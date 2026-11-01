SET @fk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblSeasonsTeams'
      AND CONSTRAINT_NAME = 'FK_tblSeasonsTeams_tblSeasons'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE tblSeasonsTeams ADD CONSTRAINT FK_tblSeasonsTeams_tblSeasons FOREIGN KEY (SeasonId) REFERENCES tblSeasons(Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblSeasonsTeams'
      AND CONSTRAINT_NAME = 'FK_tblSeasonsTeams_tblTeams'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE tblSeasonsTeams ADD CONSTRAINT FK_tblSeasonsTeams_tblTeams FOREIGN KEY (TeamId) REFERENCES tblTeams(Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
