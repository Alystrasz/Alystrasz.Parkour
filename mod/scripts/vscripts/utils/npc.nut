global function SpawnAmbientMarvin

void function SpawnAmbientMarvin( vector origin, vector angles )
{
	entity npc_marvin = CreateEntity( "npc_marvin" )
	npc_marvin.SetOrigin( origin )
	npc_marvin.SetAngles( angles )
    SetTeam( npc_marvin, TEAM_IMC )
    npc_marvin.SetTitle( "R-MY" )
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

    thread PlayAnim( npc_marvin, "mv_idle_weld", info_target, null, 0.6 )

	// Check if player is close to robot
    entity trigger = CreateTriggerRadiusMultiple( origin, 60, [], TRIG_FLAG_PLAYERONLY, 80, -80)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player) {
		Remote_CallFunction_NonReplay( player, "ServerCallback_SetRobotTalkState", true)
    })
    AddCallback_ScriptTriggerLeave( trigger, void function (entity trigger, entity player) {
        Remote_CallFunction_NonReplay( player, "ServerCallback_SetRobotTalkState", false)
    })

	// Set robot as talkable to
	npc_marvin.SetUsable()
	npc_marvin.SetUsableRadius( 60 )
	npc_marvin.AddUsableValue( USABLE_BY_PILOTS | USABLE_HINT_ONLY )
	npc_marvin.SetUsePrompts( "Press %use% to talk to R-MY." , "Press %use% to talk to R-MY." )
}