global function PK_AddPlayerParkourStat
global function PK_InitPlayerStats
global function PK_ResetPlayerStats
global struct PK_PlayerStats
{
	bool isRunning = false
	bool isResetting = false
    bool justFinished = false
	int currentCheckpoint = 0
	array<vector> checkpointAngles
	float startTime
	float bestTime = 65535

    int starts = 0
    int resets = 0
    int finishes = 0
    int top3scores = 0
}

global table< string, PK_PlayerStats > PK_localStats = {}

global enum ePlayerParkourStatType
{
    Starts,
    Resets,
    Finishes,
    Top3_scores
}

void function PK_AddPlayerParkourStat( entity player, int type )
{
    string playerName = player.GetPlayerName()
    PK_PlayerStats stats = PK_localStats[playerName]

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
void function PK_InitPlayerStats(entity player)
{
    string playerName = player.GetPlayerName()

    if (playerName in PK_localStats) {
        PK_PlayerStats stats = PK_localStats[playerName]
        player.SetPlayerGameStat( PGS_PILOT_KILLS, stats.starts )
        player.SetPlayerGameStat( PGS_DEFENSE_SCORE, stats.resets )
        player.SetPlayerGameStat( PGS_ASSAULT_SCORE, stats.finishes )
        player.SetPlayerGameStat( PGS_TITAN_KILLS, stats.top3scores )
    }
    PK_ResetPlayerStats(player)
}

/**
 * Resets a player's run statistics (check the PK_PlayerStats struct for default
 * values).
 **/
void function PK_ResetPlayerStats(entity player, bool preserveBestTime = false)
{
	string playerName = player.GetPlayerName()
	PK_PlayerStats stats = {
		...
	}

    stats.checkpointAngles = [PK_startAngles]

	if (preserveBestTime) {
		stats.bestTime = PK_localStats[playerName].bestTime
	}

    // Preserve match statistics if there are some
    if (playerName in PK_localStats) {
        stats.starts = PK_localStats[playerName].starts
        stats.resets = PK_localStats[playerName].resets
        stats.finishes = PK_localStats[playerName].finishes
        stats.top3scores = PK_localStats[playerName].top3scores
    }

	PK_localStats[playerName] <- stats
}