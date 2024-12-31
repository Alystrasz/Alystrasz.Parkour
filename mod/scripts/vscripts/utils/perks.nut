global function PK_ApplyPerks
global function PK_ForcePlayerLoadout
global function PK_ForcePlayerWeapon

global struct PK_Perks {
	string ability = ""
	string weapon = ""
	string grenade = ""
	int kit = -1 // numerical value of the passive ability
	bool floorIsLava = false
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

	if ("floor_is_lava" in tPerks) {
		print("Applying floor_is_lava perk")
		PK_perks.floorIsLava = true

		// In original "floor is lava" riff (located in
		// `Northstar.CustomServers/mod/scripts/vscripts/gamemodes/_riff_floor_is_lava.nut`),
		// fog is set up through a `AddSpawnCallback` call:
		//
		//		AddSpawnCallback( "env_fog_controller", InitLavaFogController )
		//
		// however in this mod, `PK_ApplyPerks` is called after `env_fog_controller` entities
		// are created, meaning we have to call `InitLavaFogController` ourselves on each
		// spawned `env_fog_controller` entity.
		foreach ( entity fogController in GetEntArrayByClass_Expensive("env_fog_controller") )
		{
			InitLavaFogController( fogController )
		}

		RiffFloorIsLava_Init()
	}
}

// Imported from Northstar.CustomServers/mod/scripts/vscripts/gamemodes/_riff_floor_is_lava.nut
void function InitLavaFogController( entity fogController )
{
	fogController.kv.fogztop = GetVisibleFogTop()
	fogController.kv.fogzbottom = GetVisibleFogBottom()
	fogController.kv.foghalfdisttop = "60000"
	fogController.kv.foghalfdistbottom = "200"
	fogController.kv.fogdistoffset = "0"
	fogController.kv.fogdensity = "1.25"

	fogController.kv.forceontosky = true
	//fogController.kv.foghalfdisttop = "10000"
}

/**
 * This gives player predefined grenade and ability.
 **/
void function PK_ForcePlayerLoadout(entity player) {
	if (IsAlive(player) && player != null)
	{
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

void function PK_ForcePlayerWeapon(entity player) {
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
	}
}
