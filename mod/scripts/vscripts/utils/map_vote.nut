global function PK_StartMapVote

void function PK_StartMapVote()
{
    thread PK_StartMapVote_Think()
}

void function PK_StartMapVote_Think()
{
    if ( PK_has_api_access == false )
    {
        print("(!) Cannot start map vote with no API access, exiting.")
        return
    }

    print("map vote has started")

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
    string map = ""
    int votes = 0
    foreach ( key, val in results )
    {
        if ( val > votes )
        {
            map = key
            votes = val
        }
    }

    print("Next map is " + map)
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
