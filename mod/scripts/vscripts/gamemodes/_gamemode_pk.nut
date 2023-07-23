untyped
global function _PK_Init
global bool IS_PK = false

global array<LeaderboardEntry> leaderboard = []
global array<LeaderboardEntry> worldLeaderboard = []
global array<vector> checkpoints = []
global array<entity> checkpointEntities = []

global bool has_api_access = false
global function OnPlayerConnected


void function _PK_Init() {
	IS_PK = true

	ClassicMP_SetCustomIntro( ClassicMP_DefaultNoIntro_Setup, 10 )
	ClassicMP_ForceDisableEpilogue( true )
	SetLoadoutGracePeriodEnabled( false )
	SetTimeoutWinnerDecisionFunc( ParkourDecideWinner )

	// Precache checkpoint model
	PrecacheModel($"models/fx/xo_emp_field.mdl")

	// Disable titans and boosts
	Riff_ForceTitanAvailability( eTitanAvailability.Never )
	Riff_ForceBoostAvailability( eBoostAvailability.Disabled )

	// teleport connected players to map start
	AddCallback_OnClientConnected( OnPlayerConnected )
	AddCallback_OnPlayerRespawned( RespawnPlayerToConfirmedCheckpoint )

	// Prepare map for parkour gamemode
	thread InitializeMapConfigurationFromAPI()
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
	UpdatePlayerLeaderboard( player, 0 )
	UpdatePlayerLeaderboard( player, 0, true )

	// Init server player state
	InitPlayerStats(player)
	RespawnPlayerToConfirmedCheckpoint(player)

	// Listen for
	AddButtonPressedPlayerInputCallback( player, IN_OFFHAND4, OnPlayerReset )
}

/**
 * Callback invoked on player reset.
 * If the player is currently doing a run, this will set their serverside stats
 * as such, and teleport them to the map starting line.
 **/
void function OnPlayerReset(entity player) {
	string playerName = player.GetPlayerName()
	PlayerStats stats = localStats[playerName]
	if (!stats.isRunning) return;

	stats.isResetting = true
	stats.isRunning = false
	thread MovePlayerToMapStart(player)

	Remote_CallFunction_NonReplay(player, "ServerCallback_ResetRun")
	AddPlayerParkourStat(player, ePlayerParkourStatType.Resets)

	// Reset weapons as well
	ForcePlayerLoadout(player)
}

/**
 * Finds the location of the last checkpoint that was crossed by the player,
 * and respawns them there, using the angle they had when crossing said
 * checkpoint.
 **/
void function RespawnPlayerToConfirmedCheckpoint(entity player)
{
	// Do nothing if called during server initialization
	if (checkpoints.len() == 0) return
	
	int checkpointIndex = localStats[player.GetPlayerName()].currentCheckpoint
	vector checkpoint = checkpoints[checkpointIndex]
	player.SetOrigin( checkpoint )
	player.SetAngles(localStats[player.GetPlayerName()].checkpointAngles[checkpointIndex])

	// Give player predefined weapons
	ForcePlayerLoadout(player)
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

	ResetPlayerStats( player, true )
	RespawnPlayerToConfirmedCheckpoint(player)

	player.SetAngles(<0, 0, 0>)
	player.UnfreezeControlsOnServer()

	// localStats[player.GetPlayerName()].isResetting = false
	ResetPlayerCooldowns(player)
}

int function ParkourDecideWinner()
{
	if (leaderboard.len() == 0)
		return TEAM_UNASSIGNED

	bool found = false
	string winnerName = leaderboard[0].playerName
	float time = leaderboard[0].time
	foreach( player in GetPlayerArray() ) {
		if ( player.GetPlayerName() == winnerName ) {
			SetTeam( player, TEAM_MILITIA )
			found = true
			break
		}
	}

	Chat_ServerBroadcast( format("%s is the winner of the match with a run of %.2f seconds!", winnerName, time), false )
	return found ? TEAM_MILITIA : TEAM_UNASSIGNED
}
