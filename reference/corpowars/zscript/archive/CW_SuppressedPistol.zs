// ARCHIVED 0.10.1 — superseded by the universal Suppressor attachment (service pistol + V).
// Not included by zscript.txt. Sprites (SPIL/SPIP) and sounds (cw/sd/*) are still in the mod.
// To restore: #include this file, set CW_Items.Price(IT_SDPISTOL) back to 1200, and re-add its
// IssueItem / UnissueType / IssuePersonal cases in inventory.zs.

// Magazine-fed suppressed pistol. 10 rounds, reserve uses standard Clip ammo.
class CW_SDMag : Ammo
{
	Default { Inventory.MaxAmount 10; +INVENTORY.IGNORESKILL; Inventory.Icon "Z9MMA0"; }
}

class CW_SuppressedPistol : Weapon
{
	const MAG = 10;
	Default
	{
		Weapon.SlotNumber 2;
		Weapon.SelectionOrder 1800;
		Weapon.AmmoType1 "CW_SDMag";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType2 "Clip";
		Weapon.AmmoUse2 0;
		+WEAPON.AMMO_OPTIONAL;
		+WEAPON.NOALERT;
		+WEAPON.NOAUTOFIRE;
		Tag "Suppressed pistol";
		Obituary "%o was quietly retired.";
	}

	action void CW_ReloadMag()
	{
		let mag = invoker.owner.FindInventory("CW_SDMag");
		int have = mag ? mag.Amount : 0;
		int need = CW_SuppressedPistol.MAG - have;
		int take = min(need, invoker.owner.CountInv("Clip"));
		if (take <= 0) return;
		invoker.owner.TakeInventory("Clip", take);
		invoker.owner.GiveInventory("CW_SDMag", take);
	}

	States
	{
	Spawn:
		SPIP A -1;
		Stop;
	Select:
		SPIL A 1 A_Raise;
		Loop;
	Deselect:
		SPIL A 1 A_Lower;
		Loop;
	Ready:
		SPIL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Fire:
		SPIL A 0 A_JumpIfNoAmmo("Reload");
		SPIL A 3
		{
			A_FireBullets(1.2, 0.8, -1, 14, "BulletPuff", FBF_USEAMMO | FBF_NORANDOM | FBF_NOFLASH);
			A_StartSound("cw/sd/fire", CHAN_WEAPON, 0, 0.8);
			CW_Handler.EmitNoise(self, pos, 220, 0.4);
		}
		SPIL B 2;
		SPIL C 1;
		SPIL D 1;
		SPIL E 2;
		SPIL B 3;
		Goto Ready;
	Reload:
		SPIL A 0 A_JumpIf(CountInv("CW_SDMag") >= CW_SuppressedPistol.MAG || CountInv("Clip") <= 0, "Ready");
		SPIL A 1 Offset(0, 38) A_StartSound("cw/sd/reload", CHAN_WEAPON);
		SPIL A 1 Offset(0, 50);
		SPIL A 1 Offset(0, 64);
		SPIL A 1 Offset(0, 80);
		SPIL A 18 Offset(2, 82) CW_ReloadMag();
		SPIL E 2 Offset(0, 72) A_StartSound("cw/sd/slide", CHAN_7);
		SPIL E 2 Offset(0, 58);
		SPIL D 3 Offset(0, 44);
		SPIL C 3 Offset(0, 36);
		SPIL A 2 Offset(0, 32);
		Goto Ready;
	}
}

