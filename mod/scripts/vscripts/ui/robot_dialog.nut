global function Parkour_OpenRobotDialog
struct {
    string mapName = ""
} file;

void function Parkour_OpenRobotDialog( string mapName )
{
    file.mapName = mapName
    EmitUISound( "diag_spectre_gs_LeechStart_01_1" )

    DialogData dialogData
    dialogData.image = $"rui/faction/faction_logo_mrvn"
    dialogData.header = Localize( "#ROBOT_DIALOG1_TITLE" )

    dialogData.message = Localize( "#ROBOT_DIALOG1_TEXT1" ) + "\n\n\n"
    + Localize( "#ROBOT_DIALOG1_TEXT2" ) + "\n\n"
    + Localize( "#ROBOT_DIALOG1_TEXT3" ) + "\n\n\n"
    + Localize( "#ROBOT_DIALOG1_TEXT4" )

    AddDialogButton( dialogData, "#ROBOT_DIALOG1_BTN1", ParkourShowMoreDetails )
    AddDialogButton( dialogData, "#ROBOT_DIALOG1_BTN2", ParkourExitDialog )
    dialogData.forceChoice = true

    OpenDialog( dialogData )
}

void function ParkourShowMoreDetails()
{
    EmitUISound( "diag_spectre_gs_LeechAborted_01_1" )

    DialogData dialogData
    dialogData.image = $"rui/faction/faction_logo_mrvn"
    dialogData.header = Localize( "#ROBOT_DIALOG2_TITLE" )

    dialogData.message = Localize( "#ROBOT_DIALOG2_TEXT1" ) + "\n\n"
    + Localize( "#ROBOT_DIALOG2_TEXT2" ) + "\n\n"
    + Localize( "#ROBOT_DIALOG2_TEXT3" ) + "\n"
    + Localize( "#ROBOT_DIALOG2_TEXT4" )

    AddDialogButton(dialogData, "#ROBOT_DIALOG2_BTN1", void function() {
        thread ParkourOpenWebScoreboard()
    })
    AddDialogButton( dialogData, "#ROBOT_DIALOG2_BTN2", ParkourExitDialog )
    dialogData.forceChoice = true

    OpenDialog( dialogData )
}

void function ParkourExitDialog()
{
    EmitUISound( "diag_spectre_gs_LeechEnd_01_1" )
}

/**
 * Since clicking the button directly closes current dialog and transmits click action
 * to the game, thus firing at the robot, we wait a bit before opening web scoreboard.
 **/
void function ParkourOpenWebScoreboard()
{
    ParkourExitDialog()

    wait 0.8
    string endpoint = GetConVarString("parkour_api_endpoint") + "?map=" + file.mapName
    LaunchExternalWebBrowser(endpoint, WEBBROWSER_FLAG_FORCEEXTERNAL)
}