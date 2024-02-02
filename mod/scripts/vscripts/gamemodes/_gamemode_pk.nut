untyped
global function _PK_Init
global bool IS_PK = false

global array<LeaderboardEntry> leaderboard = []
global array<LeaderboardEntry> worldLeaderboard = []
global array<vector> checkpoints = []
global array<entity> checkpointEntities = []
global vector startAngles

global bool has_api_access = false
global function PK_OnPlayerConnected


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
	AddCallback_OnClientConnected( PK_OnPlayerConnected )
	AddCallback_OnPlayerRespawned( RespawnPlayerToConfirmedCheckpoint )

	// Prepare map for parkour gamemode
	thread InitializeMapConfiguration()
}


/**
 * Callback invoked on player connection.
 * This initializes gamemode variables for player, and sends him the entire
 * leaderboard state.
 **/
void function PK_OnPlayerConnected(entity player)
{
	// Do nothing if called during server initialization
	if (mapConfiguration.finishedFetchingData == false) return

	// Put all players in the same team
	SetTeam( player, TEAM_IMC )

	// Init client-side elements
	ServerToClientStringCommand( player, "ParkourInitLine start " + mapConfiguration.startLineStr)
	ServerToClientStringCommand( player, "ParkourInitLine end " + mapConfiguration.finishLineStr)
	ServerToClientStringCommand( player, "ParkourInitLeaderboard local " + mapConfiguration.localLeaderboardStr)
	ServerToClientStringCommand( player, "ParkourInitLeaderboard world " + mapConfiguration.worldLeaderboardStr)
	Remote_CallFunction_NonReplay( player, "ServerCallback_CreateStartIndicator", mapConfiguration.startIndicator.GetEncodedEHandle() )

	UpdatePlayerLeaderboard( player, 0 )
	UpdatePlayerLeaderboard( player, 0, true )

	// Init server player state
	InitPlayerStats(player)
	RespawnPlayerToConfirmedCheckpoint(player)
	player.SetPlayerNetFloat( "gunGameLevelPercentage", 0 )

	// Listen for reset
	AddButtonPressedPlayerInputCallback( player, IN_OFFHAND4, OnPlayerReset )
	// Listen for players who wanna talk to robot
	AddButtonPressedPlayerInputCallback( player, IN_USE, void function( entity player ) {
		Remote_CallFunction_NonReplay( player, "ServerCallback_TalkToRobot" )
	} )
}

/**
 * Callback invoked on player reset.
 * If the player is currently doing a run, this will set their serverside stats
 * as such, and teleport them to the map starting line.
 **/
void function OnPlayerReset(entity player) {
	string playerName = player.GetPlayerName()
	PlayerStats stats = localStats[playerName]
	if (stats.isResetting) return;

	stats.isResetting = true
	stats.isRunning = false
	thread MovePlayerToMapStart(player)

	Remote_CallFunction_NonReplay(player, "ServerCallback_ResetRun")
	AddPlayerParkourStat(player, ePlayerParkourStatType.Resets)

	// Reset weapons as well
	ForcePlayerLoadout(player)
	Remote_CallFunction_NonReplay( player, "ServerCallback_ToggleStartIndicatorDisplay", false )
}

/**
 * Finds the location of the last checkpoint that was crossed by the player,
 * and respawns them there, using the angle they had when crossing said
 * checkpoint.
 **/
void function RespawnPlayerToConfirmedCheckpoint(entity player)
{
	// Do nothing if called during server initialization
	if (mapConfiguration.finishedFetchingData == false) return

	// Freeze player if respawn occurs after match end
	if (GetGameState() > eGameState.SuddenDeath) {
		player.FreezeControlsOnServer()
	}

	int checkpointIndex = localStats[player.GetPlayerName()].currentCheckpoint
	vector checkpoint = checkpoints[checkpointIndex]
	player.SetOrigin( checkpoint )
	player.SetAngles(localStats[player.GetPlayerName()].checkpointAngles[checkpointIndex])

	// Give player predefined weapons
	ForcePlayerLoadout(player)

	// Disable boost meter
	thread OnPlayerRespawned_Threaded( player )
}
void function OnPlayerRespawned_Threaded( entity player )
{
	// bit of a hack, need to rework earnmeter code to have better support for completely disabling it
	// rn though this just waits for earnmeter code to set the mode before we set it back
	WaitFrame()
	if ( IsValid( player ) )
		PlayerEarnMeter_SetMode( player, eEarnMeterMode.DISABLED )
}

void function MovePlayerToMapStart( entity player )
{
	player.FreezeControlsOnServer()

	if (IsAlive(player)) {
		PhaseShift(player, 0, 1)
		entity mover = CreateOwnedScriptMover (player)
		player.SetParent(mover)
		mover.NonPhysicsMoveTo (checkpoints[0], 1, 0, 0)
		mover.NonPhysicsRotateTo (startAngles, 1, 0, 0)
		wait 1

		player.SetVelocity(<0,0,0>)
		player.ClearParent()
		mover.Destroy()
	}

	player.UnfreezeControlsOnServer()
	ResetPlayerStats( player, true )
	ResetPlayerCooldowns(player)
	
	RespawnPlayerToConfirmedCheckpoint(player)
	player.SetAngles(startAngles)
}

int function ParkourDecideWinner()
{
	if (leaderboard.len() == 0)
		return TEAM_UNASSIGNED

	bool found = false
	string winnerName = leaderboard[0].playerName
	float time = leaderboard[0].time
	foreach( player in GetPlayerArray() ) {
		if ( !IsValid( player ) ) {
			continue
		}

		if ( player.GetPlayerName() == winnerName ) {
			SetTeam( player, TEAM_MILITIA )
			found = true
			break
		}
	}

	Chat_ServerBroadcast( format("%s is the winner of the match with a run of %.2f seconds!", winnerName, time), false )
	return found ? TEAM_MILITIA : TEAM_UNASSIGNED
}
