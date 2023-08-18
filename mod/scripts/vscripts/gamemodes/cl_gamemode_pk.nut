global function Cl_Parkour_Init
global function ServerCallback_UpdateNextCheckpointMarker
global function ServerCallback_StopRun
global function ServerCallback_ResetRun
global function ServerCallback_CreateStartIndicator
global function ServerCallback_ToggleStartIndicatorDisplay

struct {
    entity mover
    var topology

    table< int, entity > cache

    var worldLeaderboard
    var leaderboard
    var timerRUI
    var splashStartRUI
    var splashEndRUI
    var newHighscoreRUI
	var checkpointsCountRUI
    var startIndicatorRUI
    int startIndicatorTime = 0

    bool isRunning = false
    var nextCheckpointRui
    float bestTime = 0
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
	HidePlayerHint("#RESET_RUN_HINT")
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
    thread ShowResetHint()
}

void function ShowResetHint()
{
    wait 5
	if (file.isRunning)
    	AddPlayerHint( 5.0, 0.5, $"", "#RESET_RUN_HINT" )
}

void function ServerCallback_ResetRun()
{
    DestroyRemainingRUIs()
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
    RuiSetString( file.newHighscoreRUI, "hintText", Localize( "#NEW_HIGHSCORE", playerName, playerTime ) )
    RuiSetGameTime( file.newHighscoreRUI, "startTime", Time() )
    RuiSetFloat3( file.newHighscoreRUI, "bgColor", < 0, 0, 0 > )
    RuiSetFloat( file.newHighscoreRUI, "bgAlpha", 0.5 )

    wait 7

    SafeDestroyRUI( file.newHighscoreRUI )
}

void function ServerCallback_UpdateNextCheckpointMarker ( int checkpointHandle, int checkpointIndex, int totalCheckpointsCount )
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

void function ServerCallback_StopRun( float runDuration, bool isBestTime )
{
    file.isRunning = false
	thread DestroyCheckpointsCountRUI()

    SafeDestroyRUI( file.nextCheckpointRui )
    float stopRunRUIsDuration = 5

    // Finish splash message
    file.splashEndRUI = RuiCreate( $"ui/gauntlet_splash.rpak", clGlobal.topoCockpitHud, RUI_DRAW_COCKPIT, 0 )
	RuiSetFloat( file.splashEndRUI, "duration", stopRunRUIsDuration )
    RuiSetString( file.splashEndRUI, "message", "#GAUNTLET_FINISH_TEXT")

    // Update chronometer RUI
    if (isBestTime)
    {
        RuiSetFloat( file.timerRUI, "bestTime", runDuration )
        file.bestTime = runDuration
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

void function ServerCallback_ToggleStartIndicatorDisplay( bool show )
{
    RuiSetBool( file.startIndicatorRUI, "isVisible", show )
    if (show) {
        entity player = GetLocalClientPlayer()
        EmitSoundOnEntity( player, "UI_Spawn_FriendlyPilot" )

        // Only display warning message once every two minutes
        int now = GetUnixTimestamp()
        if ( show && now - file.startIndicatorTime > 120) {
            Chat_GameWriteLine("\x1b[93mRMY:\x1b[0m Getting lost, " + GetLocalClientPlayer().GetPlayerName() + "?\nI added coordinates of the parkour start to your HUD.")
            file.startIndicatorTime = GetUnixTimestamp()
        }
    }
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
    ParkourLine line = BuildParkourLine( data )
	var topo = CreateTopology(line.origin, line.angles, line.dimensions[0].tofloat(), line.dimensions[1].tofloat())
    var startRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( startRui, "displayText", isStartLine ? "#GAUNTLET_START_TEXT" : "#GAUNTLET_FINISH_TEXT" )
}

void function ServerCallback_CreateLeaderboard( array<string> args )
{
    bool isLocalLeaderboard = args[0] == "local"
    table data = DecodeJSON(args[1]);
    ParkourLeaderboard pl = BuildParkourLeaderboard( data )

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

void function ServerCallback_CreateStartIndicator( int indicatorEntityHandle )
{
    entity indicator = GetEntityFromEncodedEHandle( indicatorEntityHandle )
    if (!IsValid(indicator))
		return

    file.startIndicatorRUI = CreateCockpitRui( $"ui/overhead_icon_evac.rpak" )
    RuiSetBool( file.startIndicatorRUI, "isVisible", false )
    RuiSetImage( file.startIndicatorRUI, "icon", $"rui/hud/titanfall_marker_arrow_ready" )
    RuiSetString( file.startIndicatorRUI, "statusText", "Parkour start" )
    RuiTrackFloat3( file.startIndicatorRUI, "pos", indicator, RUI_TRACK_ABSORIGIN_FOLLOW )
}
