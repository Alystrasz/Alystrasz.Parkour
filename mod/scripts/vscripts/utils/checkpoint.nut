global function PK_SpawnCheckpoints


/**
 * This uses the global checkpoints list to create the actual checkpoint entities.
 * Checkpoints entities will be created starting from the second entity, the first
 * one being a start trigger (does not need the checkpoint visual); last entry will
 * also not be spawned as a checkpoint, but as a finish trigger.
 **/
void function PK_SpawnCheckpoints( vector startMins, vector startMaxs, vector endMins, vector endMaxs )
{
	int checkpointsCount = PK_checkpoints.len()-1

	foreach (int index, vector checkpoint in PK_checkpoints)
	{
		if (index == 0)
		{
			thread SpawnStartTrigger( startMins, startMaxs )
		}
		else if (index == PK_checkpoints.len()-1)
		{
			PK_checkpointEntities.append( SpawnEndTrigger( checkpoint, endMins, endMaxs ) )
		}
		else
		{
			entity checkpoint = CreateCheckpoint(checkpoint, void function (entity player): (index, checkpointsCount) {
				PK_PlayerStats pStats = PK_localStats[player.GetPlayerName()]

				// Only update player info if their currentCheckpoint index is the previous one!
				if (pStats.isRunning && !pStats.isResetting && pStats.currentCheckpoint == index-1)
				{
					pStats.checkpointPassages.append( player.GetOrigin() )	// Saves player location+angles when checkpoint is reached
					pStats.checkpointAngles.append( player.GetAngles() )
					pStats.currentCheckpoint = index						// Updates player's last reached checkpoint
					Remote_CallFunction_NonReplay( 							// Send player's client next checkpoint location, for it to be RUI displayed
						player,
						"ServerCallback_PK_UpdateNextCheckpointMarker",
						PK_checkpointEntities[index].GetEncodedEHandle(),
						index,
						checkpointsCount
					)
					EmitSoundOnEntityOnlyToPlayer( player, player, "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
				}
			})
			PK_checkpointEntities.append( checkpoint )
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

	// Debugging
    float cylinderHeight = 160.0
    DebugDrawCylinder( <origin.x, origin.y, origin.z + cylinderHeight>, <90, 0, 0>, 140.0, cylinderHeight, 0, 255, 0, true, 10000.0 )

    return point
}


/**
 * This method spawns the starting trigger.
 * This trigger checks if colliding players are currently doing a parkour run, and starts
 * one if it's not the case.
 **/
void function SpawnStartTrigger( vector volumeMins, vector volumeMaxs )
{
	int checkpointsCount = PK_checkpoints.len()-1

	// Debugging
	DebugDrawBox( <0,0,0>, volumeMins, volumeMaxs, 255, 0, 0, 10, 10000.0 )

	while (GetGameState() <= eGameState.SuddenDeath)
	{
		foreach(player in GetPlayerArray())
		{
			if ( !IsValid( player ) ) {
				continue
			}

			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), volumeMins, volumeMaxs ))
			{
				if (!PK_localStats[playerName].justFinished && !PK_localStats[playerName].isRunning && !PK_localStats[playerName].isResetting)
				{
					PK_localStats[playerName].startTime = Time()
					PK_localStats[playerName].isRunning = true
					Remote_CallFunction_NonReplay( player, "ServerCallback_PK_UpdateNextCheckpointMarker", PK_checkpointEntities[0].GetEncodedEHandle(), 0, checkpointsCount )
					EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_start" )
					PK_AddPlayerParkourStat( player, ePlayerParkourStatType.Starts )
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

	// Debugging
	DebugDrawBox( origin, volumeMins - origin, volumeMaxs - origin, 255, 255, 0, 10, 10000.0 )
	DebugDrawSphere( origin, 25.0, 255, 255, 0, true, 10000.0 )

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
    while (GetGameState() <= eGameState.SuddenDeath)
	{
		foreach(player in GetPlayerArray())
		{
			if ( !IsValid( player ) ) {
				continue
			}

			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), volumeMins, volumeMaxs ))
			{
                PK_PlayerStats playerStats = PK_localStats[playerName]
				if (playerStats.isRunning && playerStats.currentCheckpoint == PK_checkpoints.len()-2) {
                    float duration = Time() - playerStats.startTime

					thread PreventPlayerToImmediatelyStartAgain(playerStats)
                    playerStats.isRunning = false
                    playerStats.currentCheckpoint = 0
					playerStats.checkpointPassages = [PK_startOrigin]
                    playerStats.checkpointAngles = [PK_startAngles]

                    bool isBestTime = duration < playerStats.bestTime
                    if (isBestTime)
                    {
                        playerStats.bestTime = duration
						EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_high_score" )
                    } else {
						EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_end" )
					}

                    Remote_CallFunction_NonReplay( player, "ServerCallback_PK_StopRun", duration, isBestTime )
					ResetPlayerCooldowns(player)

					// Score update
					PK_StoreNewLeaderboardEntry( player, duration )
					PK_AddPlayerParkourStat(player, ePlayerParkourStatType.Finishes)
				}
			}
		}
		WaitFrame()
	}
}

/**
 * Raises a flag preventing player to start a new run.
 * This is useful on maps that share the same trigger for starting and finish lines, for
 * players not to start a new run instantly after ending one.
 **/
void function PreventPlayerToImmediatelyStartAgain(PK_PlayerStats playerStats)
{
	playerStats.justFinished = true
	wait 1
	playerStats.justFinished = false
}