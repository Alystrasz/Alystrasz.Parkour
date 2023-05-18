global function Cl_Parkour_Init
global function ServerCallback_StartRun
global function ServerCallback_UpdateLeaderboard
global function ServerCallback_UpdateNextCheckpointMarker
global function ServerCallback_StopRun
global function ServerCallback_ResetRun

struct {
    entity mover
    var topology

    table< int, entity > cache

    var leaderboard
    var timerRUI
    var splashStartRUI
    var splashEndRUI

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

    thread Cl_Parkour_Create_Start()
    Cl_Parkour_Create_End()
}

// Start/end "barrier" world UI
void function Cl_Parkour_Create_Start()
{
	vector origin = GetMapStartLineOrigin()
    vector angles = GetMapStartLineAngles()
    array<float> coordinates = GetMapStartLineDimensions()
	var topo = CreateTopology(origin, angles, coordinates[0], coordinates[1])
    var startRui = RuiCreate( $"ui/gauntlet_starting_line.rpak", topo, RUI_DRAW_WORLD, 0 )
	RuiSetString( startRui, "displayText", "#GAUNTLET_START_TEXT" )
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

void function DestroyRemainingRUIs()
{
    if ( file.timerRUI != null ) {
        RuiDestroyIfAlive( file.timerRUI )
        file.timerRUI = null
    }
    if ( file.splashStartRUI != null ) {
        RuiDestroyIfAlive( file.splashStartRUI )
        file.splashStartRUI = null
    }
    if ( file.splashEndRUI != null ) {
        RuiDestroyIfAlive( file.splashEndRUI )
        file.splashEndRUI = null
    }
    if ( file.nextCheckpointRui != null )
    {
        RuiDestroyIfAlive( file.nextCheckpointRui )
        file.nextCheckpointRui = null
    }
}

void function ServerCallback_StartRun()
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

    // Reset hint message
    thread ShowResetHint()
}

void function ShowResetHint()
{
    wait 5
    AddPlayerHint( 5.0, 0.5, $"", "Tip: hold %use% to restart the run." )
}

void function ServerCallback_ResetRun()
{
    DestroyRemainingRUIs()
}

void function ServerCallback_UpdateLeaderboard( int playerHandle, float time, int index )
{
    entity player = GetEntityFromEncodedEHandle( playerHandle )
	if (!IsValid(player))
		return

    string nameArg = "entry" + index + "Name"
    string timeArg = "entry" + index + "Time"

    RuiSetString( file.leaderboard, nameArg, player.GetPlayerName() )
    RuiSetFloat( file.leaderboard, timeArg, time )
}

void function ServerCallback_UpdateNextCheckpointMarker ( int checkpointHandle )
{
	entity checkpoint = GetEntityFromEncodedEHandle( checkpointHandle )
	if (!IsValid(checkpoint))
		return
    RuiTrackFloat3( file.nextCheckpointRui, "pos", checkpoint, RUI_TRACK_OVERHEAD_FOLLOW )
}

void function ServerCallback_StopRun( float runDuration, bool isBestTime )
{
    file.isRunning = false

    if ( file.nextCheckpointRui != null )
    {
        RuiDestroyIfAlive( file.nextCheckpointRui )
        file.nextCheckpointRui = null
    }

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
	if ( file.timerRUI != null )
		RuiDestroyIfAlive( file.timerRUI )

	file.timerRUI = null
}
