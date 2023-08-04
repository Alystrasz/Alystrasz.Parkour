/**
 * This package contains all code related to the "world" leaderboard, which scores are stored
 * on a distant API.
 * (source code for the API is available here: https://github.com/Alystrasz/parkour-api)
 **/

global function WorldLeaderboard_Init
global function SendWorldLeaderboardEntryToAPI

struct {
    var mapId
    string endpoint
    string secret
} file;

/**
 * Entrypoint of the package, this method will load the API endpoint and 
 * authentication token from dedicated configuration variables; they will
 * be used in all future HTTP requests to Parkour API.
 *
 * Once information have been saved, this starts fetching maps.
 **/
void function WorldLeaderboard_Init() {
    file.secret = GetConVarString("parkour_api_secret")
    file.endpoint = GetConVarString("parkour_api_endpoint")
    thread WorldLeaderboard_FetchMaps()
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
void function WorldLeaderboard_FetchMaps() {
    string eventId = GetConVarString("parkour_api_event_id")

    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events/%s/maps", file.endpoint, eventId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [file.secret]
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
                file.mapId = expect string(map["id"])
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
    print("Fetching scores for map n°" + file.mapId)
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/maps/%s/scores", file.endpoint, file.mapId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [file.secret]
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
    request.url = format("%s/v1/maps/%s/scores", file.endpoint, file.mapId )
    table<string, array<string> > headers
    headers[ "authentication" ] <- [file.secret]
    request.headers = headers

    // Encode leaderboard entry
    table data = {}
    data[ "name" ] <- entry.playerName
    data[ "time" ] <- entry.time
    string json = EncodeJSON( data )
    request.body = json

    NSHttpRequest( request, onSubmissionSuccess, onSubmissionFailure )
}
