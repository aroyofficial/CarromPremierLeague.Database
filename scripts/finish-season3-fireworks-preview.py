"""Finish 2026 Season 3 on the live database so the site can show the champion.

Writes scripts/revert-season3-fireworks-preview.sql from the rows it changes,
then marks the 15 league matches played, adds a played eliminator and final,
and commits only if the league table reports the season finished.

Refuses to run unless season 3 is still the untouched scheduled league.
The reversal script is not executed here.
"""

import sys
from pathlib import Path

sys.path.insert(0, r"C:\DevLabs\CarromPremierLeague.API")

from core.database import Database

SEASON_ID = 3
SCRIPT_DIR = Path(__file__).resolve().parent
REVERSAL = SCRIPT_DIR / "revert-season3-fireworks-preview.sql"

# (team1, team2, outcome). Outcome 1 means team1 won. Net coins are 2, so no tie.
# Ghoshpara Strikers (1) win the league, Nischinda Ninjas (4) finish second,
# Kumillapara Kings (5) finish third.
LEAGUE = {
    130: (1, 6, 1),
    131: (2, 5, 2),
    132: (3, 4, 2),
    133: (1, 5, 1),
    134: (6, 4, 2),
    135: (2, 3, 1),
    136: (1, 4, 1),
    137: (5, 3, 1),
    138: (6, 2, 2),
    139: (1, 3, 1),
    140: (4, 2, 1),
    141: (5, 6, 1),
    142: (1, 2, 1),
    143: (3, 6, 1),
    144: (4, 5, 1),
}

# 2nd (Nischinda Ninjas) beat 3rd (Kumillapara Kings).
# 1st (Ghoshpara Strikers) then beat the Ninjas in the final.
ELIMINATOR = (4, 5, 1)
FINAL = (1, 4, 1)


def sql_value(value):
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("'", "''")
    return f"'{text}'"


def main():
    connection = Database.get_connection()
    cursor = connection.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT Id, Name, [Show] AS Shown, Void
            FROM tblSeasons
            WHERE Id = %s
            """,
            (SEASON_ID,),
        )
        season = cursor.fetchone()
        if not season or season["Void"] or not season["Shown"] or season["Name"] != "2026 Season 3":
            raise SystemExit(f"season 3 is not the shown 2026 Season 3: {season}")

        cursor.execute(
            """
            SELECT Id, Team1, Team2, Category, Status, Outcome, NetPoints, TossOutcome,
                   Duration, Extra, GoldenStrike, StartedAt, ExtraStartedAt, UpdatedAt, Void
            FROM tblMatches
            WHERE SeasonId = %s
            ORDER BY Id
            """,
            (SEASON_ID,),
        )
        rows = cursor.fetchall()
        by_id = {int(row["Id"]): row for row in rows}
        if set(by_id) != set(LEAGUE):
            raise SystemExit(f"season 3 matches are not the 15 scheduled league fixtures: {sorted(by_id)}")
        for match_id, (team1, team2, _outcome) in LEAGUE.items():
            row = by_id[match_id]
            if (
                int(row["Team1"]) != team1
                or int(row["Team2"]) != team2
                or int(row["Category"]) != 1
                or int(row["Status"]) != 1
                or int(row["Outcome"]) != 3
                or row["NetPoints"] is not None
                or row["Void"]
            ):
                raise SystemExit(f"match {match_id} is not an untouched scheduled league match: {row}")

        lines = [
            "-- Restore 2026 Season 3 to the scheduled league that existed before the fireworks preview.",
            "-- Run this only after the live-site fireworks have been checked and approved.",
            "-- Do not run it twice.",
            "SET XACT_ABORT ON;",
            "BEGIN TRANSACTION;",
        ]
        for match_id in sorted(LEAGUE):
            row = by_id[match_id]
            lines.append(
                "UPDATE dbo.tblMatches SET "
                f"Status = {sql_value(row['Status'])}, "
                f"Outcome = {sql_value(row['Outcome'])}, "
                f"NetPoints = {sql_value(row['NetPoints'])}, "
                f"TossOutcome = {sql_value(row['TossOutcome'])}, "
                f"Duration = {sql_value(row['Duration'])}, "
                f"Extra = {sql_value(row['Extra'])}, "
                f"GoldenStrike = {sql_value(row['GoldenStrike'])}, "
                f"StartedAt = {sql_value(row['StartedAt'])}, "
                f"ExtraStartedAt = {sql_value(row['ExtraStartedAt'])}, "
                f"UpdatedAt = {sql_value(row['UpdatedAt'])} "
                f"WHERE Id = {match_id} AND SeasonId = {SEASON_ID} AND Category = 1;"
            )

        write = connection.cursor()
        for match_id, (_team1, _team2, outcome) in LEAGUE.items():
            write.execute(
                """
                UPDATE tblMatches
                SET Status = 3,
                    Outcome = %s,
                    NetPoints = 2,
                    TossOutcome = 1,
                    Duration = 900,
                    Extra = NULL,
                    GoldenStrike = 0,
                    StartedAt = '2026-12-27T10:00:00',
                    ExtraStartedAt = NULL,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = %s AND SeasonId = %s AND Status = 1 AND Void = 0
                """,
                (outcome, match_id, SEASON_ID),
            )
            if write.rowcount != 1:
                raise SystemExit(f"league match {match_id} was not updated")

        created = []
        for category, order, (team1, team2, outcome) in (
            (3, 16, ELIMINATOR),
            (2, 17, FINAL),
        ):
            write.execute(
                """
                INSERT INTO tblMatches (
                    Team1, Team2, ScheduledDate, Duration, Extra, GoldenStrike, Category, Status,
                    [Order], SeasonId, NetPoints, Outcome, TossOutcome, StartedAt
                )
                VALUES (%s, %s, '2026-12-27', 900, NULL, 0, %s, 3, %s, %s, 2, %s, 1, '2026-12-27T12:00:00')
                """,
                (team1, team2, category, order, SEASON_ID, outcome),
            )
            if not write.lastrowid:
                raise SystemExit(f"knockout category {category} was not created")
            created.append(int(write.lastrowid))

        lines.append(
            "DELETE FROM dbo.tblMatchStats WHERE MatchId IN ("
            + ", ".join(str(match_id) for match_id in created)
            + ");"
        )
        lines.append(
            "DELETE FROM dbo.tblMatches WHERE SeasonId = "
            f"{SEASON_ID} AND Id IN ("
            + ", ".join(str(match_id) for match_id in created)
            + ") AND Category IN (2, 3);"
        )
        lines.append("COMMIT TRANSACTION;")
        REVERSAL.write_text("\n".join(lines) + "\n", encoding="utf-8")

        check = connection.cursor(dictionary=True)
        check.execute("EXEC dbo.usp_GetLeagueTable ?", (SEASON_ID,))
        standings = check.fetchall()
        status = None
        while check.nextset():
            status_row = check.fetchone()
            if status_row and "SeasonStatus" in status_row:
                status = int(status_row["SeasonStatus"])
                break
        winner = next((row for row in standings if int(row.get("IsWinner") or 0) == 1), None)
        if status != 3 or not winner or int(winner["TeamId"]) != 1:
            raise SystemExit(f"season did not finish with Ghoshpara Strikers: status={status} winner={winner}")

        connection.commit()
        print(f"finished season {SEASON_ID}; champion team {winner['TeamId']} {winner['TeamName']}")
        print(f"knockout match ids {created}")
        print(f"reversal {REVERSAL}")
    except Exception:
        connection.rollback()
        if REVERSAL.exists():
            REVERSAL.unlink()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()
