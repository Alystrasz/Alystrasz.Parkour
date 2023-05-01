global function CreateCheckpoint
global function SpawnEndTrigger

entity function CreateCheckpoint(vector origin, void functionref(entity) callback, float size = 0.5, string color = "0 155 0")
{
    // Spawn bubble
    entity point = CreateEntity( "prop_dynamic" )
    point.SetValueForModelKey($"models/fx/xo_emp_field.mdl")
    point.kv.rendercolor = color
    point.kv.modelscale = size
    point.SetOrigin( origin )
    DispatchSpawn( point )

    // Spawn trigger
    entity trigger = CreateTriggerRadiusMultiple( origin, 140, [], TRIG_FLAG_NONE)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player): (callback) {
        callback(player)
    })

    return point
}

entity function SpawnEndTrigger( vector origin )
{
	entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
    DispatchSpawn( point )
    thread FinishTriggerThink()
    return point
}

void function FinishTriggerThink()
{
    while (true)
	{
		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()            

			if (PointIsWithinBounds( player.GetOrigin(), < -468.13, -3125.91, -139.767>, < -334.145, -2914.39, -7.99543> ))
			{
                PlayerStats playerStats = localStats[playerName]
				if (playerStats.isRunning && playerStats.currentCheckpoint == checkpoints.len()-2) {
                    float duration = Time() - playerStats.startTime

                    playerStats.isRunning = false
                    playerStats.currentCheckpoint = 0
                    playerStats.checkpointAngles = [<0, 0, 0>]
                    
                    bool isBestTime = duration < playerStats.bestTime
                    if (isBestTime)
                    {
                        playerStats.bestTime = duration
                    }

                    Remote_CallFunction_NonReplay( player, "ServerCallback_StopRun", duration, isBestTime )
				}
			}
		}
		WaitFrame()
	}
}