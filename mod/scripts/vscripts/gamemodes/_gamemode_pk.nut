untyped
global function _PK_Init
global bool IS_PK = false

global struct PlayerStats
{
	bool isRunning = false
	int currentCheckpoint = 0
	array<vector> checkpointAngles = [<0, 0, 0>]
	float startTime
	float bestTime = 65535
	string playerIdentifier
}

global table< string, PlayerStats > localStats = {}

// Leaderboard
global struct LeaderboardEntry
{
	string playerName
	int playerHandle
	float time
}

global array<LeaderboardEntry> leaderboard = []
global array<vector> checkpoints = []
global array<entity> checkpointEntities = []


void function _PK_Init() {
	IS_PK = true

	// AddCallback_OnPlayerKilled( OnPlayerKilled )
	ClassicMP_SetCustomIntro( ClassicMP_DefaultNoIntro_Setup, 10 )

	// teleport connected players to map start
	AddCallback_OnClientConnected( OnPlayerConnected )
	AddCallback_OnPlayerRespawned( RespawnPlayerToConfirmedCheckpoint )

	// Prepare map for parkour gamemode
	checkpoints = GetMapCheckpointLocations()
	SpawnEntities()
	thread CheckPlayersForReset()
}

/**
 * Resets a player's run statistics (check the PlayerStats struct for default
 * values), and respawns them to the last checkpoint they crossed.
 **/
void function ResetPlayerRun(entity player)
{
	PlayerStats stats = {
		...
	}
	localStats[player.GetPlayerName()] <- stats
	RespawnPlayerToConfirmedCheckpoint(player)
}

/**
 * Callback invoked on player connection.
 * This initializes gamemode variables for player, and sends him the entire
 * leaderboard state.
 **/
void function OnPlayerConnected(entity player)
{
	ResetPlayerRun(player)
	UpdatePlayersLeaderboard( 0 )
}

/**
 * Finds the location of the last checkpoint that was crossed by the player,
 * and respawns them there, using the angle they had when crossing said
 * checkpoint.
 **/
void function RespawnPlayerToConfirmedCheckpoint(entity player)
{
	int checkpointIndex = localStats[player.GetPlayerName()].currentCheckpoint
	vector checkpoint = checkpoints[checkpointIndex]
	player.SetOrigin( checkpoint )
	player.SetAngles(localStats[player.GetPlayerName()].checkpointAngles[checkpointIndex])
}

/**
 * This method listens to players, checking if they're holding their `use` button.
 * If a player holds this button for a given amount of time, this method will kill
 * him, reset his current run statistics and respawn him to the starting point.
 *
 * TODO assert this is launched in a thread
 **/
void function CheckPlayersForReset()
{
	// This table holds times players started pressing `use` button
	table times = {}
	// Duration of seconds needed for a reset
	int resetDelay = 1

	while (true)
	{
		float currTime = Time()

		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()
			if(player.UseButtonPressed() && localStats[playerName].isRunning)
			{
				if (!(playerName in times)) {
					times[playerName] <- currTime
				}

				// Player held `use` button long enough, trigger run reset
				if (currTime - times[playerName] >= resetDelay) {
					delete times[playerName]
					player.TakeDamage( player.GetMaxHealth() + 1, null, null, { damageSourceId=damagedef_suicide } )

					// TODO fix: this removes player's best time while it shouldn't
					ResetPlayerRun(player)

					NSDeleteStatusMessageOnPlayer( player, localStats[playerName].playerIdentifier )
					Remote_CallFunction_NonReplay(player, "ServerCallback_ResetRun")
				}
			}
			else {
				times[playerName] <- currTime
			}
		}
		WaitFrame()
	}
}
