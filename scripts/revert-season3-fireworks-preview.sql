-- Restore 2026 Season 3 to the scheduled league that existed before the fireworks preview.
-- Run this only after the live-site fireworks have been checked and approved.
-- Do not run it twice.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-19 15:10:35.816776' WHERE Id = 130 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:57.849022' WHERE Id = 131 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:58.017773' WHERE Id = 132 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:58.190412' WHERE Id = 133 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:58.360006' WHERE Id = 134 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:58.527742' WHERE Id = 135 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:58.697655' WHERE Id = 136 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:58.865372' WHERE Id = 137 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:59.035285' WHERE Id = 138 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:59.202918' WHERE Id = 139 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:59.378748' WHERE Id = 140 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:59.549433' WHERE Id = 141 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:59.717955' WHERE Id = 142 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:07:59.889294' WHERE Id = 143 AND SeasonId = 3 AND Category = 1;
UPDATE dbo.tblMatches SET Status = 1, Outcome = 3, NetPoints = NULL, TossOutcome = 3, Duration = NULL, Extra = NULL, GoldenStrike = 0, StartedAt = NULL, ExtraStartedAt = NULL, UpdatedAt = '2026-11-18 19:08:00.057774' WHERE Id = 144 AND SeasonId = 3 AND Category = 1;
DELETE FROM dbo.tblMatchStats WHERE MatchId IN (145, 146);
DELETE FROM dbo.tblMatches WHERE SeasonId = 3 AND Id IN (145, 146) AND Category IN (2, 3);
COMMIT TRANSACTION;
