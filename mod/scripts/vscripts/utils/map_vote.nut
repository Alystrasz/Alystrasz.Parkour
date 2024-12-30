global function PK_MapVote

struct {
    string nextMap = ""
} file

void function PK_MapVote()
{
    if ( PK_has_api_access == false )
    {
        print("(!) Cannot start map vote with no API access, exiting.")
        return
    }

    AddCallback_GameStateEnter(eGameState.Postmatch, PostMatch_ChangeMap)
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
    file.nextMap = GetMapName() // defaults to current map if nobody answers
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
