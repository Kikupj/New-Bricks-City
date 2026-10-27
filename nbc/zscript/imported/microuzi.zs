Class MicroUzi : Weapon
{
Default
{
  obituary "%o was peppered by %k's micro-uzi.";
  radius 20;
  height 16;
  attacksound "MicroUzi/Fire";
  inventory.pickupmessage "You got the micro-uzi!";
  weapon.kickback 100;
  weapon.ammotype "NBC_LightAmmo"; // NBC: use the shared light reserve.
  weapon.ammouse 1;
  weapon.ammogive 40;
  Decal "BulletChip";
  Weapon.SlotNumber 4; // NBC: dedicated Uzi slot.
  Scale 0.75;
  }
  states
  {
  Ready:
    MUZI A 1 A_WeaponReady;
    loop;
  Deselect: 
    MUZI A 1 A_Lower;
    loop;
  Select:
    MUZI A 1 A_Raise;
    loop;
  Fire:
    MUZI A 0 A_GunFlash;
    MUZI B 1 bright A_FireBullets (6, 4, -1, 4, "BulletPuff");
    MUZI A 2;
    MUZI B 0 A_ReFire;
    goto Ready;
  Flash:
    TNT1 A 1 bright A_Light1;
    TNT1 A 0 bright A_Light2;
    TNT1 A 0 bright A_Light0;
    stop;
  Spawn:
    MUZP A -1;
    stop;
  }
}

// NBC: The pack-specific UziAmmo/UziAmmo2 classes were removed; all Uzi ammo uses NBC_LightAmmo.
