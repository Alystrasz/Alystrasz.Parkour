global function WorldLeaderboard_Init

void function WorldLeaderboard_Init() {
    thread WorldLeaderboard_FetchEvents()
}


void function WorldLeaderboard_FetchEvents() {
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = "https://parkour.remyraes.com/v1/events"
    table<string, array<string> > headers
    headers[ "authentication" ] <- ["my_little_secret"]
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
                thread WorldLeaderboard_FetchScores( expect string(event["id"]) )
                return;
            }
        }

        print("No event matches the current map.")
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching events from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
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
    headers[ "authentication" ] <- ["my_little_secret"]
    request.headers = headers

    while (true)
    {
        void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
        {
            print("Received scores from parkour API...")

            string inputStr = "{\"data\":" + response.body + "}"
            table data = DecodeJSON(inputStr)
            array scores = expect array(data["data"])

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
        }

        void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
        {
            print("Something went wrong while fetching scores from parkour API.")
            print("=> " + failure.errorCode)
            print("=> " + failure.errorMessage)
        }

        NSHttpRequest( request, onSuccess, onFailure )
        wait 10
    }
}
