global function PK_StoreNewLeaderboardEntry
global function PK_UpdatePlayersLeaderboard
global function PK_UpdatePlayerLeaderboard

global struct PK_LeaderboardEntry
{
	string playerName
	float time
}

/**
 * This method creates a new entry in the local match leaderboard, and if the
 * This methods checks if the input entry fits local match leaderboard (= if it's
 * among the 10 best times, as leaderboard RUI doesn't have much entries); if it
 * does, this inserts new entry at the correct leaderboard location, and sends
 * leaderboard state to all connected players.
 *
 * Leaderboard state sending is done starting from the insertion index, to avoid
 * sending whole leaderboard on new score registration that's not the best time
 * of the match.
 **/
void function PK_StoreNewLeaderboardEntry( entity player, float duration )
{
	print("New time for " + player.GetPlayerName() + ": " + duration)
	int insertionIndex = 0
	bool leaderboardNeedsUpdating = false


	// Check if new entry will fit leaderboard
	{
		// Check if there's a previous time (and if player improved his time)
		foreach (PK_LeaderboardEntry entry in PK_leaderboard)
		{
			if (entry.playerName == player.GetPlayerName())
			{
				if (entry.time < duration)
					return
				break
			}
		}

		// If leaderboard is not full, new entry will fit
		if (PK_leaderboard.len() < 10)
			leaderboardNeedsUpdating = true

		// Check if input time should appear in leaderboard
		if (!leaderboardNeedsUpdating && PK_leaderboard.len() >= 10)
		{
			float lastTime = PK_leaderboard[9].time
			if (duration < lastTime)
			{
				leaderboardNeedsUpdating = true
			}
		}
	}


	// 2. Insert entry
	{
		if (!leaderboardNeedsUpdating)
			return

		// Remove eventual previous player entry
		array<string> entriesNames = []
		foreach (PK_LeaderboardEntry entry in PK_leaderboard) {
			entriesNames.append( entry.playerName )
		}
		int playerIndex = entriesNames.find( player.GetPlayerName() )
		if (playerIndex != -1)
			PK_leaderboard.remove( playerIndex )

		// Add actual entry
		PK_LeaderboardEntry entry = { ... }
		entry.playerName = player.GetPlayerName()
		entry.time = duration
		PK_leaderboard.append( entry )

		PK_leaderboard.sort(int function(PK_LeaderboardEntry a, PK_LeaderboardEntry b) {
			if (a.time > b.time) return 1
			else if (b.time < a.time) return -1
			return 0;
		})

		// Update insertionIndex
		entriesNames = []
		foreach (PK_LeaderboardEntry entry in PK_leaderboard) {
			entriesNames.append( entry.playerName )
		}
		insertionIndex = entriesNames.find( player.GetPlayerName() )
		Assert(insertionIndex != -1)

		// Update player stats
		if (insertionIndex <= 2)
			PK_AddPlayerParkourStat(player, ePlayerParkourStatType.Top3_scores)

		// Send new score to API
		// If score should appear in world scoreboard, refresh world scoreboard
		if ( PK_has_api_access ) {
			PK_SendWorldLeaderboardEntryToAPI( entry )

			int length = PK_worldLeaderboard.len()
			if (length < 10 || entry.time < PK_worldLeaderboard[length-1].time ) {
				// Leave some time to API to store new score
				wait 1
				print("Forcing world scores updating.")
				PK_WorldLeaderboard_FetchScores()
			}
		}
	}

	PK_UpdatePlayersLeaderboard( insertionIndex )
}

/**
 * If a new time enters the leaderboard, we don't need to send all 10 entries to all players
 * (if new entry has 7th position, we only need to send 7th, 8th, 9th and 10th entries for instance).
 **/
void function PK_UpdatePlayersLeaderboard( int startIndex, bool updateWorldLeaderboard = false )
{
	foreach(player in GetPlayerArray())
	{
		if ( !IsValid( player ) ) {
			continue
		}
		
		PK_UpdatePlayerLeaderboard( player, startIndex, updateWorldLeaderboard )
	}
}

void function PK_UpdatePlayerLeaderboard( entity player, int startIndex, bool updateWorldLeaderboard = false )
{
	array<PK_LeaderboardEntry> board = updateWorldLeaderboard ? PK_worldLeaderboard : PK_leaderboard;

	for (int i=startIndex; i<board.len(); i++)
	{
		// Leaderboard RUI has 10 entries only
		if (i >= 10) return;

		PK_LeaderboardEntry entry = board[i]
		ServerToClientStringCommand( player, "ParkourUpdateLeaderboard " + entry.playerName + " " + entry.time + " " + i + " " + (updateWorldLeaderboard ? 1 : 0).tostring())
	}
}
