INSERT INTO tblTeams (Id, Name, Slogan, LogoUrl)
VALUES
    (1, 'Ghoshpara Strikers', 'Roar of the Board', 'https://lh3.googleusercontent.com/pw/AP1GczOwWRqbzRxtbAczr1cjZP9G2x768va2xxxMR8KOJQiwAz2JP7J2fqgR0bVDSfQAVIWsBhw17tXqE_o0sdVYdO3F9CKlWXi88KwtU1O-WTyHZG8EgthasTuF3lzpBYPw67PYB4GKq_-DldsZ7C2NC2LXww=w346-h346-s-no-gm?authuser=0'),
    (2, 'Sasthitala Smashers', 'Power in Every Pocket', 'https://lh3.googleusercontent.com/pw/AP1GczP_u52hNJ_vg4neAlzdgA0rENSokLRe_VY4HWcdMSpGFQ4ZDqpdh_TJR7so88ddvSlJjwhnaSss1rc_JQ3weg0K9m20G_478-jdC5oEUOmvezt1mHds-bxZIeRhO3YDKAYJQ7OxWJFisyPSdkbzmAkI_A=w346-h346-s-no-gm?authuser=0'),
    (3, 'Santinagar Slayers', 'Strike to Conquer', 'https://lh3.googleusercontent.com/pw/AP1GczOr0OX5wyDx05jYk57OJp-dTD4lx_nIJ3cZ1epup267Y9dZUc9jNR8Nu53ayqrWWo5IvpPN2rhiH96Zqlzz46Q_pVXwlkFxAxo91unV7D6cSJbvk6H6vR6tghHAJL-BY9mCjhuUqewM6zrHzhTM0pHSGQ=w346-h346-s-no-gm?authuser=0'),
    (4, 'Nischinda Ninjas', 'Silent, Sharp, Superior', 'https://lh3.googleusercontent.com/pw/AP1GczM2jls5q1Ehv3Rwx-b3Q0QtLPIJih-taVZgb1RdyofOZwfMyEN_WYXLyx-82sCt-mIrvgzKiP8MpG5lHVFnUDsEe8KeHfCOyMMf2AgmAJtFjw9on20s_F48NPCHMiWjDI3RZXDyOLQ9HHBmy8KJo8eqQw=w346-h346-s-no-gm?authuser=0')
ON DUPLICATE KEY UPDATE
    Name = VALUES(Name),
    Slogan = VALUES(Slogan),
    LogoUrl = VALUES(LogoUrl);
