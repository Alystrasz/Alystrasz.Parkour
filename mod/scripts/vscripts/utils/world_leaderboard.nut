/**
 * This package contains all code related to the "world" leaderboard, which scores are stored
 * on a distant API.
 * (source code for the API is available here: https://github.com/Alystrasz/parkour-api)
 **/

global function WorldLeaderboard_FetchScores
global function SendWorldLeaderboardEntryToAPI


/**
 * This fetches scores for the map linked to the current match, using the previously
 * stored map id.
 * Scores fetching happens every few seconds.
 *
 * On scores reception, those are sent to connected game clients, to update the in-game
 * "world" leaderboard.
 **/
void function WorldLeaderboard_FetchScores()
{
    print("Fetching scores for map n°" + credentials.mapId)
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/maps/%s/scores", credentials.endpoint, credentials.mapId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [credentials.secret]
    request.headers = headers

    while (true)
    {
        void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
        {
            print("Received scores from parkour API...")

            string inputStr = "{\"data\":" + response.body + "}"
            table data = DecodeJSON(inputStr)
            array scores = expect array(data["data"])

            // TODO Each time we receive a scores list, we sent it entirely to clients, which should be improved.
            array<LeaderboardEntry> localWorldLeaderboard = []
            foreach (value in scores) {
                table raw_score = expect table(value)
                LeaderboardEntry entry
                entry.playerName = expect string(raw_score["name"])
                entry.time = expect float(raw_score["time"])
                localWorldLeaderboard.append(entry)
            }

            worldLeaderboard = localWorldLeaderboard;
            print("Scores received.")
            has_api_access = true
            UpdatePlayersLeaderboard(0, true)
        }

        void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
        {
            print("Something went wrong while fetching scores from parkour API.")
            print("=> " + failure.errorCode)
            print("=> " + failure.errorMessage)
            has_api_access = false
        }

        NSHttpRequest( request, onSuccess, onFailure )
        wait 10
    }
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
