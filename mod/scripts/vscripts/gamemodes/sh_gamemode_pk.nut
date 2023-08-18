global function PKMode_Init

global const GAMEMODE_PK = "pk"

void function PKMode_Init() {
    AddCallback_OnCustomGamemodesInit( CreateGamemode )
	AddCallback_OnRegisteringCustomNetworkVars( PKRegisterNetworkVars )
}

void function CreateGamemode() {
    GameMode_Create( GAMEMODE_PK )
    GameMode_SetName( GAMEMODE_PK, "#GAMEMODE_PK" )
    GameMode_SetDesc( GAMEMODE_PK, "#PK_DESC" )

    // Game statistics
    GameMode_AddScoreboardColumnData( GAMEMODE_PK, "#SCOREBOARD_STARTED_RUNS", PGS_PILOT_KILLS, 2)
    GameMode_AddScoreboardColumnData( GAMEMODE_PK, "#SCOREBOARD_FINISHED_RUNS", PGS_ASSAULT_SCORE, 2)
    GameMode_AddScoreboardColumnData( GAMEMODE_PK, "#SCOREBOARD_RESETS", PGS_DEFENSE_SCORE, 2)
    GameMode_AddScoreboardColumnData( GAMEMODE_PK, "#SCOREBOARD_TOP_THREE", PGS_TITAN_KILLS, 2 )

	GameMode_SetEvacEnabled( GAMEMODE_PK, false )
    GameMode_SetGameModeAnnouncement( GAMEMODE_PK, "gnrc_modeDesc" )

    AddPrivateMatchMode( GAMEMODE_PK )

    #if SERVER
    GameMode_AddServerInit( GAMEMODE_PK, _PK_Init )
    GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_PK, RateSpawnpoints_Generic )
    #elseif CLIENT
    GameMode_AddClientInit( GAMEMODE_PK, Cl_Parkour_Init )
    #endif
}

void function PKRegisterNetworkVars()
{
	if ( GAMETYPE != GAMEMODE_PK )
		return

    Remote_RegisterFunction( "ServerCallback_UpdateNextCheckpointMarker" )
    Remote_RegisterFunction( "ServerCallback_StopRun" )
    Remote_RegisterFunction( "ServerCallback_ResetRun" )
    Remote_RegisterFunction( "ServerCallback_CreateStartIndicator" )
    Remote_RegisterFunction( "ServerCallback_ToggleStartIndicatorDisplay" )
}
