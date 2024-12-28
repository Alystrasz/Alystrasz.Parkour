global function Cl_Parkour_Init
global function ServerCallback_PK_UpdateNextCheckpointMarker
global function ServerCallback_PK_StopRun
global function ServerCallback_PK_ResetRun
global function ServerCallback_PK_ApplyClientsidePerks
global function ServerCallback_PK_SetRobotTalkState
global function ServerCallback_PK_TalkToRobot
global function ServerCallback_PK_CreateStartIndicator
global function ServerCallback_PK_ToggleStartIndicatorDisplay

struct {
    entity mover
    var topology

    table< int, entity > cache

    // Starting/end lines
    ParkourLine &startLine
    ParkourLine &endLine

    var worldLeaderboard
    var leaderboard
    var timerRUI
    var splashStartRUI
    var splashEndRUI
    var startLineRUI
    var endLineRUI
    var newHighscoreRUI
    var resetHintRUI
	var checkpointsCountRUI
    var startIndicatorRUI
    int startIndicatorTime = 0

    bool isRunning = false
    var nextCheckpointRui
    float bestTime = 0

    bool canTalktoRobot = false
    string endpoint = ""
    string routeId = ""
} file;


var function CreateTopology( vector org, vector ang, float width, float height ) {
    // adjust so the RUI is drawn with the org as its center point
    org += ( (AnglesToRight( ang )*-1) * (width*0.5) )
    org += ( AnglesToUp( ang ) * (height*0.5) )

    // right and down vectors that get added to base org to create the display size
    vector right = ( AnglesToRight( ang ) * width )
    vector down = ( (AnglesToUp( ang )*-1) * height )

    return RuiTopology_CreatePlane( org, right, down, true )
}

void function UpdateTopology( var topo, vector org, vector ang, float width, float height ) {
    // adjust so the RUI is drawn with the org as its center point
    org += ( (AnglesToRight( ang )*-1) * (width*0.5) )
    org += ( AnglesToUp( ang ) * (height*0.5) )

    // right and down vectors that get added to base org to create the display size
    vector right = ( AnglesToRight( ang ) * width )
    vector down = ( (AnglesToUp( ang )*-1) * height )

    RuiTopology_UpdatePos(topo, org, right, down)
}

void function Cl_Parkour_Init()
{
    // register command to receive leaderboard updates from server
    AddServerToClientStringCommandCallback( "ParkourUpdateLeaderboard", ServerCallback_UpdateLeaderboard )
    AddServerToClientStringCommandCallback( "ParkourInitLine", ServerCallback_CreateLine )
    AddServerToClientStringCommandCallback( "ParkourInitLeaderboard", ServerCallback_CreateLeaderboard )
    AddServerToClientStringCommandCallback( "ParkourInitRouteName", ServerCallback_CreateRouteName )
    AddServerToClientStringCommandCallback( "ParkourInitEndpoint", ServerCallback_SaveParkourEndpoint )

    // hide boost progress
    Cl_GGEarnMeter_Init(ClGamemodePK_GetWeaponIcon, ClGamemodePK_ShouldChangeWeaponIcon)

    // register callbacks to prepare eventual perks
    AddCreateCallback( "player", FloorIsLavaPlayerCreated )
}

void function FloorIsLavaPlayerCreated( entity player )
{
    table s = expect table(player.s)
    s.inLavaFog <- false
}

// No arguments for now, until we need some.
void function ServerCallback_PK_ApplyClientsidePerks()
{
    ClRiffFloorIsLava_Init()
}

asset function ClGamemodePK_GetWeaponIcon()
{
	return $"rui/faction/faction_logo_mrvn";
}

bool function ClGamemodePK_ShouldChangeWeaponIcon()
{
	return true
}

void function SafeDestroyRUI( var rui )
{
    if ( rui != null ) {
        RuiDestroyIfAlive( rui )
        rui = null
    }
}

void function DestroyRemainingRUIs()
{
    SafeDestroyRUI( file.timerRUI )
    SafeDestroyRUI( file.splashStartRUI )
    SafeDestroyRUI( file.splashEndRUI )
    SafeDestroyRUI( file.nextCheckpointRui )
    SafeDestroyRUI( file.newHighscoreRUI )
    SafeDestroyRUI( file.checkpointsCountRUI )
    SafeDestroyRUI( file.startLineRUI )
    SafeDestroyRUI( file.endLineRUI )
    SafeDestroyRUI( file.resetHintRUI )
}

void function StartRun( int checkpointsCount )
{
    file.isRunning = true

    // Remove RUIs used in previous run
    DestroyRemainingRUIs()

    // Start splash message
    file.splashStartRUI = RuiCreate( $"ui/gauntlet_splash.rpak", clGlobal.topoCockpitHud, RUI_DRAW_COCKPIT, 0 )
	RuiSetFloat( file.splashStartRUI, "duration", 5 )
	RuiSetString( file.splashStartRUI, "message", "#GAUNTLET_START_TEXT")


    // Chronometer
    file.timerRUI = RuiCreate( $"ui/gauntlet_hud.rpak", clGlobal.topoCockpitHud, RUI_DRAW_COCKPIT, 0 )
    RuiSetGameTime( file.timerRUI, "startTime", Time() )
    if (file.bestTime != 0)
        RuiSetFloat( file.timerRUI, "bestTime", file.bestTime )

    // Track speed
    entity player = GetLocalViewPlayer()
    RuiTrackFloat3( file.timerRUI, "playerPos", player, RUI_TRACK_ABSORIGIN_FOLLOW )
    RuiSetBool( file.timerRUI, "useMetric", true )

    // Display a "best time" entry on RUI
    // RuiSetFloat( file.timerRUI, "bestTime", 142 )
    // RuiSetBool( file.timerRUI, "runFinished", true )
    // RuiSetFloat( file.timerRUI, "finalTime", 215 )


    // Next checkpoint marker
    var rui = CreateCockpitRui( $"ui/fra_battery_icon.rpak" )
	RuiSetImage( rui, "imageName", $"rui/hud/gametype_icons/ctf/ctf_flag_neutral" )
	RuiSetBool( rui, "isVisible", true )
    file.nextCheckpointRui = rui

    // Checkpoints count RUI
    file.checkpointsCountRUI = CreatePermanentCockpitRui( $"ui/at_wave_intro.rpak" )
    RuiSetInt( file.checkpointsCountRUI, "listPos", 0 )
    RuiSetGameTime( file.checkpointsCountRUI, "startFadeInTime", Time() )
    RuiSetString( file.checkpointsCountRUI, "titleText", "0/" + checkpointsCount )
    RuiSetString( file.checkpointsCountRUI, "itemText", "#REACHED_CHECKPOINTS" )
    RuiSetFloat2( file.checkpointsCountRUI, "offset", < 0, -250, 0 > )

    // Reset hint message
    thread ResetHintThink()

    // Spawn/despawn start+end lines
    DespawnStartLine()
    SpawnEndLine()
}

void function ResetHintThink()
{
    SafeDestroyRUI( file.resetHintRUI )
    entity player = GetLocalViewPlayer()
    int time = GetUnixTimestamp()
    bool isMoving = true

    while (GetGameState() <= eGameState.SuddenDeath)
    {
        if (!file.isRunning)
            return
        if ( !IsValid( player ) )
            return

        vector movement = player.GetVelocity()
        if ( movement.x == 0 && movement.y == 0 )
        {
            if ( isMoving )
            {
                time = GetUnixTimestamp()
                isMoving = false
            }

            if ( GetUnixTimestamp() - time >= 2 )
                break
        }
        else
        {
            isMoving = true
        }

        WaitFrame()
    }

    // Don't show element on match end
    if ( GetGameState() >= eGameState.SuddenDeath )
        return

    file.resetHintRUI = CreatePermanentCockpitRui( $"ui/death_hint_mp.rpak" )
    RuiSetString( file.resetHintRUI, "hintText", Localize( "#RESET_RUN_HINT" ) )
    RuiSetGameTime( file.resetHintRUI, "startTime", Time() )
    RuiSetFloat3( file.resetHintRUI, "bgColor", < 0, 0, 0 > )
    RuiSetFloat( file.resetHintRUI, "bgAlpha", 0.5 )

    wait 7
    SafeDestroyRUI( file.resetHintRUI )
}

void function ServerCallback_PK_ResetRun()
{
    DestroyRemainingRUIs()
    SpawnStartLine()
	file.isRunning = false
}

void function ServerCallback_UpdateLeaderboard( array<string> args )
{
    string playerName = args[0]
    float time = args[1].tofloat()
    int index = args[2].tointeger()
    bool world = args[3].tointeger() == 1;

    string nameArg = "entry" + index + "Name"
    string timeArg = "entry" + index + "Time"

    RuiSetString( world ? file.worldLeaderboard : file.leaderboard, nameArg, playerName )
    RuiSetFloat( world ? file.worldLeaderboard : file.leaderboard, timeArg, time )

    // Highlight personal entries
    entity localPlayer = GetLocalViewPlayer()
    if (playerName == localPlayer.GetPlayerName()) {
        RuiSetInt( world ? file.worldLeaderboard : file.leaderboard, "activeEntryIdx", index )
    }

    // Stop here for world scores
    if (world) return;

    // Display a special message on new highscore
    if (index == 0)
    {
        thread ShowNewHighscoreMessage( playerName, time )
    }

    // When reconnecting to a server where a score has previously been registered,
    // restore it as best time.
    if (localPlayer.GetPlayerName() == playerName && file.bestTime == 0)
        file.bestTime = time
}

void function ShowNewHighscoreMessage( string playerName, float playerTime )
{
    SafeDestroyRUI(  file.newHighscoreRUI )

    file.newHighscoreRUI = CreatePermanentCockpitRui( $"ui/death_hint_mp.rpak" )
    RuiSetString( file.newHighscoreRUI, "hintText", Localize( "#NEW_HIGHSCORE", playerName, format( "%.2f", playerTime ) ) )
    RuiSetGameTime( file.newHighscoreRUI, "startTime", Time() )
    RuiSetFloat3( file.newHighscoreRUI, "bgColor", < 0, 0, 0 > )
    RuiSetFloat( file.newHighscoreRUI, "bgAlpha", 0.5 )

    wait 7

    SafeDestroyRUI( file.newHighscoreRUI )
}

void function ServerCallback_PK_UpdateNextCheckpointMarker ( int checkpointHandle, int checkpointIndex, int totalCheckpointsCount )
{
	entity checkpoint = GetEntityFromEncodedEHandle( checkpointHandle )
	if (!IsValid(checkpoint))
		return

    if (checkpointIndex == 0)
    {
        // Setup run RUIs
        StartRun( totalCheckpointsCount );
    }
    else
    {
        // Update checkpoints count RUI
		RuiSetString( file.checkpointsCountRUI, "titleText", checkpointIndex + "/" + totalCheckpointsCount )
    }

    // Update checkpoint overhead icon
    RuiTrackFloat3( file.nextCheckpointRui, "pos", checkpoint, RUI_TRACK_OVERHEAD_FOLLOW )
}

void function ServerCallback_PK_StopRun( float runDuration, bool isBestTime )
{
    file.isRunning = false
	thread DestroyCheckpointsCountRUI()

    SafeDestroyRUI( file.nextCheckpointRui )
    float stopRunRUIsDuration = 5

    // Spawn/despawn start+end lines
    SpawnStartLine()
    DespawnEndLine()

    // Finish splash message
    file.splashEndRUI = RuiCreate( $"ui/gauntlet_splash.rpak", clGlobal.topoCockpitHud, RUI_DRAW_COCKPIT, 0 )
	RuiSetFloat( file.splashEndRUI, "duration", stopRunRUIsDuration )
    RuiSetString( file.splashEndRUI, "message", "#GAUNTLET_FINISH_TEXT")

    // Update chronometer RUI
    if (isBestTime)
    {
        // Even if server thinks this is a match best time, locally stored PB could mean a better time was recorded
        // in a previous match
        if ( runDuration < file.bestTime )
        {
            file.bestTime = runDuration
            RuiSetFloat( file.timerRUI, "bestTime", runDuration )
            PK_StoreRouteBestTime( file.routeId, runDuration )
        }
    }
    RuiSetBool( file.timerRUI, "runFinished", true )
	RuiSetFloat( file.timerRUI, "finalTime", runDuration )
    thread DestroyTimerRUI( stopRunRUIsDuration )
}

void function DestroyTimerRUI( float delay )
{
	wait delay - 0.5

    if (file.isRunning)
        return
    SafeDestroyRUI( file.timerRUI )

	file.timerRUI = null
}

void function DestroyCheckpointsCountRUI()
{
	RuiSetGameTime( file.checkpointsCountRUI, "startFadeOutTime", Time() )
	wait 0.6
    SafeDestroyRUI( file.checkpointsCountRUI )
}

void function ServerCallback_PK_ToggleStartIndicatorDisplay( bool show )
{
    RuiSetBool( file.startIndicatorRUI, "isVisible", show )
    if (show) {
        entity player = GetLocalClientPlayer()

        // Only display warning message once every two minutes
        int now = GetUnixTimestamp()
        if ( show && now - file.startIndicatorTime > 120) {
            string prefix = format("\x1b[93m%s:\x1b[0m ", PK_ROBOT_NAME)
            string message = Localize("#ROBOT_LOST_PLAYER", GetLocalClientPlayer().GetPlayerName())
            Chat_GameWriteLine(prefix + message)
            file.startIndicatorTime = GetUnixTimestamp()
            EmitSoundOnEntity( player, "diag_spectre_gs_LeechStart_01_1" )
        } else {
            EmitSoundOnEntity( player, "UI_Spawn_FriendlyPilot" )
        }
    }
}


// ██████╗  ██████╗ ██████╗  ██████╗ ████████╗
// ██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝
// ██████╔╝██║   ██║██████╔╝██║   ██║   ██║
// ██╔══██╗██║   ██║██╔══██╗██║   ██║   ██║
// ██║  ██║╚██████╔╝██████╔╝╚██████╔╝   ██║
// ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝

void function ServerCallback_SaveParkourEndpoint( array<string> args )
{
    table endpoint = DecodeJSON( args[0] )
    file.endpoint = expect string( endpoint["url"] )
    file.routeId = expect string( endpoint["routeId"] )
    thread LoadPB()
}

void function LoadPB()
{
    // Retrieve local PB
    float time = PK_GetRouteBestTime( file.routeId )
    if ( time < 0)
    {
        print("=> No local PB found.")
    }
    else
    {
        print("=> Local PB found.")
        file.bestTime = time
    }
}

void function ServerCallback_PK_SetRobotTalkState( bool canTalk )
{
    file.canTalktoRobot = canTalk
    if ( canTalk )
    {
        AddPlayerHint( 1800.0, 0.25, $"", "#ROBOT_INTERACTION_PROMPT" )
    }
    else
    {
        HidePlayerHint( "#ROBOT_INTERACTION_PROMPT" )
    }
}

void function ServerCallback_PK_TalkToRobot()
{
    if (!file.canTalktoRobot) return
    RunUIScript( "Parkour_OpenRobotDialog", file.endpoint )
}


/*
███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗    ██╗███╗   ██╗██╗████████╗
████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝    ██║████╗  ██║██║╚══██╔══╝
██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝     ██║██╔██╗ ██║██║   ██║
██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗     ██║██║╚██╗██║██║   ██║
██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗    ██║██║ ╚████║██║   ██║
╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝
*/

void function ServerCallback_CreateLine( array<string> args )
{
    bool isStartLine = args[0] == "start"
    table data = DecodeJSON(args[1]);
    if ( isStartLine )
    {
        file.startLine = PK_BuildParkourLine( data )
        if ( file.startLineRUI == null)
            SpawnStartLine()
    }
    else
    {
        file.endLine = PK_BuildParkourLine( data )
    }
}

void function ServerCallback_CreateLeaderboard( array<string> args )
{
    bool isLocalLeaderboard = args[0] == "local"
    table data = DecodeJSON(args[1]);
    ParkourLeaderboard pl = PK_BuildParkourLeaderboard( data )

    // Build leaderboard
    var topo = CreateTopology(pl.origin, pl.angles, pl.dimensions[0].tofloat(), pl.dimensions[1].tofloat())
    var rui = RuiCreate( $"ui/gauntlet_leaderboard.rpak", topo, RUI_DRAW_WORLD, 0 )
    if (isLocalLeaderboard) {
        SafeDestroyRUI( file.leaderboard )
        file.leaderboard = rui
    } else {
        SafeDestroyRUI( file.worldLeaderboard )
        file.worldLeaderboard = rui
    }

    // Build "LOCAL"/"WORLD" sign
	topo = CreateTopology(pl.sourceOrigin, pl.sourceAngles, pl.sourceDimensions[0].tofloat(), pl.sourceDimensions[1].tofloat())
    rui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( rui, "displayText", isLocalLeaderboard ? "#LEADERBOARD_LOCAL" : "#LEADERBOARD_WORLD" )
}

void function ServerCallback_CreateRouteName( array<string> args )
{
    table data = DecodeJSON(args[0]);
    string name = expect string(data["name"])
    vector origin = PK_ArrayToFloatVector( expect array(data["origin"]) )
    vector angles = PK_ArrayToIntVector( expect array(data["angles"]) )
    array dimensions = expect array( data["dimensions"] )

    var topo = CreateTopology(origin, angles, expect int(dimensions[0]).tofloat(), expect int(dimensions[1]).tofloat())
    var rui = RuiCreate( $"ui/big_button_hint.rpak", topo, RUI_DRAW_WORLD, 0 )
    RuiSetString(rui, "msgText", name)
    RuiSetString( rui, "msgTextPC", name )
    RuiSetFloat(rui, "duration", 10000)
    RuiSetGameTime(rui, "startTime", Time())
    RuiSetFloat(rui, "msgFontSize", 550)
}

void function ServerCallback_PK_CreateStartIndicator( int indicatorEntityHandle )
{
    entity indicator = GetEntityFromEncodedEHandle( indicatorEntityHandle )
    if (!IsValid(indicator))
		return

    file.startIndicatorRUI = CreateCockpitRui( $"ui/overhead_icon_evac.rpak" )
    RuiSetBool( file.startIndicatorRUI, "isVisible", false )
    RuiSetImage( file.startIndicatorRUI, "icon", $"rui/hud/titanfall_marker_arrow_ready" )
    RuiSetString( file.startIndicatorRUI, "statusText", "#PARKOUR_START" )
    RuiTrackFloat3( file.startIndicatorRUI, "pos", indicator, RUI_TRACK_ABSORIGIN_FOLLOW )
}


/*
██╗     ██╗███╗   ██╗███████╗███████╗
██║     ██║████╗  ██║██╔════╝██╔════╝
██║     ██║██╔██╗ ██║█████╗  ███████╗
██║     ██║██║╚██╗██║██╔══╝  ╚════██║
███████╗██║██║ ╚████║███████╗███████║
╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝
*/

void function SpawnStartLine()
{
    var topo = CreateTopology(file.startLine.origin, file.startLine.angles, file.startLine.dimensions[0].tofloat(), file.startLine.dimensions[1].tofloat())
    var startRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( startRui, "displayText", "#GAUNTLET_START_TEXT" )
    file.startLineRUI = startRui
}

void function SpawnEndLine()
{
    var topo = CreateTopology(file.endLine.origin, file.endLine.angles, file.endLine.dimensions[0].tofloat(), file.endLine.dimensions[1].tofloat())
    var endRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( endRui, "displayText", "#GAUNTLET_FINISH_TEXT" )
    file.endLineRUI = endRui
}

void function DespawnStartLine()
{
    if ( file.startLineRUI != null )
		RuiDestroyIfAlive( file.startLineRUI )
	file.startLineRUI = null
}

void function DespawnEndLine()
{
    if ( file.endLineRUI != null )
		RuiDestroyIfAlive( file.endLineRUI )
	file.endLineRUI = null
}