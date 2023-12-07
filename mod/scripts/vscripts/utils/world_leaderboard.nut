/**
 * This package contains all code related to the "world" leaderboard, which scores are stored
 * on a distant API.
 * (source code for the API is available here: https://github.com/Alystrasz/parkour-api)
 **/

global function WorldLeaderboard_StartPeriodicFetching
global function SendWorldLeaderboardEntryToAPI


/**
 * This fetches scores for the map linked to the current match, using the previously
 * stored map id.
 * Scores fetching happens every few seconds.
 *
 * On scores reception, those are sent to connected game clients, to update the in-game
 * "world" leaderboard.
 **/
void function WorldLeaderboard_StartPeriodicFetching()
{
    while (GetGameState() <= eGameState.SuddenDeath)
    {
        WorldLeaderboard_FetchScores()
        wait 10
    }
}

void function WorldLeaderboard_FetchScores_OnSuccess( HttpRequestResponse response )
{
    string inputStr = "{\"data\":" + response.body + "}"
    table data = DecodeJSON(inputStr)
    array scores = expect array(data["data"])

    array<LeaderboardEntry> distantWorldLeaderboard = []
    foreach (value in scores) {
        table raw_score = expect table(value)
        LeaderboardEntry entry
        entry.playerName = expect string(raw_score["name"])
        entry.time = expect float(raw_score["time"])
        distantWorldLeaderboard.append(entry)
    }

    print("Scores received.")
    has_api_access = true

    // Each time a distant scores list is retrieved, we check if local list is the same
    // (to avoid sending updates to clients if nothing changed)
    int difference_index = CompareLeaderboards(worldLeaderboard, distantWorldLeaderboard)
    if (difference_index == -1) {
        print("=> Local leaderboard already up-to-date.")
    } else {
        print("=> Transmitting leaderboard updates to players.")
        worldLeaderboard = distantWorldLeaderboard;
        UpdatePlayersLeaderboard(difference_index, true)
    }
}

void function WorldLeaderboard_FetchScores_OnFailure( HttpRequestFailure failure )
{
    print("Something went wrong while fetching scores from parkour API.")
    print("=> " + failure.errorCode)
    print("=> " + failure.errorMessage)
    has_api_access = false
}

void function WorldLeaderboard_FetchScores()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/maps/%s/scores", credentials.endpoint, credentials.mapId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [credentials.secret]
    request.headers = headers

    NSHttpRequest( request, WorldLeaderboard_FetchScores_OnSuccess, WorldLeaderboard_FetchScores_OnFailure )
}

// Score submissions
void function onSubmissionSuccess ( HttpRequestResponse response )
{
    print("Score successfully submitted.")
    has_api_access = true
}

void function onSubmissionFailure ( HttpRequestFailure failure )
{
    print("Something went wrong while submitting scores to parkour API.")
    print("=> " + failure.errorCode)
    print("=> " + failure.errorMessage)
    has_api_access = false
}

void function SendWorldLeaderboardEntryToAPI( LeaderboardEntry entry )
{
    HttpRequest request
    request.method = HttpRequestMethod.POST
    request.url = format("%s/v1/maps/%s/scores", credentials.endpoint, credentials.mapId )
    table<string, array<string> > headers
    headers[ "authentication" ] <- [credentials.secret]
    request.headers = headers

    // Encode leaderboard entry
    table data = {}
    data[ "name" ] <- entry.playerName
    data[ "time" ] <- entry.time
    string json = EncodeJSON( data )
    request.body = json

    NSHttpRequest( request, onSubmissionSuccess, onSubmissionFailure )
}

/**
 * Returns the first entry index that differs between input leaderboards, or -1 if both
 * are identical.
 **/
int function CompareLeaderboards( array<LeaderboardEntry> l1, array<LeaderboardEntry> l2 )
{
    int len1 = l1.len()
    int len2 = l2.len()
    int max_len = -1
    int min_len = -1

    if (len1 > len2) {
        max_len = len1
        min_len = len2
    } else {
        max_len = len2
        min_len = len1
    }

    for (int i=0; i<max_len; i++) {
        if (i == min_len || l1[i].playerName != l2[i].playerName || l1[i].playerName == l2[i].playerName && l1[i].time != l2[i].time) {
            return i
        }
    }

    return -1

}