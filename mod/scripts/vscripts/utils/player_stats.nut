global function AddPlayerParkourStat
global function ResetPlayerStats
global struct PlayerStats
{
	bool isRunning = false
	bool isResetting = false
	int currentCheckpoint = 0
	array<vector> checkpointAngles = [<0, 0, 0>]
	float startTime
	float bestTime = 65535
}

global table< string, PlayerStats > localStats = {}

global enum ePlayerParkourStatType
{
    Starts,
    Resets,
    Finishes,
    Top3_scores
}

void function AddPlayerParkourStat( entity player, int type )
{
    switch( type )
    {
        case ePlayerParkourStatType.Starts:
            player.AddToPlayerGameStat( PGS_PILOT_KILLS, 1 )
            break;
        case ePlayerParkourStatType.Resets:
            player.AddToPlayerGameStat( PGS_DEFENSE_SCORE, 1 )
            break;
        case ePlayerParkourStatType.Finishes:
            player.AddToPlayerGameStat( PGS_ASSAULT_SCORE, 1 )
            break;
        case ePlayerParkourStatType.Top3_scores:
            player.AddToPlayerGameStat( PGS_TITAN_KILLS, 1 )
            break;
    }
}

/**
 * Resets a player's run statistics (check the PlayerStats struct for default
 * values).
 **/
void function ResetPlayerStats(entity player, bool preserveBestTime = false)
{
	string playerName = player.GetPlayerName()
	PlayerStats stats = {
		...
	}

	if (preserveBestTime) {
		stats.bestTime = localStats[playerName].bestTime
	}

	localStats[playerName] <- stats
}