global function SpawnAmbientMarvin

void function SpawnAmbientMarvin( vector origin, vector angles )
{
    entity npc = CreateEntity( "prop_dynamic" )
    npc.SetValueForModelKey($"models/robots/marvin/marvin.mdl")

    npc.SetSkin(1)
    npc.SetOrigin( origin )
    npc.SetAngles( angles )
    SetTeam( npc, TEAM_IMC )
    DispatchSpawn( npc )

    entity trigger = CreateTriggerRadiusMultiple( origin, 60, [], TRIG_FLAG_PLAYERONLY, 80, -80)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player) {
        Chat_ServerBroadcast("HELLO")
    })
    AddCallback_ScriptTriggerLeave( trigger, void function (entity trigger, entity player) {
        Chat_ServerBroadcast("GOODBYE")
    })

    /*
	entity npc_marvin = CreateEntity( "npc_marvin" )
	// SetTargetName( npc_marvin, UniqueString( "mp_random_marvin") )
	npc_marvin.SetOrigin( origin )
	npc_marvin.SetAngles( angles )
	npc_marvin.kv.rendercolor = "255 255 255"
	npc_marvin.kv.health = -1
	npc_marvin.kv.max_health = -1
	npc_marvin.kv.spawnflags = 516  // Fall to ground, Fade Corpse
	//npc_marvin.kv.FieldOfView = 0.5
	//npc_marvin.kv.FieldOfViewAlert = 0.2
	npc_marvin.kv.AccuracyMultiplier = 1.0
	npc_marvin.kv.physdamagescale = 1.0
	npc_marvin.kv.WeaponProficiency = eWeaponProficiency.GOOD

	// npc_marvin.s.bodytype <- MARVIN_TYPE_WORKER

	return npc_marvin*/
}