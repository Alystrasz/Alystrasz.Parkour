global function SpawnEntities


/**
 * Called on server initialization, this will spawn all entities related to this very
 * gamemode.
 **/
void function SpawnEntities()
{
    SpawnCheckpoints()
    SpawnZiplines()
}


/**
 * This uses the global checkpoints list to create the actual checkpoint entities.
 * Checkpoints entities will be created starting from the second entity, the first
 * one being a start trigger (does not need the checkpoint visual); last entry will
 * also not be spawned as a checkpoint, but as a finish trigger.
 **/
void function SpawnCheckpoints()
{
	int checkpointsCount = checkpoints.len()-1

	foreach (int index, vector checkpoint in checkpoints)
	{
		if (index == 0)
		{
			// TODO this actually does not use coordinates from `checkpoints` global entry
			thread SpawnStartTrigger()
		}
		else if (index == checkpoints.len()-1)
		{
			checkpointEntities.append( SpawnEndTrigger( checkpoint ) )
		}
		else
		{
			entity checkpoint = CreateCheckpoint(checkpoint, void function (entity player): (index, checkpointsCount) {
				PlayerStats pStats = localStats[player.GetPlayerName()]

				// Only update player info if their currentCheckpoint index is the previous one!
				if (pStats.isRunning && pStats.currentCheckpoint == index-1)
				{
					pStats.checkpointAngles.append( player.GetAngles() )	// Saves player orientation when checkpoint was reached
					pStats.currentCheckpoint = index						// Updates player's last reached checkpoint
					player.SetPlayerNetInt( "currentCheckpoint", index )	// Update player's client
					Remote_CallFunction_NonReplay( 							// Send player's client next checkpoint location, for it to be RUI displayed
						player,
						"ServerCallback_UpdateNextCheckpointMarker",
						checkpointEntities[index].GetEncodedEHandle()
					)

					// Update checkpoint UI
					string id = localStats[player.GetPlayerName()].playerIdentifier
    				NSEditStatusMessageOnPlayer(player, "[" + pStats.currentCheckpoint + "/" + checkpointsCount + "]", "checkpoints reached", id)
					EmitSoundOnEntity( player, "UI_Spawn_FriendlyPilot" )
				}
			})
			checkpointEntities.append( checkpoint )
		}
	}
}


/**
 * This method spawns a checkpoint on the map, which by default has a green bubble model.
 * The second argument is a callback that is summoned each time a player enters the
 * current checkpoint.
 **/
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


/**
 * This method spawns the starting trigger.
 * This trigger checks if colliding players are currently doing a parkour run, and starts
 * one if it's not the case.
 **/
void function SpawnStartTrigger()
{
	int checkpointsCount = checkpoints.len()-1

	while (true)
	{
		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), < -157.2, -3169.45, -200>, < -68.0326, -2931.55, -53.4112> ))
			{
				if (localStats[playerName].isRunning) {
					// Chat_ServerBroadcast(playerName + " is in start trigger but is already running!")
				}
				else
				{
					Chat_ServerBroadcast(playerName + " starts a new run!")
					localStats[playerName].startTime = Time()
					localStats[playerName].isRunning = true
					Remote_CallFunction_NonReplay( player, "ServerCallback_StartRun" )
					Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateNextCheckpointMarker", checkpointEntities[0].GetEncodedEHandle() )

					// Update checkpoint UI
					string id = UniqueString(playerName)
					localStats[playerName].playerIdentifier = id
    				NSCreateStatusMessageOnPlayer(player, "[0/" + checkpointsCount + "]", "checkpoints reached", id)
				}
			}
		}
		WaitFrame()
	}
}

/**
 * This method spawns the end trigger, which ends parkour runs.
 * The `origin` argument vector is used to create an invisible entity, which is actually
 * used client-side to mark the last place players must go to.
 **/
entity function SpawnEndTrigger( vector origin )
{
	entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
    point.Hide()
    DispatchSpawn( point )
    thread FinishTriggerThink()
    return point
}

/**
 * End trigger logic.
 * Checks if colliding players can finish a parkour run (= if they currently are running
 * and last verified checkpoint was the last one), and save their run time if need be.
 * It also resets player stats, for them to be able to start a new parkour run.
 **/
void function FinishTriggerThink()
{
    while (true)
	{
		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()

			// TODO import coordinates from `checkpoints` global array
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

					// Update checkpoint UI
					NSDeleteStatusMessageOnPlayer( player, playerStats.playerIdentifier )

					// Score update
					StoreNewLeaderboardEntry( player, duration )
				}
			}
		}
		WaitFrame()
	}
}


/**
 * I think this one is pretty much self-explanatory.
 **/
void function SpawnZiplines()
{
    CreateZipline(< -246.983, -2767.25, -55.6686>, < -1007.05, -2070.53, 207.528>)
    CreateZipline(<1278.67, -4188.2, 117.5001>, <1280.04, -3168.49, 79.5001>)
    CreateZipline(<1604.62, -2300.76, 465.017>, <1601.41, -1298.66, 521.017>)
}