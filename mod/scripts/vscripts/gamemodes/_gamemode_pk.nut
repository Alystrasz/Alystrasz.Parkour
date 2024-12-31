untyped
global function _PK_Init
global bool IS_PK = false

global array<PK_LeaderboardEntry> PK_leaderboard = []
global array<PK_LeaderboardEntry> PK_worldLeaderboard = []
global array<vector> PK_checkpoints = []
global array<entity> PK_checkpointEntities = []
global vector PK_startOrigin
global vector PK_startAngles

global bool PK_has_api_access = false
global function PK_OnPlayerConnected

string endpoint = ""


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
	AddCallback_OnPlayerRespawned( PK_ForcePlayerWeapon )

	// Prepare map for parkour gamemode
	thread PK_InitializeMapConfiguration()
}


/**
 * Callback invoked on player connection.
 * This initializes gamemode variables for player, and sends him the entire
 * leaderboard state.
 **/
void function PK_OnPlayerConnected(entity player)
{
	// Do nothing if called during server initialization
	if (PK_mapConfiguration.finishedFetchingData == false) return

	// Init endpoint object if needed
	if (endpoint == "")
	{
		// Save endpoint address, to send it to players on connection
		table t = {}
		t["url"] <- format( "%s?route=%s", GetConVarString("parkour_api_endpoint"), PK_credentials.routeId )
		t["routeId"] <- PK_credentials.routeId
		endpoint = EncodeJSON( t )
	}

	// Put all players in the same team
	SetTeam( player, TEAM_IMC )

	// Init client-side elements
	ServerToClientStringCommand( player, "ParkourInitLine start " + PK_mapConfiguration.startLineStr)
	ServerToClientStringCommand( player, "ParkourInitLine end " + PK_mapConfiguration.finishLineStr)
	ServerToClientStringCommand( player, "ParkourInitLeaderboard local " + PK_mapConfiguration.localLeaderboardStr)
	ServerToClientStringCommand( player, "ParkourInitLeaderboard world " + PK_mapConfiguration.worldLeaderboardStr)
	ServerToClientStringCommand( player, "ParkourInitRouteName " + PK_mapConfiguration.routeNameStr)
	ServerToClientStringCommand( player, "ParkourInitEndpoint " + endpoint )
	Remote_CallFunction_NonReplay( player, "ServerCallback_PK_CreateStartIndicator", PK_mapConfiguration.startIndicator.GetEncodedEHandle() )

	// Apply clientside perks
	if (PK_perks.floorIsLava) {
		Remote_CallFunction_NonReplay( player, "ServerCallback_PK_ApplyClientsidePerks" )
	}

	PK_UpdatePlayerLeaderboard( player, 0 )
	PK_UpdatePlayerLeaderboard( player, 0, true )

	// Init server player state
	PK_InitPlayerStats(player)
	RespawnPlayerToConfirmedCheckpoint(player)
	player.SetPlayerNetFloat( "gunGameLevelPercentage", 0 )

	// Listen for reset
	AddButtonPressedPlayerInputCallback( player, IN_OFFHAND4, OnPlayerReset )
	// Listen for players who wanna talk to robot
	AddButtonPressedPlayerInputCallback( player, IN_USE, void function( entity player ) {
		Remote_CallFunction_NonReplay( player, "ServerCallback_PK_TalkToRobot" )
	} )
}

/**
 * Callback invoked on player reset.
 * If the player is currently doing a run, this will set their serverside stats
 * as such, and teleport them to the map starting line.
 **/
void function OnPlayerReset(entity player) {
	string playerName = player.GetPlayerName()
	PK_PlayerStats stats = PK_localStats[playerName]
	if (stats.isResetting) return;

	stats.isResetting = true
	stats.isRunning = false
	thread MovePlayerToMapStart(player)

	Remote_CallFunction_NonReplay(player, "ServerCallback_PK_ResetRun")
	PK_AddPlayerParkourStat(player, ePlayerParkourStatType.Resets)

	// Reset weapons as well
	PK_ForcePlayerLoadout(player)

	// Stop ongoing stim boost
	player.Signal("OnChangedPlayerClass")

	Remote_CallFunction_NonReplay( player, "ServerCallback_PK_ToggleStartIndicatorDisplay", false )
}

/**
 * Finds the location of the last checkpoint that was crossed by the player,
 * and respawns them there, using the angle they had when crossing said
 * checkpoint.
 **/
void function RespawnPlayerToConfirmedCheckpoint(entity player)
{
	// Do nothing if called during server initialization
	if (PK_mapConfiguration.finishedFetchingData == false) return

	// Freeze player if respawn occurs after match end
	if (GetGameState() > eGameState.SuddenDeath) {
		player.FreezeControlsOnServer()
	}

	string playerName = player.GetPlayerName()
	int checkpointIndex = PK_localStats[playerName].currentCheckpoint
	/*vector checkpoint = PK_checkpoints[checkpointIndex]
	player.SetOrigin( checkpoint )*/
	player.SetOrigin(PK_localStats[playerName].checkpointPassages[checkpointIndex])
	player.SetAngles(PK_localStats[playerName].checkpointAngles[checkpointIndex])

	// Give player predefined loadout
	PK_ForcePlayerLoadout(player)

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
		mover.NonPhysicsMoveTo (PK_checkpoints[0], 1, 0, 0)
		mover.NonPhysicsRotateTo (PK_startAngles, 1, 0, 0)
		wait 1

		player.SetVelocity(<0,0,0>)
		player.ClearParent()
		mover.Destroy()
	}

	player.UnfreezeControlsOnServer()
	PK_ResetPlayerStats( player, true )
	ResetPlayerCooldowns(player)
	
	RespawnPlayerToConfirmedCheckpoint(player)
	player.SetAngles(PK_startAngles)
}

int function ParkourDecideWinner()
{
	if (PK_leaderboard.len() == 0)
		return TEAM_UNASSIGNED

	bool found = false
	string winnerName = PK_leaderboard[0].playerName
	float time = PK_leaderboard[0].time
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

	// Tell players about the winner
	foreach ( player in GetPlayerArray() )
	{
		if ( !IsValid( player ) )
			continue

        ServerToClientStringCommand( player, "ParkourResults " + winnerName + " " + format("%.2f", time) )
	}

	return found ? TEAM_MILITIA : TEAM_UNASSIGNED
}
