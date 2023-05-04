global function CreateCheckpoint
global function SpawnEndTrigger
global function SpawnCheckpoints

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

void function SpawnStartTrigger()
{
	while (true)
	{
		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), < -157.2, -3169.45, -200>, < -68.0326, -2931.55, -53.4112> ))
			{
				if (localStats[playerName].isRunning) {
					Chat_ServerBroadcast(playerName + " is in start trigger but is already running!")
				}
				else
				{
					Chat_ServerBroadcast(playerName + " starts a new run!")
					localStats[playerName].startTime = Time()
					localStats[playerName].isRunning = true
					Remote_CallFunction_NonReplay( player, "ServerCallback_StartRun" )
					Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateNextCheckpointMarker", checkpointEntities[0].GetEncodedEHandle() )
				}
			}
		}
		WaitFrame()
	}
}

entity function SpawnEndTrigger( vector origin )
{
	entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
    point.Hide()
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

void function SpawnCheckpoints()
{
	foreach (int index, vector checkpoint in checkpoints)
	{
		if (index == 0) 
		{
			thread SpawnStartTrigger()
		}
		else if (index == checkpoints.len()-1)
		{
			checkpointEntities.append( SpawnEndTrigger( checkpoint ) )
		}
		else
		{
			entity checkpoint = CreateCheckpoint(checkpoint, void function (entity player): (index) {
				PlayerStats pStats = localStats[player.GetPlayerName()]

				// Only update player info if their currentCheckpoint index is the previous one!
				if (pStats.isRunning && pStats.currentCheckpoint == index-1)
				{
					pStats.checkpointAngles.append( player.GetAngles() )
					pStats.currentCheckpoint = index
					player.SetPlayerNetInt( "currentCheckpoint", index )
					Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateNextCheckpointMarker", checkpointEntities[index].GetEncodedEHandle() )
				}
			})
			checkpointEntities.append( checkpoint )
		}
	}
}
