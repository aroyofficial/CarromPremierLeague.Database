INSERT INTO tblTeams (Id, Name, Slogan, LogoUrl)
VALUES
    (1, 'Ghoshpara Strikers', 'Roar of the Board', NULL),
    (2, 'Sasthitala Smashers', 'Power in Every Pocket', NULL),
    (3, 'Santinagar Slayers', 'Strike to Conquer', NULL),
    (4, 'Nischinda Ninjas', 'Silent, Sharp, Superior', NULL),
    (5, 'Kumillapara Kings', 'Crown of the Board', NULL),
    (6, 'Dum Dum Diamonds', 'Brilliance of the Board', NULL)
ON DUPLICATE KEY UPDATE
    Name = VALUES(Name),
    Slogan = VALUES(Slogan),
    LogoUrl = VALUES(LogoUrl);
