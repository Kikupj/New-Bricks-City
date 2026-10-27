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
