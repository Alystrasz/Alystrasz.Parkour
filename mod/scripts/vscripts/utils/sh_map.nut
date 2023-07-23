global struct TriggerVolume {
    vector mins
    vector maxs
}

global function GetMapStartVolume
global function GetMapFinishVolume


/**
 * Returns the starting line volume.
 * It is used to start players' runs.
 **/
TriggerVolume function GetMapStartVolume()
{
    string mapName = GetMapName()
    TriggerVolume coordinates = { ... }

    switch( mapName )
    {
        case "mp_thaw":
            coordinates.mins = < -157.2, -3169.45, -200>
            coordinates.maxs = < -68.0326, -2931.55, -53.4112>
            return coordinates
        default:
            throw format( "Start location was not found for map \"%s\".", mapName )
    }

    unreachable
}

/**
 * Returns the finish line volume.
 * It is used to end players' runs.
 **/
TriggerVolume function GetMapFinishVolume()
{
    string mapName = GetMapName()
    TriggerVolume coordinates = { ... }

    switch( mapName )
    {
        case "mp_thaw":
            coordinates.mins = < -468.13, -3125.91, -139.767>
            coordinates.maxs = < -334.145, -2914.39, -7.99543>
            return coordinates
        default:
            throw format( "End location was not found for map \"%s\".", mapName )
    }

    unreachable
}
