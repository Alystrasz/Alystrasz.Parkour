global function InitializeMapConfiguration

global struct Credentials {
    string eventId
    string mapId = ""
    string endpoint
    string secret
}
global Credentials credentials

global struct MapConfiguration {
    bool finishedFetchingData = false
    string startLineStr
    string finishLineStr
    string localLeaderboardStr
    string worldLeaderboardStr
}

global MapConfiguration mapConfiguration

struct {
    vector startMins
    vector startMaxs
    vector endMins
    vector endMaxs
    array ziplines
} file;


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
        while(mapConfiguration.finishedFetchingData == false) {
            WaitFrame()
        }
    }

    // Set up world
	SpawnCheckpoints( file.startMins, file.startMaxs, file.endMins, file.endMaxs )
    SpawnZiplines( file.ziplines )

    // Init players
    foreach(player in GetPlayerArray())
    {
        OnPlayerConnected(player)
    }
}

void function InitializeMapConfigurationFromFile()
{
    string fileName = format("%s_configuration.json", GetMapName())
    if (!NSDoesFileExist(fileName)) {
        NSSaveFile(fileName, "")
        throw format("No configuration file found for map \"%s\", please fill the configuration file (%s).", GetMapName(), fileName)
    }
}

void function InitializeMapConfigurationFromAPI()
{
    // Initialize credentials
    credentials.eventId = GetConVarString("parkour_api_event_id")
    credentials.secret = GetConVarString("parkour_api_secret")
    credentials.endpoint = GetConVarString("parkour_api_endpoint")
    thread FindMapIdentifier()
    while (credentials.mapId == "") {
        WaitFrame()
    }

    thread FetchMapConfigurationFromAPI()
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
        print("███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗")
        print("██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝")
        print("█████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗")
        print("██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║")
        print("███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║")
        print("╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝")

        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        array maps = expect array(data["data"])

        // Currently, corresponding event is found by checking if its name contains the
        // name of the current map, which might be improved.
        string mapName = GetMapName()
        foreach (value in maps) {
            table map = expect table(value)
            string map_name = expect string(map["map_name"])
            if ( map_name.find( mapName) != null ) {
                credentials.mapId = expect string(map["id"])
                thread WorldLeaderboard_FetchScores()
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
        print("███╗   ███╗ █████╗ ██████╗      ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ")
        print("████╗ ████║██╔══██╗██╔══██╗    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ")
        print("██╔████╔██║███████║██████╔╝    ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗")
        print("██║╚██╔╝██║██╔══██║██╔═══╝     ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║")
        print("██║ ╚═╝ ██║██║  ██║██║         ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝")
        print("╚═╝     ╚═╝╚═╝  ╚═╝╚═╝          ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ ")

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

void function LoadParkourMapConfiguration(table data)
{
    // Checkpoints
    array fCheckpoints = expect array(data["checkpoints"])
    foreach( checkpoint in fCheckpoints ) {
        checkpoints.push( ArrayToFloatVector(expect array(checkpoint)) )
    }
    table startData = expect table(data["start"])
    vector start = ArrayToFloatVector( expect array(startData["origin"]) )
    checkpoints.insert( 0, start )
    table endData = expect table(data["end"])
    vector end = ArrayToFloatVector( expect array(endData["origin"]) )
    checkpoints.append( end )

    // Start/finish lines
    // Start
    table startLineData = expect table(data["startLine"])
    ParkourLine startLine = BuildParkourLine(startLineData)
    file.startMins = startLine.triggerMins
    file.startMaxs = startLine.triggerMaxs
    // End
    table finishLineData = expect table(data["finishLine"])
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

    file.ziplines = expect array(data["ziplines"])
    mapConfiguration.finishedFetchingData = true
}
