global function Parkour_OpenRobotDialog

void function Parkour_OpenRobotDialog()
{
    DialogData dialogData
    dialogData.image = $"rui/faction/faction_logo_mrvn"
    dialogData.header = "Parkour information"

    dialogData.message = "Hello pilot, and welcome to the Parkour mode!\n\n\n"
    + "The goal is simple: go through the start line, and get to the finish line as fast as you can while crossing all checkpoints in order!\n\n"
    + "If you are fast enough, you might see your name appear on the local or (even better) world scoreboard!!\n\n\n"
    + "Wanna know more?"

    AddDialogButton( dialogData, "Tell me more!", ParkourShowMoreDetails )
    AddDialogButton( dialogData, "Nope, thank you!" )

    OpenDialog( dialogData )
}

void function ParkourShowMoreDetails()
{
    DialogData dialogData
    dialogData.image = $"rui/faction/faction_logo_mrvn"
    dialogData.header = "More about Parkour"

    dialogData.message = "Don't try to switch weapons, all pilots have a predefined set of weapons and abilities, so that everyone is on an equal footing.\n\n"
    + "If your run is not going well, you can press %offhand4% to reappear here, and restart a new one!\n\n"
    + "And if your time does not appear on the leaderboards, don't worry!\n"
    + "I register scores of all pilots on this map; even scores not appearing here are saved, so pilots can compare to other pilots."

    AddDialogButton(dialogData, "Show me the world scoreboard!", void function() {
        string endpoint = GetConVarString("parkour_api_endpoint")
        LaunchExternalWebBrowser(endpoint, WEBBROWSER_FLAG_FORCEEXTERNAL)
    })
    AddDialogButton( dialogData, "Thanks!" )

    OpenDialog( dialogData )
}
