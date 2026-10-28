// Shared firearm magazine and reload behavior for M1b.
class NBC_ColtMagazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 8;
	Inventory.InterHubAmount 8;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 8;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_Dual92Magazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 30;
	Inventory.InterHubAmount 30;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 30;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_PumpMagazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 6;
	Inventory.InterHubAmount 6;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 6;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_UziMagazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 32;
	Inventory.InterHubAmount 32;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 32;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_AKMagazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 30;
	Inventory.InterHubAmount 30;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 30;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_MP5Magazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 30;
	Inventory.InterHubAmount 30;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 30;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_M16Magazine : Ammo
{
Default
{
	Inventory.Amount 0;
	Inventory.MaxAmount 30;
	Inventory.InterHubAmount 30;
	Ammo.BackpackAmount 0;
	Ammo.BackpackMaxAmount 30;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}
States { Spawn: TNT1 A -1; Stop; }
}

class NBC_ReloadWeapon : Weapon
{
	bool nbcReloading;
	bool nbcReloadWasEmpty;

	virtual int NBC_BaseMagazineSize() { return 0; }
	int NBC_MagazineCapacity()
	{
		double multiplier = 1.0;
		NBC_Player pawn = NBC_Player(Owner);
		if (pawn) multiplier = pawn.NBC_GetMagazineSizeMultiplier();
		return max(1, int(ceil(NBC_BaseMagazineSize() * multiplier)));
	}

	int NBC_MagazineAmount()
	{
		Inventory magazine = Owner ? Owner.FindInventory(AmmoType1) : null;
		return magazine ? magazine.Amount : 0;
	}

	int NBC_ReserveAmount()
	{
		Inventory reserve = Owner ? Owner.FindInventory(AmmoType2) : null;
		return reserve ? reserve.Amount : 0;
	}

	bool NBC_CanReload()
	{
		if (!Owner || !AmmoType1 || !AmmoType2) return false;
		Inventory magazine = Owner.FindInventory(AmmoType1);
		Inventory reserve = Owner.FindInventory(AmmoType2);
		if (!magazine || !reserve) return false;
		magazine.MaxAmount = NBC_MagazineCapacity();
		magazine.InterHubAmount = magazine.MaxAmount;
		return magazine.Amount < magazine.MaxAmount && reserve.Amount > 0;
	}

	void NBC_BeginReloadState()
	{
		nbcReloading = true;
		nbcReloadWasEmpty = NBC_MagazineAmount() == 0;
	}

	void NBC_CommitMagazineReloadNow()
	{
		if (!Owner || !AmmoType1 || !AmmoType2) return;
		Inventory magazine = Owner.FindInventory(AmmoType1);
		Inventory reserve = Owner.FindInventory(AmmoType2);
		if (!magazine || !reserve) return;
		magazine.MaxAmount = NBC_MagazineCapacity();
		magazine.InterHubAmount = magazine.MaxAmount;
		int transfer = min(magazine.MaxAmount - magazine.Amount, reserve.Amount);
		if (transfer > 0)
		{
			reserve.Amount -= transfer;
			magazine.Amount += transfer;
		}
	}

	void NBC_LoadOneShellNow()
	{
		if (!Owner || !AmmoType1 || !AmmoType2) return;
		Inventory magazine = Owner.FindInventory(AmmoType1);
		Inventory reserve = Owner.FindInventory(AmmoType2);
		if (!magazine || !reserve) return;
		magazine.MaxAmount = NBC_MagazineCapacity();
		magazine.InterHubAmount = magazine.MaxAmount;
		if (magazine.Amount < magazine.MaxAmount && reserve.Amount > 0)
		{
			reserve.Amount--;
			magazine.Amount++;
		}
	}

	action void NBC_BeginMagazineReload()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon) weapon.NBC_BeginReloadState();
	}

	action void NBC_CommitMagazineReload()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon) weapon.NBC_CommitMagazineReloadNow();
	}

	action void NBC_LoadOneShell()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon) weapon.NBC_LoadOneShellNow();
	}

	action void NBC_EndMagazineReload()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon)
		{
			weapon.nbcReloading = false;
			weapon.nbcReloadWasEmpty = false;
		}
	}

	action void NBC_CancelMagazineReload()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon)
		{
			weapon.nbcReloading = false;
			weapon.nbcReloadWasEmpty = false;
		}
	}

	void NBC_AbortReloadForQuickThrow()
	{
		// The caller also redirects the weapon PSprite to Ready; clearing these flags
		// alone would let the old reload sequence reach its commit action later.
		nbcReloading = false;
		nbcReloadWasEmpty = false;
	}

	action void NBC_SyncMagazineCapacity()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (!weapon || !weapon.Owner || !weapon.AmmoType1) return;
		Inventory magazine = weapon.Owner.FindInventory(weapon.AmmoType1);
		if (magazine) magazine.MaxAmount = weapon.NBC_MagazineCapacity();
	}

	action void NBC_AdjustReloadTics(int baseTics)
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		double speed = 1.0;
		NBC_Player pawn = weapon ? NBC_Player(weapon.Owner) : null;
		if (pawn) speed = pawn.NBC_GetReloadSpeedMultiplier();
		A_SetTics(max(1, int(ceil(baseTics / speed))));
	}

	action void NBC_DryClick()
	{
		A_StartSound("nbc_dryclick", CHAN_WEAPON);
	}

	action void NBC_ReloadReject()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon && weapon.NBC_MagazineAmount() == 0 && weapon.NBC_ReserveAmount() == 0)
			A_StartSound("nbc_dryclick", CHAN_WEAPON);
		if (weapon) weapon.nbcReloading = false;
	}

	// An empty magazine with rounds in the reserve isn't "out of ammo": the trigger reaches the Fire state, which
	// reloads. Without this the engine switched weapons whenever a magazine ran dry. Magazine and reserve both
	// empty: the engine's own check (and its switch).
	override bool CheckAmmo(int fireMode, bool autoSwitch, bool requireAmmo, int ammocount)
	{
		if ((fireMode == PrimaryFire || fireMode == EitherFire) && Owner && AmmoType1 && AmmoType2
			&& (NBC_MagazineAmount() > 0 || NBC_ReserveAmount() > 0))
			return true;
		return Super.CheckAmmo(fireMode, autoSwitch, requireAmmo, ammocount);
	}

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		if (Owner && AmmoType1)
		{
			Inventory magazine = Owner.FindInventory(AmmoType1);
			if (magazine)
			{
				magazine.MaxAmount = NBC_MagazineCapacity();
				magazine.InterHubAmount = magazine.MaxAmount;
			}
		}
	}

}
