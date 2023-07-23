global function SpawnCheckpoints


/**
 * This uses the global checkpoints list to create the actual checkpoint entities.
 * Checkpoints entities will be created starting from the second entity, the first
 * one being a start trigger (does not need the checkpoint visual); last entry will
 * also not be spawned as a checkpoint, but as a finish trigger.
 **/
void function SpawnCheckpoints( vector startMins, vector startMaxs, vector endMins, vector endMaxs )
{
	int checkpointsCount = checkpoints.len()-1

	foreach (int index, vector checkpoint in checkpoints)
	{
		if (index == 0)
		{
			thread SpawnStartTrigger( startMins, startMaxs )
		}
		else if (index == checkpoints.len()-1)
		{
			checkpointEntities.append( SpawnEndTrigger( checkpoint, endMins, endMaxs ) )
		}
		else
		{
			entity checkpoint = CreateCheckpoint(checkpoint, void function (entity player): (index, checkpointsCount) {
				PlayerStats pStats = localStats[player.GetPlayerName()]

				// Only update player info if their currentCheckpoint index is the previous one!
				if (pStats.isRunning && !pStats.isResetting && pStats.currentCheckpoint == index-1)
				{
					pStats.checkpointAngles.append( player.GetAngles() )	// Saves player orientation when checkpoint was reached
					pStats.currentCheckpoint = index						// Updates player's last reached checkpoint
					Remote_CallFunction_NonReplay( 							// Send player's client next checkpoint location, for it to be RUI displayed
						player,
						"ServerCallback_UpdateNextCheckpointMarker",
						checkpointEntities[index].GetEncodedEHandle(),
						index,
						checkpointsCount
					)
					EmitSoundOnEntityOnlyToPlayer( player, player, "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
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
    entity trigger = CreateTriggerRadiusMultiple( origin, 140, [], TRIG_FLAG_PLAYERONLY, 80, -80)
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
void function SpawnStartTrigger( vector volumeMins, vector volumeMaxs )
{
	int checkpointsCount = checkpoints.len()-1

	while (true)
	{
		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), volumeMins, volumeMaxs ))
			{
				if (!localStats[playerName].isRunning && !localStats[playerName].isResetting)
				{
					localStats[playerName].startTime = Time()
					localStats[playerName].isRunning = true
					Remote_CallFunction_NonReplay( player, "ServerCallback_UpdateNextCheckpointMarker", checkpointEntities[0].GetEncodedEHandle(), 0, checkpointsCount )
					EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_start" )
					AddPlayerParkourStat( player, ePlayerParkourStatType.Starts )
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
entity function SpawnEndTrigger( vector origin, vector volumeMins, vector volumeMaxs )
{
	entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
	point.SetValueForModelKey($"models/fx/xo_emp_field.mdl")
	point.kv.modelscale = 0.3
    point.Hide()
    DispatchSpawn( point )
    thread FinishTriggerThink(volumeMins, volumeMaxs)
    return point
}

/**
 * End trigger logic.
 * Checks if colliding players can finish a parkour run (= if they currently are running
 * and last verified checkpoint was the last one), and save their run time if need be.
 * It also resets player stats, for them to be able to start a new parkour run.
 **/
void function FinishTriggerThink(vector volumeMins, vector volumeMaxs)
{
    while (true)
	{
		foreach(player in GetPlayerArray())
		{
			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), volumeMins, volumeMaxs ))
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
						EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_high_score" )
                    } else {
						EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_end" )
					}

                    Remote_CallFunction_NonReplay( player, "ServerCallback_StopRun", duration, isBestTime )
					ResetPlayerCooldowns(player)

					// Score update
					StoreNewLeaderboardEntry( player, duration )
					AddPlayerParkourStat(player, ePlayerParkourStatType.Finishes)
				}
			}
		}
		WaitFrame()
	}
}
