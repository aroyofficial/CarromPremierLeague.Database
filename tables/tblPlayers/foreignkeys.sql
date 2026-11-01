SET @fk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblPlayers'
      AND CONSTRAINT_NAME = 'FK_tblPlayers_tblCountries'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE tblPlayers ADD CONSTRAINT FK_tblPlayers_tblCountries FOREIGN KEY (NationalityId) REFERENCES tblCountries(Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tblPlayers'
      AND CONSTRAINT_NAME = 'FK_tblPlayers_tblSeasons_Debut'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE tblPlayers ADD CONSTRAINT FK_tblPlayers_tblSeasons_Debut FOREIGN KEY (DebutSeasonId) REFERENCES tblSeasons(Id);',
    'DO 0;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
