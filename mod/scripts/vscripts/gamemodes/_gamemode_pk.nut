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
	int playerHandle
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

		// TODO update insertionIndex
	}

	UpdatePlayersLeaderboard( insertionIndex )
}

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
