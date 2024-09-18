global function PK_ApplyPerks
global function PK_ForcePlayerLoadout

global struct PK_Perks {
	string ability = ""
	string weapon = ""
	string grenade = ""
	int kit = -1 // numerical value of the passive ability
}
global PK_Perks PK_perks

array<string> abilities = [ "mp_ability_cloak", "mp_weapon_grenade_sonar", "mp_ability_grapple", "mp_ability_heal", "mp_weapon_deployable_cover", "mp_ability_shifter", "mp_ability_holopilot" ]
array<string> grenades = [ "mp_weapon_frag_grenade", "mp_weapon_grenade_emp", "mp_weapon_thermite_grenade", "mp_weapon_grenade_gravity", "mp_weapon_grenade_electric_smoke", "mp_weapon_satchel" ]


void function PK_ApplyPerks( table tPerks ) {
	if ("weapon" in tPerks) {
		string weapon = expect string(tPerks["weapon"])
		print(format("Applying weapon perk (%s)", weapon))
		PK_perks.weapon = weapon
	}

	if ("ability" in tPerks) {
		string ability = expect string(tPerks["ability"])
		print(format("Applying ability perk (%s)", ability))
		PK_perks.ability = ability
	}

	if ("grenade" in tPerks) {
		string grenade = expect string(tPerks["grenade"])
		print(format("Applying grenade perk (%s)", grenade))
		PK_perks.grenade = grenade
	}

	if ("kit" in tPerks) {
		string kit = expect string(tPerks["kit"])
		print(format("Applying kit perk (%s)", kit))
		PK_perks.kit = kit.tointeger()
	}
}

/**
 * This gives player predefined weapon, grenade and ability.
 **/
void function PK_ForcePlayerLoadout(entity player) {
	if (IsAlive(player) && player != null)
	{
		// Weapon switch (removes all weapons and give one perk weapon)
		if (PK_perks.weapon != "") {
			foreach ( int index, entity weapon in player.GetMainWeapons() ) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				if (weapon.GetWeaponClassName().find("mp_weapon_") != null && index == 0)
					player.GiveWeapon( PK_perks.weapon, [] )
			}
		}

		// Ability+grenade switch
		bool abilityGiven = false;
		bool grenadeGiven = false;

		foreach ( int index, entity weapon in player.GetOffhandWeapons() ) {
			if (PK_perks.ability != "" && abilityGiven == false && abilities.find(weapon.GetWeaponClassName()) != -1) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				player.GiveOffhandWeapon( PK_perks.ability, index )
				abilityGiven = true
			}

			else if (PK_perks.grenade != "" && grenadeGiven == false && grenades.find(weapon.GetWeaponClassName()) != -1) {
				player.TakeWeaponNow( weapon.GetWeaponClassName() )
				player.GiveOffhandWeapon( PK_perks.grenade, index )
				grenadeGiven = true
			}
		}

		// Kit
		if (PK_perks.kit != -1) {
			GivePassive (player, PK_perks.kit)
		}
	}
}