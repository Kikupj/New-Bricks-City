// Shared reserve ammunition and global pickup/drop integration for M1.
class NBC_LightAmmo : Ammo
{
Default
{
	Inventory.Amount 10;
	Inventory.MaxAmount 300;
	Ammo.BackpackAmount 10;
	Ammo.BackpackMaxAmount 600;
	Inventory.PickupMessage "Picked up light ammunition.";
}
States
{
Spawn:
	CLIP A -1;
	Stop;
}
}

class NBC_LightAmmoBox : NBC_LightAmmo
{
Default
{
	Inventory.Amount 50;
	Inventory.PickupMessage "Picked up a box of light ammunition.";
}
States
{
Spawn:
	AMMO A -1;
	Stop;
}
}

// The Shell ammo type remains the stock shared reserve, but dropped shell boxes get an NBC pickup wrapper.
class NBC_ShellAmmoBox : CustomInventory
{
Default
{
	Inventory.PickupMessage "Picked up a box of shells.";
}
States
{
Spawn:
	SBOX A -1;
	Stop;
Pickup:
	TNT1 A 0 A_GiveInventory("Shell", 20);
	Stop;
}
}

class NBC_RifleAmmo : Ammo
{
Default
{
	Inventory.Amount 10;
	Inventory.MaxAmount 300;
	Ammo.BackpackAmount 10;
	Ammo.BackpackMaxAmount 600;
	Inventory.PickupMessage "Picked up rifle ammunition.";
}
States
{
Spawn:
	ROCK A -1;
	Stop;
}
}

class NBC_RifleAmmoBox : NBC_RifleAmmo
{
Default
{
	Inventory.Amount 50;
	Inventory.PickupMessage "Picked up a box of rifle ammunition.";
}
States
{
Spawn:
	BROK A -1;
	Stop;
}
}

class NBC_Loot : EventHandler
{
	override void CheckReplacement(ReplaceEvent e)
	{
		Class<Actor> replacement = null;
		// Weapons: every vanilla pickup becomes a weapon from the active pack roster.
		if (e.Replacee == "Fist") replacement = "FistsOfFury";
		else if (e.Replacee == "Pistol") replacement = "NBC_Colt45";
		else if (e.Replacee == "Shotgun") replacement = "NBC_PumpShotgun";
		else if (e.Replacee == "SuperShotgun") replacement = "NBC_SuperShorty";
		// the SMGs and rifles drop either way (the MP5kSD and M16 packs joined the roster later)
		else if (e.Replacee == "Chaingun") { if (random[nbcloot](0, 2)) replacement = "NBC_MicroUzi"; else replacement = "NBC_MP5kSD"; }
		else if (e.Replacee == "PlasmaRifle") { if (random[nbcloot](0, 2)) replacement = "NBC_AK47"; else replacement = "NBC_M16"; }
		else if (e.Replacee == "RocketLauncher" || e.Replacee == "BFG9000") replacement = "MolotovCocktail";
		else if (e.Replacee == "Chainsaw") replacement = "Machete";

		// Vanilla ammunition, including nested Thuggundropper drops, feeds the three shared reserves.
		else if (e.Replacee == "Clip") replacement = "NBC_LightAmmo";
		else if (e.Replacee == "ClipBox") replacement = "NBC_LightAmmoBox";
		else if (e.Replacee == "ShellBox") replacement = "NBC_ShellAmmoBox";
		else if (e.Replacee == "RocketAmmo" || e.Replacee == "Cell") replacement = "NBC_RifleAmmo";
		else if (e.Replacee == "RocketBox" || e.Replacee == "CellPack") replacement = "NBC_RifleAmmoBox";

		if (replacement)
		{
			e.Replacement = replacement;
			e.IsFinal = true;
		}
	}

	override void ConsoleProcess(ConsoleEvent e)
	{
		if (e.Name != "nbc_debug_weapon") return;
		if (consoleplayer < 0 || consoleplayer >= MAXPLAYERS || !playeringame[consoleplayer])
		{
			Console.Printf("[NBC] No active player.\n");
			return;
		}
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(players[consoleplayer].ReadyWeapon);
		if (!weapon)
		{
			Console.Printf("[NBC] The ready weapon has no reload magazine.\n");
			return;
		}
		Inventory magazine = weapon.Ammo1;
		Inventory reserve = weapon.Ammo2;
		Console.Printf("[NBC] magazine %d/%d, reserve %d, reloading=%d\n",
			magazine ? magazine.Amount : 0, magazine ? magazine.MaxAmount : 0,
			reserve ? reserve.Amount : 0, weapon.nbcReloading ? 1 : 0);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || e.Player >= MAXPLAYERS || !playeringame[e.Player]) return;
		NBC_Player pawn = NBC_Player(players[e.Player].mo);
		if (!pawn) return;
		if (e.Name == "nbc_flashlight") pawn.ToggleNBCFlashlight();
		else if (e.Name == "nbc_throw_start") pawn.NBC_BeginQuickThrow();
		else if (e.Name == "nbc_throw_release") pawn.NBC_ReleaseQuickThrow();
		else if (e.Name == "nbc_debris_next") pawn.NBC_CycleDebris();
	}
}
