global function StoreNewLeaderboardEntry

void function StoreNewLeaderboardEntry( entity player, float duration )
{
	print("New time for " + player.GetPlayerName() + ": " + duration)
	int insertionIndex = 0
	bool leaderboardNeedsUpdating = false


	// Check if new entry will fit leaderboard
	{
		// Check if there's a previous time (and if player improved his time)
		foreach (LeaderboardEntry entry in leaderboard)
		{
			if (entry.playerName == player.GetPlayerName())
			{
				if (entry.time < duration)
					return
				break
			}
		}

		// If leaderboard is not full, new entry will fit
		if (leaderboard.len() < 10)
			leaderboardNeedsUpdating = true

		// Check if input time should appear in leaderboard
		if (!leaderboardNeedsUpdating && leaderboard.len() == 10)
		{
			float lastTime = leaderboard[9].time
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
		foreach (LeaderboardEntry entry in leaderboard) {
			entriesNames.append( entry.playerName )
		}
		int playerIndex = entriesNames.find( player.GetPlayerName() )
		if (playerIndex != -1)
			leaderboard.remove( playerIndex )

		// Add actual entry
		LeaderboardEntry entry = { ... }
		entry.playerName = player.GetPlayerName()
		entry.playerHandle = player.GetEncodedEHandle()
		entry.time = duration
		leaderboard.append( entry )

		leaderboard.sort(int function(LeaderboardEntry a, LeaderboardEntry b) {
			if (a.time > b.time) return 1
			else if (b.time < a.time) return -1
			return 0;
		})

		// Update insertionIndex
		entriesNames = []
		foreach (LeaderboardEntry entry in leaderboard) {
			entriesNames.append( entry.playerName )
		}
		insertionIndex = entriesNames.find( player.GetPlayerName() )
		Assert(insertionIndex != -1)
	}

	UpdatePlayersLeaderboard( insertionIndex )
}

/**
 * If a new time enters the leaderboard, we don't need to send all 10 entries to all players
 * (if new entry has 7th position, we only need to send 7th, 8th, 9th and 10th entries for instance).
 **/
void function UpdatePlayersLeaderboard( int startIndex )
{
	foreach(player in GetPlayerArray())
	{
		for (int i=startIndex; i<leaderboard.len(); i++)
		{
			LeaderboardEntry entry = leaderboard[i]
			Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateLeaderboard", entry.playerHandle, entry.time, i )
		}
	}
}

void function TransmitNewScoreToAllPlayers( entity nPlayer, float duration, int leaderboardIndex )
{
	foreach(player in GetPlayerArray())
	{
		Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateLeaderboard", nPlayer.GetEncodedEHandle(), duration, leaderboardIndex )
	}
}
