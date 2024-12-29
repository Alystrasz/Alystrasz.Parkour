global function Parkour_OpenRobotDialog
struct {
    string scoreboardUrl = ""
} file;

void function Parkour_OpenRobotDialog( string endpoint )
{
    file.scoreboardUrl = endpoint
    EmitUISound( "diag_mcor_marvin_vocal_excited_short" )

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
    EmitUISound( "diag_mcor_marvin_vocal_excited_short" )

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
    EmitUISound( "diag_mcor_marvin_vocal_command_short" )
}

/**
 * Since clicking the button directly closes current dialog and transmits click action
 * to the game, thus firing at the robot, we wait a bit before opening web scoreboard.
 **/
void function ParkourOpenWebScoreboard()
{
    ParkourExitDialog()

    wait 0.8
    LaunchExternalWebBrowser(file.scoreboardUrl, WEBBROWSER_FLAG_FORCEEXTERNAL)
}