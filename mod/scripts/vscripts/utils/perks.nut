global function ForcePlayerLoadout

global struct Perks {
	string ability = ""
	string weapon = ""
	string grenade = ""
}
global Perks perks

array<string> abilities = [ "mp_ability_cloak", "mp_weapon_grenade_sonar", "mp_ability_grapple", "mp_ability_heal", "mp_weapon_deployable_cover", "mp_ability_shifter", "mp_ability_holopilot" ]
array<string> grenades = [ "mp_weapon_frag_grenade", "mp_weapon_grenade_emp", "mp_weapon_thermite_grenade", "mp_weapon_grenade_gravity", "mp_weapon_grenade_electric_smoke", "mp_weapon_satchel" ]

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
		bool abilityGiven = false;
		bool grenadeGiven = false;

		foreach ( int index, entity weapon in player.GetOffhandWeapons() ) {
			if (perks.ability != "" && abilityGiven == false && abilities.find(weapon.GetWeaponClassName()) != -1) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				player.GiveOffhandWeapon( perks.ability, index )
				abilityGiven = true
			}

			else if (perks.grenade != "" && grenadeGiven == false && grenades.find(weapon.GetWeaponClassName()) != -1) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				player.GiveOffhandWeapon( perks.grenade, index )
				grenadeGiven = true
			}
		}
	}
}