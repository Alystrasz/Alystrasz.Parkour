untyped
global function _PK_Init
global bool IS_PK = false
global function UpdatePlayersLeaderboard

global struct PlayerStats
{
	bool isRunning = false
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
global table<int, LeaderboardEntry> leaderboard = {}

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
	InitLeaderboard()
}

void function InitLeaderboard()
{
	LeaderboardEntry entry1 = {
		playerName = "Alystrasz"
		time = 42
	} 
	leaderboard[1] <- entry1

	LeaderboardEntry entry2 = {
		playerName = "Gecko"
		time = 55.45
	}
	leaderboard[2] <- entry2

	LeaderboardEntry entry3 = {
		playerName = "uniboi"
		time = 169.56
	}
	leaderboard[3] <- entry3
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
