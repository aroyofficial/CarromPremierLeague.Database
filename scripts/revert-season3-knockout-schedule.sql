-- Reverses the season 3 knockout schedule: removes the Eliminator (Id 147) and the Final (Id 148)
-- that were scheduled after the league stage. Only rows that are still untouched (Scheduled, no
-- outcome, no stats) are removed, and the whole change rolls back if the row count is not exactly 2.

BEGIN TRANSACTION;

DECLARE @Expected INT = 2;
DECLARE @Deleted INT;

IF EXISTS (
    SELECT 1 FROM tblMatchStats
    WHERE MatchId IN (147, 148)
)
BEGIN
    RAISERROR('Knockout matches already have stats. Nothing was reverted.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END

DELETE FROM tblMatches
WHERE Id IN (147, 148)
  AND SeasonId = 3
  AND Category IN (2, 3)
  AND Status = 1
  AND Outcome = 3
  AND [Order] IN (16, 17);

SET @Deleted = @@ROWCOUNT;

IF @Deleted <> @Expected
BEGIN
    RAISERROR('Expected to remove 2 knockout matches; nothing was reverted.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END

COMMIT TRANSACTION;
