global function InitializeMapConfigurationFromAPI

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

void function InitializeMapConfigurationFromAPI()
{
    thread FetchMapConfigurationFromAPI()

    while(mapConfiguration.finishedFetchingData == false) {
		WaitFrame()
	}

    // Set up world
	SpawnCheckpoints( file.startMins, file.startMaxs, file.endMins, file.endMaxs )
    SpawnZiplines( file.ziplines )
	WorldLeaderboard_Init()

    // Init players
    foreach(player in GetPlayerArray())
    {
        OnPlayerConnected(player)
    }
}

void function FetchMapConfigurationFromAPI()
{
    string source = "{\"startLine\":{\"origin\":[-160.82,-3041.79,-35.0],\"angles\":[0,0,0],\"dimensions\":[120,80],\"trigger\":[[-157.2,-3169.45,-200.0],[-68.0326,-2931.55,-53.4112]]},\"finishLine\":{\"origin\":[-399.065,-2906.22,-43.9688],\"angles\":[0,-90,0],\"dimensions\":[120,80],\"trigger\":[[-468.13,-3125.91,-139.767],[-334.145,-2914.39,-7.99543]]},\"leaderboards\":{\"local\":{\"origin\":[-536.0,-2929.38,-36.0],\"angles\":[0,90,0],\"dimensions\":[80,75],\"source\":{\"origin\":[-536.0,-2929.38,17.0],\"angles\":[0,90,0],\"dimensions\":[50,33]}},\"world\":{\"origin\":[-616.0,-2992.5,-36.0],\"angles\":[0,180,0],\"dimensions\":[80,75],\"source\":{\"origin\":[-616.0,-2992.5,17.0],\"angles\":[0,180,0],\"dimensions\":[50,33]}}},\"checkpoints\":[[471.636,-3438.36,112.031],[1078.87,-4349.23,30.0313],[1286.21,-5821.39,-174.185],[1478.94,-4339.42,30.0313],[2337.49,-2532.42,63.8572],[1767.95,-554.624,-16.3175],[-488.85,-956.027,-191.969],[-1806.92,-1307.96,-319.969],[-1206.72,-766.02,328.031],[-1844.4,-1307.25,949.407]],\"start\":{\"origin\":[-492.656,-3036.0,-107.969],\"angles\":[0,90,0]},\"end\":{\"origin\":[-399.065,-2906.22,-83.9688]},\"ziplines\":[[[-246.983,-2767.25,-55.6686],[-1007.05,-2070.53,207.528]],[[1278.67,-4188.2,117.5001],[1280.04,-3168.49,79.5001]],[[1604.62,-2300.76,465.017],[1601.41,-1298.66,521.017]]]}"
    table data = DecodeJSON(source)

    // simulate network delay
    wait 1

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
