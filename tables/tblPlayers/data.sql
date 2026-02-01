INSERT INTO tblPlayers (Id, FirstName, LastName, DateOfBirth, NationalityId, AvatarUrl)
VALUES
    (1, 'Arijit', 'Roy', '2000-07-02', 102, 'https://lh3.googleusercontent.com/pw/AP1GczMPp0ohBmJBb8-pZtqoS7cloF2JJRRNogB-OJ8oPO0PvVnXdwRiyOc1V_zulWrRdBmNDHFcDFwtSkFS48JkawIJ0LpXXUgj6FNFiGA84SN9FTDQZrcjGMa0kftuzSR7yU8ypEGkOLc2d33og9RSagaRvg=w500-h500-s-no-gm?authuser=0'),
    (2, 'Sanchar', 'Bagh', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczMjRdm59jvJIHnRj0q514dvDMaJyJqnsECA-XD2glBqosGKGyMLkOCeQuKaV8iOBsG8HZFg12fTQbYln7uOggQCoXOc-f-LE3vNg45bOavB5TP1Ogq25vO8gWrN93bNwQl0SpZO5aul4No9Psrf13b0vQ=w500-h500-s-no-gm?authuser=0'),
    (3, 'Avirup', 'Saha', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczPjXqJX79aKxXi-mtIOOJvdeMGL1w404m0mEas1O6woBcQW0hzPmGY4oDhhTCzxPo-GQ21iCWctRDwP7j5hZBJvjW1Bfg4kvF350JSvpus6d0sAvUoHCYGBrc4KerC6gMcCyk5cmSsV8VXDoSjIfRlnuA=w500-h500-s-no-gm?authuser=0'),
    (4, 'Tusar', 'Maji', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczPVAeMXI8RhoN6jiHVmRcvAzc_Y0sQlFSei6-VQsefm-YhNjdRUyOiifmtf4GzBbJkq0_pL0mLI-BswShS1DrGEhQfPMlhFexth5j7E63UfbGXjf0UKI19zmISWHN8nmS3hhJsJ1caJbCm0MVLQ_pWXzw=w500-h500-s-no-gm?authuser=0'),
    (5, 'Tushar', 'Roy', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczMhQVNL4gLQ2E1z87kKQOiFmwxJdZGpiXuiaDu3dzfAtCtWDavZUjEJeJ2ibqlIEPliEZL3C7XppClGhN9lrYufREmLqzC9tabNXXNljmHLMu_oCr2YeXrchQvUofN94OZgjg0a3MIIoYrbx1gdceJApQ=w500-h500-s-no-gm?authuser=0'),
    (6, 'Debjit', 'Pal', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczPoo0sDOdxHBQvWSo-cZiQNmNb3tQ9_0moUZXz2hHNl2SZ5aCX1kgJn8MEEcTDPjnW6xUdpfcsTLtt9OZoBE-okI2mVAmAvuvdI84jgpN2aj488srQKWEHv8mw6y901_arkc9NSzM7--povzqxOWMP7iw=w500-h500-s-no-gm?authuser=0'),
    (7, 'Sohan', 'Ghosh', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczPOdLR8sj-rYJh7hL-k6ZhDf2FJk47mc8hi-bizY5wIhVnbO6lkj2Msx9JnMg76Z8_OZ8qC2dMPfEhZlXEzDEkHiABKz5B1KMvsddQsbH-8LuYabp6kCuxadFqyYBMWhv8orVi3Z8x0kyLbmfiIsyK1rw=w500-h500-s-no-gm?authuser=0'),
    (8, 'Sisir K', 'Bagh', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczOSCK1ZTZyk2VcNnqkYmiCs65IOnOAB4S3DPayev3hqqCNk57LEXQe50Olxl8rGxUNhwN2HL3eWUICi4sGH5CcV7Qa4FaPaIJv2up32hvnvVv3PMT497CO-W8KNgPdKpqqSugD1wI8kyOFPx8_gzRbGdA=w500-h500-s-no-gm?authuser=0'),
    (9, 'Arghya K', 'Mishra', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczOqFF3Ag3IRJ9gIpA108ddjNUhyI0Guon3cYCf3dnBdojlEv_cEnW2q6J3_f4eYuZbp9EnnPZJEcRhEWy2YFB9EeyjQH8BgFVfmN8nhVE2-io4V6Alqe-IIPPyD0YtuIb2srnHKP3IhqW0TUgl16zXWJg=w500-h500-s-no-gm?authuser=0'),
    (10, 'Ajit', 'Saha', NULL, 102, 'https://lh3.googleusercontent.com/pw/AP1GczNgWM5pJ8xpLhOUuGngtfBwVZ9lvLy4Hvo18TDJIH68n4smh-jQOyP0ws50m29N7_iIgVINNX1eKn_7Ct0KRkX7PQPuNCv7A7RNn8j0yzZymeM06u0LJNNAo1w4HRKI0X-sz7ebzjTsvta1bJn4zQy-6g=w500-h500-s-no-gm?authuser=0')
ON DUPLICATE KEY UPDATE
    FirstName = VALUES(FirstName),
    LastName = VALUES(LastName),
    DateOfBirth = VALUES(DateOfBirth),
    NationalityId = VALUES(NationalityId),
    AvatarUrl = VALUES(AvatarUrl);
