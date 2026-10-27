// =============================================================================
// Corpo Wars — Taser (sprites/sounds/light from "Tazer" by DeVloek; see CREDITS.txt)
// Hold fire at point-blank range. Each zap staggers a guard; keep it on them
// for about a second and they drop, non-lethal. Runs on a battery.
// =============================================================================
class CW_TaserCharge : Ammo
{
	Default { Inventory.MaxAmount 100; +INVENTORY.IGNORESKILL; Inventory.Icon "VTAZP0"; Tag "Taser battery"; }
}

class CW_Taser : Weapon
{
	const RANGE = 56;
	Default
	{
		Weapon.SlotNumber 1;
		Weapon.SelectionOrder 2300;
		Weapon.AmmoType "CW_TaserCharge";
		Weapon.AmmoUse 4;
		Weapon.AmmoGive 0;
		+WEAPON.NOALERT;
		+WEAPON.MELEEWEAPON;
		Tag "Taser";
	}

	action void CW_Zap()
	{
		invoker.owner.A_AttachLightDef("CWTZL", "CW_TASERLIGHT");
		A_StartSound("cw/taser/zap", CHAN_WEAPON, CHANF_NOSTOP);
		A_FireBullets(0, -3, -1, 1, "CW_TaserSpark", FBF_USEAMMO | FBF_EXPLICITANGLE | FBF_NOFLASH, CW_Taser.RANGE);
		CW_Handler.EmitNoise(self, pos, 180, 0.3);
	}
	action void CW_ZapOff()
	{
		invoker.owner.A_RemoveLight("CWTZL");
		A_StopSound(CHAN_WEAPON);
	}

	States
	{
	Spawn:
		VTAZ P -1;
		Stop;
	Ready:
		VTAZ A 1 A_WeaponReady;
		Loop;
	Deselect:
		VTAZ A 0 CW_ZapOff();
		VTAZ A 1 A_Lower(16);
		Wait;
	Select:
		VTAZ A 1 A_Raise(16);
		Loop;
	Fire:
		VTAZ AAA 1 A_WeaponOffset(-12, 14, WOF_ADD);
	Hold:
		VTAZ B 3 Bright CW_Zap();
		VTAZ C 3 Bright CW_Zap();
		VTAZ D 3 Bright CW_Zap();
		TNT1 A 0 A_ReFire;
		VTAZ AAA 1
		{
			CW_ZapOff();
			A_WeaponOffset(12, -14, WOF_ADD);
		}
		Goto Ready;
	}
}

class CW_TaserSpark : Actor
{
	Default
	{
		Scale 0.1;
		RenderStyle "Add";
		DamageType "Taser";
		+NOINTERACTION;
		+NOBLOCKMAP;
		+ROLLSPRITE;
		+BLOODLESSIMPACT;
		+PUFFONACTORS;
		-ALLOWPARTICLES;
	}
	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			A_SetRoll(random(0, 359));
			A_StartSound("cw/taser/spark", CHAN_BODY, 0, 0.7);
		}
		VTZS ABC 1 Bright;
		Stop;
	}
}
