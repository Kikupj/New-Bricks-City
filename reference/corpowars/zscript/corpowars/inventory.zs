// =============================================================================
// Corpo Wars — grid inventory: item catalogue + locker / transport / personal
//   Container 0 = LOCKER    (hub only, unlimited list)
//   Container 1 = TRANSPORT (vehicle grid; crew kits must ride here)
//   Container 2 = PERSONAL  (what the operative carries; issued on deploy)
// =============================================================================
class CW_Items
{
	enum EItem
	{
		IT_SDPISTOL, IT_TRANQ, IT_ARMOR, IT_NOISEMAKER, IT_FLASHBANG,
		IT_AMMO9, IT_DARTS, IT_MEDKIT, IT_KIT_NYX, IT_KIT_MARROW, IT_KIT_VOX,
		IT_PISTOL,          // appended: keeps saved item ids stable
		IT_SHOTGUN, IT_SMG, IT_SHELLS,
		IT_SUPPRESSOR,      // universal: fits any weapon with a ToggleSuppressor state
		IT_TASER, IT_FLASHLIGHT,
		IT_BREACH, IT_BYPASS,   // door entry (round 5)
		IT_COUNT
	}
	enum ECat { CAT_WEAPON, CAT_AMMO, CAT_GADGET, CAT_ARMOR, CAT_MEDICAL, CAT_CREW, CAT_ATTACH }

	static clearscope String Name(int t)
	{
		switch (t)
		{
		case IT_PISTOL:     return "Service pistol";
		case IT_SHOTGUN:    return "Pump shotgun";
		case IT_SMG:        return "Submachine gun";
		case IT_SHELLS:     return "Shell box (8)";
		case IT_SUPPRESSOR: return "Suppressor";
		case IT_TASER:      return "Taser";
		case IT_FLASHLIGHT: return "Flashlight";
		case IT_BREACH:     return "Breaching charge";
		case IT_BYPASS:     return "Maglock bypass";
		case IT_SDPISTOL:   return "Suppressed pistol (retired)";
		case IT_TRANQ:      return "Tranquilizer rifle";
		case IT_ARMOR:      return "Body armor";
		case IT_NOISEMAKER: return "Noisemaker";
		case IT_FLASHBANG:  return "Flashbang";
		case IT_AMMO9:      return "9mm box (15)";
		case IT_DARTS:      return "Dart pack (3)";
		case IT_MEDKIT:     return "Field medkit";
		case IT_KIT_NYX:    return "Nyx: hacking rig";
		case IT_KIT_MARROW: return "Marrow: cleanup kit";
		case IT_KIT_VOX:    return "Vox: lure kit";
		}
		return "?";
	}
	static clearscope String Desc(int t)
	{
		switch (t)
		{
		case IT_PISTOL:     return "Slot 2. 12-round mag, R reloads. Loud: guards hear it across the floor.";
		case IT_SHOTGUN:    return "Slot 3. 6-shell tube, loads one at a time. Brutal up close. Very loud.";
		case IT_SMG:        return "Slot 4. 30-round mag, full auto, 9mm. Very loud.";
		case IT_SHELLS:     return "8 shotgun shells. Loaded when carried.";
		case IT_SUPPRESSOR: return "[V] Fit/remove on the weapon in hand (service pistol, SMG). Quiet shots, no flash.";
		case IT_TASER:      return "Slot 1. Hold fire point-blank: staggers, then drops a guard in ~1 s. Non-lethal.";
		case IT_BREACH:     return "[K] at a maglocked door: blows it open after a 3 s fuse. Very loud, and it hurts anyone close.";
		case IT_BYPASS:     return "Hold USE at a maglock: opens it silently in 3 s. Single use.";
		case IT_FLASHLIGHT: return "[L] Toggle. Lights your way, but guards see you far more easily while it's on.";
		case IT_SDPISTOL:   return "Retired. Converted to a Suppressor: fit it to the service pistol with V.";
		case IT_TRANQ:      return "Slot 3. Bolt-action, alt-fire scope. Darts drop a target in 2 s.";
		case IT_ARMOR:      return "Issued as full armor when you deploy. Reusable.";
		case IT_NOISEMAKER: return "[G] Throw it. It clatters on landing and guards go look.";
		case IT_FLASHBANG:  return "[H] Stuns every guard with eyes on the blast for 5 seconds.";
		case IT_AMMO9:      return "15 rounds of 9mm: both pistols and the SMG. Loaded when carried.";
		case IT_DARTS:      return "3 tranquilizer darts. Loaded when carried.";
		case IT_MEDKIT:     return "[J] Patch up for 40 health.";
		case IT_KIT_NYX:    return "Nyx can't cut the power unless this rides in the transport.";
		case IT_KIT_MARROW: return "Marrow can't clean up unless this rides in the transport.";
		case IT_KIT_VOX:    return "Vox can't throw lures unless this rides in the transport.";
		}
		return "";
	}
	static clearscope String Icon(int t)
	{
		switch (t)
		{
		case IT_PISTOL:     return "GLCKH0";
		case IT_SHOTGUN:    return "DNSPA0";
		case IT_SMG:        return "MP5IA0";
		case IT_SHELLS:     return "SHELA0";
		case IT_SUPPRESSOR:   return "SUPPA0";
		case IT_TASER:      return "VTAZP0";
		case IT_FLASHLIGHT: return "FLSHA0";
		case IT_BREACH:     return "SPMIA0";
		case IT_BYPASS:     return "ZGPSA0";
		case IT_SDPISTOL:   return "SPIPA0";
		case IT_TRANQ:      return "SRILA0";
		case IT_ARMOR:      return "ARM2A0";
		case IT_NOISEMAKER: return "CWC4A0";
		case IT_FLASHBANG:  return "Z40MA0";
		case IT_AMMO9:      return "Z9MMA0";
		case IT_DARTS:      return "ZDRTA0";
		case IT_MEDKIT:     return "MEDIA0";
		case IT_KIT_NYX:    return "CWRCA0";
		case IT_KIT_MARROW: return "ZBPCK0";
		case IT_KIT_VOX:    return "CWC3A0";
		}
		return "TNT1A0";
	}
	static clearscope int W(int t)
	{
		switch (t)
		{
		case IT_PISTOL: return 2; case IT_SDPISTOL: return 2; case IT_TRANQ: return 4;
		case IT_SHOTGUN: return 4; case IT_SMG: return 3; case IT_TASER: return 2; case IT_ARMOR: return 2;
		case IT_MEDKIT: return 2; case IT_KIT_NYX: return 2; case IT_KIT_MARROW: return 2; case IT_KIT_VOX: return 2;
		}
		return 1;
	}
	static clearscope int H(int t)
	{
		switch (t) { case IT_ARMOR: return 2; case IT_KIT_NYX: return 2; case IT_SMG: return 2; }
		return 1;
	}
	static clearscope int Price(int t)
	{
		switch (t)
		{
		case IT_PISTOL: return 300; case IT_TRANQ: return 1500;
		case IT_SHOTGUN: return 1400; case IT_SMG: return 1800; case IT_SHELLS: return 80;
		case IT_SUPPRESSOR: return 900;
		case IT_TASER: return 700; case IT_FLASHLIGHT: return 150;
		case IT_BREACH: return 400; case IT_BYPASS: return 350; case IT_ARMOR: return 600;
		case IT_NOISEMAKER: return 150; case IT_FLASHBANG: return 250;
		case IT_AMMO9: return 60; case IT_DARTS: return 120; case IT_MEDKIT: return 100;
		}
		return 0;   // crew kits are company property, not sold
	}
	static clearscope int Cat(int t)
	{
		switch (t)
		{
		case IT_PISTOL: case IT_SDPISTOL: case IT_TRANQ: case IT_SHOTGUN: case IT_SMG: case IT_TASER: return CAT_WEAPON;
		case IT_AMMO9: case IT_DARTS: case IT_SHELLS: return CAT_AMMO;
		case IT_NOISEMAKER: case IT_FLASHBANG: case IT_FLASHLIGHT: case IT_BREACH: case IT_BYPASS: return CAT_GADGET;
		case IT_ARMOR: return CAT_ARMOR;
		case IT_MEDKIT: return CAT_MEDICAL;
		case IT_SUPPRESSOR: return CAT_ATTACH;
		}
		return CAT_CREW;
	}
	static clearscope String CatName(int t)
	{
		static const String n[] = { "WEAPON", "AMMO", "GADGET", "ARMOR", "MEDICAL", "CREW", "ATTACH" };
		return n[Cat(t)];
	}
	static clearscope Color CatColor(int t)
	{
		switch (Cat(t))
		{
		case CAT_WEAPON:  return Color(230, 80, 60);
		case CAT_AMMO:    return Color(200, 170, 90);
		case CAT_GADGET:  return Color(240, 170, 40);
		case CAT_ARMOR:   return Color(70, 160, 255);
		case CAT_MEDICAL: return Color(80, 200, 110);
		case CAT_ATTACH:  return Color(170, 110, 240);
		}
		return Color(60, 220, 200);   // crew
	}
	static clearscope bool Unique(int t) { return Cat(t) == CAT_WEAPON || t == IT_ARMOR || t == IT_FLASHLIGHT || Cat(t) == CAT_CREW || Cat(t) == CAT_ATTACH; }
	static clearscope int CrewKit(int crew)
	{
		switch (crew) { case 0: return IT_KIT_NYX; case 1: return IT_KIT_MARROW; case 2: return IT_KIT_VOX; }
		return -1;
	}
}

extend class CW_Ledger
{
	const TR_W = 6;  const TR_H = 4;   // transport (sedan)
	const PS_W = 6;  const PS_H = 3;   // personal kit

	Array<int> itType, itCont, itX, itY, itRot;
	bool invReady;
	bool pistolSeeded;
	bool armorIssued;

	clearscope int GridW(int c) { return c == 1 ? TR_W : PS_W; }
	clearscope int GridH(int c) { return c == 1 ? TR_H : PS_H; }
	clearscope int ItW(int i) { return itRot[i] ? CW_Items.H(itType[i]) : CW_Items.W(itType[i]); }
	clearscope int ItH(int i) { return itRot[i] ? CW_Items.W(itType[i]) : CW_Items.H(itType[i]); }
	clearscope int ItemCount() { return itType.Size(); }

	clearscope bool Fits(int c, int x, int y, int w, int h, int ignore)
	{
		if (c == 0) return true;
		if (x < 0 || y < 0 || x + w > GridW(c) || y + h > GridH(c)) return false;
		for (int i = 0; i < itType.Size(); i++)
		{
			if (i == ignore || itCont[i] != c) continue;
			if (x < itX[i] + ItW(i) && itX[i] < x + w && y < itY[i] + ItH(i) && itY[i] < y + h) return false;
		}
		return true;
	}

	clearscope int CountIn(int c, int t)
	{
		int n = 0;
		for (int i = 0; i < itType.Size(); i++) if (itCont[i] == c && itType[i] == t) n++;
		return n;
	}
	clearscope int CountAll(int t)
	{
		int n = 0;
		for (int i = 0; i < itType.Size(); i++) if (itType[i] == t) n++;
		return n;
	}
	clearscope int CellsUsed(int c)
	{
		int n = 0;
		for (int i = 0; i < itType.Size(); i++) if (itCont[i] == c) n += ItW(i) * ItH(i);
		return n;
	}

	int AddItem(int t, int c = 0)
	{
		itType.Push(t); itCont.Push(0); itX.Push(0); itY.Push(0); itRot.Push(0);
		int i = itType.Size() - 1;
		if (c != 0 && !AutoPlace(i, c)) { /* stays in locker */ }
		return i;
	}

	void RemoveItem(int i)
	{
		itType.Delete(i); itCont.Delete(i); itX.Delete(i); itY.Delete(i); itRot.Delete(i);
	}

	bool AutoPlace(int i, int c)
	{
		for (int r = 0; r < 2; r++)
		{
			int w = r ? CW_Items.H(itType[i]) : CW_Items.W(itType[i]);
			int h = r ? CW_Items.W(itType[i]) : CW_Items.H(itType[i]);
			for (int y = 0; y < GridH(c); y++)
				for (int x = 0; x < GridW(c); x++)
					if (Fits(c, x, y, w, h, i)) { itCont[i] = c; itX[i] = x; itY[i] = y; itRot[i] = r; return true; }
		}
		return false;
	}

	bool ConsumeOne(int c, int t)
	{
		for (int i = itType.Size() - 1; i >= 0; i--)
			if (itCont[i] == c && itType[i] == t) { RemoveItem(i); return true; }
		return false;
	}

	// First-time setup + migration from the old owned/stock gear.
	void InvInit()
	{
		if (!pistolSeeded)
		{
			pistolSeeded = true;
			if (CountAll(CW_Items.IT_PISTOL) == 0) AddItem(CW_Items.IT_PISTOL, 2);
		}
		if (!invReady)
		{
			invReady = true;
			InvLegacy();
		}
		RetireItems();
	}

	void RetireItems()
	{
		for (int i = itType.Size() - 1; i >= 0; i--)
		{
			if (itType[i] != CW_Items.IT_SDPISTOL) continue;
			if (CountAll(CW_Items.IT_SUPPRESSOR) == 0) { itType[i] = CW_Items.IT_SUPPRESSOR; itCont[i] = 0; itRot[i] = 0; }
			else { RemoveItem(i); budget += 1200; }
		}
	}

	void InvLegacy()
	{
		AddItem(CW_Items.IT_KIT_NYX, 1);
		AddItem(CW_Items.IT_KIT_MARROW, 1);
		AddItem(CW_Items.IT_KIT_VOX, 1);
		if (gearOwned & 1) AddItem(CW_Items.IT_SDPISTOL, 2);
		if (gearOwned & 2) AddItem(CW_Items.IT_TRANQ, 2);
		if (gearOwned & 4) AddItem(CW_Items.IT_ARMOR);
		for (int n = 0; n < noisemakers; n++) AddItem(CW_Items.IT_NOISEMAKER, 2);
		for (int n = 0; n < flashbangs; n++) AddItem(CW_Items.IT_FLASHBANG, 2);
		gearOwned = 0; noisemakers = 0; flashbangs = 0;
	}

	void BuyItem(int t)
	{
		if (missionActive || t < 0 || t >= CW_Items.IT_COUNT) return;
		int price = ShopPrice(t);
		if (price <= 0 || budget < price) return;
		if (CW_Items.Unique(t) && CountAll(t) > 0) return;
		budget -= price;
		AddItem(t, 0);
	}

	// packed = x | y << 8 | rot << 16
	void MoveItem(int i, int c, int packed, Actor pm)
	{
		if (i < 0 || i >= itType.Size() || c < 0 || c > 2) return;
		if (missionActive && (c == 0 || itCont[i] == 0)) return;   // no locker in the field
		int x = packed & 255, y = (packed >> 8) & 255, r = (packed >> 16) & 1;
		int w = r ? CW_Items.H(itType[i]) : CW_Items.W(itType[i]);
		int h = r ? CW_Items.W(itType[i]) : CW_Items.H(itType[i]);
		if (!Fits(c, x, y, w, h, i)) return;
		int from = itCont[i];
		int t = itType[i];
		itCont[i] = c; itX[i] = x; itY[i] = y; itRot[i] = r;
		if (missionActive && pm)
		{
			if (c == 2 && from != 2) IssueItem(pm, i);
			else if (c != 2 && from == 2) UnissueType(pm, t);
			ApplyAttachments(pm);
		}
	}

	clearscope String ItemIcon(int i) { return CW_Items.Icon(itType[i]); }

	// Can't have more suppressed weapons than suppressors in the personal kit.
	void ApplyAttachments(Actor pm)
	{
		int have = CountIn(2, CW_Items.IT_SUPPRESSOR);
		for (Inventory it = pm.Inv; it; it = it.Inv)
		{
			let w = Weapon(it);
			if (w && CW_Handler.IsSuppressed(w))
			{
				if (have > 0) have--;
				else CW_Handler.SetSuppressed(w, false);
			}
		}
	}

	clearscope String MissingKits()
	{
		String s = "";
		for (int k = 0; k < CW_Services.CREW_COUNT; k++)
			if (HasCrew(k) && CountIn(1, CW_Items.CrewKit(k)) == 0)
				s = s .. (s.Length() ? ", " : "") .. CW_Services.CrewName(k);
		return s;
	}

	// ---------------------------------------------------------------- field issue
	// Returns true if the item was used up by issuing (ammo is loaded).
	bool IssueItem(Actor pm, int i)
	{
		int t = itType[i];
		switch (t)
		{
		case CW_Items.IT_PISTOL:
			pm.GiveInventory("CW_ServicePistol", 1);
			pm.GiveInventory("CW_PistolMag", CW_ServicePistol.MAG);   // one loaded magazine
			return false;
		case CW_Items.IT_TRANQ:
			pm.GiveInventory("CW_TranqGun", 1);
			return false;
		case CW_Items.IT_TASER:
			pm.GiveInventory("CW_Taser", 1);
			pm.GiveInventory("CW_TaserCharge", 100);
			return false;
		case CW_Items.IT_SHOTGUN:
			pm.GiveInventory("CW_Shotgun", 1);
			pm.GiveInventory("CW_ShellTube", CW_Shotgun.TUBE);
			return false;
		case CW_Items.IT_SMG:
			pm.GiveInventory("CW_SMG", 1);
			pm.GiveInventory("CW_SMGMag", CW_SMG.MAG);
			return false;
		case CW_Items.IT_SHELLS:
			pm.GiveInventory("Shell", 8);
			RemoveItem(i);
			return true;
		case CW_Items.IT_ARMOR:
			if (!armorIssued) { pm.GiveInventory("GreenArmor", 1); armorIssued = true; }
			return false;
		case CW_Items.IT_AMMO9:
			pm.GiveInventory("Clip", 15);
			RemoveItem(i);
			return true;
		case CW_Items.IT_DARTS:
			pm.GiveInventory("CW_TranqDart", 3);
			RemoveItem(i);
			return true;
		}
		return false;
	}

	void UnissueType(Actor pm, int t)
	{
		if (CountIn(2, t) > 0) return;
		if (t == CW_Items.IT_PISTOL) pm.TakeInventory("CW_ServicePistol", 1);
		else if (t == CW_Items.IT_TRANQ) pm.TakeInventory("CW_TranqGun", 1);
		else if (t == CW_Items.IT_SHOTGUN) pm.TakeInventory("CW_Shotgun", 1);
		else if (t == CW_Items.IT_TASER) pm.TakeInventory("CW_Taser", 1);
		else if (t == CW_Items.IT_SMG) pm.TakeInventory("CW_SMG", 1);
	}

	void IssuePersonal(Actor pm)
	{
		armorIssued = false;
		pm.TakeInventory("Pistol", 1);
		pm.TakeInventory("CW_ServicePistol", 1);
		pm.TakeInventory("CW_PistolMag", 999);
		pm.TakeInventory("Clip", 999);
		pm.TakeInventory("CW_TranqGun", 1);
		pm.TakeInventory("CW_TranqDart", 999);
		pm.TakeInventory("Shotgun", 1);
		pm.TakeInventory("CW_Shotgun", 1);
		pm.TakeInventory("CW_ShellTube", 999);
		pm.TakeInventory("Shell", 999);
		pm.TakeInventory("CW_SMG", 1);
		pm.TakeInventory("CW_SMGMag", 999);
		pm.TakeInventory("CW_Taser", 1);
		pm.TakeInventory("CW_TaserCharge", 999);
		for (int i = itType.Size() - 1; i >= 0; i--)
			if (itCont[i] == 2) IssueItem(pm, i);
		ApplyAttachments(pm);
		Weapon best = Weapon(pm.FindInventory("CW_ServicePistol"));
		if (!best) best = Weapon(pm.FindInventory("CW_TranqGun"));
		if (!best) best = Weapon(pm.FindInventory("Fist"));
		if (best) pm.player.PendingWeapon = best;
	}
}

// Transport access point in the field (placed at the insertion/extraction point).
class CW_TransportAccess : CW_Interactable
{
	Default
	{
		Radius 26;
		Height 35;
		Tag "Transport";
	}
	override String GetPrompt(Actor user) { return "Transport: swap kit"; }
	override void Interact(Actor user)
	{
		A_StartSound("cw/tranq/open", CHAN_BODY, 0, 0.5);
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		if (h) h.kitRequests++;
	}
	States { Spawn: CWC1 A -1; Stop; }
}
