untyped
global function _PK_Init
global bool IS_PK = false

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

// Leaderboard
global struct LeaderboardEntry
{
	string playerName
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

	// Disable titans and boosts
	Riff_ForceTitanAvailability( eTitanAvailability.Never )
	Riff_ForceBoostAvailability( eBoostAvailability.Disabled )

	// Prepare map for parkour gamemode
	checkpoints = GetMapCheckpointLocations()
	SpawnEntities()
	thread CheckPlayersForReset()
}

/**
 * Resets a player's run statistics (check the PlayerStats struct for default
 * values), and respawns them to the last checkpoint they crossed.
 **/
void function ResetPlayerRun(entity player, bool preserveBestTime = false)
{
	string playerName = player.GetPlayerName()
	PlayerStats stats = {
		...
	}

	if (preserveBestTime) {
		stats.bestTime = localStats[playerName].bestTime
	}

	localStats[playerName] <- stats
	RespawnPlayerToConfirmedCheckpoint(player)
}

/**
 * Callback invoked on player connection.
 * This initializes gamemode variables for player, and sends him the entire
 * leaderboard state.
 **/
void function OnPlayerConnected(entity player)
{
	// Put all players in the same team
	SetTeam( player, TEAM_IMC )
	ResetPlayerRun(player)
	UpdatePlayerLeaderboard( player, 0 )
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
					localStats[playerName].isResetting = true
					localStats[playerName].isRunning = false
					thread MovePlayerToMapStart(player)

					Remote_CallFunction_NonReplay(player, "ServerCallback_ResetRun")
					player.AddToPlayerGameStat( PGS_DEFENSE_SCORE, 1 )
				}
			}
			else {
				times[playerName] <- currTime
			}
		}
		WaitFrame()
	}
}

void function MovePlayerToMapStart( entity player )
{
	player.FreezeControlsOnServer()

	if (IsAlive(player)) {
		PhaseShift(player, 0, 1)
		entity mover = CreateOwnedScriptMover (player)
		player.SetParent(mover)
		mover.NonPhysicsMoveTo (checkpoints[0], 1, 0, 0)
		mover.NonPhysicsRotateTo (<0,0,0>, 1, 0, 0)
		wait 1

		player.SetVelocity(<0,0,0>)
		player.ClearParent()
		mover.Destroy()
	}

	ResetPlayerRun( player, true )
	player.SetAngles(<0, 0, 0>)
	player.UnfreezeControlsOnServer()

	localStats[player.GetPlayerName()].isResetting = false
	ResetPlayerCooldowns(player)
}
