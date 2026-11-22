"""Write played results for season 3 matches 1-14 and leave match 15 scheduled.

Nischinda Ninjas and Kumillapara Kings finish level on 8 points and +14 coins.
Their meeting is the 15th match and stays Scheduled.
"""

import sys
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(r"C:\DevLabs\CarromPremierLeague.API")))

from core.database import Database

# player tuple: player_id, team_id, own coins, opponent coins, shots, strikers
# A team's score is its own coins plus the other team's opponent coins of that colour.
MATCHES = [
    {"id": 8, "order": 1, "team1": 1, "team2": 6, "outcome": 1, "net": 2, "duration": 900, "toss": 1,
     "players": [(4, 1, 4, 1, 9, 0), (13, 1, 2, 0, 6, 1), (14, 6, 2, 0, 7, 0), (15, 6, 1, 0, 5, 0)]},
    {"id": 9, "order": 2, "team1": 2, "team2": 5, "outcome": 2, "net": 4, "duration": 900, "toss": 2,
     "players": [(7, 2, 2, 0, 6, 0), (8, 2, 1, 1, 5, 0), (5, 5, 4, 1, 8, 1), (11, 5, 3, 0, 6, 0)]},
    {"id": 10, "order": 3, "team1": 3, "team2": 4, "outcome": 2, "net": 5, "duration": 752, "toss": 1,
     "players": [(2, 3, 2, 1, 6, 0), (6, 3, 1, 0, 4, 0), (1, 4, 5, 1, 10, 1), (3, 4, 3, 0, 6, 0)]},
    {"id": 11, "order": 4, "team1": 1, "team2": 5, "outcome": 2, "net": 5, "duration": 688, "toss": 1,
     "players": [(4, 1, 2, 1, 6, 0), (13, 1, 1, 0, 4, 0), (5, 5, 5, 0, 9, 0), (11, 5, 3, 1, 7, 1)]},
    {"id": 12, "order": 5, "team1": 4, "team2": 6, "outcome": 1, "net": 3, "duration": 900, "toss": 1,
     "players": [(1, 4, 3, 1, 7, 0), (3, 4, 2, 0, 5, 0), (14, 6, 2, 1, 6, 0), (15, 6, 0, 0, 3, 0)]},
    {"id": 13, "order": 6, "team1": 2, "team2": 3, "outcome": 1, "net": 4, "duration": 900, "toss": 2,
     "players": [(7, 2, 4, 0, 8, 1), (8, 2, 2, 1, 6, 0), (2, 3, 2, 1, 6, 0), (6, 3, 0, 0, 3, 0)]},
    {"id": 14, "order": 7, "team1": 1, "team2": 4, "outcome": 2, "net": 2, "duration": 900, "toss": 1,
     "players": [(4, 1, 2, 0, 5, 0), (13, 1, 0, 1, 4, 0), (1, 4, 3, 0, 6, 0), (3, 4, 1, 1, 5, 0)]},
    {"id": 15, "order": 8, "team1": 3, "team2": 5, "outcome": 2, "net": 2, "duration": 900, "toss": 2,
     "players": [(2, 3, 2, 1, 6, 0), (6, 3, 1, 0, 4, 0), (5, 5, 3, 0, 6, 0), (11, 5, 2, 1, 6, 0)]},
    {"id": 16, "order": 9, "team1": 2, "team2": 6, "outcome": 2, "net": 1, "duration": 900, "toss": 2,
     "players": [(7, 2, 2, 1, 6, 0), (8, 2, 1, 0, 4, 0), (14, 6, 3, 0, 7, 1), (15, 6, 1, 1, 5, 0)]},
    {"id": 17, "order": 10, "team1": 1, "team2": 3, "outcome": 2, "net": 5, "duration": 620, "toss": 2,
     "players": [(4, 1, 2, 1, 6, 0), (13, 1, 1, 0, 4, 0), (2, 3, 5, 0, 9, 1), (6, 3, 3, 1, 7, 0)]},
    {"id": 18, "order": 11, "team1": 2, "team2": 4, "outcome": 2, "net": 4, "duration": 900, "toss": 1,
     "players": [(7, 2, 1, 0, 4, 0), (8, 2, 1, 1, 5, 0), (1, 4, 4, 1, 8, 0), (3, 4, 2, 0, 5, 0)]},
    {"id": 19, "order": 12, "team1": 5, "team2": 6, "outcome": 1, "net": 3, "duration": 900, "toss": 1,
     "players": [(5, 5, 4, 1, 8, 1), (11, 5, 1, 0, 4, 0), (14, 6, 1, 0, 4, 0), (15, 6, 1, 1, 5, 0)]},
    {"id": 20, "order": 13, "team1": 1, "team2": 2, "outcome": 1, "net": 3, "duration": 900, "toss": 2,
     "players": [(4, 1, 3, 0, 7, 0), (13, 1, 2, 1, 6, 0), (7, 2, 2, 1, 6, 0), (8, 2, 0, 0, 3, 0)]},
    {"id": 21, "order": 14, "team1": 3, "team2": 6, "outcome": 2, "net": 2, "duration": 900, "toss": 1,
     "players": [(2, 3, 2, 1, 5, 0), (6, 3, 0, 0, 3, 0), (14, 6, 2, 0, 5, 0), (15, 6, 2, 1, 6, 0)]},
]

FULL_TIME = 15 * 60
START = datetime(2026, 12, 27, 4, 30)


def team_score(players, team_id):
    own = sum(own_coins for _, side, own_coins, _, _, _ in players if side == team_id)
    opponent = sum(opp for _, side, _, opp, _, _ in players if side != team_id)
    return own + opponent


def check(match):
    scores = {match["team1"]: team_score(match["players"], match["team1"]),
              match["team2"]: team_score(match["players"], match["team2"])}
    for team_id, score in scores.items():
        if score > 9:
            raise SystemExit(f"match {match['id']} team {team_id} has {score} coins off the board")
    winner = match["team1"] if match["outcome"] == 1 else match["team2"]
    loser = match["team2"] if winner == match["team1"] else match["team1"]
    margin = scores[winner] - scores[loser]
    if margin != match["net"] or margin <= 0:
        raise SystemExit(f"match {match['id']} margin {margin} does not match net {match['net']}")
    cleared = max(scores.values()) == 9
    if cleared and not (0 <= match["duration"] < FULL_TIME):
        raise SystemExit(f"match {match['id']} cleared a colour but duration is {match['duration']}")
    if not cleared and match["duration"] != FULL_TIME:
        raise SystemExit(f"match {match['id']} did not clear a colour but duration is {match['duration']}")
    return scores


def main():
    for match in MATCHES:
        check(match)

    connection = Database.get_connection()
    cursor = connection.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT Id, [Order] AS MatchOrder, Team1, Team2, Status
            FROM tblMatches
            WHERE SeasonId = 3 AND Void = 0
            ORDER BY [Order]
            """
        )
        rows = {row["Id"]: row for row in cursor.fetchall()}
        if len(rows) != 15:
            raise SystemExit(f"expected 15 season 3 matches, found {len(rows)}")
        for match in MATCHES:
            row = rows.get(match["id"])
            if row is None or row["MatchOrder"] != match["order"] or row["Team1"] != match["team1"] or row["Team2"] != match["team2"]:
                raise SystemExit(f"match {match['id']} does not match the fixture list")
            if row["Status"] != 1:
                raise SystemExit(f"match {match['id']} is not scheduled")
        fifteenth = rows.get(22)
        if fifteenth is None or fifteenth["MatchOrder"] != 15 or fifteenth["Status"] != 1:
            raise SystemExit("match 15 is not the scheduled Ninjas vs Kings fixture")

        for match in MATCHES:
            started = START + timedelta(minutes=20 * (match["order"] - 1))
            cursor.execute(
                """
                UPDATE tblMatches
                SET Status = 3,
                    Outcome = %s,
                    TossOutcome = %s,
                    NetPoints = %s,
                    Duration = %s,
                    Extra = NULL,
                    GoldenStrike = 0,
                    StartedAt = %s,
                    ExtraStartedAt = NULL,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = %s AND SeasonId = 3 AND Void = 0 AND Status = 1
                """,
                (match["outcome"], match["toss"], match["net"], match["duration"], started, match["id"]),
            )
            if cursor.rowcount != 1:
                raise SystemExit(f"match {match['id']} was not updated")
            for player_id, _, own, opp, shots, strikers in match["players"]:
                cursor.execute(
                    """
                    INSERT INTO tblMatchStats
                        (MatchId, PlayerId, CoinsPocketed, OpponentCoinsPocketed,
                         SingleFines, DoubleFines, StrikersPocketed, CoinsFined, ShotsTaken)
                    VALUES (%s, %s, %s, %s, 0, 0, %s, 0, %s)
                    """,
                    (match["id"], player_id, own, opp, strikers, shots),
                )

        cursor.execute("EXEC dbo.usp_GetLeagueTable %s", (3,))
        table = cursor.fetchall()
        while cursor.nextset():
            pass
        leaders = [row for row in table if int(row["Points"]) == 8 and int(row["TotalNetPoints"]) == 14]
        leader_ids = {int(row["TeamId"]) for row in leaders}
        if leader_ids != {4, 5} or any(int(row["Points"]) > 8 for row in table):
            raise SystemExit(f"table is not a two-team tie: {table}")
        cursor.execute(
            "SELECT Status FROM tblMatches WHERE Id = 22 AND Void = 0"
        )
        if int(cursor.fetchone()["Status"]) != 1:
            raise SystemExit("match 15 was changed")

        connection.commit()
        print("COMMITTED")
        for row in table:
            print(
                f"{row['TeamName']}: played {row['MatchesPlayed']} wins {row['Wins']} "
                f"points {row['Points']} net {row['TotalNetPoints']}"
            )
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()
