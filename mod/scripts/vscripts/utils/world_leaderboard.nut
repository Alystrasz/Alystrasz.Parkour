/**
 * This package contains all code related to the "world" leaderboard, which scores are stored
 * on a distant API.
 * (source code for the API is available here: https://github.com/Alystrasz/parkour-api)
 **/

global function WorldLeaderboard_Init
global function SendWorldLeaderboardEntryToAPI

struct {
    var event_id
    string endpoint
    string secret
} file;

/**
 * Entrypoint of the package, this method will load the API authentication token
 * from the dedicated configuration variable; it will be used in all future HTTP
 * requests to Parkour API.
 *
 * Once the token has been saved, this starts fetching events.
 **/
void function WorldLeaderboard_Init() {
    file.secret = GetConVarString("parkour_api_secret")
    file.endpoint = GetConVarString("parkour_api_endpoint")
    thread WorldLeaderboard_FetchEvents()
}


/**
 * This method fetches the `events` resource of the Parkour API to find information
 * about the current match: where to save new scores, which settings (weapons/ability
 * set) to apply to all players...
 *
 * Once corresponding event has been found, this will register said event identifier
 * locally, for it to be used in future HTTP requests, apply required changes to
 * current match, and start fetching scores from distant API every few seconds.
 *
 * If no corresponding event is found, no further HTTP request will occur during the
 * current match.
 **/
void function WorldLeaderboard_FetchEvents() {
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events", file.endpoint)
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
        array events = expect array(data["data"])

        // Currently, corresponding event is found by checking if its name contains the
        // name of the current map, which might be improved.
        string mapName = GetMapName()
        foreach (value in events) {
            table event = expect table(value)
            string event_name = expect string(event["name"])
            if ( event_name.find( mapName) != null ) {
                file.event_id = expect string(event["id"])
                thread WorldLeaderboard_FetchScores( expect string(event["id"]) )
                has_api_access = true

                table perks = expect table(event["perks"]);
                ApplyPerks( perks )

                return;
            }
        }

        print("No event matches the current map.")
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
 * This fetches scores for the event linked to the current match, using the previously
 * stored event id.
 * Scores fetching happens every few seconds.
 *
 * On scores reception, those are sent to connected game clients, to update the in-game
 * "world" leaderboard.
 **/
void function WorldLeaderboard_FetchScores(string event_id)
{
    print("Fetching scores for event n°" + event_id)
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events/%s/scores", file.endpoint, event_id)
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
    request.url = format("%s/v1/events/%s/scores", file.endpoint, file.event_id )
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
