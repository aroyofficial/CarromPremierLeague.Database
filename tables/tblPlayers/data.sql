INSERT INTO tblPlayers (Id, Void, FirstName, LastName, DateOfBirth, NationalityId, AvatarUrl, DebutSeasonId)
VALUES
    (1, 0, 'Arijit', 'Roy', '2000-07-02', 102, NULL, 3),
    (2, 0, 'Sanchar', 'Bagh', '2001-07-22', 102, NULL, 3),
    (3, 0, 'Avirup', 'Saha', '2005-12-30', 102, NULL, 3),
    (4, 0, 'Tusar', 'Maji', '2006-04-04', 102, NULL, 3),
    (5, 0, 'Tushar', 'Roy', '2006-09-17', 102, NULL, 3),
    (6, 0, 'Debjit', 'Pal', '2005-07-25', 102, NULL, 3),
    (7, 0, 'Sohan', 'Ghosh', '2006-03-15', 102, NULL, 3),
    (8, 0, 'Sisir K', 'Bagh', '1962-09-13', 102, NULL, 3),
    (9, 0, 'Arghya K', 'Mishra', '2001-04-09', 102, NULL, 3),
    (10, 0, 'Ajit', 'Saha', '1972-01-17', 102, NULL, 3),
    (11, 0, 'Priyatosh', 'Das', '2005-09-03', 102, NULL, 3),
    (12, 0, 'Dipankar', 'Das', '2006-04-04', 102, NULL, 3),
    (13, 0, 'Imon', 'Bagh', '1990-08-01', 102, NULL, 3),
    (14, 0, 'Akash', 'Gupta', '2003-08-07', 102, NULL, 3),
    (15, 0, 'Rupankar', 'Das', '2003-09-15', 102, NULL, 3)
ON DUPLICATE KEY UPDATE
    FirstName = VALUES(FirstName),
    LastName = VALUES(LastName),
    DateOfBirth = VALUES(DateOfBirth),
    NationalityId = VALUES(NationalityId),
    AvatarUrl = VALUES(AvatarUrl),
    DebutSeasonId = VALUES(DebutSeasonId),
    Void = VALUES(Void);
