// The only player pawn. M1 owns weapon slots and the direct flashlight toggle.
class NBC_Player : PlayerPawn
{
	Spotlight nbcFlashlightBeam;
	bool nbcFlashlightOn;
	float nbcReloadSpeedMultiplier;
	float nbcMagazineSizeMultiplier;
	int nbcDebrisCarryLimit;
	bool nbcThrowActive;
	bool nbcThrowQueued;
	bool nbcThrowHeld;
	bool nbcThrowReleaseStarted;
	int nbcThrowType;
	int nbcThrowChargeTics;
	int nbcThrowChargeSteps;
	Weapon nbcThrowWeapon;

Default
{
	Player.DisplayName "New Bricks City Officer";
	Player.StartItem "FistsOfFury";
	Player.StartItem "NBC_Colt45";
	Player.StartItem "NBC_DebrisSatchel";
	Player.StartItem "NBC_QuickThrow";
	Player.StartItem "NBC_LightAmmo", 18; // NBC: Colt45 contributes 6 pickup-give rounds, for 24 total.
	Player.WeaponSlot 1, "FistsOfFury", "CombatKnife", "Machete";
	Player.WeaponSlot 2, "NBC_Colt45", "NBC_Dual92";
	Player.WeaponSlot 3, "NBC_PumpShotgun";
	Player.WeaponSlot 4, "NBC_MicroUzi";
	Player.WeaponSlot 5, "NBC_AK47";
	Player.WeaponSlot 6, "MolotovCocktail";
}

double NBC_GetReloadSpeedMultiplier()
{
	return nbcReloadSpeedMultiplier > 0 ? nbcReloadSpeedMultiplier : 1.0;
}

double NBC_GetMagazineSizeMultiplier()
{
	return nbcMagazineSizeMultiplier > 0 ? nbcMagazineSizeMultiplier : 1.0;
}

clearscope NBC_DebrisSatchel NBC_GetDebrisSatchel()
{
	return NBC_DebrisSatchel(FindInventory("NBC_DebrisSatchel"));
}

clearscope int NBC_GetDebrisCarryLimit()
{
	return nbcDebrisCarryLimit > 0 ? nbcDebrisCarryLimit : 3;
}

clearscope int NBC_GetDebrisCount(int type)
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!satchel || type < 0 || type >= NBC_DEBRIS_KIND_COUNT) return 0;
	return satchel.nbcCounts[type];
}

clearscope int NBC_GetSelectedDebris()
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	return satchel ? clamp(satchel.nbcSelected, 0, NBC_DEBRIS_KIND_COUNT - 1) : NBC_DEBRIS_BRICK;
}

clearscope int NBC_GetTotalDebris()
{
	int total = 0;
	for (int i = 0; i < NBC_DEBRIS_KIND_COUNT; i++) total += NBC_GetDebrisCount(i);
	return total;
}

bool NBC_AddDebris(int type, int amount)
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!satchel || type < 0 || type >= NBC_DEBRIS_KIND_COUNT || amount <= 0) return false;
	int room = max(0, NBC_GetDebrisCarryLimit() - NBC_GetTotalDebris());
	int grant = min(room, amount);
	if (grant <= 0) return false;
	bool wasEmpty = NBC_GetTotalDebris() == 0;
	satchel.nbcCounts[type] += grant;
	if (wasEmpty || satchel.nbcCounts[satchel.nbcSelected] <= 0)
		satchel.nbcSelected = type;
	return true;
}

bool NBC_TakeDebris(int type, int amount)
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!satchel || type < 0 || type >= NBC_DEBRIS_KIND_COUNT || amount <= 0 || satchel.nbcCounts[type] < amount)
		return false;
	satchel.nbcCounts[type] -= amount;
	if (satchel.nbcCounts[satchel.nbcSelected] <= 0)
		NBC_CycleDebris();
	return true;
}

void NBC_CycleDebris()
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!satchel) return;
	for (int step = 1; step <= NBC_DEBRIS_KIND_COUNT; step++)
	{
		int next = (satchel.nbcSelected + step) % NBC_DEBRIS_KIND_COUNT;
		if (satchel.nbcCounts[next] > 0)
		{
			satchel.nbcSelected = next;
			return;
		}
	}
}

void NBC_BeginQuickThrow()
{
	if (nbcThrowActive || nbcThrowQueued || NBC_GetTotalDebris() <= 0) return;
	if (!FindInventory("NBC_QuickThrow")) return;
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!satchel || satchel.nbcCounts[satchel.nbcSelected] <= 0) return;
	nbcThrowHeld = true;
	if (player && player.PendingWeapon != WP_NOCHANGE && player.PendingWeapon != null)
	{
		nbcThrowQueued = true;
		return;
	}
	NBC_StartQuickThrow();
}

void NBC_StartQuickThrow()
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!player || !satchel || satchel.nbcCounts[satchel.nbcSelected] <= 0) return;
	nbcThrowType = satchel.nbcSelected;
	nbcThrowChargeTics = 0;
	nbcThrowChargeSteps = 0;
	nbcThrowReleaseStarted = false;
	nbcThrowWeapon = player.ReadyWeapon;
	nbcThrowActive = true;

	NBC_ReloadWeapon reloadWeapon = NBC_ReloadWeapon(nbcThrowWeapon);
	if (reloadWeapon) reloadWeapon.NBC_AbortReloadForQuickThrow();
	if (nbcThrowWeapon)
		player.SetPsprite(PSP_WEAPON, nbcThrowWeapon.GetReadyState());

	if (nbcThrowType == NBC_DEBRIS_BOTTLE)
		A_Overlay(2, "NBC_DebrisBottleHold");
	else
		A_Overlay(2, "NBC_DebrisHold");
}

void NBC_ReleaseQuickThrow()
{
	if (!nbcThrowActive && !nbcThrowQueued) return;
	nbcThrowHeld = false;
	if (nbcThrowActive && !nbcThrowReleaseStarted)
	{
		nbcThrowReleaseStarted = true;
		A_Overlay(2, "NBC_DebrisRelease");
	}
}

void NBC_CancelQuickThrow()
{
	if (!nbcThrowActive) { nbcThrowQueued = false; nbcThrowHeld = false; return; }
	Weapon oldWeapon = nbcThrowWeapon;
	NBC_ReloadWeapon reloadWeapon = NBC_ReloadWeapon(oldWeapon);
	if (reloadWeapon) reloadWeapon.NBC_AbortReloadForQuickThrow();
	A_ClearOverlays(2, 2);
	nbcThrowActive = false;
	nbcThrowQueued = false;
	nbcThrowHeld = false;
	if (player && oldWeapon && player.ReadyWeapon == oldWeapon && player.PendingWeapon == WP_NOCHANGE)
		player.SetPsprite(PSP_WEAPON, oldWeapon.GetUpState());
	nbcThrowWeapon = null;
}

void NBC_AdvanceDebrisOverlay()
{
	if (!nbcThrowActive) { A_ClearOverlays(2, 2); return; }
	if (player && (player.PendingWeapon != WP_NOCHANGE || player.ReadyWeapon != nbcThrowWeapon))
	{
		NBC_CancelQuickThrow();
		return;
	}
	if (!nbcThrowHeld)
	{
		if (!nbcThrowReleaseStarted)
		{
			nbcThrowReleaseStarted = true;
			A_Overlay(2, "NBC_DebrisRelease");
		}
		return;
	}
	nbcThrowChargeTics++;
	if (nbcThrowChargeTics >= 3)
	{
		nbcThrowChargeTics = 0;
		nbcThrowChargeSteps = min(12, nbcThrowChargeSteps + 1);
		if (nbcThrowChargeSteps > 0)
		{
			if (nbcThrowType == NBC_DEBRIS_BOTTLE)
				A_Overlay(2, "NBC_DebrisBottleWindup");
			else
				A_Overlay(2, "NBC_DebrisWindup");
		}
	}
}

void NBC_ThrowSelectedDebris()
{
	NBC_DebrisSatchel satchel = NBC_GetDebrisSatchel();
	if (!satchel || satchel.nbcCounts[nbcThrowType] <= 0) return;
	Class<Actor> projectileClass;
	switch (nbcThrowType)
	{
	case NBC_DEBRIS_BRICK: projectileClass = "NBC_BrickProjectile"; break;
	case NBC_DEBRIS_HALF_BRICK: projectileClass = "NBC_HalfBrickProjectile"; break;
	case NBC_DEBRIS_CONCRETE: projectileClass = "NBC_ConcreteProjectile"; break;
	case NBC_DEBRIS_BOTTLE: projectileClass = "NBC_BottleProjectile"; break;
	}
	if (!projectileClass) return;

	Actor missile = A_SpawnProjectile(projectileClass, 14, 4, angle, 0, pitch, AAPTR_NULL);
	if (!missile) return;
	missile.target = self;
	int speed = 10 + (20 * nbcThrowChargeSteps) / 12;
	NBC_DebrisProjectile debris = NBC_DebrisProjectile(missile);
	double scale = (speed * (debris ? debris.NBC_SpeedFactor() : 1.0)) / max(1.0, missile.Speed);
	missile.vel *= scale;
	satchel.nbcCounts[nbcThrowType]--;
	if (satchel.nbcCounts[nbcThrowType] <= 0)
		NBC_CycleDebris();
	A_StartSound("nbc_debris_throw", CHAN_WEAPON);
}

void NBC_FinishQuickThrow()
{
	Weapon oldWeapon = nbcThrowWeapon;
	A_ClearOverlays(2, 2);
	nbcThrowActive = false;
	nbcThrowQueued = false;
	nbcThrowHeld = false;
	nbcThrowChargeTics = 0;
	nbcThrowChargeSteps = 0;
	nbcThrowReleaseStarted = false;
	if (player && oldWeapon && player.ReadyWeapon == oldWeapon && player.PendingWeapon == WP_NOCHANGE)
		player.SetPsprite(PSP_WEAPON, oldWeapon.GetUpState());
	nbcThrowWeapon = null;
}

void ToggleNBCFlashlight()
{
	if (!nbcFlashlightOn)
	{
		nbcFlashlightOn = true;
		UpdateNBCFlashlight();
		A_StartSound("flashlight/on", CHAN_WEAPON);
	}
	else
	{
		nbcFlashlightOn = false;
		if (nbcFlashlightBeam)
		{
			nbcFlashlightBeam.Destroy();
			nbcFlashlightBeam = null;
		}
		A_StartSound("flashlight/off", CHAN_WEAPON);
	}
}

void UpdateNBCFlashlight()
{
	if (!nbcFlashlightOn || !player) return;
	if (!nbcFlashlightBeam)
	{
		nbcFlashlightBeam = Spotlight(Spawn("Spotlight", (pos.xy, player.viewz - 10)));
		if (!nbcFlashlightBeam) return;
		nbcFlashlightBeam.args[0] = 255;
		nbcFlashlightBeam.args[1] = 255;
		nbcFlashlightBeam.args[2] = 255;
		nbcFlashlightBeam.args[3] = 512;
		nbcFlashlightBeam.SpotInnerAngle = 8;
		nbcFlashlightBeam.SpotOuterAngle = 24;
		nbcFlashlightBeam.bATTENUATE = true;
	}
	nbcFlashlightBeam.SetOrigin((pos.xy, player.viewz - 10), true);
	nbcFlashlightBeam.A_SetAngle(angle, SPF_INTERPOLATE);
	nbcFlashlightBeam.A_SetPitch(pitch, SPF_INTERPOLATE);
}

override void Tick()
{
	// Clear primary/secondary fire and reload before the engine advances weapon states.
	if (nbcThrowActive && player)
		player.cmd.buttons &= ~(BT_ATTACK | BT_ALTATTACK | BT_RELOAD);
	Super.Tick();
	if (nbcThrowQueued && player && player.ReadyWeapon &&
		(player.PendingWeapon == WP_NOCHANGE || player.PendingWeapon == null))
	{
		nbcThrowQueued = false;
		if (NBC_GetTotalDebris() > 0) NBC_StartQuickThrow();
		else nbcThrowHeld = false;
	}
	if (nbcThrowActive)
	{
		if (player && (player.PendingWeapon != WP_NOCHANGE || player.ReadyWeapon != nbcThrowWeapon))
			NBC_CancelQuickThrow();
		else
		{
			PSprite weaponSprite = null;
			if (player) weaponSprite = player.GetPSprite(PSP_WEAPON);
			if (weaponSprite) weaponSprite.y = min(WEAPONBOTTOM, weaponSprite.y + 12);
		}
	}
	UpdateNBCFlashlight();
}

States
{
NBC_DebrisHold:
	BRKH A 1 { NBC_AdvanceDebrisOverlay(); }
	Loop;
NBC_DebrisWindup:
	BRKH B 1 { NBC_AdvanceDebrisOverlay(); }
	Loop;
NBC_DebrisBottleHold:
	MOLT A 1 { NBC_AdvanceDebrisOverlay(); }
	Loop;
NBC_DebrisBottleWindup:
	MOLT A 1 { NBC_AdvanceDebrisOverlay(); }
	Loop;
NBC_DebrisRelease:
	HGT2 A 1 { NBC_ThrowSelectedDebris(); }
	HGT2 BCD 1;
	HGT2 FGH 1;
	HGT2 IJ 1;
	TNT1 A 1 { NBC_FinishQuickThrow(); }
	Stop;
}

}
