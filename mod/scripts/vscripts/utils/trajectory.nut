global function PK_InitTrajectoryHighlight

const float REFRESH_FREQUENCY = 1
const float MOVE_TIME_BETWEN_POINTS = 0.5

void function PK_InitTrajectoryHighlight()
{
    thread PK_InitTrajectoryHighlightThreaded()
}

void function PK_InitTrajectoryHighlightThreaded()
{
    while ( true )
    {
        thread StartHighlightPing()
        wait REFRESH_FREQUENCY
    }
}

void function StartHighlightPing()
{
    int routeindex = 1
    entity mover = CreateScriptMover( checkpoints[0] )
    int checkpointsCount = checkpoints.len()

    while ( true )
    {
        PlayLoopFXOnEntity( $"P_pod_Dlight_console1", mover )
        PlayLoopFXOnEntity( FLAG_FX_FRIENDLY, mover )

        mover.NonPhysicsMoveTo( checkpoints[routeindex] + <0, 0, 30>, MOVE_TIME_BETWEN_POINTS, 0.0, 0.0 )
        wait MOVE_TIME_BETWEN_POINTS
        routeindex++

        if ( routeindex == checkpointsCount )
        {
            mover.Destroy()
		    break
        }
	}
}