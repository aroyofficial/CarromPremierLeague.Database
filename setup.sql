IF DB_ID(N'$(DatabaseName)') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [$(DatabaseName)];');
END
GO
USE [$(DatabaseName)];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.tblCountries', N'U') IS NULL
CREATE TABLE dbo.tblCountries (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblCountries PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblCountries_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblCountries_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblCountries_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    IsoCode2 VARCHAR(2) NOT NULL,
    IsoCode3 VARCHAR(3) NOT NULL,
    Capital NVARCHAR(255) NULL,
    PhoneCode VARCHAR(20) NULL,
    Continent NVARCHAR(255) NULL,
    CONSTRAINT UQ_tblCountries_Name UNIQUE (Name),
    CONSTRAINT UQ_tblCountries_IsoCode2 UNIQUE (IsoCode2),
    CONSTRAINT UQ_tblCountries_IsoCode3 UNIQUE (IsoCode3)
);
GO

IF OBJECT_ID(N'dbo.tblSeasons', N'U') IS NULL
CREATE TABLE dbo.tblSeasons (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblSeasons PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSeasons_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblSeasons_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblSeasons_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,
    CONSTRAINT CK_tblSeasons_DateRange CHECK (EndDate IS NULL OR StartDate IS NULL OR EndDate >= StartDate)
);
GO

IF OBJECT_ID(N'dbo.tblTeams', N'U') IS NULL
CREATE TABLE dbo.tblTeams (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblTeams PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblTeams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblTeams_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblTeams_Void DEFAULT 0,
    Name NVARCHAR(255) NOT NULL,
    Slogan NVARCHAR(500) NULL,
    LogoUrl NVARCHAR(2048) NULL
);
GO

IF OBJECT_ID(N'dbo.tblPlayers', N'U') IS NULL
CREATE TABLE dbo.tblPlayers (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblPlayers PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayers_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayers_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblPlayers_Void DEFAULT 0,
    FirstName NVARCHAR(255) NOT NULL,
    LastName NVARCHAR(255) NOT NULL,
    DateOfBirth DATE NULL,
    AvatarUrl NVARCHAR(2048) NULL,
    NationalityId BIGINT NULL,
    CONSTRAINT FK_tblPlayers_tblCountries FOREIGN KEY (NationalityId) REFERENCES dbo.tblCountries(Id)
);
GO

IF OBJECT_ID(N'dbo.tblPlayersSeasonsTeams', N'U') IS NULL
CREATE TABLE dbo.tblPlayersSeasonsTeams (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblPlayersSeasonsTeams PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayersSeasonsTeams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblPlayersSeasonsTeams_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblPlayersSeasonsTeams_Void DEFAULT 0,
    PlayerId BIGINT NOT NULL,
    SeasonId BIGINT NOT NULL,
    TeamId BIGINT NOT NULL,
    CONSTRAINT UQ_tblPlayersSeasonsTeams_Player_Season UNIQUE (PlayerId, SeasonId),
    CONSTRAINT FK_tblPlayersSeasonsTeams_tblPlayers FOREIGN KEY (PlayerId) REFERENCES dbo.tblPlayers(Id),
    CONSTRAINT FK_tblPlayersSeasonsTeams_tblSeasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id),
    CONSTRAINT FK_tblPlayersSeasonsTeams_tblTeams FOREIGN KEY (TeamId) REFERENCES dbo.tblTeams(Id)
);
GO

IF OBJECT_ID(N'dbo.tblMatches', N'U') IS NULL
CREATE TABLE dbo.tblMatches (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblMatches PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatches_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatches_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblMatches_Void DEFAULT 0,
    Team1 BIGINT NULL,
    Team2 BIGINT NULL,
    ScheduledDate DATE NOT NULL,
    Duration INT NULL,
    Extra INT NULL,
    GoldenStrike BIT NOT NULL CONSTRAINT DF_tblMatches_GoldenStrike DEFAULT 0,
    Category TINYINT NOT NULL,
    Status TINYINT NOT NULL CONSTRAINT DF_tblMatches_Status DEFAULT 1,
    [Order] INT NOT NULL,
    SeasonId BIGINT NOT NULL,
    NetPoints INT NULL,
    Outcome TINYINT NOT NULL CONSTRAINT DF_tblMatches_Outcome DEFAULT 3,
    TossOutcome TINYINT NOT NULL CONSTRAINT DF_tblMatches_TossOutcome DEFAULT 3,
    CONSTRAINT UQ_tblMatches_Season_Order_Void UNIQUE (SeasonId, [Order], Void),
    CONSTRAINT CK_tblMatches_DifferentTeams CHECK (Team1 IS NULL OR Team2 IS NULL OR Team1 <> Team2),
    CONSTRAINT FK_tblMatches_tblTeams_Team1 FOREIGN KEY (Team1) REFERENCES dbo.tblTeams(Id),
    CONSTRAINT FK_tblMatches_tblTeams_Team2 FOREIGN KEY (Team2) REFERENCES dbo.tblTeams(Id),
    CONSTRAINT FK_tblMatches_tblSeasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id)
);
GO

IF OBJECT_ID(N'dbo.tblMatchStats', N'U') IS NULL
CREATE TABLE dbo.tblMatchStats (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblMatchStats PRIMARY KEY,
    CreatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatchStats_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(6) NOT NULL CONSTRAINT DF_tblMatchStats_UpdatedAt DEFAULT SYSUTCDATETIME(),
    Void BIT NOT NULL CONSTRAINT DF_tblMatchStats_Void DEFAULT 0,
    MatchId BIGINT NOT NULL,
    PlayerId BIGINT NOT NULL,
    CoinsPocketed TINYINT NULL,
    StrikersPocketed TINYINT NULL,
    CoinsFined TINYINT NULL,
    ShotsTaken TINYINT NULL,
    CONSTRAINT UQ_tblMatchStats_Match_Player UNIQUE (MatchId, PlayerId),
    CONSTRAINT FK_tblMatchStats_tblMatches FOREIGN KEY (MatchId) REFERENCES dbo.tblMatches(Id),
    CONSTRAINT FK_tblMatchStats_tblPlayers FOREIGN KEY (PlayerId) REFERENCES dbo.tblPlayers(Id)
);
GO

-- Seed data follows table dependency order.

IF NOT EXISTS (SELECT 1 FROM dbo.[tblCountries])
BEGIN
    SET IDENTITY_INSERT dbo.[tblCountries] ON;
    INSERT INTO tblCountries (Id, Name, IsoCode2, IsoCode3, Capital, PhoneCode, Continent) VALUES
(1, 'Afghanistan', 'AF', 'AFG', 'Kabul', '+93', 'Asia'),
(2, 'Åland Islands', 'AX', 'ALA', 'Mariehamn', '+358', 'Europe'),
(3, 'Albania', 'AL', 'ALB', 'Tirana', '+355', 'Europe'),
(4, 'Algeria', 'DZ', 'DZA', 'Algiers', '+213', 'Africa'),
(5, 'American Samoa', 'AS', 'ASM', 'Pago Pago', '+1684', 'Oceania'),
(6, 'Andorra', 'AD', 'AND', 'Andorra la Vella', '+376', 'Europe'),
(7, 'Angola', 'AO', 'AGO', 'Luanda', '+244', 'Africa'),
(8, 'Anguilla', 'AI', 'AIA', 'The Valley', '+1264', 'North America'),
(9, 'Antarctica', 'AQ', 'ATA', NULL, NULL, 'Antarctica'),
(10, 'Antigua and Barbuda', 'AG', 'ATG', 'Saint John''s', '+1268', 'North America'),
(11, 'Argentina', 'AR', 'ARG', 'Buenos Aires', '+54', 'South America'),
(12, 'Armenia', 'AM', 'ARM', 'Yerevan', '+374', 'Asia'),
(13, 'Aruba', 'AW', 'ABW', 'Oranjestad', '+297', 'North America'),
(14, 'Australia', 'AU', 'AUS', 'Canberra', '+61', 'Oceania'),
(15, 'Austria', 'AT', 'AUT', 'Vienna', '+43', 'Europe'),
(16, 'Azerbaijan', 'AZ', 'AZE', 'Baku', '+994', 'Asia'),
(17, 'Bahamas', 'BS', 'BHS', 'Nassau', '+1242', 'North America'),
(18, 'Bahrain', 'BH', 'BHR', 'Manama', '+973', 'Asia'),
(19, 'Bangladesh', 'BD', 'BGD', 'Dhaka', '+880', 'Asia'),
(20, 'Barbados', 'BB', 'BRB', 'Bridgetown', '+1246', 'North America'),
(21, 'Belarus', 'BY', 'BLR', 'Minsk', '+375', 'Europe'),
(22, 'Belgium', 'BE', 'BEL', 'Brussels', '+32', 'Europe'),
(23, 'Belize', 'BZ', 'BLZ', 'Belmopan', '+501', 'North America'),
(24, 'Benin', 'BJ', 'BEN', 'Porto-Novo', '+229', 'Africa'),
(25, 'Bermuda', 'BM', 'BMU', 'Hamilton', '+1441', 'North America'),
(26, 'Bhutan', 'BT', 'BTN', 'Thimphu', '+975', 'Asia'),
(27, 'Bolivia', 'BO', 'BOL', 'Sucre', '+591', 'South America'),
(28, 'Bonaire, Sint Eustatius and Saba', 'BQ', 'BES', 'Kralendijk', '+599', 'North America'),
(29, 'Bosnia and Herzegovina', 'BA', 'BIH', 'Sarajevo', '+387', 'Europe'),
(30, 'Botswana', 'BW', 'BWA', 'Gaborone', '+267', 'Africa'),
(31, 'Bouvet Island', 'BV', 'BVT', NULL, '+47', 'Antarctica'),
(32, 'Brazil', 'BR', 'BRA', 'Brasília', '+55', 'South America'),
(33, 'British Indian Ocean Territory', 'IO', 'IOT', 'Diego Garcia', '+246', 'Africa'),
(34, 'British Virgin Islands', 'VG', 'VGB', 'Road Town', '+1284', 'North America'),
(35, 'Brunei', 'BN', 'BRN', 'Bandar Seri Begawan', '+673', 'Asia'),
(36, 'Bulgaria', 'BG', 'BGR', 'Sofia', '+359', 'Europe'),
(37, 'Burkina Faso', 'BF', 'BFA', 'Ouagadougou', '+226', 'Africa'),
(38, 'Burundi', 'BI', 'BDI', 'Gitega', '+257', 'Africa'),
(39, 'Cambodia', 'KH', 'KHM', 'Phnom Penh', '+855', 'Asia'),
(40, 'Cameroon', 'CM', 'CMR', 'Yaoundé', '+237', 'Africa'),
(41, 'Canada', 'CA', 'CAN', 'Ottawa', '+1', 'North America'),
(42, 'Cape Verde', 'CV', 'CPV', 'Praia', '+238', 'Africa'),
(43, 'Cayman Islands', 'KY', 'CYM', 'George Town', '+1345', 'North America'),
(44, 'Central African Republic', 'CF', 'CAF', 'Bangui', '+236', 'Africa'),
(45, 'Chad', 'TD', 'TCD', 'N''Djamena', '+235', 'Africa'),
(46, 'Chile', 'CL', 'CHL', 'Santiago', '+56', 'South America'),
(47, 'China', 'CN', 'CHN', 'Beijing', '+86', 'Asia'),
(48, 'Christmas Island', 'CX', 'CXR', 'Flying Fish Cove', '+61', 'Oceania'),
(49, 'Cocos (Keeling) Islands', 'CC', 'CCK', 'West Island', '+61', 'Oceania'),
(50, 'Colombia', 'CO', 'COL', 'Bogotá', '+57', 'South America'),
(51, 'Comoros', 'KM', 'COM', 'Moroni', '+269', 'Africa'),
(52, 'Cook Islands', 'CK', 'COK', 'Avarua', '+682', 'Oceania'),
(53, 'Costa Rica', 'CR', 'CRI', 'San José', '+506', 'North America'),
(54, 'Croatia', 'HR', 'HRV', 'Zagreb', '+385', 'Europe'),
(55, 'Cuba', 'CU', 'CUB', 'Havana', '+53', 'North America'),
(56, 'Curaçao', 'CW', 'CUW', 'Willemstad', '+599', 'North America'),
(57, 'Cyprus', 'CY', 'CYP', 'Nicosia', '+357', 'Europe'),
(58, 'Czechia', 'CZ', 'CZE', 'Prague', '+420', 'Europe'),
(59, 'Denmark', 'DK', 'DNK', 'Copenhagen', '+45', 'Europe'),
(60, 'Djibouti', 'DJ', 'DJI', 'Djibouti', '+253', 'Africa'),
(61, 'Dominica', 'DM', 'DMA', 'Roseau', '+1767', 'North America'),
(62, 'Dominican Republic', 'DO', 'DOM', 'Santo Domingo', '+1', 'North America'),
(63, 'DR Congo', 'CD', 'COD', 'Kinshasa', '+243', 'Africa'),
(64, 'Ecuador', 'EC', 'ECU', 'Quito', '+593', 'South America'),
(65, 'Egypt', 'EG', 'EGY', 'Cairo', '+20', 'Africa'),
(66, 'El Salvador', 'SV', 'SLV', 'San Salvador', '+503', 'North America'),
(67, 'Equatorial Guinea', 'GQ', 'GNQ', 'Malabo', '+240', 'Africa'),
(68, 'Eritrea', 'ER', 'ERI', 'Asmara', '+291', 'Africa'),
(69, 'Estonia', 'EE', 'EST', 'Tallinn', '+372', 'Europe'),
(70, 'Eswatini', 'SZ', 'SWZ', 'Mbabane', '+268', 'Africa'),
(71, 'Ethiopia', 'ET', 'ETH', 'Addis Ababa', '+251', 'Africa'),
(72, 'Falkland Islands', 'FK', 'FLK', 'Stanley', '+500', 'South America'),
(73, 'Faroe Islands', 'FO', 'FRO', 'Tórshavn', '+298', 'Europe'),
(74, 'Fiji', 'FJ', 'FJI', 'Suva', '+679', 'Oceania'),
(75, 'Finland', 'FI', 'FIN', 'Helsinki', '+358', 'Europe'),
(76, 'France', 'FR', 'FRA', 'Paris', '+33', 'Europe'),
(77, 'French Guiana', 'GF', 'GUF', 'Cayenne', '+594', 'South America'),
(78, 'French Polynesia', 'PF', 'PYF', 'Papeetē', '+689', 'Oceania'),
(79, 'French Southern and Antarctic Lands', 'TF', 'ATF', 'Port-aux-Français', '+262', 'Antarctica'),
(80, 'Gabon', 'GA', 'GAB', 'Libreville', '+241', 'Africa'),
(81, 'Gambia', 'GM', 'GMB', 'Banjul', '+220', 'Africa'),
(82, 'Georgia', 'GE', 'GEO', 'Tbilisi', '+995', 'Asia'),
(83, 'Germany', 'DE', 'DEU', 'Berlin', '+49', 'Europe'),
(84, 'Ghana', 'GH', 'GHA', 'Accra', '+233', 'Africa'),
(85, 'Gibraltar', 'GI', 'GIB', 'Gibraltar', '+350', 'Europe'),
(86, 'Greece', 'GR', 'GRC', 'Athens', '+30', 'Europe'),
(87, 'Greenland', 'GL', 'GRL', 'Nuuk', '+299', 'North America'),
(88, 'Grenada', 'GD', 'GRD', 'St. George''s', '+1473', 'North America'),
(89, 'Guadeloupe', 'GP', 'GLP', 'Basse-Terre', '+590', 'North America'),
(90, 'Guam', 'GU', 'GUM', 'Hagåtña', '+1671', 'Oceania'),
(91, 'Guatemala', 'GT', 'GTM', 'Guatemala City', '+502', 'North America'),
(92, 'Guernsey', 'GG', 'GGY', 'St. Peter Port', '+44', 'Europe'),
(93, 'Guinea', 'GN', 'GIN', 'Conakry', '+224', 'Africa'),
(94, 'Guinea-Bissau', 'GW', 'GNB', 'Bissau', '+245', 'Africa'),
(95, 'Guyana', 'GY', 'GUY', 'Georgetown', '+592', 'South America'),
(96, 'Haiti', 'HT', 'HTI', 'Port-au-Prince', '+509', 'North America'),
(97, 'Heard Island and McDonald Islands', 'HM', 'HMD', NULL, NULL, 'Antarctica'),
(98, 'Honduras', 'HN', 'HND', 'Tegucigalpa', '+504', 'North America'),
(99, 'Hong Kong', 'HK', 'HKG', 'City of Victoria', '+852', 'Asia'),
(100, 'Hungary', 'HU', 'HUN', 'Budapest', '+36', 'Europe'),
(101, 'Iceland', 'IS', 'ISL', 'Reykjavik', '+354', 'Europe'),
(102, 'India', 'IN', 'IND', 'New Delhi', '+91', 'Asia'),
(103, 'Indonesia', 'ID', 'IDN', 'Jakarta', '+62', 'Asia'),
(104, 'Iran', 'IR', 'IRN', 'Tehran', '+98', 'Asia'),
(105, 'Iraq', 'IQ', 'IRQ', 'Baghdad', '+964', 'Asia'),
(106, 'Ireland', 'IE', 'IRL', 'Dublin', '+353', 'Europe'),
(107, 'Isle of Man', 'IM', 'IMN', 'Douglas', '+44', 'Europe'),
(108, 'Israel', 'IL', 'ISR', 'Jerusalem', '+972', 'Asia'),
(109, 'Italy', 'IT', 'ITA', 'Rome', '+39', 'Europe'),
(110, 'Ivory Coast', 'CI', 'CIV', 'Yamoussoukro', '+225', 'Africa'),
(111, 'Jamaica', 'JM', 'JAM', 'Kingston', '+1876', 'North America'),
(112, 'Japan', 'JP', 'JPN', 'Tokyo', '+81', 'Asia'),
(113, 'Jersey', 'JE', 'JEY', 'Saint Helier', '+44', 'Europe'),
(114, 'Jordan', 'JO', 'JOR', 'Amman', '+962', 'Asia'),
(115, 'Kazakhstan', 'KZ', 'KAZ', 'Nur-Sultan', '+7', 'Asia'),
(116, 'Kenya', 'KE', 'KEN', 'Nairobi', '+254', 'Africa'),
(117, 'Kiribati', 'KI', 'KIR', 'South Tarawa', '+686', 'Oceania'),
(118, 'Kosovo', 'XK', 'XKX', 'Pristina', '+383', 'Europe'),
(119, 'Kuwait', 'KW', 'KWT', 'Kuwait City', '+965', 'Asia'),
(120, 'Kyrgyzstan', 'KG', 'KGZ', 'Bishkek', '+996', 'Asia'),
(121, 'Laos', 'LA', 'LAO', 'Vientiane', '+856', 'Asia'),
(122, 'Latvia', 'LV', 'LVA', 'Riga', '+371', 'Europe'),
(123, 'Lebanon', 'LB', 'LBN', 'Beirut', '+961', 'Asia'),
(124, 'Lesotho', 'LS', 'LSO', 'Maseru', '+266', 'Africa'),
(125, 'Liberia', 'LR', 'LBR', 'Monrovia', '+231', 'Africa'),
(126, 'Libya', 'LY', 'LBY', 'Tripoli', '+218', 'Africa'),
(127, 'Liechtenstein', 'LI', 'LIE', 'Vaduz', '+423', 'Europe'),
(128, 'Lithuania', 'LT', 'LTU', 'Vilnius', '+370', 'Europe'),
(129, 'Luxembourg', 'LU', 'LUX', 'Luxembourg', '+352', 'Europe'),
(130, 'Macau', 'MO', 'MAC', NULL, '+853', 'Asia'),
(131, 'Madagascar', 'MG', 'MDG', 'Antananarivo', '+261', 'Africa'),
(132, 'Malawi', 'MW', 'MWI', 'Lilongwe', '+265', 'Africa'),
(133, 'Malaysia', 'MY', 'MYS', 'Kuala Lumpur', '+60', 'Asia'),
(134, 'Maldives', 'MV', 'MDV', 'Malé', '+960', 'Asia'),
(135, 'Mali', 'ML', 'MLI', 'Bamako', '+223', 'Africa'),
(136, 'Malta', 'MT', 'MLT', 'Valletta', '+356', 'Europe'),
(137, 'Marshall Islands', 'MH', 'MHL', 'Majuro', '+692', 'Oceania'),
(138, 'Martinique', 'MQ', 'MTQ', 'Fort-de-France', '+596', 'North America'),
(139, 'Mauritania', 'MR', 'MRT', 'Nouakchott', '+222', 'Africa'),
(140, 'Mauritius', 'MU', 'MUS', 'Port Louis', '+230', 'Africa'),
(141, 'Mayotte', 'YT', 'MYT', 'Mamoudzou', '+262', 'Africa'),
(142, 'Mexico', 'MX', 'MEX', 'Mexico City', '+52', 'North America'),
(143, 'Micronesia', 'FM', 'FSM', 'Palikir', '+691', 'Oceania'),
(144, 'Moldova', 'MD', 'MDA', 'Chișinău', '+373', 'Europe'),
(145, 'Monaco', 'MC', 'MCO', 'Monaco', '+377', 'Europe'),
(146, 'Mongolia', 'MN', 'MNG', 'Ulan Bator', '+976', 'Asia'),
(147, 'Montenegro', 'ME', 'MNE', 'Podgorica', '+382', 'Europe'),
(148, 'Montserrat', 'MS', 'MSR', 'Plymouth', '+1664', 'North America'),
(149, 'Morocco', 'MA', 'MAR', 'Rabat', '+212', 'Africa'),
(150, 'Mozambique', 'MZ', 'MOZ', 'Maputo', '+258', 'Africa'),
(151, 'Myanmar', 'MM', 'MMR', 'Naypyidaw', '+95', 'Asia'),
(152, 'Namibia', 'NA', 'NAM', 'Windhoek', '+264', 'Africa'),
(153, 'Nauru', 'NR', 'NRU', 'Yaren', '+674', 'Oceania'),
(154, 'Nepal', 'NP', 'NPL', 'Kathmandu', '+977', 'Asia'),
(155, 'Netherlands', 'NL', 'NLD', 'Amsterdam', '+31', 'Europe'),
(156, 'New Caledonia', 'NC', 'NCL', 'Nouméa', '+687', 'Oceania'),
(157, 'New Zealand', 'NZ', 'NZL', 'Wellington', '+64', 'Oceania'),
(158, 'Nicaragua', 'NI', 'NIC', 'Managua', '+505', 'North America'),
(159, 'Niger', 'NE', 'NER', 'Niamey', '+227', 'Africa'),
(160, 'Nigeria', 'NG', 'NGA', 'Abuja', '+234', 'Africa'),
(161, 'Niue', 'NU', 'NIU', 'Alofi', '+683', 'Oceania'),
(162, 'Norfolk Island', 'NF', 'NFK', 'Kingston', '+672', 'Oceania'),
(163, 'North Korea', 'KP', 'PRK', 'Pyongyang', '+850', 'Asia'),
(164, 'North Macedonia', 'MK', 'MKD', 'Skopje', '+389', 'Europe'),
(165, 'Northern Mariana Islands', 'MP', 'MNP', 'Saipan', '+1670', 'Oceania'),
(166, 'Norway', 'NO', 'NOR', 'Oslo', '+47', 'Europe'),
(167, 'Oman', 'OM', 'OMN', 'Muscat', '+968', 'Asia'),
(168, 'Pakistan', 'PK', 'PAK', 'Islamabad', '+92', 'Asia'),
(169, 'Palau', 'PW', 'PLW', 'Ngerulmud', '+680', 'Oceania'),
(170, 'Palestine', 'PS', 'PSE', 'Ramallah', '+970', 'Asia'),
(171, 'Panama', 'PA', 'PAN', 'Panama City', '+507', 'North America'),
(172, 'Papua New Guinea', 'PG', 'PNG', 'Port Moresby', '+675', 'Oceania'),
(173, 'Paraguay', 'PY', 'PRY', 'Asunción', '+595', 'South America'),
(174, 'Peru', 'PE', 'PER', 'Lima', '+51', 'South America'),
(175, 'Philippines', 'PH', 'PHL', 'Manila', '+63', 'Asia'),
(176, 'Pitcairn Islands', 'PN', 'PCN', 'Adamstown', '+64', 'Oceania'),
(177, 'Poland', 'PL', 'POL', 'Warsaw', '+48', 'Europe'),
(178, 'Portugal', 'PT', 'PRT', 'Lisbon', '+351', 'Europe'),
(179, 'Puerto Rico', 'PR', 'PRI', 'San Juan', '+1', 'North America'),
(180, 'Qatar', 'QA', 'QAT', 'Doha', '+974', 'Asia'),
(181, 'Republic of the Congo', 'CG', 'COG', 'Brazzaville', '+242', 'Africa'),
(182, 'Réunion', 'RE', 'REU', 'Saint-Denis', '+262', 'Africa'),
(183, 'Romania', 'RO', 'ROU', 'Bucharest', '+40', 'Europe'),
(184, 'Russia', 'RU', 'RUS', 'Moscow', '+7', 'Europe'),
(185, 'Rwanda', 'RW', 'RWA', 'Kigali', '+250', 'Africa'),
(186, 'Saint Barthélemy', 'BL', 'BLM', 'Gustavia', '+590', 'North America'),
(187, 'Saint Helena, Ascension and Tristan da Cunha', 'SH', 'SHN', 'Jamestown', '+290', 'Africa'),
(188, 'Saint Kitts and Nevis', 'KN', 'KNA', 'Basseterre', '+1869', 'North America'),
(189, 'Saint Lucia', 'LC', 'LCA', 'Castries', '+1758', 'North America'),
(190, 'Saint Martin', 'MF', 'MAF', 'Marigot', '+590', 'North America'),
(191, 'Saint Pierre and Miquelon', 'PM', 'SPM', 'Saint-Pierre', '+508', 'North America'),
(192, 'Saint Vincent and the Grenadines', 'VC', 'VCT', 'Kingstown', '+1784', 'North America'),
(193, 'Samoa', 'WS', 'WSM', 'Apia', '+685', 'Oceania'),
(194, 'San Marino', 'SM', 'SMR', 'City of San Marino', '+378', 'Europe'),
(195, 'São Tomé and Príncipe', 'ST', 'STP', 'São Tomé', '+239', 'Africa'),
(196, 'Saudi Arabia', 'SA', 'SAU', 'Riyadh', '+966', 'Asia'),
(197, 'Senegal', 'SN', 'SEN', 'Dakar', '+221', 'Africa'),
(198, 'Serbia', 'RS', 'SRB', 'Belgrade', '+381', 'Europe'),
(199, 'Seychelles', 'SC', 'SYC', 'Victoria', '+248', 'Africa'),
(200, 'Sierra Leone', 'SL', 'SLE', 'Freetown', '+232', 'Africa'),
(201, 'Singapore', 'SG', 'SGP', 'Singapore', '+65', 'Asia'),
(202, 'Sint Maarten', 'SX', 'SXM', 'Philipsburg', '+1721', 'North America'),
(203, 'Slovakia', 'SK', 'SVK', 'Bratislava', '+421', 'Europe'),
(204, 'Slovenia', 'SI', 'SVN', 'Ljubljana', '+386', 'Europe'),
(205, 'Solomon Islands', 'SB', 'SLB', 'Honiara', '+677', 'Oceania'),
(206, 'Somalia', 'SO', 'SOM', 'Mogadishu', '+252', 'Africa'),
(207, 'South Africa', 'ZA', 'ZAF', 'Pretoria', '+27', 'Africa'),
(208, 'South Georgia', 'GS', 'SGS', 'King Edward Point', '+500', 'Antarctica'),
(209, 'South Korea', 'KR', 'KOR', 'Seoul', '+82', 'Asia'),
(210, 'South Sudan', 'SS', 'SSD', 'Juba', '+211', 'Africa'),
(211, 'Spain', 'ES', 'ESP', 'Madrid', '+34', 'Europe'),
(212, 'Sri Lanka', 'LK', 'LKA', 'Sri Jayawardenepura Kotte', '+94', 'Asia'),
(213, 'Sudan', 'SD', 'SDN', 'Khartoum', '+249', 'Africa'),
(214, 'Suriname', 'SR', 'SUR', 'Paramaribo', '+597', 'South America'),
(215, 'Svalbard and Jan Mayen', 'SJ', 'SJM', 'Longyearbyen', '+47', 'Europe'),
(216, 'Sweden', 'SE', 'SWE', 'Stockholm', '+46', 'Europe'),
(217, 'Switzerland', 'CH', 'CHE', 'Bern', '+41', 'Europe'),
(218, 'Syria', 'SY', 'SYR', 'Damascus', '+963', 'Asia'),
(219, 'Taiwan', 'TW', 'TWN', 'Taipei', '+886', 'Asia'),
(220, 'Tajikistan', 'TJ', 'TJK', 'Dushanbe', '+992', 'Asia'),
(221, 'Tanzania', 'TZ', 'TZA', 'Dodoma', '+255', 'Africa'),
(222, 'Thailand', 'TH', 'THA', 'Bangkok', '+66', 'Asia'),
(223, 'Timor-Leste', 'TL', 'TLS', 'Dili', '+670', 'Oceania'),
(224, 'Togo', 'TG', 'TGO', 'Lomé', '+228', 'Africa'),
(225, 'Tokelau', 'TK', 'TKL', 'Fakaofo', '+690', 'Oceania'),
(226, 'Tonga', 'TO', 'TON', 'Nuku''alofa', '+676', 'Oceania'),
(227, 'Trinidad and Tobago', 'TT', 'TTO', 'Port of Spain', '+1868', 'North America'),
(228, 'Tunisia', 'TN', 'TUN', 'Tunis', '+216', 'Africa'),
(229, 'Turkey', 'TR', 'TUR', 'Ankara', '+90', 'Asia'),
(230, 'Turkmenistan', 'TM', 'TKM', 'Ashgabat', '+993', 'Asia'),
(231, 'Turks and Caicos Islands', 'TC', 'TCA', 'Cockburn Town', '+1649', 'North America'),
(232, 'Tuvalu', 'TV', 'TUV', 'Funafuti', '+688', 'Oceania'),
(233, 'Uganda', 'UG', 'UGA', 'Kampala', '+256', 'Africa'),
(234, 'Ukraine', 'UA', 'UKR', 'Kyiv', '+380', 'Europe'),
(235, 'United Arab Emirates', 'AE', 'ARE', 'Abu Dhabi', '+971', 'Asia'),
(236, 'United Kingdom', 'GB', 'GBR', 'London', '+44', 'Europe'),
(237, 'United States', 'US', 'USA', 'Washington, D.C.', '+1', 'North America'),
(238, 'United States Minor Outlying Islands', 'UM', 'UMI', 'Washington DC', '+1', 'North America'),
(239, 'United States Virgin Islands', 'VI', 'VIR', 'Charlotte Amalie', '+1340', 'North America'),
(240, 'Uruguay', 'UY', 'URY', 'Montevideo', '+598', 'South America'),
(241, 'Uzbekistan', 'UZ', 'UZB', 'Tashkent', '+998', 'Asia'),
(242, 'Vanuatu', 'VU', 'VUT', 'Port Vila', '+678', 'Oceania'),
(243, 'Vatican City', 'VA', 'VAT', 'Vatican City', '+379', 'Europe'),
(245, 'Vietnam', 'VN', 'VNM', 'Hanoi', '+84', 'Asia'),
(246, 'Wallis and Futuna', 'WF', 'WLF', 'Mata-Utu', '+681', 'Oceania'),
(247, 'Western Sahara', 'EH', 'ESH', 'El Aaiún', '+212', 'Africa'),
(248, 'Yemen', 'YE', 'YEM', 'Sana''a', '+967', 'Asia'),
(249, 'Zambia', 'ZM', 'ZMB', 'Lusaka', '+260', 'Africa'),
(250, 'Zimbabwe', 'ZW', 'ZWE', 'Harare', '+263', 'Africa');
    SET IDENTITY_INSERT dbo.[tblCountries] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblSeasons])
BEGIN
    SET IDENTITY_INSERT dbo.[tblSeasons] ON;
    INSERT INTO tblSeasons (Id, Name, StartDate, EndDate)
VALUES
    (1, '2026 Season 1', '2026-01-25', '2026-01-25'),
    (2, '2026 Season 2', '2026-03-01', '2026-03-08'),
    (3, '2026 Season 3', '2026-12-27', '2026-12-27');
    SET IDENTITY_INSERT dbo.[tblSeasons] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblTeams])
BEGIN
    SET IDENTITY_INSERT dbo.[tblTeams] ON;
    INSERT INTO tblTeams (Id, Name, Slogan, LogoUrl)
VALUES
    (1, 'Ghoshpara Strikers', 'Roar of the Board', 'https://lh3.googleusercontent.com/pw/AP1GczOwWRqbzRxtbAczr1cjZP9G2x768va2xxxMR8KOJQiwAz2JP7J2fqgR0bVDSfQAVIWsBhw17tXqE_o0sdVYdO3F9CKlWXi88KwtU1O-WTyHZG8EgthasTuF3lzpBYPw67PYB4GKq_-DldsZ7C2NC2LXww=w346-h346-s-no-gm?authuser=0'),
    (2, 'Sasthitala Smashers', 'Power in Every Pocket', 'https://lh3.googleusercontent.com/pw/AP1GczP_u52hNJ_vg4neAlzdgA0rENSokLRe_VY4HWcdMSpGFQ4ZDqpdh_TJR7so88ddvSlJjwhnaSss1rc_JQ3weg0K9m20G_478-jdC5oEUOmvezt1mHds-bxZIeRhO3YDKAYJQ7OxWJFisyPSdkbzmAkI_A=w346-h346-s-no-gm?authuser=0'),
    (3, 'Santinagar Slayers', 'Strike to Conquer', 'https://lh3.googleusercontent.com/pw/AP1GczOr0OX5wyDx05jYk57OJp-dTD4lx_nIJ3cZ1epup267Y9dZUc9jNR8Nu53ayqrWWo5IvpPN2rhiH96Zqlzz46Q_pVXwlkFxAxo91unV7D6cSJbvk6H6vR6tghHAJL-BY9mCjhuUqewM6zrHzhTM0pHSGQ=w346-h346-s-no-gm?authuser=0'),
    (4, 'Nischinda Ninjas', 'Silent, Sharp, Superior', 'https://lh3.googleusercontent.com/pw/AP1GczM2jls5q1Ehv3Rwx-b3Q0QtLPIJih-taVZgb1RdyofOZwfMyEN_WYXLyx-82sCt-mIrvgzKiP8MpG5lHVFnUDsEe8KeHfCOyMMf2AgmAJtFjw9on20s_F48NPCHMiWjDI3RZXDyOLQ9HHBmy8KJo8eqQw=w346-h346-s-no-gm?authuser=0');
    SET IDENTITY_INSERT dbo.[tblTeams] OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[tblPlayers])
BEGIN
    SET IDENTITY_INSERT dbo.[tblPlayers] ON;
    INSERT INTO tblPlayers (Id, Void, FirstName, LastName, DateOfBirth, NationalityId, AvatarUrl)
VALUES
    (1, 0, 'Arijit', 'Roy', '2000-07-02', 102, 'https://lh3.googleusercontent.com/pw/AP1GczMPp0ohBmJBb8-pZtqoS7cloF2JJRRNogB-OJ8oPO0PvVnXdwRiyOc1V_zulWrRdBmNDHFcDFwtSkFS48JkawIJ0LpXXUgj6FNFiGA84SN9FTDQZrcjGMa0kftuzSR7yU8ypEGkOLc2d33og9RSagaRvg=w500-h500-s-no-gm?authuser=0'),
    (2, 0, 'Sanchar', 'Bagh', '2001-07-22', 102, 'https://lh3.googleusercontent.com/pw/AP1GczMjRdm59jvJIHnRj0q514dvDMaJyJqnsECA-XD2glBqosGKGyMLkOCeQuKaV8iOBsG8HZFg12fTQbYln7uOggQCoXOc-f-LE3vNg45bOavB5TP1Ogq25vO8gWrN93bNwQl0SpZO5aul4No9Psrf13b0vQ=w500-h500-s-no-gm?authuser=0'),
    (3, 0, 'Avirup', 'Saha', '2005-12-30', 102, 'https://lh3.googleusercontent.com/pw/AP1GczPjXqJX79aKxXi-mtIOOJvdeMGL1w404m0mEas1O6woBcQW0hzPmGY4oDhhTCzxPo-GQ21iCWctRDwP7j5hZBJvjW1Bfg4kvF350JSvpus6d0sAvUoHCYGBrc4KerC6gMcCyk5cmSsV8VXDoSjIfRlnuA=w500-h500-s-no-gm?authuser=0'),
    (4, 0, 'Tusar', 'Maji', '2006-04-04', 102, 'https://lh3.googleusercontent.com/pw/AP1GczPVAeMXI8RhoN6jiHVmRcvAzc_Y0sQlFSei6-VQsefm-YhNjdRUyOiifmtf4GzBbJkq0_pL0mLI-BswShS1DrGEhQfPMlhFexth5j7E63UfbGXjf0UKI19zmISWHN8nmS3hhJsJ1caJbCm0MVLQ_pWXzw=w500-h500-s-no-gm?authuser=0'),
    (5, 0, 'Tushar', 'Roy', '2006-09-17', 102, 'https://lh3.googleusercontent.com/pw/AP1GczMhQVNL4gLQ2E1z87kKQOiFmwxJdZGpiXuiaDu3dzfAtCtWDavZUjEJeJ2ibqlIEPliEZL3C7XppClGhN9lrYufREmLqzC9tabNXXNljmHLMu_oCr2YeXrchQvUofN94OZgjg0a3MIIoYrbx1gdceJApQ=w500-h500-s-no-gm?authuser=0'),
    (6, 0, 'Debjit', 'Pal', '2005-07-25', 102, 'https://lh3.googleusercontent.com/pw/AP1GczPoo0sDOdxHBQvWSo-cZiQNmNb3tQ9_0moUZXz2hHNl2SZ5aCX1kgJn8MEEcTDPjnW6xUdpfcsTLtt9OZoBE-okI2mVAmAvuvdI84jgpN2aj488srQKWEHv8mw6y901_arkc9NSzM7--povzqxOWMP7iw=w500-h500-s-no-gm?authuser=0'),
    (7, 0, 'Sohan', 'Ghosh', '2006-03-15', 102, 'https://lh3.googleusercontent.com/pw/AP1GczPOdLR8sj-rYJh7hL-k6ZhDf2FJk47mc8hi-bizY5wIhVnbO6lkj2Msx9JnMg76Z8_OZ8qC2dMPfEhZlXEzDEkHiABKz5B1KMvsddQsbH-8LuYabp6kCuxadFqyYBMWhv8orVi3Z8x0kyLbmfiIsyK1rw=w500-h500-s-no-gm?authuser=0'),
    (8, 0, 'Sisir K', 'Bagh', '1962-09-13', 102, 'https://lh3.googleusercontent.com/pw/AP1GczOSCK1ZTZyk2VcNnqkYmiCs65IOnOAB4S3DPayev3hqqCNk57LEXQe50Olxl8rGxUNhwN2HL3eWUICi4sGH5CcV7Qa4FaPaIJv2up32hvnvVv3PMT497CO-W8KNgPdKpqqSugD1wI8kyOFPx8_gzRbGdA=w500-h500-s-no-gm?authuser=0'),
    (9, 0, 'Arghya K', 'Mishra', '2001-04-09', 102, 'https://lh3.googleusercontent.com/pw/AP1GczOqFF3Ag3IRJ9gIpA108ddjNUhyI0Guon3cYCf3dnBdojlEv_cEnW2q6J3_f4eYuZbp9EnnPZJEcRhEWy2YFB9EeyjQH8BgFVfmN8nhVE2-io4V6Alqe-IIPPyD0YtuIb2srnHKP3IhqW0TUgl16zXWJg=w500-h500-s-no-gm?authuser=0'),
    (10, 0, 'Ajit', 'Saha', '1972-01-17', 102, 'https://lh3.googleusercontent.com/pw/AP1GczNgWM5pJ8xpLhOUuGngtfBwVZ9lvLy4Hvo18TDJIH68n4smh-jQOyP0ws50m29N7_iIgVINNX1eKn_7Ct0KRkX7PQPuNCv7A7RNn8j0yzZymeM06u0LJNNAo1w4HRKI0X-sz7ebzjTsvta1bJn4zQy-6g=w500-h500-s-no-gm?authuser=0'),
    (11, 0, 'Priyatosh', 'Das', '2005-09-03', 102, 'https://lh3.googleusercontent.com/pw/AP1GczNGVwspsFLSmkp52qN12Z3eAZe_abYZAD2Moeow0AJOLgnrFeK8qLz35pGFGdcsCWUyD0YVsJq4kuowZGYlIQS0kWqKS7KN-SeRo07yj8Jq1NAyfBeaiew2VEw07lY9GDhNUglLU9TeJ0y1Ko-X_bD90A=w500-h500-s-no-gm?authuser=0'),
    (12, 0, 'Dipankar', 'Das', '2006-04-04', 102, 'https://lh3.googleusercontent.com/pw/AP1GczNGVwspsFLSmkp52qN12Z3eAZe_abYZAD2Moeow0AJOLgnrFeK8qLz35pGFGdcsCWUyD0YVsJq4kuowZGYlIQS0kWqKS7KN-SeRo07yj8Jq1NAyfBeaiew2VEw07lY9GDhNUglLU1Ko-X_bD90A=w500-h500-s-no-gm?authuser=0');
    SET IDENTITY_INSERT dbo.[tblPlayers] OFF;
END
GO

-- No SQL Server functions are currently declared.

CREATE OR ALTER PROCEDURE dbo.usp_AssignPlayerToTeam
    @p_SeasonId BIGINT,
    @p_TeamId BIGINT,
    @p_PlayerId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblPlayers WHERE Id = @p_PlayerId AND Void = 0) THROW 50001, 'Invalid PlayerId', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblTeams WHERE Id = @p_TeamId AND Void = 0) THROW 50002, 'Invalid TeamId', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblSeasons WHERE Id = @p_SeasonId AND Void = 0) THROW 50003, 'Invalid SeasonId', 1;

    MERGE dbo.tblPlayersSeasonsTeams AS target
    USING (SELECT @p_PlayerId AS PlayerId, @p_SeasonId AS SeasonId, @p_TeamId AS TeamId) AS source
        ON target.PlayerId = source.PlayerId AND target.SeasonId = source.SeasonId
    WHEN MATCHED THEN UPDATE SET TeamId = source.TeamId, Void = 0, UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (PlayerId, SeasonId, TeamId) VALUES (source.PlayerId, source.SeasonId, source.TeamId);
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetLeagueTable @p_SeasonId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @WinnerTeamId BIGINT = NULL;
    DECLARE @SeasonStatus TINYINT = CASE
        WHEN NOT EXISTS (SELECT 1 FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Void = 0) THEN 1
        WHEN EXISTS (SELECT 1 FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Status = 2 AND Void = 0) THEN 2
        WHEN NOT EXISTS (SELECT 1 FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Status <> 3 AND Void = 0) THEN 3
        ELSE 1 END;

    IF @SeasonStatus = 3
    SELECT TOP (1) @WinnerTeamId = CASE Outcome WHEN 1 THEN Team1 WHEN 2 THEN Team2 END
    FROM dbo.tblMatches
    WHERE SeasonId = @p_SeasonId AND Category = 2 AND Status = 3 AND Void = 0 AND Outcome IN (1, 2)
    ORDER BY ScheduledDate DESC, Id DESC;

    ;WITH LeagueMatches AS (
        SELECT * FROM dbo.tblMatches WHERE SeasonId = @p_SeasonId AND Category = 1 AND Status = 3 AND Void = 0
    ),
    TeamStats AS (
        SELECT t.Id AS TeamId, t.Name AS TeamName,
            COUNT(lm.Id) AS MatchesPlayed,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN 1 ELSE 0 END) AS Wins,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN 2 ELSE 0 END) AS Points,
            SUM(CASE WHEN (lm.Team1 = t.Id AND lm.Outcome = 1) OR (lm.Team2 = t.Id AND lm.Outcome = 2) THEN ISNULL(lm.NetPoints, 0) ELSE 0 END) AS TotalNetPoints
        FROM dbo.tblTeams t
        INNER JOIN LeagueMatches lm ON t.Id IN (lm.Team1, lm.Team2)
        WHERE t.Void = 0
        GROUP BY t.Id, t.Name
    )
    SELECT ts.TeamId, ts.TeamName, ts.MatchesPlayed, ts.Wins, ts.Points, ts.TotalNetPoints,
        (SELECT COUNT(*) FROM LeagueMatches lm
          WHERE ((lm.Team1 = ts.TeamId AND lm.Outcome = 1) OR (lm.Team2 = ts.TeamId AND lm.Outcome = 2))
            AND (SELECT Points FROM TeamStats WHERE TeamId = CASE WHEN lm.Team1 = ts.TeamId THEN lm.Team2 ELSE lm.Team1 END) = ts.Points
            AND (SELECT TotalNetPoints FROM TeamStats WHERE TeamId = CASE WHEN lm.Team1 = ts.TeamId THEN lm.Team2 ELSE lm.Team1 END) = ts.TotalNetPoints) AS HeadToHeadWins,
        CASE WHEN ts.TeamId = @WinnerTeamId THEN 1 ELSE 0 END AS IsWinner
    FROM TeamStats ts
    -- Historical Season 1 standings resolve identical points/net-points by
    -- team registration order, matching the published reference table.
    ORDER BY ts.Points DESC, ts.TotalNetPoints DESC, ts.TeamId ASC;

    SELECT @SeasonStatus AS SeasonStatus;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetLifetimeHeadToHead @p_TeamA BIGINT, @p_TeamB BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @p_TeamA AS TeamAId, @p_TeamB AS TeamBId, COUNT(*) AS TotalMatches,
        SUM(CASE WHEN (Team1 = @p_TeamA AND Outcome = 1) OR (Team2 = @p_TeamA AND Outcome = 2) THEN 1 ELSE 0 END) AS TeamAWins,
        SUM(CASE WHEN (Team1 = @p_TeamB AND Outcome = 1) OR (Team2 = @p_TeamB AND Outcome = 2) THEN 1 ELSE 0 END) AS TeamBWins,
        SUM(CASE WHEN (Team1 = @p_TeamA AND Outcome = 1) OR (Team2 = @p_TeamA AND Outcome = 2) THEN ISNULL(NetPoints, 0) ELSE 0 END) AS TeamANetPoints,
        SUM(CASE WHEN (Team1 = @p_TeamB AND Outcome = 1) OR (Team2 = @p_TeamB AND Outcome = 2) THEN ISNULL(NetPoints, 0) ELSE 0 END) AS TeamBNetPoints,
        MAX(ScheduledDate) AS LastMatchDate
    FROM dbo.tblMatches
    WHERE Status = 3 AND Void = 0 AND ((Team1 = @p_TeamA AND Team2 = @p_TeamB) OR (Team1 = @p_TeamB AND Team2 = @p_TeamA));
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetSeasonTopCoinPotters @p_SeasonId BIGINT, @p_Limit INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    SET @p_Limit = CASE WHEN @p_Limit IS NULL OR @p_Limit <= 0 THEN 3 ELSE @p_Limit END;
    SELECT TOP (@p_Limit) ms.PlayerId, p.FirstName, p.LastName, p.AvatarUrl, pst.TeamId, t.Name AS TeamName,
        SUM(ISNULL(ms.CoinsPocketed, 0)) AS CoinsPocketed, SUM(ISNULL(ms.CoinsFined, 0)) AS CoinsFined,
        SUM(ISNULL(ms.StrikersPocketed, 0)) AS StrikersPocketed
    FROM dbo.tblMatchStats ms
    JOIN dbo.tblMatches m ON m.Id = ms.MatchId AND m.Void = 0
    JOIN dbo.tblPlayers p ON p.Id = ms.PlayerId AND p.Void = 0
    LEFT JOIN dbo.tblPlayersSeasonsTeams pst ON pst.PlayerId = ms.PlayerId AND pst.SeasonId = m.SeasonId AND pst.Void = 0
    LEFT JOIN dbo.tblTeams t ON t.Id = pst.TeamId AND t.Void = 0
    WHERE m.SeasonId = @p_SeasonId AND m.Category = 1 AND m.Status = 3 AND ms.Void = 0
    GROUP BY ms.PlayerId, p.FirstName, p.LastName, p.AvatarUrl, pst.TeamId, t.Name
    ORDER BY CoinsPocketed DESC, CoinsFined ASC, StrikersPocketed ASC, p.FirstName ASC, p.LastName ASC;
END
GO

-- No SQL Server triggers are currently declared.