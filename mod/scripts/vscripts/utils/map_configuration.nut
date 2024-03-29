global function InitializeMapConfiguration

/**
 * This global object holds parkour API information needed to interact
 * with it, namely its address, secret token, current event and current
 * map identifiers.
 *
 * These information are used by the world leaderboard to fetch scores,
 * for instance.
 **/
global struct Credentials {
    string eventId = ""
    string mapId = ""
    string endpoint
    string secret
}
global Credentials credentials

/**
 * This global object stores serialized coordinates of in-game entities
 * such as leaderboards, that must be sent to players when they connect
 * (hence the string type, since they're passed to clients using
 * `ServerToClientStringCommand` calls).
 **/
global struct MapConfiguration {
    bool finishedFetchingData = false
    entity startIndicator
    string startLineStr
    string finishLineStr
    string localLeaderboardStr
    string worldLeaderboardStr
}
global MapConfiguration mapConfiguration

/**
 * This object stores start and finish triggers plus ziplines coordinates.
 * Those are used to spawn related entities after map configuration fetching
 * is done.
 **/
struct {
    vector startMins
    vector startMaxs
    vector endMins
    vector endMaxs
    array ziplines
} file;

/**
 * This object stores information needed to spawn a helping robot on the map.
 **/
struct {
    vector origin
    vector angles
    int talkableRadius
    string animation
} robot;



/**
 * Get the map configuration, applies it to the game level and send UI elements
 * (start/finish indicators, leaderboards) coordinates to clients.
 *
 * Map configuration can be fetched from two sources: Parkour API or local file.
 **/
void function InitializeMapConfiguration()
{
    // Load map configuration either from local file or distant API
    bool useLocal = GetConVarInt("parkour_use_local_config") == 1

    if (useLocal) {
        print("Loading map configuration from local file.")
        InitializeMapConfigurationFromFile()
    } else {
        print("Loading map configuration from API.")
        thread InitializeMapConfigurationFromAPI()
    }
    while(mapConfiguration.finishedFetchingData == false) {
        WaitFrame()
    }

    // Set up world
	SpawnCheckpoints( file.startMins, file.startMaxs, file.endMins, file.endMaxs )
    SpawnZiplines( file.ziplines )
    SpawnAmbientMarvin( robot.origin, robot.angles, robot.talkableRadius, robot.animation )

    // Init players
    foreach(player in GetPlayerArray())
    {
        if ( !IsValid( player ) ) {
			continue
		}
        PK_OnPlayerConnected(player)
    }
}


/**
 * This method loads all needed information from input table into memory, to spawn
 * current level's layout (start/finish lines, leaderboards, checkpoints, ziplines
 * etc).
 *
 * It also serializes some coordinates (namely start/finish lines and leaderboards
 * coordinates) to prepare sending them to clients, since clients need those
 * coordinates to spawn world RUIs.
 **/
void function LoadParkourMapConfiguration(table data)
{
    try {
        // Checkpoints
        array fCheckpoints = expect array(data["checkpoints"])
        foreach( checkpoint in fCheckpoints ) {
            checkpoints.push( ArrayToFloatVector(expect array(checkpoint)) )
        }
        table startData = expect table(data["start"])
        vector start = ArrayToFloatVector( expect array(startData["origin"]) )
        checkpoints.insert( 0, start )
        vector angles = ArrayToIntVector( expect array(startData["angles"]) )
        startAngles = angles
        table endData = expect table(data["end"])
        vector end = ArrayToFloatVector( expect array(endData["origin"]) )
        checkpoints.append( end )

        // Start/finish lines
        // Start
        table startLineData = expect table(data["start_line"])
        ParkourLine startLine = BuildParkourLine(startLineData)
        file.startMins = startLine.triggerMins
        file.startMaxs = startLine.triggerMaxs
        // End
        table finishLineData = expect table(data["finish_line"])
        ParkourLine endLine = BuildParkourLine(finishLineData)
        file.endMins = endLine.triggerMins
        file.endMaxs = endLine.triggerMaxs
        // Leaderboards
        table leaderboardsData = expect table(data["leaderboards"])
        table localLeaderboardData = expect table(leaderboardsData["local"])
        table worldLeaderboardData = expect table(leaderboardsData["world"])

        // Serialized
        mapConfiguration.startLineStr = EncodeJSON(startLineData)
        mapConfiguration.finishLineStr = EncodeJSON(finishLineData)
        mapConfiguration.localLeaderboardStr = EncodeJSON(localLeaderboardData)
        mapConfiguration.worldLeaderboardStr = EncodeJSON(worldLeaderboardData)

        // Robot
        table robotData = expect table(data["robot"])
        robot.origin = ArrayToFloatVector( expect array(robotData["origin"]) )
        robot.angles = ArrayToIntVector( expect array(robotData["angles"]) )
        robot.talkableRadius = expect int(robotData["talkable_radius"])
        robot.animation = expect string(robotData["animation"])

        // Start indicator
        table startIndicator = expect table(data["indicator"])
        vector startIndicatorOrigin = ArrayToFloatVector( expect array(startIndicator["coordinates"]) )
        int startIndicatorRadius = expect int(startIndicator["trigger_radius"])
        SetUpStartIndicator( startIndicatorOrigin, startIndicatorRadius )

        file.ziplines = expect array(data["ziplines"])
        mapConfiguration.finishedFetchingData = true
    } catch (err) {
        print("Error while loading map configuration: " + err)
    }
}


void function SetUpStartIndicator( vector origin, int triggerRadius )
{
    // Entity used to show indicator's location
    entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
    point.SetValueForModelKey($"models/fx/xo_emp_field.mdl")
    point.kv.modelscale = 1
    point.Hide()
    DispatchSpawn( point )
    mapConfiguration.startIndicator = point

    // Only showing indicator when player is far from its origin
    entity trigger = CreateTriggerRadiusMultiple( origin, triggerRadius.tofloat(), [], TRIG_FLAG_PLAYERONLY)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player) {
        string playerName = player.GetPlayerName()
        if ( !localStats[playerName].isRunning && !localStats[playerName].isResetting ) {
            Remote_CallFunction_NonReplay( player, "ServerCallback_ToggleStartIndicatorDisplay", false )
        }
    })
    AddCallback_ScriptTriggerLeave( trigger, void function (entity trigger, entity player) {
        string playerName = player.GetPlayerName()
        if ( !localStats[playerName].isRunning && !localStats[playerName].isResetting && IsAlive(player) ) {
            Remote_CallFunction_NonReplay( player, "ServerCallback_ToggleStartIndicatorDisplay", true )
        }
    })
}


/**
 * Spawns ziplines on the map (pretty self-explanatory, right?).
 **/
void function SpawnZiplines( array coordinates )
{
	foreach (c in coordinates)
	{
        array zipline = expect array(c)
        array startCoordinates = expect array(zipline[0])
        array endCoordinates = expect array(zipline[1])
		CreateZipline( ArrayToFloatVector(startCoordinates), ArrayToFloatVector(endCoordinates) )
	}
}


/*
 ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗     ███████╗███████╗████████╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝     ██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║██║████╗  ██║██╔════╝
██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗    █████╗  █████╗     ██║   ██║     ███████║██║██╔██╗ ██║██║  ███╗
██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║    ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║██║██║╚██╗██║██║   ██║
╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝    ██║     ███████╗   ██║   ╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
 ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝     ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
*/

/*
 ██╗██╗     ██╗      ██████╗  ██████╗ █████╗ ██╗          ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
███║╚██╗    ██║     ██╔═══██╗██╔════╝██╔══██╗██║         ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
╚██║ ██║    ██║     ██║   ██║██║     ███████║██║         ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
 ██║ ██║    ██║     ██║   ██║██║     ██╔══██║██║         ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
 ██║██╔╝    ███████╗╚██████╔╝╚██████╗██║  ██║███████╗    ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
 ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝
*/

/**
 * Loads map configuration from a local configuration file.
 *
 * The expected configuration file name is [MAPNAME]_configuration.json (e.g.
 * map_thaw_configuration.json) and should be located in the mod's files
 * directory (i.e. R2Northstar/save_data/Alystrasz.Parkour/FILE.json).
 *
 * If invoked on a map where there is no configuration file, said file will
 * be created, and an error will be thrown telling the developer to fill it
 * with a valid map configuration.
 **/
void function InitializeMapConfigurationFromFile()
{
    string fileName = format("%s_configuration.json", GetMapName())
    if (!NSDoesFileExist(fileName)) {
        NSSaveFile(fileName, "")
        throw format("No configuration file found for map \"%s\", please fill the configuration file (%s).", GetMapName(), fileName)
    }

    void functionref( string ) onFileLoad = void function ( string result )
    {
        table data = DecodeJSON(result)
        LoadParkourMapConfiguration( expect table(data["configuration"]) )
        ApplyPerks( expect table(data["perks"]) )
        mapConfiguration.finishedFetchingData = true;
    }
    NSLoadFile(fileName, onFileLoad)
}


/*
██████╗ ██╗     ██████╗ ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗     ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
╚════██╗╚██╗    ██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
 █████╔╝ ██║    ██║  ██║██║███████╗   ██║   ███████║██╔██╗ ██║   ██║       ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
██╔═══╝  ██║    ██║  ██║██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║       ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
███████╗██╔╝    ██████╔╝██║███████║   ██║   ██║  ██║██║ ╚████║   ██║       ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
╚══════╝╚═╝     ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝        ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝
*/

/**
 * Loads map configuration from Parkour API.
 *
 * This involves retrieving the current event, then the map configuration
 * associated to the current map (including perks and level layout).
 **/
void function InitializeMapConfigurationFromAPI()
{
    // Initialize credentials
    credentials.endpoint = GetConVarString("parkour_api_endpoint")
    credentials.secret = GetConVarString("parkour_api_secret")
    thread FindEventIdentifier()
    while (credentials.eventId == "") {
        WaitFrame()
    }
    thread FindMapIdentifier()
    while (credentials.mapId == "") {
        WaitFrame()
    }

    thread FetchMapConfigurationFromAPI()
}


/**
 * This method fetches the `events` resource of the Parkour API to find the identifier
 * of the current event, based on its start and end timestamps.
 *
 * Once corresponding event has been found, this will register said event identifier
 * locally, for it to be used in future HTTP requests to retrieve map information.
 *
 * If no corresponding event is found, no further HTTP request will occur during the
 * current match.
 **/
void function FindEventIdentifier()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events", credentials.endpoint)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        array events = expect array(data["data"])

        // Looking for an event whose dates match server current time.
        foreach (eValue in events) {
            table event = expect table(eValue)
            int start = expect int(event["start"])
            int end = expect int(event["end"])
            int currentTime = GetUnixTimestamp();

            if (currentTime >= start && currentTime <= end) {
                credentials.eventId = expect string(event["id"])
                print("==> Parkour event found!")
                return;
            }
        }

        print("No parkour event is available at the moment.")
        has_api_access = false
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching events from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}


/**
 * This method fetches the `maps` resource of the Parkour API to find information
 * about the current match: where to save new scores, which settings (weapons/ability
 * set) to apply to all players...
 *
 * Once corresponding map has been found, this will register said map identifier
 * locally, for it to be used in future HTTP requests, apply required changes to
 * current match, and start fetching scores from distant API every few seconds.
 *
 * If no corresponding map is found, no further HTTP request will occur during the
 * current match.
 **/
void function FindMapIdentifier()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events/%s/maps", credentials.endpoint, credentials.eventId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        array maps = expect array(data["data"])

        // Looking for a map whose name matches current map's name.
        string mapName = GetMapName()
        foreach (value in maps) {
            table map = expect table(value)
            string map_name = expect string(map["map_name"])
            if ( map_name.find( mapName) != null ) {
                print("==> Parkour map found!")
                credentials.mapId = expect string(map["id"])
                thread WorldLeaderboard_StartPeriodicFetching()
                has_api_access = true

                table perks = expect table(map["perks"]);
                ApplyPerks( perks )

                return;
            }
        }

        print("No map matches the event id and current map.")
        has_api_access = false
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching maps from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}


/**
 * This method fetches the `maps` resource of the Parkour API to retrieve the map
 * configuration for the current match: where to spawn leaderboards and start/finish
 * lines, what are the checkpoints coordinates etc.
 *
 * Once fetched, said map configuration is applied to create current level layout.
 *
 * If HTTP call fails, no further HTTP request will occur during the current match.
 **/
void function FetchMapConfigurationFromAPI()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/maps/%s/configuration", credentials.endpoint, credentials.mapId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        print("==> Parkour map configuration retrieved!")
        table data = DecodeJSON(response.body)
        LoadParkourMapConfiguration(data)
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching map configuration from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}
