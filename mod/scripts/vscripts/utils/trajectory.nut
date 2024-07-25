global function PK_InitTrajectoryHighlight

const float REFRESH_FREQUENCY = 5
const float MOVE_TIME_BETWEN_POINTS = 0.5

void function PK_InitTrajectoryHighlight()
{
    thread PK_InitTrajectoryHighlightThreaded()
}

void function PK_InitTrajectoryHighlightThreaded()
{
    while (true)
    {
        thread StartHighlightPing()
        wait REFRESH_FREQUENCY
    }
}

void function StartHighlightPing()
{
    print("hello there!")
}