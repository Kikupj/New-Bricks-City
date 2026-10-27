// =============================================================================
// Corpo Wars — Quartermaster gear: catalogue, weapons, gadgets, gear menu
// =============================================================================
// ------------------------------------------------------------------ suppressor support
// Any weapon that mixes this in and has a "ToggleSuppressor" state can take the universal Suppressor.
mixin class CW_Suppressible
{
	bool cwSuppressed;
	action void CW_FlipSuppressor()
	{
		invoker.cwSuppressed = !invoker.cwSuppressed;
		A_StartSound("cw/tranq/open", CHAN_7, 0, 0.6);
	}
}

// ------------------------------------------------------------------ weapons
// Sprites/sounds: DeePayback Weapons (see CREDITS.txt). Balancing is Corpo Wars' own.

// Company-issue service pistol: 12-round magazine, reserve is standard Clip ammo.
// Inherits Pistol so it keeps slot 2, the muzzle flash and the loud-gunfire noise rule.
class CW_PistolMag : Ammo
{
	Default { Inventory.MaxAmount 12; +INVENTORY.IGNORESKILL; Inventory.Icon "Z9MMA0"; }
}

class CW_ServicePistol : Pistol
{
	mixin CW_Suppressible;
	const MAG = 12;
	Default
	{
		Weapon.SlotNumber 2;
		Weapon.SelectionOrder 1900;
		Weapon.AmmoType1 "CW_PistolMag";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType2 "Clip";
		Weapon.AmmoUse2 0;
		Weapon.AmmoGive2 0;
		+WEAPON.AMMO_OPTIONAL;
		Tag "Service pistol";
	}

	action void CW_ReloadServiceMag()
	{
		let loaded = invoker.owner.FindInventory("CW_PistolMag");
		int need = CW_ServicePistol.MAG - (loaded ? loaded.Amount : 0);
		int take = min(need, invoker.owner.CountInv("Clip"));
		if (take <= 0) return;
		invoker.owner.TakeInventory("Clip", take);
		invoker.owner.GiveInventory("CW_PistolMag", take);
	}

	States
	{
	Spawn:
		GLCK H -1;
		Stop;
	Select:
		GLCK A 1 A_Raise;
		Loop;
	Deselect:
		GLCK A 1 A_Lower;
		Loop;
	Ready:
		GLCK A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Fire:
		GLCK A 0 A_JumpIfNoAmmo("Reload");
		GLCK A 0 A_JumpIf(invoker.cwSuppressed, "FireSilenced");
		GLCK B 1 Bright
		{
			A_FireBullets(2.5, 0, -1, 12, "BulletPuff", FBF_USEAMMO | FBF_NORANDOM);
			A_StartSound("cw/pistol/fire", CHAN_WEAPON);
		}
		GLCK C 1;
		GLCK D 2;
		GLCK E 2;
		GLCK A 5;
		GLCK A 0 A_ReFire;
		Goto Ready;
	FireSilenced:
		GLCK C 1
		{
			A_FireBullets(2.2, 0, -1, 11, "BulletPuff", FBF_USEAMMO | FBF_NORANDOM | FBF_NOFLASH);
			A_StartSound("cw/sd/fire", CHAN_WEAPON, 0, 0.8);
			CW_Handler.EmitNoise(self, pos, 220, 0.4);
		}
		GLCK D 2;
		GLCK E 2;
		GLCK A 5;
		GLCK A 0 A_ReFire;
		Goto Ready;
	Flash:
		TNT1 A 2 A_Light1;
		Goto LightDone;
	ToggleSuppressor:
		GLCK A 1 Offset(0, 38);
		GLCK A 1 Offset(0, 50);
		GLCK A 1 Offset(0, 64);
		GLCK A 1 Offset(0, 80);
		GLCK A 14 Offset(2, 82) CW_FlipSuppressor();
		GLCK E 2 Offset(0, 72);
		GLCK E 2 Offset(0, 58);
		GLCK D 3 Offset(0, 44);
		GLCK D 3 Offset(0, 36);
		GLCK A 2 Offset(0, 32);
		Goto Ready;
	Reload:
		GLCK A 0 A_JumpIf(CountInv("CW_PistolMag") >= CW_ServicePistol.MAG || CountInv("Clip") <= 0, "Ready");
		GLCK A 1 Offset(0, 38) A_StartSound("cw/sd/reload", CHAN_WEAPON);
		GLCK A 1 Offset(0, 50);
		GLCK A 1 Offset(0, 64);
		GLCK A 1 Offset(0, 80);
		GLCK A 16 Offset(2, 82) CW_ReloadServiceMag();
		GLCK E 2 Offset(0, 72) A_StartSound("cw/sd/slide", CHAN_7);
		GLCK E 2 Offset(0, 58);
		GLCK D 3 Offset(0, 44);
		GLCK D 3 Offset(0, 36);
		GLCK A 2 Offset(0, 32);
		Goto Ready;
	}
}

// ------------------------------------------------------------------ loud guns (placeholders)
// Pump shotgun: Freedoom sprites/sounds. 6-shell tube, shell-by-shell reload you can interrupt by firing.
class CW_ShellTube : Ammo
{
	Default { Inventory.MaxAmount 6; +INVENTORY.IGNORESKILL; Inventory.Icon "SHELA0"; }
}

class CW_Shotgun : Shotgun
{
	const TUBE = 6;
	Default
	{
		Weapon.SlotNumber 3;
		Weapon.SelectionOrder 1300;
		Weapon.AmmoType1 "CW_ShellTube";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType2 "Shell";
		Weapon.AmmoUse2 0;
		Weapon.AmmoGive2 0;
		+WEAPON.AMMO_OPTIONAL;
		Tag "Pump shotgun";
	}

	action void CW_LoadShell()
	{
		if (CountInv("Shell") <= 0 || CountInv("CW_ShellTube") >= CW_Shotgun.TUBE) return;
		TakeInventory("Shell", 1);
		GiveInventory("CW_ShellTube", 1);
		A_StartSound("misc/ammo_pkup", CHAN_7, 0, 0.5);
	}

	States
	{
	Spawn:
		DNSP A -1;
		Stop;
	Select:
		DNSG A 1 A_Raise;
		Loop;
	Deselect:
		DNSG A 1 A_Lower;
		Loop;
	Ready:
		DNSG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Fire:
		DNSG A 0 A_JumpIfNoAmmo("Reload");
		DNSG A 3;
		DNSG B 1
		{
			A_FireBullets(5.0, 0, 8, 6, "BulletPuff", FBF_USEAMMO | FBF_NORANDOM);
			A_StartSound("cw/shotgun/fire", CHAN_WEAPON);
			A_ZoomFactor(0.98, ZOOM_NOSCALETURNING);
		}
		DNSG C 1 Bright A_ZoomFactor(1.0, ZOOM_NOSCALETURNING);
		DNSG DE 1 Bright;
		DNSG MNO 1;
		DNSG A 3;
		DNSG FGH 1;
		DNSG I 2 A_StartSound("cw/shotgun/pump", CHAN_7);
		DNSG JKLKJI 2;
		DNSG HGF 1;
		DNSG A 7 A_ReFire;
		Goto Ready;
	Flash:
		TNT1 A 2 A_Light1;
		TNT1 A 2 A_Light2;
		Goto LightDone;
	Reload:
		DNSG A 0 A_JumpIf(CountInv("CW_ShellTube") >= CW_Shotgun.TUBE || CountInv("Shell") <= 0, "Ready");
		DNSG A 2 Offset(0, 40);
		DNSG A 2 Offset(0, 50);
	ReloadLoop:
		DNSG A 9 Offset(0, 56) CW_LoadShell();
		DNSG A 0 A_JumpIf(CountInv("CW_ShellTube") >= CW_Shotgun.TUBE || CountInv("Shell") <= 0, "ReloadEnd");
		DNSG A 0 A_WeaponReady(WRF_NOBOB | WRF_NOSWITCH | WRF_NOSECONDARY);   // fire interrupts
		Goto ReloadLoop;
	ReloadEnd:
		DNSG A 2 Offset(0, 44);
		DNSG A 2 Offset(0, 36);
		DNSG FGH 1 Offset(0, 32);
		DNSG I 2 A_StartSound("cw/shotgun/pump", CHAN_7);
		DNSG JKLKJI 2;
		DNSG HGF 1;
		Goto Ready;
	}
}

// Submachine gun: DeePayback MP5 sprites/sounds (see CREDITS.txt). 30-round mag, 9mm reserve.
class CW_SMGMag : Ammo
{
	Default { Inventory.MaxAmount 30; +INVENTORY.IGNORESKILL; Inventory.Icon "Z9MMA0"; }
}

class CW_SMG : Weapon
{
	mixin CW_Suppressible;
	const MAG = 30;
	Default
	{
		Weapon.SlotNumber 4;
		Weapon.SelectionOrder 1200;
		Weapon.AmmoType1 "CW_SMGMag";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType2 "Clip";
		Weapon.AmmoUse2 0;
		Weapon.AmmoGive2 0;
		+WEAPON.AMMO_OPTIONAL;
		+WEAPON.NOALERT;
		Tag "Submachine gun";
		Obituary "%o was hosed down by %k.";
	}

	action void CW_ReloadSMG()
	{
		int need = CW_SMG.MAG - CountInv("CW_SMGMag");
		int take = min(need, CountInv("Clip"));
		if (take <= 0) return;
		TakeInventory("Clip", take);
		GiveInventory("CW_SMGMag", take);
	}

	States
	{
	Spawn:
		MP5I A -1;
		Stop;
	Select:
		MP5K A 1 A_Raise;
		Loop;
	Deselect:
		MP5K A 1 A_Lower;
		Loop;
	Ready:
		MP5K A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Fire:
		MP5K A 0 A_JumpIfNoAmmo("Reload");
		MP5K A 0 A_JumpIf(invoker.cwSuppressed, "FireSilenced");
		MP5F A 1 Bright
		{
			A_FireBullets(2.4, 1.2, -1, 8, "BulletPuff", FBF_USEAMMO | FBF_NORANDOM);
			A_StartSound("cw/smg/fire", CHAN_WEAPON);
			A_ZoomFactor(0.99, ZOOM_NOSCALETURNING);
			A_Light2();
		}
		MP5K B 1 A_Light1;
		MP5K A 1
		{
			A_ZoomFactor(1.0, ZOOM_NOSCALETURNING);
			A_SetPitch(pitch - 0.4);
			A_Light0();
		}
		MP5K A 0 A_ReFire;
		Goto Ready;
	FireSilenced:
		MP5F A 1
		{
			A_FireBullets(2.4, 1.2, -1, 7, "BulletPuff", FBF_USEAMMO | FBF_NORANDOM | FBF_NOFLASH);
			A_StartSound("cw/smg/silenced", CHAN_WEAPON, 0, 0.8);
			A_ZoomFactor(0.995, ZOOM_NOSCALETURNING);
			CW_Handler.EmitNoise(self, pos, 260, 0.4);
		}
		MP5K B 1;
		MP5K A 1
		{
			A_ZoomFactor(1.0, ZOOM_NOSCALETURNING);
			A_SetPitch(pitch - 0.3);
		}
		MP5K A 0 A_ReFire;
		Goto Ready;
	Flash:
		TNT1 A 1;
		Stop;
	ToggleSuppressor:
		MP5K A 1 Offset(0, 38);
		MP5K A 1 Offset(0, 48);
		MP5K A 1 Offset(0, 60);
		MP5K A 1 Offset(0, 74);
		MP5K A 14 Offset(2, 84) CW_FlipSuppressor();
		MP5K A 2 Offset(0, 72);
		MP5K A 2 Offset(0, 58);
		MP5K B 4 Offset(0, 44);
		MP5K A 3 Offset(0, 36);
		MP5K A 2 Offset(0, 32);
		Goto Ready;
	Reload:
		MP5K A 0 A_JumpIf(CountInv("CW_SMGMag") >= CW_SMG.MAG || CountInv("Clip") <= 0, "Ready");
		MP5K A 1 Offset(0, 38) A_StartSound("cw/smg/mag", CHAN_WEAPON);
		MP5K A 1 Offset(0, 48);
		MP5K A 1 Offset(0, 60);
		MP5K A 1 Offset(0, 74);
		MP5K A 18 Offset(2, 84) CW_ReloadSMG();
		MP5K A 2 Offset(0, 72);
		MP5K A 2 Offset(0, 58);
		MP5K B 4 Offset(0, 44) A_StartSound("cw/smg/bolt", CHAN_7);
		MP5K A 3 Offset(0, 36);
		MP5K A 2 Offset(0, 32);
		Goto Ready;
	}
}

// Bolt-action tranquilizer rifle: one dart loaded, bolt cycle between shots.
// AltFire toggles the scope.
class CW_TranqDart : Ammo
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 12;
		Inventory.Icon "ZDRTA0";
		Tag "Tranq darts";
	}
	States { Spawn: ZDRT A -1; Stop; }
}

class CW_TranqGun : Weapon
{
	bool scoped;
	Default
	{
		Weapon.SlotNumber 3;
		Weapon.AmmoType "CW_TranqDart";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 0;
		Weapon.SelectionOrder 3000;
		+WEAPON.NOALERT;
		+WEAPON.NOAUTOFIRE;
		Tag "Tranquilizer rifle";
	}

	action void CW_Unscope()
	{
		if (invoker.scoped) { invoker.scoped = false; A_ZoomFactor(1.0); }
	}

	States
	{
	Spawn:
		SRIL A -1;
		Stop;
	Select:
		SPRF A 1 A_Raise;
		Loop;
	Deselect:
		SPRF A 0 CW_Unscope();
		SPRF A 1 A_Lower;
		Wait;
	Ready:
		SPRF A 0 A_JumpIf(invoker.scoped, "ReadyScoped");
		SPRF A 1 A_WeaponReady;
		Loop;
	ReadyScoped:
		SNPS A 1 A_WeaponReady;
		Goto Ready;
	Fire:
		SPRF A 0 A_JumpIf(invoker.scoped, "FireScoped");
		SRIF B 2
		{
			A_FireProjectile("CW_Dart");
			A_StartSound("cw/tranq/fire", CHAN_WEAPON, 0, 0.35, ATTN_NORM, 1.4);
			CW_Handler.EmitNoise(self, pos, 120, 0.3);
		}
		SPRF A 4;
		Goto Cycle;
	FireScoped:
		SNPS A 3
		{
			A_FireProjectile("CW_Dart");
			A_StartSound("cw/tranq/fire", CHAN_WEAPON, 0, 0.35, ATTN_NORM, 1.4);
			CW_Handler.EmitNoise(self, pos, 120, 0.3);
		}
		SNPS A 30 A_StartSound("cw/tranq/bolt", CHAN_7);
		Goto Ready;
	Cycle:
		SPRF BC 3;
		SPRF D 3 A_StartSound("cw/tranq/bolt", CHAN_7);
		SPRF E 3;
		SPRF F 5;
		SPRF EDG 3;
		SPRF CB 3;
		SPRF A 3;
		Goto Ready;
	AltFire:
		SPRF A 0
		{
			invoker.scoped = !invoker.scoped;
			A_ZoomFactor(invoker.scoped ? 4.0 : 1.0);
			A_StartSound("cw/tranq/open", CHAN_7, 0, 0.4);
		}
		SPRF A 8;
		Goto Ready;
	}
}

class CW_Dart : Actor
{
	Default
	{
		Projectile;
		Radius 3;
		Height 4;
		Speed 55;
		Damage 1;
		DamageType "Tranq";
		Scale 0.6;
		+NODAMAGETHRUST;
		+BLOODLESSIMPACT;
	}
	States
	{
	Spawn:
		ZDRT B -1;
		Stop;
	Death:
		TNT1 A 1;
		Stop;
	}
}

// ------------------------------------------------------------------ thrown gadgets
class CW_Thrown : Actor
{
	Default
	{
		Projectile;
		-NOGRAVITY;
		+NOBLOCKMONST;
		Gravity 0.6;
		Radius 4;
		Height 4;
		Speed 22;
		Damage 0;
		Scale 0.5;
		BounceType "Doom";
		BounceCount 3;
		BounceFactor 0.4;
		BounceSound "plats/pt1_stop";
	}
}

class CW_ThrownNoisemaker : CW_Thrown
{
	States
	{
	Spawn:
		CWC4 A -1;
		Stop;
	Death:
		CWC4 A 1
		{
			A_StartSound("plats/pt1_stop", CHAN_BODY, 0, 1.0, 0.6);
			CW_Handler.EmitNoise(null, pos, 650, 0.6);
		}
		CWC4 A 15 A_StartSound("plats/pt1_stop", CHAN_5, 0, 0.8, 0.6);
		CWC4 A 20 A_StartSound("plats/pt1_stop", CHAN_6, 0, 0.6, 0.6);
		CWC4 A 1 A_FadeOut(0.05);
		Wait;
	}
}

class CW_ThrownFlashbang : CW_Thrown
{
	States
	{
	Spawn:
		CWC3 A -1;
		Stop;
	Death:
		TNT1 A 0
		{
			A_StartSound("world/barrelx", CHAN_BODY, 0, 0.8);
			A_SetScale(1.2);
			let it = ThinkerIterator.Create("Actor");
			Actor a;
			while (a = Actor(it.Next()))
			{
				if (a.health <= 0 || Distance3D(a) > 420) continue;
				if (!a.CheckSight(self, SF_IGNOREVISIBILITY)) continue;
				let g = CW_Guard(a);
				if (g) g.Stun(35 * 5, pos);
				let cv = CW_Civilian(a);
				if (cv) cv.Panic(pos);
			}
			CW_Handler.EmitNoise(null, pos, 900, 1.0);
		}
		MISL B 4 Bright;
		MISL C 4 Bright;
		MISL D 4 Bright;
		Stop;
	}
}

// ------------------------------------------------------------------ hub: quartermaster
class CW_GearLocker : CW_Interactable
{
	Default
	{
		Radius 42;
		Height 42;
		Tag "Quartermaster";
	}
	override String GetPrompt(Actor user) { return "Quartermaster: gear & loadout"; }
	override void Interact(Actor user)
	{
		A_StartSound("switches/normbutn");
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		if (h) h.gearRequests++;
	}
	States { Spawn: CWWB A -1; Stop; }
}

// ------------------------------------------------------------------ Quartermaster / Transport menu
// LOADOUT: drag items between Locker (list), Transport (grid) and Personal (grid).
// SHOP: buy items into the locker. In the field (at the transport) only the two grids show.
class CW_GearMenu : CW_UiMenu
{
	bool inField;
	int tab;                     // 0 loadout, 1 shop
	double tabX[2], tabW[2], tabY, tabH;
	// shop
	int scur;
	double shopY0, shopH;
	// loadout layout (from last draw)
	double gx[3], gy[3], cs;
	double lockX, lockY, lockW, lockH, lockRowH;
	int lockScroll;
	Array<int> lockRows;
	// drag state
	int held, heldRot, grabX, grabY;
	double mx, my;
	int hover;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		DontDim = true;
		held = -1;
		hover = -1;
		MenuSound("menu/activate");
	}

	// ------------------------------------------------------------------ helpers
	void Icon(String name, double x, double y, double w, double h, double alpha = 1.0)
	{
		TextureID t = TexMan.CheckForTexture(name, TexMan.Type_Any);
		if (!t.IsValid()) t = TexMan.CheckForTexture(name, TexMan.Type_Sprite);
		if (!t.IsValid()) return;
		int texW, texH;
		[texW, texH] = TexMan.GetSize(t);
		if (texW <= 0 || texH <= 0) return;
		double k = min(w / texW, h / texH) * 0.88;
		double dw = texW * k, dh = texH * k;
		Screen.DrawTexture(t, false, x + (w - dw) / 2, y + (h - dh) / 2,
			DTA_DestWidthF, dw, DTA_DestHeightF, dh, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_Alpha, alpha);
	}

	int ItemAt(int c, double px, double py)
	{
		let l = Ledger();
		if (!l || cs <= 0) return -1;
		for (int i = 0; i < l.ItemCount(); i++)
		{
			if (l.itCont[i] != c || i == held) continue;
			double x0 = gx[c] + l.itX[i] * cs, y0 = gy[c] + l.itY[i] * cs;
			if (px >= x0 && px < x0 + l.ItW(i) * cs && py >= y0 && py < y0 + l.ItH(i) * cs) return i;
		}
		return -1;
	}

	bool InGrid(int c, double px, double py)
	{
		let l = Ledger();
		return l && px >= gx[c] && py >= gy[c] && px < gx[c] + l.GridW(c) * cs && py < gy[c] + l.GridH(c) * cs;
	}

	int HeldW() { let l = Ledger(); return heldRot ? CW_Items.H(l.itType[held]) : CW_Items.W(l.itType[held]); }
	int HeldH() { let l = Ledger(); return heldRot ? CW_Items.W(l.itType[held]) : CW_Items.H(l.itType[held]); }

	// top-left target cell for the held item over grid c
	int TargetX(int c) { return int(floor((mx - gx[c]) / cs)) - min(grabX, HeldW() - 1); }
	int TargetY(int c) { return int(floor((my - gy[c]) / cs)) - min(grabY, HeldH() - 1); }

	void Rotate()
	{
		if (held < 0) return;
		heldRot ^= 1;
		int t = grabX; grabX = grabY; grabY = t;
		MenuSound("menu/cursor");
	}

	// ------------------------------------------------------------------ input
	override bool OnUIEvent(UIEvent ev)
	{
		if ((ev.Type == UIEvent.Type_KeyDown || ev.Type == UIEvent.Type_Char) && (ev.KeyChar == 114 || ev.KeyChar == 82))
		{
			Rotate();
			return true;
		}
		if (ev.Type == UIEvent.Type_RButtonDown) { Rotate(); return true; }
		if (ev.Type == UIEvent.Type_WheelUp)   { lockScroll = max(0, lockScroll - 1); return true; }
		if (ev.Type == UIEvent.Type_WheelDown) { lockScroll++; return true; }
		return Super.OnUIEvent(ev);
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		switch (mkey)
		{
		case MKEY_Left: case MKEY_Right:
			if (!inField && held < 0) { tab ^= 1; MenuSound("menu/change"); }
			return true;
		case MKEY_Up:   if (tab == 1) { scur = max(0, scur - 1); MenuSound("menu/cursor"); } return true;
		case MKEY_Down: if (tab == 1) { scur = min(ShopCount() - 1, scur + 1); MenuSound("menu/cursor"); } return true;
		case MKEY_Enter: if (tab == 1) Buy(); return true;
		case MKEY_Back:
			if (held >= 0) { held = -1; SetMouseCapture(false); return true; }
			break;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		mx = x; my = y;
		let l = Ledger();
		if (!l) return true;

		if (type == MOUSE_Click && !inField && held < 0 && y >= tabY && y <= tabY + tabH)
		{
			for (int t = 0; t < 2; t++) if (x >= tabX[t] && x <= tabX[t] + tabW[t]) { tab = t; MenuSound("menu/change"); }
			return true;
		}

		if (tab == 1)
		{
			if (shopH > 0 && y >= shopY0)
			{
				int r = int((y - shopY0) / shopH);
				if (r >= 0 && r < ShopCount()) { scur = r; if (type == MOUSE_Release) Buy(); return true; }
			}
			if (type == MOUSE_Release && x >= btnX && x <= btnX + btnW && y >= btnY && y <= btnY + btnH) Buy();
			return true;
		}

		// ---- loadout: hover
		hover = -1;
		for (int c = 1; c <= 2 && hover < 0; c++) hover = ItemAt(c, x, y);
		if (hover < 0 && !inField && x >= lockX && x < lockX + lockW && y >= lockY && lockRowH > 0)
		{
			int r = int((y - lockY) / lockRowH) + lockScroll;
			if (r >= 0 && r < lockRows.Size()) hover = lockRows[r];
		}

		if (type == MOUSE_Click && held < 0 && hover >= 0)
		{
			held = hover;
			heldRot = l.itRot[held];
			grabX = grabY = 0;
			int c = l.itCont[held];
			if (c > 0)
			{
				grabX = int((x - (gx[c] + l.itX[held] * cs)) / cs);
				grabY = int((y - (gy[c] + l.itY[held] * cs)) / cs);
			}
			SetMouseCapture(true);
			MenuSound("menu/cursor");
		}
		else if (type == MOUSE_Release && held >= 0)
		{
			bool done = false;
			for (int c = 1; c <= 2 && !done; c++)
			{
				if (!InGrid(c, x, y)) continue;
				int tx = TargetX(c), ty = TargetY(c);
				if (l.Fits(c, tx, ty, HeldW(), HeldH(), held))
				{
					EventHandler.SendNetworkEvent("cw_move", held, c, tx | (ty << 8) | (heldRot << 16));
					MenuSound("menu/choose");
				}
				else MenuSound("menu/invalid");
				done = true;
			}
			if (!done && !inField && x >= lockX && x < lockX + lockW && y >= lockY - 30 && y < lockY + lockH)
			{
				EventHandler.SendNetworkEvent("cw_move", held, 0, 0);
				MenuSound("menu/choose");
			}
			held = -1;
			SetMouseCapture(false);
		}
		return true;
	}

	// ------------------------------------------------------------------ shop
	int ShopCount() { int n = 0; for (int t = 0; t < CW_Items.IT_COUNT; t++) if (CW_Items.Price(t) > 0) n++; return n; }
	int ShopItem(int row)
	{
		for (int t = 0; t < CW_Items.IT_COUNT; t++)
		{
			if (CW_Items.Price(t) <= 0) continue;
			if (row == 0) return t;
			row--;
		}
		return 0;
	}

	bool CanBuy(int t)
	{
		let l = Ledger();
		if (!l || l.missionActive) return false;
		int pr = l.ShopPrice(t);
		if (pr <= 0 || l.budget < pr) return false;
		return !(CW_Items.Unique(t) && l.CountAll(t) > 0);
	}

	void Buy()
	{
		int t = ShopItem(scur);
		if (!CanBuy(t)) { MenuSound("menu/invalid"); return; }
		EventHandler.SendNetworkEvent("cw_buy", t);
		MenuSound("menu/choose");
	}

	// ------------------------------------------------------------------ drawing
	override void Drawer()
	{
		Super.Drawer();
		double sw = Screen.GetWidth(), sh = Screen.GetHeight();
		s = max(1.0, sh / 540.0);
		Color amber = Color(240, 170, 40), line = Color(45, 55, 70);
		Box(0, 0, sw, sh, Color(0, 0, 0), 0.65);

		double ww = min(sw * 0.94, 1080 * s), wh = min(sh * 0.9, 560 * s);
		double wx = (sw - ww) / 2, wy = (sh - wh) / 2, pad = 14 * s;
		Box(wx, wy, ww, wh, Color(8, 12, 18), 0.96);
		TextureID art = TexMan.CheckForTexture("CWGEARWL", TexMan.Type_Any);
		if (art.IsValid()) Screen.DrawTexture(art, false, wx, wy, DTA_DestWidthF, ww, DTA_DestHeightF, wh, DTA_Alpha, 0.08);
		Box(wx, wy, ww, 3 * s, amber);

		let l = Ledger();
		double y = wy + pad;
		Txt(wx + pad, y, inField ? "TRANSPORT  //  FIELD RESUPPLY" : "MERIDIAN HOLDINGS  //  QUARTERMASTER", Font.CR_GOLD);
		if (l)
		{
			String bud = "Budget  " .. CW_Handler.Money(l.budget);
			Txt(wx + ww - pad - TW(bud), y, bud, Font.CR_GREEN);
		}
		y += LH() + 6 * s;
		Box(wx + pad, y, ww - pad * 2, max(1.0, s), line);
		y += 10 * s;
		if (!l) return;

		if (!inField)
		{
			static const String tn[] = { "LOADOUT", "SHOP" };
			double tx = wx + pad;
			tabY = y; tabH = LH() + 8 * s;
			for (int t = 0; t < 2; t++)
			{
				tabX[t] = tx; tabW[t] = TW(tn[t]) + 24 * s;
				Box(tx, tabY, tabW[t], tabH, t == tab ? Color(30, 38, 52) : Color(14, 18, 26));
				if (t == tab) Box(tx, tabY + tabH - 2 * s, tabW[t], 2 * s, amber);
				Txt(tx + 12 * s, tabY + 4 * s + 1, tn[t], t == tab ? Font.CR_GOLD : Font.CR_DARKGRAY);
				tx += tabW[t] + 6 * s;
			}
			String hint = tab == 0 ? "DRAG  move    R / RIGHT-CLICK  rotate    ESC  close" : "UP/DOWN  select    ENTER  buy    ESC  close";
			Txt(wx + ww - pad - TW(hint), tabY + 4 * s + 1, hint, Font.CR_DARKGRAY);
			y = tabY + tabH + 10 * s;
		}
		else
		{
			String hint = "DRAG  move between transport and your kit    R  rotate    ESC  close";
			Txt(wx + pad, y, hint, Font.CR_DARKGRAY);
			y += LH() + 6 * s;
		}

		double bottom = wy + wh - pad - LH() * 2 - 12 * s;   // footer: info panel
		if (tab == 1 && !inField) DrawShop(l, wx + pad, y, ww - pad * 2, wy + wh - pad, amber, line);
		else DrawLoadout(l, wx + pad, y, ww - pad * 2, bottom, amber, line);
	}

	void DrawLoadout(CW_Ledger l, double x, double top, double w, double bottom, Color amber, Color line)
	{
		// ---- column layout
		double lw = inField ? 0 : w * 0.28;
		double gxs = x + (inField ? 0 : lw + 16 * s);
		double gw = w - (gxs - x);
		int cols = l.GridW(1) + l.GridW(2);
		cs = min((gw - 30 * s) / cols, (bottom - top - LH() * 2) / max(l.GridH(1), l.GridH(2)));
		cs = min(cs, 56 * s);

		// ---- locker list
		lockRows.Clear();
		for (int i = 0; i < l.ItemCount(); i++) if (l.itCont[i] == 0) lockRows.Push(i);
		if (!inField)
		{
			Txt(x, top, String.Format("LOCKER  (%d)", lockRows.Size()), Font.CR_DARKGRAY);
			lockX = x; lockY = top + LH() + 4 * s; lockW = lw; lockH = bottom - lockY;
			lockRowH = LH() + 12 * s;
			Box(lockX, lockY, lockW, lockH, Color(12, 16, 22));
			int vis = int(lockH / lockRowH);
			lockScroll = clamp(lockScroll, 0, max(0, lockRows.Size() - vis));
			for (int r = 0; r < vis && r + lockScroll < lockRows.Size(); r++)
			{
				int i = lockRows[r + lockScroll];
				double ry = lockY + r * lockRowH;
				bool hot = i == hover;
				Box(lockX + 2 * s, ry + 2 * s, lockW - 4 * s, lockRowH - 4 * s, hot ? Color(30, 38, 52) : Color(16, 21, 29), i == held ? 0.4 : 1.0);
				Box(lockX + 2 * s, ry + 2 * s, 3 * s, lockRowH - 4 * s, CW_Items.CatColor(l.itType[i]));
				Icon(l.ItemIcon(i), lockX + 10 * s, ry + 3 * s, 44 * s, lockRowH - 6 * s, i == held ? 0.3 : 1.0);
				Txt(lockX + 60 * s, ry + (lockRowH - LH()) / 2 + 2 * s, CW_Items.Name(l.itType[i]), i == held ? Font.CR_DARKGRAY : Font.CR_WHITE);
				String sz = String.Format("%dx%d", CW_Items.W(l.itType[i]), CW_Items.H(l.itType[i]));
				Txt(lockX + lockW - 8 * s - TW(sz), ry + (lockRowH - LH()) / 2 + 2 * s, sz, Font.CR_DARKGRAY);
			}
			if (lockRows.Size() == 0) Txt(lockX + 10 * s, lockY + 8 * s, "Empty. Buy gear in the SHOP tab.", Font.CR_DARKGRAY);
		}

		// ---- grids
		gx[1] = gxs; gy[1] = top + LH() + 4 * s;
		gx[2] = gxs + l.GridW(1) * cs + 30 * s; gy[2] = gy[1];
		for (int c = 1; c <= 2; c++)
		{
			int cap = l.GridW(c) * l.GridH(c), used = l.CellsUsed(c);
			String title = c == 1 ? "TRANSPORT  (sedan)" : "PERSONAL KIT";
			Txt(gx[c], top, title, c == 1 ? Font.CR_CYAN : Font.CR_GOLD);
			String u = String.Format("%d/%d", used, cap);
			Txt(gx[c] + l.GridW(c) * cs - TW(u), top, u, used >= cap ? Font.CR_RED : Font.CR_DARKGRAY);
			for (int yy = 0; yy < l.GridH(c); yy++)
				for (int xx = 0; xx < l.GridW(c); xx++)
					Box(gx[c] + xx * cs + 1, gy[c] + yy * cs + 1, cs - 2, cs - 2, Color(22, 28, 38));
		}

		// ---- items in grids
		for (int i = 0; i < l.ItemCount(); i++)
		{
			int c = l.itCont[i];
			if (c < 1) continue;
			double x0 = gx[c] + l.itX[i] * cs, y0 = gy[c] + l.itY[i] * cs;
			double iw = l.ItW(i) * cs, ih = l.ItH(i) * cs;
			double a = i == held ? 0.25 : 1.0;
			Color cc = CW_Items.CatColor(l.itType[i]);
			Box(x0 + 2, y0 + 2, iw - 4, ih - 4, cc, 0.18 * a);
			Box(x0 + 2, y0 + 2, iw - 4, max(2.0, 2 * s), cc, a);
			if (i == hover && held < 0) Box(x0 + 2, y0 + ih - 4, iw - 4, 2, Color(255, 255, 255), 0.8);
			Icon(l.ItemIcon(i), x0 + 3, y0 + 3, iw - 6, ih - 6, a);
		}

		// ---- held item: snap preview + ghost at cursor
		if (held >= 0 && held < l.ItemCount())
		{
			int hw = HeldW(), hh = HeldH();
			for (int c = 1; c <= 2; c++)
			{
				if (!InGrid(c, mx, my)) continue;
				int tx = TargetX(c), ty = TargetY(c);
				bool ok = l.Fits(c, tx, ty, hw, hh, held);
				for (int yy = 0; yy < hh; yy++)
					for (int xx = 0; xx < hw; xx++)
					{
						int cx = tx + xx, cy = ty + yy;
						if (cx < 0 || cy < 0 || cx >= l.GridW(c) || cy >= l.GridH(c)) continue;
						Box(gx[c] + cx * cs + 1, gy[c] + cy * cs + 1, cs - 2, cs - 2, ok ? Color(60, 200, 90) : Color(220, 60, 50), 0.35);
					}
			}
			double gxp = mx - (min(grabX, hw - 1) + 0.5) * cs, gyp = my - (min(grabY, hh - 1) + 0.5) * cs;
			Box(gxp, gyp, hw * cs, hh * cs, CW_Items.CatColor(l.itType[held]), 0.25);
			Icon(l.ItemIcon(held), gxp + 3, gyp + 3, hw * cs - 6, hh * cs - 6, 0.9);
		}

		// ---- footer: item info + warnings
		double fy = bottom + 8 * s;
		Box(x, fy - 4 * s, w, max(1.0, s), line);
		int info = held >= 0 ? held : hover;
		if (info >= 0 && info < l.ItemCount())
		{
			int t = l.itType[info];
			String chip = CW_Items.CatName(t);
			double chw = TW("MEDICAL") + 12 * s;
			Box(x, fy + 1, chw, LH() - 3 * s, CW_Items.CatColor(t), 0.85);
			Txt(x + (chw - TW(chip)) / 2, fy + 2, chip, Font.CR_WHITE);
			Txt(x + chw + 10 * s, fy, CW_Items.Name(t) .. String.Format("   %dx%d", CW_Items.W(t), CW_Items.H(t)), Font.CR_WHITE);
			Txt(x + chw + 10 * s, fy + LH(), CW_Items.Desc(t), Font.CR_TAN);
		}
		else
		{
			String mk = l.MissingKits();
			if (mk.Length()) Txt(x, fy, "Hired crew without their kit in the transport: " .. mk, Font.CR_RED);
			else Txt(x, fy, "Only the PERSONAL KIT is carried. Crew kits must ride in the TRANSPORT.", Font.CR_DARKGRAY);
			Txt(x, fy + LH(), inField ? "Walk back here any time to swap gear." : "Anything left in the locker stays safe at the office.", Font.CR_DARKGRAY);
		}
	}

	void DrawShop(CW_Ledger l, double x, double top, double w, double bottom, Color amber, Color line)
	{
		int st0 = ShopItem(scur);
		String btn = CanBuy(st0) ? "BUY  " .. CW_Handler.Money(Ledger().ShopPrice(st0))
			: ((CW_Items.Unique(st0) && l.CountAll(st0) > 0) ? "OWNED" : "INSUFFICIENT BUDGET");
		bool ok = CanBuy(st0);
		btnW = TW(btn) + 36 * s; btnH = LH() + 10 * s;
		btnX = x + w - btnW; btnY = bottom - btnH;
		Box(x, btnY - 8 * s, w, max(1.0, s), line);
		Box(btnX, btnY, btnW, btnH, ok ? amber : line);
		Txt(btnX + 18 * s, btnY + 5 * s + 1, btn, ok ? Font.CR_BLACK : Font.CR_DARKGRAY);
		Txt(x, btnY + 5 * s + 1, "Purchases go to your locker. Pack them in the LOADOUT tab.", Font.CR_DARKGRAY);

		shopY0 = top;
		shopH = min(LH() * 2 + 12 * s, (btnY - 12 * s - top) / ShopCount());
		double chipW = TW("MEDICAL") + 14 * s;
		for (int row = 0; row < ShopCount(); row++)
		{
			int t = ShopItem(row);
			double ry = shopY0 + row * shopH;
			Box(x, ry, w, shopH - 4 * s, row == scur ? Color(30, 38, 52) : Color(14, 18, 26));
			Box(x, ry, 3 * s, shopH - 4 * s, CW_Items.CatColor(t));
			Icon(CW_Items.Icon(t), x + 10 * s, ry + 2 * s, 56 * s, shopH - 8 * s);
			double tx = x + 74 * s;
			Box(tx, ry + 4 * s, chipW, LH() - 3 * s, CW_Items.CatColor(t), 0.85);
			String k = CW_Items.CatName(t);
			Txt(tx + (chipW - TW(k)) / 2, ry + 5 * s, k, Font.CR_WHITE);
			Txt(tx + chipW + 10 * s, ry + 4 * s, CW_Items.Name(t), Font.CR_WHITE);
			if (shopH > LH() * 1.8) Txt(tx + chipW + 10 * s, ry + 4 * s + LH(), CW_Items.Desc(t), Font.CR_TAN);
			int have = l.CountAll(t);
			String st = CW_Items.Unique(t) ? (have ? "OWNED" : "") : (have ? String.Format("Have %d", have) : "");
			int sp = Ledger() ? Ledger().ShopPrice(t) : CW_Items.Price(t);
			String price = sp > 0 ? CW_Handler.Money(sp) : "closed";
			Txt(x + w - 12 * s - TW(price), ry + 4 * s, price, CanBuy(t) ? Font.CR_GOLD : Font.CR_DARKGRAY);
			if (st.Length()) Txt(x + w - 24 * s - TW(price) - TW(st), ry + 4 * s, st, Font.CR_GREEN);
		}
	}
}
