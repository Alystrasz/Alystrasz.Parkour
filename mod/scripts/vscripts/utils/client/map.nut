global function GetMapFinishLineAngles
global function GetMapFinishLineDimensions
global function GetMapFinishLineOrigin

global function GetMapStartLineAngles
global function GetMapStartLineDimensions
global function GetMapStartLineOrigin

global function GetMapLeaderboardAngles
global function GetMapLeaderboardDimensions
global function GetMapLeaderboardOrigin


/*
███████╗████████╗ █████╗ ██████╗ ████████╗    ██╗     ██╗███╗   ██╗███████╗
██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝    ██║     ██║████╗  ██║██╔════╝
███████╗   ██║   ███████║██████╔╝   ██║       ██║     ██║██╔██╗ ██║█████╗  
╚════██║   ██║   ██╔══██║██╔══██╗   ██║       ██║     ██║██║╚██╗██║██╔══╝  
███████║   ██║   ██║  ██║██║  ██║   ██║       ███████╗██║██║ ╚████║███████╗
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
*/

vector function GetMapStartLineOrigin()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return < -160.82, -3041.79, -35>
        default:
            throw format( "Start line coordinates were not found for map \"%s\".", mapName )
    }

    unreachable
}

vector function GetMapStartLineAngles()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return <0, 0, 0>
        default:
            throw format( "Start line angles were not found for map \"%s\".", mapName )
    }

    unreachable
}

array<float> function GetMapStartLineDimensions()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return [120.0, 80.0]
        default:
            throw format( "Start line dimensions were not found for map \"%s\".", mapName )
    }

    unreachable
}


/*
███████╗██╗███╗   ██╗██╗███████╗██╗  ██╗    ██╗     ██╗███╗   ██╗███████╗
██╔════╝██║████╗  ██║██║██╔════╝██║  ██║    ██║     ██║████╗  ██║██╔════╝
█████╗  ██║██╔██╗ ██║██║███████╗███████║    ██║     ██║██╔██╗ ██║█████╗  
██╔══╝  ██║██║╚██╗██║██║╚════██║██╔══██║    ██║     ██║██║╚██╗██║██╔══╝  
██║     ██║██║ ╚████║██║███████║██║  ██║    ███████╗██║██║ ╚████║███████╗
╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
*/

vector function GetMapFinishLineOrigin()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return < -399.065, -2906.22, -43.9688>
        default:
            throw format( "Finish line coordinates were not found for map \"%s\".", mapName )
    }

    unreachable
}

vector function GetMapFinishLineAngles()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return <0, -90, 0>
        default:
            throw format( "Finish line angles were not found for map \"%s\".", mapName )
    }

    unreachable
}

array<float> function GetMapFinishLineDimensions()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return [120.0, 80.0]
        default:
            throw format( "Finish line dimensions were not found for map \"%s\".", mapName )
    }

    unreachable
}


/*
██╗     ███████╗ █████╗ ██████╗ ███████╗██████╗ ██████╗  ██████╗  █████╗ ██████╗ ██████╗ 
██║     ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗
██║     █████╗  ███████║██║  ██║█████╗  ██████╔╝██████╔╝██║   ██║███████║██████╔╝██║  ██║
██║     ██╔══╝  ██╔══██║██║  ██║██╔══╝  ██╔══██╗██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║
███████╗███████╗██║  ██║██████╔╝███████╗██║  ██║██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
*/

vector function GetMapLeaderboardOrigin()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return < -536, -2929.38, -36>
        default:
            throw format( "Leaderboard coordinates were not found for map \"%s\".", mapName )
    }

    unreachable
}

vector function GetMapLeaderboardAngles()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return <0, 90, 0>
        default:
            throw format( "Leaderboard angles were not found for map \"%s\".", mapName )
    }

    unreachable
}

array<float> function GetMapLeaderboardDimensions()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return [80.0, 75.0]
        default:
            throw format( "Leaderboard dimensions were not found for map \"%s\".", mapName )
    }

    unreachable
}
