global function ForcePlayerLoadout

global struct Perks {
	string ability = ""
	string weapon = ""
	string grenade = ""
}
global Perks perks

void function ForcePlayerLoadout(entity player) {
	if (IsAlive(player) && player != null)
	{
		// Weapon switch
		if (perks.weapon != "") {
			foreach ( int index, entity weapon in player.GetMainWeapons() ) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				if (weapon.GetWeaponClassName().find("mp_weapon_") != null && index == 0)
					player.GiveWeapon( "mp_weapon_epg", [] )
			}
		}

		// Ability+grenade switch
		foreach ( int index, entity weapon in player.GetOffhandWeapons() ) {
			if (perks.ability != "" && weapon.GetWeaponClassName().find("mp_ability_") != null) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				player.GiveOffhandWeapon( perks.ability, index )
			}

			else if (perks.grenade != "" && weapon.GetWeaponClassName().find("mp_weapon_") != null) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				player.GiveOffhandWeapon( perks.grenade, index )
			}
		}
	}
}