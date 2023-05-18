global function GetMapCheckpointLocations
global function GetMapStartVolume
global function GetMapFinishVolume
global function GetMapZiplinesCoordinates

global struct TriggerVolume {
    vector mins
    vector maxs
}

global struct ZiplineCoordinates {
    vector start
    vector end
}


array<vector> function GetMapCheckpointLocations()
{
    array<vector> checkpoints = _GetMapCheckpointLocations()
    checkpoints.insert( 0, _GetMapStartLocation() )
    checkpoints.append( _GetMapEndLocation() )
    return checkpoints
}

// Return checkpoints player must go through during run.
array<vector> function _GetMapCheckpointLocations()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return [
                <471.636, -3438.36, 112.031>,
                <1078.87, -4349.23, 30.0313>,
                <1286.21, -5821.39, -174.185>,
                <1478.94, -4339.42, 30.0313>,
                <2337.49, -2532.42, 63.8572>,
                <1767.95, -554.624, -16.3175>,
                < -488.85, -956.027, -191.969>,
                < -1806.92, -1307.96, -319.969>,
                < -1206.72, -766.02, 328.031>,
                < -1844.4, -1307.25, 949.407>
            ]
        default:
            throw format( "Checkpoints were not found for map \"%s\".", mapName )
    }

    unreachable
}

/**
 * Returns location of the spawning point.
 * This is used to spawn new players.
 **/
vector function _GetMapStartLocation()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return < -492.656, -3036, -107.969>
        default:
            throw format( "End location was not found for map \"%s\".", mapName )
    }

    unreachable
}

/**
 * Returns location of the finish line.
 * This is used to display the icon on players UI.
 **/
vector function _GetMapEndLocation()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return < -399.065, -2906.22, -83.9688>
        default:
            throw format( "End location was not found for map \"%s\".", mapName )
    }

    unreachable
}

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

/**
 * Returns ziplines coordinates for the current map.
 **/
array<ZiplineCoordinates> function GetMapZiplinesCoordinates()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            ZiplineCoordinates zip1 = {
                start = < -246.983, -2767.25, -55.6686>,
                end = < -1007.05, -2070.53, 207.528>
            }
            ZiplineCoordinates zip2 = {
                start = <1278.67, -4188.2, 117.5001>,
                end = <1280.04, -3168.49, 79.5001>
            }
            ZiplineCoordinates zip3 = {
                start = <1604.62, -2300.76, 465.017>,
                end = <1601.41, -1298.66, 521.017>
            }
            return [ zip1, zip2, zip3 ]
        default:
            throw format( "Ziplines coordinates were not found for map \"%s\".", mapName )
    }

    unreachable
}
