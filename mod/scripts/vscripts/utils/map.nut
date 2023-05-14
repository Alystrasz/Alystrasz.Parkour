global function GetMapCheckpointLocations


array<vector> function GetMapCheckpointLocations()
{
    string mapName = GetMapName()

    switch( mapName )
    {
        case "mp_thaw":
            return [
                // Start
                < -492.656, -3036, -107.969>,

                // Checkpoints
                <471.636, -3438.36, 112.031>,
                <1078.87, -4349.23, 30.0313>,
                <1286.21, -5821.39, -174.185>,
                <1478.94, -4339.42, 30.0313>,
                <2337.49, -2532.42, 63.8572>,
                <1767.95, -554.624, -16.3175>,
                < -488.85, -956.027, -191.969>,
                < -1806.92, -1307.96, -319.969>,
                < -1206.72, -766.02, 328.031>,
                < -1844.4, -1307.25, 949.407>,

                // End
                < -399.065, -2906.22, -83.9688>
            ]
        default:
            throw format( "Checkpoints were not found for map \"%s\".", mapName )
    }

    unreachable
}