-- Undoes the simulated results for season 3 matches 1-14.
-- Match 15 (Nischinda Ninjas vs Kumillapara Kings) is not touched.
-- After this script those fourteen matches are Scheduled again, with no scorecard.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DELETE ms
FROM dbo.tblMatchStats AS ms
INNER JOIN dbo.tblMatches AS m ON m.Id = ms.MatchId
WHERE m.SeasonId = 3
  AND m.[Order] BETWEEN 1 AND 14
  AND m.Void = 0;

UPDATE dbo.tblMatches
SET Status = 1,
    Outcome = 3,
    TossOutcome = 3,
    NetPoints = NULL,
    Duration = NULL,
    Extra = NULL,
    GoldenStrike = 0,
    StartedAt = NULL,
    ExtraStartedAt = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHERE SeasonId = 3
  AND [Order] BETWEEN 1 AND 14
  AND Void = 0;

COMMIT TRANSACTION;
