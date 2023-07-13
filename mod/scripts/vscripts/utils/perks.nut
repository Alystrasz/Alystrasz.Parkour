global function ForcePlayerLoadout

void function ForcePlayerLoadout(entity player) {
	if (IsAlive(player) && player != null)
	{
        foreach ( entity weapon in player.GetMainWeapons() )
			player.TakeWeaponNow( weapon.GetWeaponClassName() )
		foreach ( entity weapon in player.GetOffhandWeapons() )
			player.TakeWeaponNow( weapon.GetWeaponClassName() )
		
		player.GiveOffhandWeapon( "mp_ability_grapple", 1 )
		player.GiveOffhandWeapon( "mp_weapon_grenade_gravity", 0 )
        player.GiveWeapon( "mp_weapon_epg", [] )
	}
}