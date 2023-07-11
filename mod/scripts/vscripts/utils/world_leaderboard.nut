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
        foreach (value in events) {
            table event = expect table(value)
            print(event["name"])
            print(event["id"])
        }
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching events from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
    }

    NSHttpRequest( request, onSuccess, onFailure )
}
