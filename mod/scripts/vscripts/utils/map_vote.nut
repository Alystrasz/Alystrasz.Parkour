global function PK_MapVote

struct {
    string nextMap = ""
    string nextDefaultMap = ""
    array playedMaps
} file

void function PK_MapVote()
{
    if ( PK_has_api_access == false )
    {
        print("(!) Cannot start map vote with no API access, exiting.")
        return
    }

    AddCallback_GameStateEnter(eGameState.Postmatch, PostMatch_ChangeMap)
    thread StoreCurrentMap()
    thread MapVoteThink()
}

void function MapVoteThink()
{
    float matchDuration = GetCurrentPlaylistVarFloat( "timelimit", 1 ) * 60
    wait matchDuration - 120 // wait until 2 minutes before match end
    StartMapVote()
}

void function StartMapVote()
{
    // Tell players vote is starting
    foreach ( entity player in GetPlayerArray() )
        Remote_CallFunction_NonReplay( player, "ServerCallback_PK_AnnonceMapVote" )

    float voteDuration = 30
    int now = GetUnixTimestamp()

    // Init next default map (round-robin to avoid circling over same map if nobody answers the poll)
    LoadNextMap()

    wait 2
    CreatePoll( voteDuration )

    // Wait poll duration, or until all players answered
    while ( GetUnixTimestamp() - now < voteDuration )
    {
        if ( GetVoteAnswersCount() >= GetPlayerArray().len() )
        {
            break
        }
        WaitFrame()
    }

    // Prepare table to gather player responses
    table<string, int> results = {}
    foreach ( map in PK_credentials.maps )
    {
        results[map] <- 0
    }

    // Get answers from players
    foreach ( entity player in GetPlayerArray() )
    {
        int result = NSGetPlayerResponse( player )
        if ( result == -1 )
            continue
        results[PK_credentials.maps[result]] += 1
    }

    // Decide map
    file.nextMap = file.nextDefaultMap
    int votes = 0
    foreach ( key, val in results )
    {
        if ( val > votes )
        {
            file.nextMap = key
            votes = val
        }
    }

    TellPlayersMapChoice()
}

void function CreatePoll( float duration )
{
    // Prefix map names so they are localized clientside
    array<string> names = []
    foreach ( map in PK_credentials.maps )
    {
        names.append( "#" + map )
    }

    foreach(entity player in GetPlayerArray())
        NSCreatePollOnPlayer(player, "Vote for the next map", names, duration)
}

void function TellPlayersMapChoice()
{
    foreach ( entity player in GetPlayerArray() )
    {
        ServerToClientStringCommand( player, "ParkourNextMap " + file.nextMap)
    }
}

void function PostMatch_ChangeMap()
{
    thread ChangeMap()
}

void function ChangeMap() {
    wait GAME_POSTMATCH_LENGTH - 1
    GameRules_ChangeMap(file.nextMap, GameRules_GetGameMode())
}

int function GetVoteAnswersCount()
{
    int count = 0

    foreach ( entity player in GetPlayerArray() )
    {
        int result = NSGetPlayerResponse( player )
        if ( result == -1 )
            continue
        count += 1
    }

    return count
}


//  ███╗   ███╗ █████╗ ██████╗     ██████╗  ██████╗ ██╗   ██╗███╗   ██╗██████╗     ██████╗  ██████╗ ██████╗ ██╗███╗   ██╗
//  ████╗ ████║██╔══██╗██╔══██╗    ██╔══██╗██╔═══██╗██║   ██║████╗  ██║██╔══██╗    ██╔══██╗██╔═══██╗██╔══██╗██║████╗  ██║
//  ██╔████╔██║███████║██████╔╝    ██████╔╝██║   ██║██║   ██║██╔██╗ ██║██║  ██║    ██████╔╝██║   ██║██████╔╝██║██╔██╗ ██║
//  ██║╚██╔╝██║██╔══██║██╔═══╝     ██╔══██╗██║   ██║██║   ██║██║╚██╗██║██║  ██║    ██╔══██╗██║   ██║██╔══██╗██║██║╚██╗██║
//  ██║ ╚═╝ ██║██║  ██║██║         ██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝    ██║  ██║╚██████╔╝██████╔╝██║██║ ╚████║
//  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝         ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝

const string fileName = "maps_round_robin.json"

/**
 * The aim for this section is to circle over all event maps in a round-robin fashion,
 * to avoid replaying the same map over and over if no player answers map poll.
 **/

void function StoreCurrentMap()
{
    string currentMap = GetMapName()

    if ( !NSDoesFileExist( fileName) )
    {
        NSSaveFile(fileName, "[\"" + currentMap + "\"]")
        file.playedMaps = [ currentMap ]
        return
    }

    void functionref( string ) onFileLoad = void function ( string result ): ( currentMap )
    {
        string inputStr = "{\"data\":" + result + "}"
        table data = DecodeJSON(inputStr)
        array fileMaps = expect array(data["data"])
        file.playedMaps = fileMaps

        // add current map if not found in file
        foreach ( map in fileMaps )
            if ( map == currentMap )
                return

        fileMaps.append( currentMap )
        file.playedMaps = fileMaps
        NSSaveFile(fileName, ArrayToString(fileMaps))
    }
    NSLoadFile(fileName, onFileLoad)
}

string function ArrayToString( array a )
{
    string s = "["
    int l = a.len()
    for ( int i=0; i<l; i++ )
    {
        s += "\"" + expect string(a[i]) + "\""
        if ( i < l-1 )
        {
            s += ","
        }
    }
    s += "]"
    return s
}

void function LoadNextMap()
{
    // If all maps have been played, loop back to the first map
    if ( file.playedMaps.len() == PK_credentials.maps.len() )
    {
        file.nextDefaultMap = PK_credentials.maps[0]
        print("=> If no player answers map poll, next map will be " + file.nextDefaultMap + ".")
        NSDeleteFile( fileName )
        return
    }

    // Else, pick first map that haven't been played yet
    foreach ( map in PK_credentials.maps )
    {
        bool found = false;
        foreach ( playedMap in file.playedMaps )
        {
            if ( playedMap == map )
            {
                found = true
                break
            }
        }
        if ( found == false )
        {
            file.nextDefaultMap = map
            print("=> If no player answers map poll, next map will be " + file.nextDefaultMap + ".")
            return
        }
    }
}