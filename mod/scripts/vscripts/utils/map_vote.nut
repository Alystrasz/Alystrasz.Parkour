global function PK_MapVote

void function PK_MapVote()
{
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
    if ( PK_has_api_access == false )
    {
        print("(!) Cannot start map vote with no API access, exiting.")
        return
    }

    // Tell players vote is starting
    foreach ( entity player in GetPlayerArray() )
        Remote_CallFunction_NonReplay( player, "ServerCallback_PK_AnnonceMapVote" )

    float voteDuration = 10
    int now = GetUnixTimestamp()

    CreatePoll( voteDuration )

    // Wait poll duration
    while ( GetUnixTimestamp() - now < voteDuration )
    {
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
    string map = GetMapName() // defaults to current map if nobody answers
    int votes = 0
    foreach ( key, val in results )
    {
        if ( val > votes )
        {
            map = key
            votes = val
        }
    }

    TellPlayersMapChoice( map )
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

void function TellPlayersMapChoice( string map )
{
    foreach ( entity player in GetPlayerArray() )
    {
        ServerToClientStringCommand( player, "ParkourNextMap " + map)
    }
}