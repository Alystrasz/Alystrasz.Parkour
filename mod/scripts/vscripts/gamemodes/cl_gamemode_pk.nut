global function Cl_Parkour_Init
global function ServerCallback_UpdateNextCheckpointMarker
global function ServerCallback_StopRun
global function ServerCallback_ResetRun

struct {
    entity mover
    var topology

    table< int, entity > cache

    bool receivedWorldScores = false
    var worldLeaderboard
    var leaderboard
    var timerRUI
    var splashStartRUI
    var splashEndRUI
    var newHighscoreRUI
	var checkpointsCountRUI

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
    // leaderboard
    vector origin = GetMapLeaderboardOrigin()
    vector angles = GetMapLeaderboardAngles()
    array<float> coordinates = GetMapLeaderboardDimensions()
    var topo = CreateTopology(origin, angles, coordinates[0], coordinates[1])
    var rui = RuiCreate( $"ui/gauntlet_leaderboard.rpak", topo, RUI_DRAW_WORLD, 0 )
    file.leaderboard = rui    

    // register command to receive leaderboard updates from server
    AddServerToClientStringCommandCallback( "ParkourUpdateLeaderboard", ServerCallback_UpdateLeaderboard )
    AddServerToClientStringCommandCallback( "ParkourInitStartLine", ServerCallback_CreateStartLine )

    Cl_Parkour_Create_End()
}

void function Cl_Parkour_InitWorldLeaderboard()
{
    // Local/World leaderboard signs
    Cl_ParkourCreateLeaderboardSource();
    Cl_ParkourCreateLeaderboardSource(true);

    // world leaderboard
    vector origin = GetMapLeaderboardOrigin(true)
    vector angles = GetMapLeaderboardAngles(true)
    array<float> coordinates = GetMapLeaderboardDimensions(true)
    var topo = CreateTopology(origin, angles, coordinates[0], coordinates[1])
    var rui = RuiCreate( $"ui/gauntlet_leaderboard.rpak", topo, RUI_DRAW_WORLD, 0 )
    file.worldLeaderboard = rui
}

void function Cl_ParkourCreateLeaderboardSource(bool world = false) {
    vector origin = GetMapLeaderboardSourceOrigin(world)
    vector angles = GetMapLeaderboardSourceAngles(world)
    array<float> dimensions = GetMapLeaderboardSourceDimensions(world)
	var topo = CreateTopology(origin, angles, dimensions[0], dimensions[1])
    var startRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( startRui, "displayText", world ? "#LEADERBOARD_WORLD" : "#LEADERBOARD_LOCAL" )
}


void function Cl_Parkour_Create_End()
{
    vector origin = GetMapFinishLineOrigin()
    vector angles = GetMapFinishLineAngles()
    array<float> coordinates = GetMapFinishLineDimensions()
	var topo = CreateTopology(origin, angles, coordinates[0], coordinates[1])
    var endRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( endRui, "displayText", "#GAUNTLET_FINISH_TEXT" )
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


    // World leaderboard is only displayed if server is connected to world parkour API
    if (world && !file.receivedWorldScores) {
        Cl_Parkour_InitWorldLeaderboard()
        file.receivedWorldScores = true
    }


    string nameArg = "entry" + index + "Name"
    string timeArg = "entry" + index + "Time"

    RuiSetString( world ? file.worldLeaderboard : file.leaderboard, nameArg, playerName )
    RuiSetFloat( world ? file.worldLeaderboard : file.leaderboard, timeArg, time )

    // Stop here for world scores
    if (world) return;

    // Display a special message on new highscore
    if (index == 0)
    {
        thread ShowNewHighscoreMessage( playerName, time )
    }

    // When reconnecting to a server where a score has previously been registered,
    // restore it as best time.
    entity localPlayer = GetLocalViewPlayer()
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


/*
███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗    ██╗███╗   ██╗██╗████████╗
████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝    ██║████╗  ██║██║╚══██╔══╝
██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝     ██║██╔██╗ ██║██║   ██║   
██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗     ██║██║╚██╗██║██║   ██║   
██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗    ██║██║ ╚████║██║   ██║   
╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝ 
*/

vector function ArrayToFloatVector(array a)
{
    float v1 = expect float(a[0]);
    float v2 = expect float(a[1]);
    float v3 = expect float(a[2]);
    return < v1, v2, v3 >
}

vector function ArrayToIntVector(array a)
{
    int v1 = expect int(a[0]);
    int v2 = expect int(a[1]);
    int v3 = expect int(a[2]);
    return < v1, v2, v3 >
}


void function ServerCallback_CreateStartLine( array<string> args ) 
{
    table data = DecodeJSON(args[0]);

    vector origin = ArrayToFloatVector( expect array(data["origin"]) )
    vector angles = ArrayToIntVector( expect array(data["angles"]) )
    array dimensions = expect array(data["dimensions"])

    float width = expect int(dimensions[0]).tofloat()
    float height = expect int(dimensions[1]).tofloat()
	var topo = CreateTopology(origin, angles, width, height)
    var startRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( startRui, "displayText", "#GAUNTLET_START_TEXT" )
}