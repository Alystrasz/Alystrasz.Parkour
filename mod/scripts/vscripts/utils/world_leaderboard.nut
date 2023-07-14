global function WorldLeaderboard_Init
global function SendWorldLeaderboardEntryToAPI

struct {
    var event_id
    string secret
} file;

void function WorldLeaderboard_Init() {
    file.secret = GetConVarString("parkour_api_secret")
    thread WorldLeaderboard_FetchEvents()
}


void function WorldLeaderboard_FetchEvents() {
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = "https://parkour.remyraes.com/v1/events"
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

        string mapName = GetMapName()
        foreach (value in events) {
            table event = expect table(value)
            string event_name = expect string(event["name"])
            if ( event_name.find( mapName) != null ) {
                file.event_id = expect string(event["id"])
                thread WorldLeaderboard_FetchScores( expect string(event["id"]) )
                has_api_access = true

                // Simulate assigning weapons
                perks.weapon = "mp_weapon_epg"
                perks.ability = "mp_ability_grapple"
                perks.grenade = "mp_weapon_grenade_gravity"

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

void function WorldLeaderboard_FetchScores(string event_id)
{
    print("Starting fetching scores for event n°" + event_id)
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("https://parkour.remyraes.com/v1/events/%s/scores", event_id)
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
    request.url = format("https://parkour.remyraes.com/v1/events/%s/scores", file.event_id )
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
