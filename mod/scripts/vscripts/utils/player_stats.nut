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

    int starts = 0
    int resets = 0
    int finishes = 0
    int top3scores = 0
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
    string playerName = player.GetPlayerName()
    PlayerStats stats = localStats[playerName]
    
    switch( type )
    {
        case ePlayerParkourStatType.Starts:
            stats.starts = stats.starts + 1
            player.AddToPlayerGameStat( PGS_PILOT_KILLS, 1 )
            break;
        case ePlayerParkourStatType.Resets:
            stats.resets = stats.resets + 1
            player.AddToPlayerGameStat( PGS_DEFENSE_SCORE, 1 )
            break;
        case ePlayerParkourStatType.Finishes:
            stats.finishes += 1
            player.AddToPlayerGameStat( PGS_ASSAULT_SCORE, 1 )
            break;
        case ePlayerParkourStatType.Top3_scores:
            stats.top3scores += 1
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

    // Preserve match statistics
    if (playerName in localStats) {
        stats.starts = localStats[playerName].starts
        stats.resets = localStats[playerName].resets
        stats.finishes = localStats[playerName].finishes
        stats.top3scores = localStats[playerName].top3scores
    }

	localStats[playerName] <- stats
}