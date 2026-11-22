"""Finish the 14 still-scheduled league matches of 2026 Season 3 on the live database, with scorecards.

Match 130 (order 1) is already played and is not touched.

Results are decisive and transitive, so the final table has six different point totals:
Dum Dum Diamonds 10, Ghoshpara Strikers 8, Nischinda Ninjas 6, Kumillapara Kings 4,
Sasthitala Smashers 2, Santinagar Slayers 0. No knockout match is created.

Writes scripts/revert-season3-league-complete.sql from the rows it changes, before it commits.
The reversal script is not executed here.

    python scripts/complete-season3-league.py --rehearse   apply, reverse, compare, then roll everything back
    python scripts/complete-season3-league.py              apply and commit

Refuses to run unless match 130 is the only played match and matches 131-144 are untouched and scheduled.
"""

import sys
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, r"C:\DevLabs\CarromPremierLeague.API")

from core.database import Database

SEASON_ID = 3
PLAYED_ALREADY = 130
SCRIPT_DIR = Path(__file__).resolve().parent
REVERSAL = SCRIPT_DIR / "revert-season3-league-complete.sql"
FULL_TIME = 15 * 60

# match id: (team1, team2, winning side 1 or 2, winner coins, loser coins, duration in seconds)
# A side's score is its own pocketed coins minus fines, plus the coins the other team pocketed of its colour.
# A side that reaches 9 clears the board, so the match ends before full time.
FIXTURES = {
    131: (2, 5, 2, 9, 4, 612),
    132: (3, 4, 2, 7, 5, FULL_TIME),
    133: (1, 5, 1, 9, 6, 744),
    134: (6, 4, 1, 8, 3, FULL_TIME),
    135: (2, 3, 1, 6, 4, FULL_TIME),
    136: (1, 4, 1, 9, 2, 531),
    137: (5, 3, 1, 7, 6, FULL_TIME),
    138: (6, 2, 1, 9, 5, 688),
    139: (1, 3, 1, 8, 1, FULL_TIME),
    140: (4, 2, 1, 9, 7, 803),
    141: (5, 6, 2, 7, 2, FULL_TIME),
    142: (1, 2, 1, 6, 5, FULL_TIME),
    143: (3, 6, 2, 9, 3, 457),
    144: (4, 5, 1, 8, 7, FULL_TIME),
}

EXPECTED_ORDER = [(6, 10), (1, 8), (4, 6), (5, 4), (2, 2), (3, 0)]  # (team id, points), best first

READY_FIRST = datetime(2026, 11, 22, 9, 20, 0)
SLOT = timedelta(minutes=20)
COLUMNS = (
    "Status", "Outcome", "NetPoints", "TossOutcome", "Duration", "Extra", "GoldenStrike",
    "StartedAt", "ExtraStartedAt", "ReadyAt", "CompletedAt", "UpdatedAt",
)


def sql_value(value):
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def side_stats(match_id, side, players, score, opponent_pocketed, fine):
    """Split one side's score between its two players. Returns rows for those players."""
    own_net = score - opponent_pocketed
    gross = own_net + fine
    first = min(gross, (gross * 3 + 4) // 5)
    second = gross - first
    if fine and first < fine:
        raise SystemExit(f"match {match_id}: no coin to fine")
    fines = [fine, 0]
    rows = []
    for index, (player_id, own) in enumerate(zip(players, (first, second))):
        striker = 1 if (match_id + side + index) % 7 == 0 and own >= 1 else 0
        rows.append({"player_id": player_id, "own": own, "fines": fines[index], "striker": striker})
    return rows


def build_scorecards(rosters):
    cards = {}
    for match_id, (team1, team2, winner_side, win_coins, lose_coins, duration) in FIXTURES.items():
        scores = {1: win_coins if winner_side == 1 else lose_coins, 2: win_coins if winner_side == 2 else lose_coins}
        teams = {1: team1, 2: team2}
        # Coins of side X's colour that the other team pocketed.
        opponent = {s: 1 if (match_id + s) % 3 == 0 and scores[s] >= 2 else 0 for s in (1, 2)}
        fine = {s: 1 if (match_id + s) % 4 == 0 and scores[s] >= 2 else 0 for s in (1, 2)}
        rows = []
        for side in (1, 2):
            other = 2 if side == 1 else 1
            side_rows = side_stats(match_id, side, rosters[teams[side]], scores[side], opponent[side], fine[side])
            # This side's players pocketed some of the other colour: that is the other side's opponent count.
            carrier = side_rows[0] if match_id % 2 == 0 else side_rows[1]
            for row in side_rows:
                row["opp"] = opponent[other] if row is carrier else 0
            rows.extend(side_rows)
        for row in rows:
            row["shots"] = row["own"] + row["opp"] + row["fines"] + row["striker"] + 1 + (match_id + row["player_id"]) % 3
        cards[match_id] = rows
    return cards


def check_card(match_id, rows, rosters):
    team1, team2, winner_side, win_coins, lose_coins, duration = FIXTURES[match_id]
    totals = {}
    for team_id in (team1, team2):
        own = sum(r["own"] for r in rows if r["player_id"] in rosters[team_id])
        fined = sum(r["fines"] for r in rows if r["player_id"] in rosters[team_id])
        other = team2 if team_id == team1 else team1
        opp = sum(r["opp"] for r in rows if r["player_id"] in rosters[other])
        totals[team_id] = max(own - fined, 0) + opp
    expected = {team1: win_coins if winner_side == 1 else lose_coins, team2: win_coins if winner_side == 2 else lose_coins}
    if totals != expected:
        raise SystemExit(f"match {match_id}: scorecard gives {totals}, wanted {expected}")
    if max(totals.values()) > 9:
        raise SystemExit(f"match {match_id}: more than nine coins off the board")
    cleared = max(totals.values()) == 9
    if cleared and not duration < FULL_TIME:
        raise SystemExit(f"match {match_id}: cleared the board but ran full time")
    if not cleared and duration != FULL_TIME:
        raise SystemExit(f"match {match_id}: did not clear the board but ended early")
    if win_coins <= lose_coins:
        raise SystemExit(f"match {match_id}: winner does not lead")
    return win_coins - lose_coins


def fetch_matches(cursor, ids):
    cursor.execute(
        f"""
        SELECT Id, Team1, Team2, Category, Status, Outcome, NetPoints, TossOutcome, Duration, Extra, GoldenStrike,
               StartedAt, ExtraStartedAt, ReadyAt, CompletedAt, UpdatedAt, Void
        FROM tblMatches
        WHERE SeasonId = %s AND Id IN ({", ".join(str(i) for i in ids)})
        ORDER BY Id
        """,
        (SEASON_ID,),
    )
    return {int(row["Id"]): row for row in cursor.fetchall()}


def league_table(connection):
    cursor = connection.cursor(dictionary=True)
    cursor.execute("EXEC dbo.usp_GetLeagueTable ?", (SEASON_ID,))
    standings = cursor.fetchall()
    status = None
    while cursor.nextset():
        row = cursor.fetchone()
        if row and "SeasonStatus" in row:
            status = int(row["SeasonStatus"])
            break
    return standings, status


def main():
    rehearse = "--rehearse" in sys.argv
    connection = Database.get_connection()
    cursor = connection.cursor(dictionary=True)
    reversal_written = False
    try:
        cursor.execute("SELECT Id, Name, [Show] AS Shown, Void FROM tblSeasons WHERE Id = %s", (SEASON_ID,))
        season = cursor.fetchone()
        if not season or season["Void"] or not season["Shown"] or season["Name"] != "2026 Season 3":
            raise SystemExit(f"season 3 is not the shown 2026 Season 3: {season}")

        cursor.execute(
            "SELECT Id, Status, Category, Void FROM tblMatches WHERE SeasonId = %s ORDER BY Id", (SEASON_ID,)
        )
        season_matches = {int(r["Id"]): r for r in cursor.fetchall()}
        if set(season_matches) != {PLAYED_ALREADY, *FIXTURES}:
            raise SystemExit(f"season 3 matches are not the 15 league fixtures: {sorted(season_matches)}")
        if any(int(r["Category"]) != 1 or r["Void"] for r in season_matches.values()):
            raise SystemExit("season 3 holds a non-league or void match")
        played = sorted(i for i, r in season_matches.items() if int(r["Status"]) == 3)
        if played != [PLAYED_ALREADY]:
            raise SystemExit(f"expected only match {PLAYED_ALREADY} to be played, found {played}")

        before = fetch_matches(cursor, FIXTURES)
        for match_id, (team1, team2, *_rest) in FIXTURES.items():
            row = before[match_id]
            if (
                int(row["Team1"]) != team1 or int(row["Team2"]) != team2
                or int(row["Status"]) != 1 or int(row["Outcome"]) != 3
                or row["NetPoints"] is not None or row["Void"]
                or row["StartedAt"] or row["ReadyAt"] or row["CompletedAt"]
            ):
                raise SystemExit(f"match {match_id} is not an untouched scheduled match: {row}")
        cursor.execute(
            f"SELECT COUNT(*) AS N FROM tblMatchStats WHERE MatchId IN ({', '.join(str(i) for i in FIXTURES)})"
        )
        if int(cursor.fetchone()["N"]) != 0:
            raise SystemExit("matches 131-144 already have scorecard rows")

        cursor.execute(
            """
            SELECT TeamId, PlayerId FROM tblPlayersSeasonsTeams
            WHERE SeasonId = %s AND Void = 0 ORDER BY TeamId, PlayerId
            """,
            (SEASON_ID,),
        )
        rosters = {}
        for row in cursor.fetchall():
            rosters.setdefault(int(row["TeamId"]), []).append(int(row["PlayerId"]))
        if sorted(rosters) != [1, 2, 3, 4, 5, 6] or any(len(p) != 2 for p in rosters.values()):
            raise SystemExit(f"season 3 rosters are not six teams of two: {rosters}")

        cards = build_scorecards(rosters)
        nets = {match_id: check_card(match_id, rows, rosters) for match_id, rows in cards.items()}

        # Reversal script, built from the rows as they are now.
        undo = [
            "DELETE FROM dbo.tblMatchStats WHERE MatchId IN (" + ", ".join(str(i) for i in sorted(FIXTURES)) + ");"
        ]
        for match_id in sorted(FIXTURES):
            row = before[match_id]
            assignments = ", ".join(f"{c} = {sql_value(row[c])}" for c in COLUMNS)
            undo.append(
                f"UPDATE dbo.tblMatches SET {assignments} WHERE Id = {match_id} AND SeasonId = {SEASON_ID} AND Category = 1;"
            )
        lines = [
            "-- Undo scripts/complete-season3-league.py: matches 131-144 of 2026 Season 3 go back to Scheduled",
            "-- with no scorecard, exactly as they were before. Match 130 is not touched.",
            "-- Run it once, only after the completed league has been checked. Do not run it twice.",
            "SET XACT_ABORT ON;",
            "BEGIN TRANSACTION;",
            *undo,
            "COMMIT TRANSACTION;",
        ]
        REVERSAL.write_text("\n".join(lines) + "\n", encoding="utf-8")
        reversal_written = True

        write = connection.cursor()
        for slot, match_id in enumerate(sorted(FIXTURES)):
            team1, team2, winner_side, win_coins, lose_coins, duration = FIXTURES[match_id]
            ready = READY_FIRST + SLOT * slot
            started = ready + timedelta(minutes=2)
            completed = started + timedelta(seconds=duration)
            write.execute(
                """
                UPDATE tblMatches
                SET Status = 3, Outcome = %s, NetPoints = %s, TossOutcome = %s, Duration = %s,
                    Extra = NULL, GoldenStrike = 0, ReadyAt = %s, StartedAt = %s, ExtraStartedAt = NULL,
                    CompletedAt = %s, UpdatedAt = SYSUTCDATETIME()
                WHERE Id = %s AND SeasonId = %s AND Category = 1 AND Status = 1 AND Void = 0
                """,
                (winner_side, nets[match_id], 1 if match_id % 2 else 2, duration, ready, started, completed,
                 match_id, SEASON_ID),
            )
            if write.rowcount != 1:
                raise SystemExit(f"match {match_id} was not updated")
            for row in cards[match_id]:
                write.execute(
                    """
                    INSERT INTO tblMatchStats
                        (MatchId, PlayerId, CoinsPocketed, OpponentCoinsPocketed, SingleFines, DoubleFines,
                         StrikersPocketed, CoinsFined, ShotsTaken)
                    VALUES (%s, %s, %s, %s, %s, 0, %s, %s, %s)
                    """,
                    (match_id, row["player_id"], row["own"], row["opp"], row["fines"], row["striker"],
                     row["fines"], row["shots"]),
                )

        standings, status = league_table(connection)
        order = [(int(r["TeamId"]), int(r["Points"])) for r in standings]
        if order != EXPECTED_ORDER:
            raise SystemExit(f"league table is not as designed: {order}")
        if any(int(r["MatchesPlayed"]) != 5 for r in standings):
            raise SystemExit("a team did not play five matches")
        cursor.execute(
            "SELECT COUNT(*) AS N FROM tblMatches WHERE SeasonId = %s AND Category = 1 AND Status = 3 AND Void = 0",
            (SEASON_ID,),
        )
        if int(cursor.fetchone()["N"]) != 15:
            raise SystemExit("not all 15 league matches are played")

        if rehearse:
            # Run the reversal statements inside the same transaction and compare with the starting rows.
            for statement in undo:
                write.execute(statement)
            after = fetch_matches(cursor, FIXTURES)
            for match_id in FIXTURES:
                for column in COLUMNS:
                    if before[match_id][column] != after[match_id][column]:
                        raise SystemExit(f"reversal did not restore match {match_id} {column}")
            cursor.execute(
                f"SELECT COUNT(*) AS N FROM tblMatchStats WHERE MatchId IN ({', '.join(str(i) for i in FIXTURES)})"
            )
            if int(cursor.fetchone()["N"]) != 0:
                raise SystemExit("reversal left scorecard rows behind")
            connection.rollback()
            print("REHEARSAL OK: applied, reversed, matched the original rows, rolled back. Nothing was written.")
        else:
            connection.commit()
            print("COMMITTED")

        print("table after applying:")
        for r in standings:
            print(f"  {r['TeamName']}: played {r['MatchesPlayed']} wins {r['Wins']} points {r['Points']} net {r['TotalNetPoints']}")
        print(f"season status {status}; reversal {REVERSAL}")
    except BaseException:
        connection.rollback()
        if reversal_written and not rehearse:
            REVERSAL.unlink(missing_ok=True)
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()
