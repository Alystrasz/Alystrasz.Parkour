global function PKMode_Init

global const GAMEMODE_PK = "pk"
global const PK_NAME = "Parkour"
global const PK_DESC = "The gauntlet mission, but on multiplayer maps."

void function PKMode_Init() {
    AddCallback_OnCustomGamemodesInit( CreateGamemode )	
	AddCallback_OnRegisteringCustomNetworkVars( PKRegisterNetworkVars )
}

void function CreateGamemode() {
    GameMode_Create( GAMEMODE_PK )
    GameMode_SetName( GAMEMODE_PK, PK_NAME )
    GameMode_SetDesc( GAMEMODE_PK, PK_DESC )
    
    // Green because batteries are green.. idk
	GameMode_SetColor( GAMEMODE_PK, [56, 181, 34, 255] )

    // Clueless Surely this'll work
	GameMode_SetDefaultTimeLimits( GAMEMODE_PK, 3, 0 )
	GameMode_SetDefaultScoreLimits( GAMEMODE_PK, 5, 0 )
	GameMode_SetEvacEnabled( GAMEMODE_PK, false )
    
    // IDK what this is but it works
    GameMode_SetGameModeAnnouncement( GAMEMODE_PK, "gnrc_modeDesc" )

    AddPrivateMatchMode( GAMEMODE_PK )

    #if SERVER
    GameMode_AddServerInit( GAMEMODE_PK, _PK_Init )
    GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_PK, RateSpawnpoints_Generic )
    #elseif CLIENT
    GameMode_AddClientInit( GAMEMODE_PK, Cl_Parkour_Init )
    GameMode_AddClientInit( GAMEMODE_PK, Cl_Parkour_Update )
    #endif
}

void function PKRegisterNetworkVars()
{
	if ( GAMETYPE != GAMEMODE_PK )
		return

    Remote_RegisterFunction( "ServerCallback_StartRun" )
    Remote_RegisterFunction( "ServerCallback_UpdateLeaderboard" )
    Remote_RegisterFunction( "ServerCallback_UpdateNextCheckpointMarker" )
    Remote_RegisterFunction( "ServerCallback_StopRun" )
    Remote_RegisterFunction( "ServerCallback_ResetRun" )

    RegisterNetworkedVariable( "currentCheckpoint", SNDC_PLAYER_GLOBAL, SNVT_INT, 0 )
}
