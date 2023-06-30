global function AddPlayerParkourStat
global function InitPlayerStats
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
 * This is invoked on player connection, and will check if newly connected
 * player already have statistics in the current match.
 * If yes, this will update the tab scoreboard with said stats. 
 **/
void function InitPlayerStats(entity player)
{
    string playerName = player.GetPlayerName()

    if (playerName in localStats) {
        PlayerStats stats = localStats[playerName]
        player.SetPlayerGameStat( PGS_PILOT_KILLS, stats.starts )
        player.SetPlayerGameStat( PGS_DEFENSE_SCORE, stats.resets )
        player.SetPlayerGameStat( PGS_ASSAULT_SCORE, stats.finishes )
        player.SetPlayerGameStat( PGS_TITAN_KILLS, stats.top3scores )
    } 
    ResetPlayerStats(player)
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

    // Preserve match statistics if there are some
    if (playerName in localStats) {
        stats.starts = localStats[playerName].starts
        stats.resets = localStats[playerName].resets
        stats.finishes = localStats[playerName].finishes
        stats.top3scores = localStats[playerName].top3scores
    }

	localStats[playerName] <- stats
}