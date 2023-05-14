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

void function OnPlayerConnected(entity player)
{
	PlayerStats stats = {
		...
	}
	localStats[player.GetPlayerName()] <- stats
	RespawnPlayerToConfirmedCheckpoint(player)
}

void function RespawnPlayerToConfirmedCheckpoint(entity player)
{
	int checkpointIndex = localStats[player.GetPlayerName()].currentCheckpoint
	vector checkpoint = checkpoints[checkpointIndex]
	player.SetOrigin( checkpoint )

	player.SetAngles(localStats[player.GetPlayerName()].checkpointAngles[checkpointIndex])
}

void function CheckPlayersForReset()
{
	table times = {}
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

				if (currTime - times[playerName] >= resetDelay) {
					delete times[playerName]
					player.Die()
					OnPlayerConnected(player)
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
