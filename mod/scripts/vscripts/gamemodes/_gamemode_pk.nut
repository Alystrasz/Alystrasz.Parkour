untyped
global function _PK_Init
global bool IS_PK = false
global function UpdatePlayersLeaderboard
global function StoreNewLeaderboardEntry

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
	float time
}

global array<LeaderboardEntry> leaderboard = []

global array<vector> checkpoints = [
	// Start
	< -492.656, -3036, -107.969>,

	// Checkpoints
	<471.636, -3438.36, 112.031>,
	<1078.87, -4349.23, 30.0313>,
	<1286.21, -5821.39, -174.185>,
	<1478.94, -4339.42, 30.0313>,
	<2337.49, -2532.42, 63.8572>,
	<1767.95, -554.624, -16.3175>,
	< -488.85, -956.027, -191.969>,
	< -1806.92, -1307.96, -319.969>,
	< -1206.72, -766.02, 328.031>,
	< -1844.4, -1307.25, 949.407>,

	// End
	< -399.065, -2906.22, -83.9688>
]

global array<entity> checkpointEntities = []


void function _PK_Init() {
	IS_PK = true

	// AddCallback_OnPlayerKilled( OnPlayerKilled )
	ClassicMP_SetCustomIntro( ClassicMP_DefaultNoIntro_Setup, 10 )

	// teleport connected players to map start
	AddCallback_OnClientConnected( OnPlayerConnected )
	AddCallback_OnPlayerRespawned( RespawnPlayerToConfirmedCheckpoint )

	// Prepare map for parkour gamemode
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

// Unfinished
void function UpdatePlayersLeaderboard()
{
	string results = ""

	foreach(int index, LeaderboardEntry entry in leaderboard)
	{
		results += index + ";" + entry.playerName + ";" + entry.time + "\n"
	}

	// TODO find a way to transmit `results` variable to all players
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

void function StoreNewLeaderboardEntry( entity player, float duration )
{
	// TODO check if new entry changes table
	// TODO if yes, send new state to all players
	print("New time for " + player.GetPlayerName() + ": " + duration)

	int insertionIndex = -1
	foreach(int index, LeaderboardEntry entry in leaderboard)
	{
		if (duration < entry.time)
		{
			insertionIndex = index

			// Add entry to leaderboard
			LeaderboardEntry entry = { ... }
			entry.playerName = player.GetPlayerName()
			entry.time = duration
			leaderboard.insert( insertionIndex, entry )

			break;
		}
	}

	
	if (insertionIndex == -1)
	{
		// If new player time does not change the leaderboard, don't
		// send leaderboard updates to client.
		if (leaderboard.len() != 0)
			return;

		// Otherwise, it means this is the first leaderboard entry.
		insertionIndex = 0
	}


	TransmitNewScoreToAllPlayers( player, duration, insertionIndex )
}

// TODO compute new leaderboard index
// TODO check if score is among 10 best before updating all clients
void function TransmitNewScoreToAllPlayers( entity nPlayer, float duration, int leaderboardIndex )
{
	foreach(player in GetPlayerArray())
	{
		Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateLeaderboard", nPlayer.GetEncodedEHandle(), duration, leaderboardIndex )
	}
}