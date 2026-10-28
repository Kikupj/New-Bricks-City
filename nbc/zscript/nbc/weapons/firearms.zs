// Active firearms ported from the five packs in Weapons/ for M1b.
class NBC_LightPuff : BulletPuff
{
Default { DamageType "NBC_Light"; }
}

class NBC_ShellPuff : BulletPuff
{
Default { DamageType "NBC_Shell"; }
}

class NBC_RiflePuff : BulletPuff
{
Default { DamageType "NBC_Rifle"; }
}

class NBC_Colt45 : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 8; }

Default
{
	Weapon.SlotNumber 2;
	Weapon.SelectionOrder 1900;
	Weapon.AmmoType1 "NBC_ColtMagazine";
	Weapon.AmmoType2 "NBC_LightAmmo";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 8;
	Weapon.AmmoGive2 6;
	Weapon.Kickback 100;
	AttackSound "Weapon/COLTFIRE";
	Obituary "%o was killed by %k's Colt45.";
	Inventory.PickupMessage "Picked up a Colt45.";
	Decal "BulletChip";
	+WEAPON.WIMPY_WEAPON;
}

States
{
Spawn:
	COLT P -1;
	Stop;
Ready:
	COLT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	COLT A 1 A_Lower;
	Loop;
Select:
	COLT A 1 A_Raise;
	Loop;
Fire:
	TNT1 A 0 A_JumpIfInventory("NBC_ColtMagazine", 1, "FireShot");
	TNT1 A 0 A_JumpIfInventory("NBC_LightAmmo", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
FireShot:
	COLT F 1 A_FireBullets(5.2, 1, 1, 7, "NBC_LightPuff");
	COLT F 1 A_Light2;
	COLT F 1 A_Light1;
	COLT B 3 A_Light0;
	COLT CDE 3;
	COLT B 3 A_ReFire;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	TNT1 A 0 A_StartSound("B92REL1", CHAN_7);
	Goto ReloadDip;
ReloadDip:
	COLT A 3 Offset(0, 44) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 3 Offset(0, 56) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 3 Offset(0, 68) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 3 Offset(0, 80) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 14 Offset(0, 92) { NBC_AdjustReloadTics(14); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadRack");
	Goto ReloadCommit;
ReloadRack:
	COLT A 9 Offset(0, 92) { NBC_AdjustReloadTics(9); A_StartSound("B92REL3", CHAN_7); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	Goto ReloadCommit;
ReloadCommit:
	TNT1 A 0 A_StartSound("B92REL2", CHAN_7);
	TNT1 A 0 NBC_CommitMagazineReload;
ReloadFinish:
	COLT A 3 Offset(0, 80) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 3 Offset(0, 68) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 3 Offset(0, 56) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	COLT A 1 Offset(0, 32) A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY);
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
Flash:
	TNT1 A 2 bright A_Light2;
	Stop;
}
}

class NBC_Dual92FireSwap : Inventory { Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; } }

class NBC_Dual92 : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 30; }

Default
{
	Weapon.SelectionOrder 700;
	Weapon.SlotNumber 2;
	Weapon.AmmoType1 "NBC_Dual92Magazine";
	Weapon.AmmoType2 "NBC_LightAmmo";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 30;
	Weapon.AmmoGive2 12;
	Inventory.PickupMessage "You got the Dual 92s! Shed some blood!";
	Obituary "%o didn't wake up to a better tomorrow.";
	Tag "Dual 92s";
	Scale 0.6;
	+WEAPON.NOALERT;
	+WEAPON.NOAUTOFIRE;
}

States
{
Spawn:
	B92G A -1;
	Stop;
Ready:
	B92I A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	B92I A 1 A_Lower;
	B92I AA 0 A_Lower;
	Loop;
Select:
	B92I A 1 A_Raise;
	B92I AA 0 A_Raise;
	Loop;
Fire:
	TNT1 A 0 A_JumpIfInventory("NBC_Dual92Magazine", 1, "FireShot");
	TNT1 A 0 A_JumpIfInventory("NBC_LightAmmo", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
FireShot:
	TNT1 A 0 A_AlertMonsters;
	TNT1 A 0 A_StartSound("B92FIRE", CHAN_WEAPON);
	TNT1 A 0 A_FireBullets(2.5, 2.5, -1, 5, "NBC_LightPuff");
	TNT1 A 0 A_JumpIfInventory("NBC_Dual92FireSwap", 1, "FireRight");
FireLeft:
	B92L A 1 bright A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY|WRF_NOSWITCH);
	TNT1 A 0 A_Quake(1, 2, 0, 48576, "None");
	TNT1 A 0 A_GiveInventory("NBC_Dual92FireSwap", 1);
	B92L B 1 bright A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY|WRF_NOSWITCH);
	B92L C 1 A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY|WRF_NOSWITCH);
	B92L DEF 1 A_WeaponReady(WRF_NOSWITCH);
	Goto FireRest;
FireRight:
	B92R A 1 bright A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY|WRF_NOSWITCH);
	TNT1 A 0 A_Quake(1, 2, 0, 48576, "None");
	TNT1 A 0 A_TakeInventory("NBC_Dual92FireSwap", 99);
	B92R B 1 bright A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY|WRF_NOSWITCH);
	B92R C 1 A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY|WRF_NOSWITCH);
	B92R DEF 1 A_WeaponReady(WRF_NOSWITCH);
	Goto FireRest;
FireRest:
	B92I A 1 A_WeaponReady;
	B92I A 0 A_ReFire("Fire");
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	TNT1 A 0 A_StartSound("B92REL1", CHAN_7);
	Goto ReloadOpen;
ReloadOpen:
	D9RA A 0 A_TakeInventory("NBC_Dual92FireSwap", 1);
	D92R K 2 { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	D92R A 2 { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	D92R BC 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_StartSound("B92REL1", CHAN_7);
	TNT1 A 2 { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92L ABCD 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92L E 2 { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_StartSound("B92REL2", CHAN_6);
	R92L FGHI 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92L JK 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92L CBAL 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92R ABCD 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92R E 2 { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_StartSound("B92REL2", CHAN_6);
	R92R FGHI 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadRack");
	Goto ReloadCommit;
ReloadRack:
	D92R DEF 4 { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_StartSound("B92REL3", CHAN_6);
	D92R GH 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	D92R IJK 2 { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
ReloadCommit:
	TNT1 A 0 NBC_CommitMagazineReload;
	R92R JK 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92R CBAL 1 { NBC_AdjustReloadTics(1); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	R92R A 6 { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
ReloadFinish:
	D92R IJK 2;
	TNT1 A 0 A_Refire("Fire");
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
}
}

class NBC_PumpShotgun : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 6; }

Default
{
	Weapon.SelectionOrder 1300;
	Weapon.SlotNumber 3;
	Weapon.Kickback 100;
	Weapon.AmmoType1 "NBC_PumpMagazine";
	Weapon.AmmoType2 "Shell";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 6;
	Weapon.AmmoGive2 4;
	AttackSound "weapons/Xshotgf";
	Inventory.PickupMessage "You got the Pump-Action Shotgun!";
	Obituary "%o was blown by %k's shotty.";
	Decal "BulletChip";
	Tag "Pump-Action Shotgun";
}

States
{
Spawn:
	XSOT A -1;
	Stop;
Ready:
	XSTG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	XSTG A 1 A_Lower;
	Loop;
Select:
	XSTG A 1 A_Raise;
	Loop;
Fire:
	TNT1 A 0 NBC_CancelMagazineReload;
	TNT1 A 0 A_JumpIfInventory("NBC_PumpMagazine", 1, "FireShot");
	TNT1 A 0 A_JumpIfInventory("Shell", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
FireShot:
	XSTG A 3;
	XSTG A 0 A_FireBullets(5.6, 5.6, 8, 5, "NBC_ShellPuff");
	XSTG A 7 A_GunFlash;
	XSTG B 4;
	XSTG C 3 A_PlaySound("weapons/Xshotgr");
	XSTG DC 4;
	XSTG B 2;
	XSTG A 6 A_ReFire;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	TNT1 A 0 A_StartSound("nbc_shotgun_open", CHAN_7);
	Goto ReloadOpen;
ReloadOpen:
	XSTR AB 2 Offset(0, 42) A_WeaponReady(WRF_NOSECONDARY);
ReloadLoop:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadInsert");
	Goto ReloadClose;
ReloadInsert:
	XSTR C 2 Offset(0, 50) { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOSECONDARY); }
	XSTR D 2 Offset(0, 55) { NBC_AdjustReloadTics(2); A_WeaponReady(WRF_NOSECONDARY); }
	XSTR E 3 Offset(0, 60) { NBC_AdjustReloadTics(3); NBC_LoadOneShell(); A_StartSound("nbc_shotgun_load", CHAN_7); A_WeaponReady(WRF_NOSECONDARY); }
	XSTR F 3 Offset(0, 56) { NBC_AdjustReloadTics(3); A_WeaponReady(WRF_NOSECONDARY); }
	Goto ReloadLoop;
ReloadClose:
	XSTR GHIJ 1 Offset(0, 48);
	XSTR KLM 1 Offset(0, 36) A_StartSound("nbc_shotgun_close", CHAN_7);
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadRack");
	Goto ReloadCommit;
ReloadRack:
	XSTG C 12 A_PlaySound("weapons/Xshotgr");
ReloadCommit:
ReloadFinish:
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
Flash:
	XSTF A 3 bright A_Light2;
	TNT1 A 3 A_Light1;
	Goto LightDone;
}
}

class NBC_MicroUzi : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 32; }

Default
{
	Weapon.SlotNumber 4;
	Weapon.SelectionOrder 1200;
	Weapon.Kickback 100;
	Weapon.AmmoType1 "NBC_UziMagazine";
	Weapon.AmmoType2 "NBC_LightAmmo";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 32;
	Weapon.AmmoGive2 12;
	AttackSound "MicroUzi/Fire";
	Inventory.PickupMessage "You got the micro-uzi!";
	Obituary "%o was peppered by %k's micro-uzi.";
	Decal "BulletChip";
	Scale 0.75;
}

States
{
Spawn:
	MUZP A -1;
	Stop;
Ready:
	MUZI A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	MUZI A 1 A_Lower;
	Loop;
Select:
	MUZI A 1 A_Raise;
	Loop;
Fire:
	TNT1 A 0 A_JumpIfInventory("NBC_UziMagazine", 1, "FireShot");
	TNT1 A 0 A_JumpIfInventory("NBC_LightAmmo", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
FireShot:
	MUZI A 0 A_GunFlash;
	MUZI B 1 bright A_FireBullets(6, 4, -1, 4, "NBC_LightPuff");
	MUZI A 2;
	MUZI B 0 A_ReFire;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	TNT1 A 0 A_StartSound("B92REL1", CHAN_7);
	Goto ReloadDip;
ReloadDip:
	MUZI A 4 Offset(0, 44) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 4 Offset(0, 56) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 4 Offset(0, 68) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 4 Offset(0, 80) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 18 Offset(0, 92) { NBC_AdjustReloadTics(18); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadRack");
	Goto ReloadCommit;
ReloadRack:
	MUZI A 12 Offset(0, 92) { NBC_AdjustReloadTics(12); A_StartSound("B92REL3", CHAN_7); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
 	Goto ReloadCommit;
ReloadCommit:
	TNT1 A 0 A_StartSound("B92REL2", CHAN_7);
	TNT1 A 0 NBC_CommitMagazineReload;
ReloadFinish:
	MUZI A 4 Offset(0, 80) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 4 Offset(0, 68) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 4 Offset(0, 56) { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	MUZI A 2 Offset(0, 32) A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY);
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
Flash:
	TNT1 A 1 bright A_Light1;
	TNT1 A 0 bright A_Light2;
	TNT1 A 0 bright A_Light0;
	Stop;
}
}

class NBC_AK47 : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 30; }

Default
{
	Weapon.SlotNumber 5;
	Weapon.SelectionOrder 1100;
	Weapon.Kickback 100;
	Weapon.AmmoType1 "NBC_AKMagazine";
	Weapon.AmmoType2 "NBC_RifleAmmo";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 30;
	Weapon.AmmoGive2 12;
	AttackSound "Weapons/AK47FIR";
	Inventory.PickupMessage "You got the AK47 assault rifle!";
	Obituary "%o was begded down by %k's AK47.";
	Decal "BulletChip";
}

States
{
Spawn:
	AK4I A -1;
	Stop;
Ready:
	AK47 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	AK47 A 1 A_Lower;
	Loop;
Select:
	AK47 A 1 A_Raise;
	Loop;
Fire:
	TNT1 A 0 A_JumpIfInventory("NBC_AKMagazine", 1, "Burst");
	TNT1 A 0 A_JumpIfInventory("NBC_RifleAmmo", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
Burst:
	AK4F A 1 bright A_FireBullets(4.2, 2.5, -1, 4, "NBC_RiflePuff");
	AK47 A 2 Radius_Quake(1, 2, 0, 1, 0);
	AK4F B 1 bright
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (weapon && weapon.NBC_MagazineAmount() > 0)
			A_FireBullets(4.2, 2.5, -1, 4, "NBC_RiflePuff");
	}
	AK47 B 2 Radius_Quake(1, 2, 0, 1, 0);
	AK47 B 0 A_ReFire;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	Goto ReloadDip;
ReloadDip:
	AK47 A 6 Offset(0, 44) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 6 Offset(0, 56) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 6 Offset(0, 68) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 6 Offset(0, 80) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 18 Offset(0, 92) { NBC_AdjustReloadTics(18); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadRack");
	Goto ReloadCommit;
ReloadRack:
	AK47 A 15 Offset(0, 92) { NBC_AdjustReloadTics(15); A_StartSound("en/mgCOCK", CHAN_7); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
 	Goto ReloadCommit;
ReloadCommit:
	TNT1 A 0 NBC_CommitMagazineReload;
ReloadFinish:
	AK47 A 6 Offset(0, 80) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 6 Offset(0, 68) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 6 Offset(0, 56) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	AK47 A 3 Offset(0, 32) A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY);
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
Flash:
	TNT1 A 2 bright;
	Stop;
}
}

// The MP5kSD pack (Weapons/MP5kSD.zip; original DECORATE kept unused in actors/weapons/mp5ksd/): a suppressed
// machine pistol. Light rounds, 30 in the magazine. Altfire cycles auto, three-round burst and semi (tighter each
// step). Suppressed: its shots raise no alarm (off-guard gang members, clock.zs, don't hear it). The pack's own
// reloads: a tactical swap, and from empty the cocking handle and the slap.
class NBC_MP5Burst : Inventory { Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; } }
class NBC_MP5Semi : Inventory { Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; } }

class NBC_MP5kSD : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 30; }

Default
{
	Weapon.SlotNumber 4;
	Weapon.SelectionOrder 1150;
	Weapon.Kickback 60;
	Weapon.AmmoType1 "NBC_MP5Magazine";
	Weapon.AmmoType2 "NBC_LightAmmo";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 30;
	Weapon.AmmoGive2 12;
	Inventory.PickupMessage "You got the MP5K-SD!";
	Obituary "%o was mowed down by %k's MP5K-SD.";
	Tag "MP5K-SD";
	Decal "BulletChip";
	+WEAPON.NOALERT;
	+WEAPON.NOAUTOFIRE;
}

States
{
Spawn:
	MP5G A -1;
	Stop;
Ready:
	MP5A A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	MP5A A 1 A_Lower;
	MP5A AA 0 A_Lower;
	Loop;
Select:
	MP5A A 1 A_Raise;
	MP5A AA 0 A_Raise;
	Loop;
Fire:
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Magazine", 1, "FireMode");
	TNT1 A 0 A_JumpIfInventory("NBC_LightAmmo", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
FireMode:
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Semi", 1, "FireSemi");
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Burst", 1, "FireBurst");
FireAuto:
	MP5A B 1 bright { A_StartSound("MP5kSD/Fire", CHAN_WEAPON); A_FireBullets(3.5, 3.5, -1, 4, "NBC_LightPuff"); }
	MP5A CD 1;
	MP5A A 1 A_ReFire;
	Goto Ready;
FireBurst:
	MP5A B 1 bright { A_StartSound("MP5kSD/Fire", CHAN_WEAPON); A_FireBullets(1, 1, -1, 4, "NBC_LightPuff"); }
	MP5A C 1;
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Magazine", 1, 1);
	Goto BurstEnd;
	MP5A B 1 bright { A_StartSound("MP5kSD/Fire", CHAN_WEAPON); A_FireBullets(1, 1, -1, 4, "NBC_LightPuff"); }
	MP5A C 1;
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Magazine", 1, 1);
	Goto BurstEnd;
	MP5A B 1 bright { A_StartSound("MP5kSD/Fire", CHAN_WEAPON); A_FireBullets(1, 1, -1, 4, "NBC_LightPuff"); }
	MP5A C 1;
BurstEnd:
	MP5A D 1;
	MP5A A 3;
	Goto Ready;
FireSemi:
	MP5A B 1 bright { A_StartSound("MP5kSD/Fire", CHAN_WEAPON); A_FireBullets(0.5, 0.5, 1, 4, "NBC_LightPuff"); }
	MP5A CD 1;
	MP5A A 1;
	Goto Ready;
AltFire:
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Semi", 1, "ToAuto");
	TNT1 A 0 A_JumpIfInventory("NBC_MP5Burst", 1, "ToSemi");
	MP5A D 1 { A_StartSound("MP5kSD/Mode", CHAN_WEAPON); A_Print("Burst"); A_GiveInventory("NBC_MP5Burst", 1); }
	MP5A A 4;
	Goto Ready;
ToSemi:
	MP5A D 1 { A_StartSound("MP5kSD/Mode", CHAN_WEAPON); A_Print("Semi"); A_TakeInventory("NBC_MP5Burst", 1); A_GiveInventory("NBC_MP5Semi", 1); }
	MP5A A 4;
	Goto Ready;
ToAuto:
	MP5A D 1 { A_StartSound("MP5kSD/Mode", CHAN_WEAPON); A_Print("Auto"); A_TakeInventory("NBC_MP5Semi", 1); }
	MP5A A 4;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadEmpty");
	// the tactical swap: the old magazine out, the new one in
	MP5A A 2 NBC_AdjustReloadTics(2);
	MP5R ABC 2 NBC_AdjustReloadTics(2);
	TNT1 A 0 A_StartSound("MP5kSD/MagOut", CHAN_6);
	MP5R DEF 1;
	MP5R G 8 NBC_AdjustReloadTics(8);
	MP5R HIJ 1;
	TNT1 A 0 A_StartSound("MP5kSD/MagIn", CHAN_6);
	TNT1 A 0 NBC_CommitMagazineReload;
	MP5R C 5 NBC_AdjustReloadTics(5);
	Goto ReloadFinish;
ReloadEmpty:
	// from empty: the cocking handle back, the magazine, the slap
	MP5A A 2 NBC_AdjustReloadTics(2);
	MPCO AB 2 NBC_AdjustReloadTics(2);
	TNT1 A 0 A_StartSound("MP5kSD/Cock", CHAN_7);
	MPCO CDEF 2 NBC_AdjustReloadTics(2);
	MPCO G 6 NBC_AdjustReloadTics(6);
	MPCO H 1;
	MPER C 1;
	TNT1 A 0 A_StartSound("MP5kSD/MagOut", CHAN_6);
	MPER DEF 1;
	MPER G 8 NBC_AdjustReloadTics(8);
	MPER HIJ 1;
	TNT1 A 0 A_StartSound("MP5kSD/MagIn", CHAN_6);
	TNT1 A 0 NBC_CommitMagazineReload;
	MPCO H 1;
	MPCO G 2 NBC_AdjustReloadTics(2);
	MPSL AB 2 NBC_AdjustReloadTics(2);
	MPSL C 3 NBC_AdjustReloadTics(3);
	MPSL D 4 NBC_AdjustReloadTics(4);
	TNT1 A 0 A_StartSound("MP5kSD/Slap", CHAN_7);
	MPSL EF 1;
	MPCO G 7 NBC_AdjustReloadTics(7);
ReloadFinish:
	MP5R BA 2 NBC_AdjustReloadTics(2);
	MP5A A 1;
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
}
}

// The Vanilla M16 pack (Weapons/VanillaM16.zip; original DECORATE kept unused in actors/weapons/m16/): three-round
// bursts, fully automatic while the trigger's held. Rifle rounds, 30 in the magazine. The pack has no reload frames:
// the in-engine dip reload. The pack's 20-damage rounds are brought into line with the AK (rifle rounds, 5 x 1d3).
class NBC_M16 : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 30; }

	action void NBC_M16Round()
	{
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(invoker);
		if (!weapon || weapon.NBC_MagazineAmount() <= 0) return;
		A_StartSound("VM16/Fire", CHAN_WEAPON);
		A_GunFlash();
		A_FireBullets(2, 2, 1, 5, "NBC_RiflePuff");
		A_AlertMonsters();
	}

Default
{
	Weapon.SlotNumber 5;
	Weapon.SelectionOrder 1050;
	Weapon.Kickback 100;
	Weapon.AmmoType1 "NBC_M16Magazine";
	Weapon.AmmoType2 "NBC_RifleAmmo";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 30;
	Weapon.AmmoGive2 12;
	Inventory.PickupMessage "You got the M16 assault rifle!";
	Obituary "%o was mowed down by %k's M16.";
	Tag "M16";
	Decal "BulletChip";
}

States
{
Spawn:
	M16V A -1;
	Stop;
Ready:
	M16A A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	M16A A 1 A_Lower;
	Loop;
Select:
	M16A A 1 A_Raise;
	Loop;
Fire:
	TNT1 A 0 A_JumpIfInventory("NBC_M16Magazine", 1, "Burst");
	TNT1 A 0 A_JumpIfInventory("NBC_RifleAmmo", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
Burst:
	M16A B 3 bright NBC_M16Round;
	M16A C 3 bright NBC_M16Round;
	M16A D 3 bright NBC_M16Round;
	M16A E 1 A_ReFire;
	M16A A 4;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
ReloadDip:
	M16A A 6 Offset(0, 44) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 6 Offset(0, 56) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 6 Offset(0, 68) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 6 Offset(0, 80) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 18 Offset(0, 92) { NBC_AdjustReloadTics(18); A_StartSound("B92REL1", CHAN_7); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadRack");
	Goto ReloadCommit;
ReloadRack:
	M16A A 15 Offset(0, 92) { NBC_AdjustReloadTics(15); A_StartSound("en/mgCOCK", CHAN_7); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	Goto ReloadCommit;
ReloadCommit:
	TNT1 A 0 A_StartSound("B92REL2", CHAN_7);
	TNT1 A 0 NBC_CommitMagazineReload;
ReloadFinish:
	M16A A 6 Offset(0, 80) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 6 Offset(0, 68) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 6 Offset(0, 56) { NBC_AdjustReloadTics(6); A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY); }
	M16A A 3 Offset(0, 32) A_WeaponReady(WRF_NOFIRE|WRF_NOSECONDARY);
	TNT1 A 0 NBC_EndMagazineReload;
	Goto Ready;
Flash:
	TNT1 A 2 bright A_Light1;
	TNT1 A 0 bright A_Light0;
	Stop;
}
}

// The Super Shorty pack (Weapons/SuperShorty.zip): a three-shot sawn-off pump. Pumps after every shot, loads shell by
// shell (the trigger cuts a reload short), and a dry gun is pumped after its first shell goes in.
class NBC_SuperShorty : NBC_ReloadWeapon
{
	override int NBC_BaseMagazineSize() { return 3; }

Default
{
	Weapon.SlotNumber 3;
	Weapon.SelectionOrder 1250;
	Weapon.Kickback 400;
	Weapon.AmmoType1 "NBC_ShortyMagazine";
	Weapon.AmmoType2 "Shell";
	Weapon.AmmoUse1 1;
	Weapon.AmmoUse2 0;
	Weapon.AmmoGive1 3;
	Weapon.AmmoGive2 5;
	Inventory.PickupMessage "You got the Super Shorty!";
	Obituary "%o caught both barrels of %k's Super Shorty. Well, all three.";
	Tag "Super Shorty";
	Decal "BulletChip";
	+WEAPON.NOAUTOFIRE;
}

States
{
Spawn:
	SERC A -1;
	Stop;
Ready:
	SERB A 1 A_WeaponReady(WRF_ALLOWRELOAD);
	Loop;
Deselect:
	TNT1 A 0 NBC_CancelMagazineReload;
	SERB A 1 A_Lower;
	SERB AA 0 A_Lower;
	Loop;
Select:
	SERB A 1 A_Raise;
	SERB AA 0 A_Raise;
	Loop;
Fire:
	TNT1 A 0 NBC_CancelMagazineReload;
	TNT1 A 0 A_JumpIfInventory("NBC_ShortyMagazine", 1, "FireShot");
	TNT1 A 0 A_JumpIfInventory("Shell", 1, "Reload");
	TNT1 A 0 NBC_DryClick;
	Goto Ready;
FireShot:
	SERF A 1 bright { A_GunFlash(); A_StartSound("SuperShorty/Fire", CHAN_WEAPON); A_FireBullets(8.5, 8.5, 9, 8, "NBC_ShellPuff"); }
	SERF B 1 bright;
	SERF CD 2;
	TNT1 A 0 A_JumpIfInventory("NBC_ShortyMagazine", 1, "FirePump");
	SERB A 4;
	TNT1 A 0 A_JumpIfInventory("Shell", 1, "Reload");
	Goto Ready;
FirePump:
	SERB A 8;
	SERB BC 1;
	SERB D 1 A_StartSound("SuperShorty/PumpBack", CHAN_6);
	SERB FE 2;
	SERB D 2 A_StartSound("SuperShorty/PumpForward", CHAN_7);
	SERB CB 2;
	SERB A 0 A_ReFire;
	Goto Ready;
Reload:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadBegin");
	TNT1 A 0 NBC_ReloadReject;
	Goto Ready;
ReloadBegin:
	TNT1 A 0 NBC_BeginMagazineReload;
	SERB ABCD 1;
	SERR AB 1;
ReloadLoop:
	TNT1 A 0 A_JumpIf(invoker.NBC_CanReload(), "ReloadInsert");
	Goto ReloadFinish;
ReloadInsert:
	TNT1 A 0 A_StartSound("SuperShorty/Load", CHAN_WEAPON);
	SERR C 2 NBC_AdjustReloadTics(2);
	SERR D 2 NBC_AdjustReloadTics(2);
	SERR E 2 { NBC_AdjustReloadTics(2); NBC_LoadOneShell(); }
	TNT1 A 0 A_JumpIf(invoker.nbcReloadWasEmpty, "ReloadDryPump");
	SERR B 4 { NBC_AdjustReloadTics(4); A_WeaponReady(WRF_NOBOB | WRF_NOSWITCH | WRF_NOSECONDARY); }
	Goto ReloadLoop;
ReloadDryPump:
	TNT1 A 0 { invoker.nbcReloadWasEmpty = false; }
	SERR B 3;
	SERR BA 2;
	SERB D 1;
	SERB D 1 A_StartSound("SuperShorty/PumpBack", CHAN_6);
	SERB F 2;
	SERB E 1;
	SERB E 1 A_StartSound("SuperShorty/PumpForward", CHAN_7);
	SERB D 3;
	SERR AB 2;
	SERR B 5;
	Goto ReloadLoop;
ReloadFinish:
	TNT1 A 0 NBC_EndMagazineReload;
	SERR A 1;
	SERB DCBA 2;
	Goto Ready;
Flash:
	TNT1 A 2 bright A_Light2;
	TNT1 A 2 A_Light1;
	Goto LightDone;
}
}
