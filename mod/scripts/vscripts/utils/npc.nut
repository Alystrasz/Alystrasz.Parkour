global function PK_SpawnAmbientMarvin

void function PK_SpawnAmbientMarvin( vector origin, vector angles, int talkableRadius, string animation )
{
	entity npc_marvin = CreateEntity( "npc_marvin" )
	npc_marvin.SetOrigin( origin )
	npc_marvin.SetAngles( angles )
    SetTeam( npc_marvin, TEAM_IMC )
    npc_marvin.SetTitle( PK_ROBOT_NAME )
	npc_marvin.kv.rendercolor = "255 255 255"
	npc_marvin.kv.health = -1
	npc_marvin.kv.max_health = -1
	// npc_marvin.kv.spawnflags = 516  // Fall to ground, Fade Corpse
	//npc_marvin.kv.FieldOfView = 0.5
	//npc_marvin.kv.FieldOfViewAlert = 0.2
	npc_marvin.kv.AccuracyMultiplier = 1.0
	npc_marvin.kv.physdamagescale = 1.0
	npc_marvin.kv.WeaponProficiency = eWeaponProficiency.GOOD
	DispatchSpawn( npc_marvin )

    entity info_target = CreateEntity( "info_target" )
    info_target.SetOrigin( origin )
	info_target.SetAngles( angles )

    thread PlayAnim( npc_marvin, animation, info_target, null, 0.6 )
	// sad marvin
	if ( animation == "mv_arctool_steal_endidle" )
	{
		npc_marvin.SetSkin(2)
	}

	// Check if player is close to robot
    entity trigger = CreateTriggerRadiusMultiple( origin, talkableRadius.tofloat() + 6, [], TRIG_FLAG_PLAYERONLY, 80, -80)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player) {
		Remote_CallFunction_NonReplay( player, "ServerCallback_PK_SetRobotTalkState", true)
    })
    AddCallback_ScriptTriggerLeave( trigger, void function (entity trigger, entity player) {
        Remote_CallFunction_NonReplay( player, "ServerCallback_PK_SetRobotTalkState", false)
    })

	float cylinderHeight = 40.0
	DebugDrawCylinder( <origin.x, origin.y, origin.z>, <90, 0, 0>, talkableRadius.tofloat(), -2*cylinderHeight, 255, 255, 255, true, 10000.0 )

	// Set robot as talkable to
	/*npc_marvin.SetUsable()
	npc_marvin.SetUsableRadius( talkableRadius )
	npc_marvin.AddUsableValue( USABLE_BY_PILOTS | USABLE_HINT_ONLY )
	npc_marvin.SetUsePrompts( "#ROBOT_INTERACTION_PROMPT", "#ROBOT_INTERACTION_PROMPT" )*/
	// DebugDrawCircleOnEnt( npc_marvin, talkableRadius.tofloat() + 6, 255, 255, 255, 10000.0 )
}