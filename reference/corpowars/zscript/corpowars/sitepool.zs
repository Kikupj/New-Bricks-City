// =============================================================================
// Corpo Wars — the After Hours site pack (CorpoWars_sites.wad + CorpoWars_sitemaps.pk3)
//
// The pack holds ~6 generated layouts ("variants") per site type, built by the After Hours generators
// (Assets/maps/AfterHours/gen_site_pool.py + build_mod_pack.py). Every building is a few maps named
//     S<CODE><NN><floor letter>     SBAR03A = bar pool, variant 3, main floor;  SHOT02C = hotel 2, third map
// and one record in the data lump CWSITES says what is in it (entries, markers, zones). This file:
//   * CW_SiteBld   one building's record, parsed from CWSITES
//   * CW_SitePool  the routing: which pool a building type / neutral site uses, which variant a layout seed
//                  gets, which map a visit or a contract opens, which entry the player comes in by.
// The mission itself (guards, objectives, extraction) is sitemission.zs.
//
// Routing falls back to the old in-engine kits / G02 office floor when: cw_newsites is 0, the pool has no
// maps in the loaded files, the pool's maps have no mission markers (CWPOOLS says so), or the table below
// has no pool for the type (power plant PLT, parking, rooftops, and the office-like types for now).
// =============================================================================

class CW_SiteBld
{
	String name, code, title, size;         // SBAR03, BAR, ...
	int variant, seed, cluster, floors;
	Array<String> mMap, mRole;              // the building's maps, in floor order (A, B, C ...)
	Array<int> mFloor;
	// entries (E lines): type 31012 front 31013 back 31014 service 31015 covert, via '' / stairs / lift / roof
	Array<String> eMap, eVia, eName;
	Array<int> eType, eX, eY, eZ, eAng;
	// markers (K lines): 31020 objective 31021 guard post 31022 patrol point 31023 bystander 31024 extraction
	Array<String> kMap, kNote;
	Array<int> kType, kX, kY, kZ;

	int FloorOf(String m)
	{
		for (int i = 0; i < mMap.Size(); i++) if (mMap[i] == m) return i;
		return -1;
	}
	int CountOn(String m, int type)
	{
		int n = 0;
		for (int i = 0; i < kMap.Size(); i++) if (kMap[i] == m && kType[i] == type) n++;
		return n;
	}
	int CountAll(int type)
	{
		int n = 0;
		for (int i = 0; i < kMap.Size(); i++) if (kType[i] == type) n++;
		return n;
	}
	// does this entry lead outside (a way in / out of the building), as opposed to a stair or lift between floors?
	// (the ground floor's lift is the way in from the street, as in a tower; a lift on an upper floor only joins floors)
	bool IsOutside(int i)
	{
		if (eVia[i] == "" || eVia[i] == "roof") return true;
		if (eVia[i] == "emergency_stairs") return FloorOf(eMap[i]) == 0;      // an office's back way in at street level
		return (eVia[i] == "elevator" || eVia[i] == "lift") && FloorOf(eMap[i]) == 0;
	}
	// the old entry kinds (CW_ObsSite.EEntryKind): 2 front 3 back 4 service 5 roof / covert
	int KindOf(int i)
	{
		if (eVia[i] == "roof") return 5;
		switch (eType[i])
		{
		case 31012: return 2;
		case 31013: return 3;
		case 31014: return 4;
		}
		return 5;
	}
}

class CW_SitePool
{
	// ---- the one place that decides which pool a type uses -------------------------------------------------
	// Pool codes (see gen_site_pool.py). A comma list means "several pools share this type": the layout seed picks.
	//
	// OFFICES: the six office-like property types (CW_PropType PT_OFF, PT_HQ, PT_CLN, PT_STU, PT_TRN, PT_RND) use the
	// office pools below (generate_office.py: one floor + the roof; the training site: floor + parking garage). Set a
	// type back to "" to send it to the G02 office floor again. A pool with no markers (CWPOOLS) is ignored automatically.
	static clearscope String OfficeCode(int ptype)
	{
		switch (ptype)
		{
		case PT_OFF: return "OFC";
		case PT_HQ:  return "HQT";
		case PT_CLN: return "CLC";
		case PT_STU: return "STD";
		case PT_TRN: return "TRN";
		case PT_RND: return "RND";
		}
		return "";
	}

	// kit (1..6) / variant (CW_KitGen's EVar) -> pool code(s). "" = keep the old kit.
	static clearscope String KitCode(int kit, int kvar)
	{
		switch (kit)
		{
		case 1:
			switch (kvar)
			{
			case 0: return "BAR,NCL";
			case 1: return "RST";
			case 2: return "PWN";
			case 3: return "MKT,CNV";
			case 4: return "MAL";
			case 5: return "DLB,BPL";
			case 6: return "CHP";
			case 7: return "GAM";
			}
			break;
		case 2:
			switch (kvar)
			{
			case 0: return "TEN";
			case 1: return "APT";
			case 2: return "LUX";
			case 3: return "HOT";
			case 4: return "HKD,CLK";
			}
			return "";                       // 5: rooftops stay on the old kit
		case 3:
			switch (kvar)
			{
			case 0: return "WHS";
			case 1: return "DOK";
			case 2: return "FAB";
			case 4: return "SUB";
			case 5: return "PRK";
			case 6: return "SAL";
			case 7: return "CON";
			}
			return "";                       // 3: the power plant (PLT) stays on the old K03
		case 4:
			switch (kvar)
			{
			case 0: return "TUN";
			case 1: return "UND";
			case 2: return "TRS";
			case 4: return "FRM";
			case 5: return "BUN";
			}
			return "";                       // 3: parking structure stays old
		case 5:
			switch (kvar)
			{
			case 0: return "UNI";
			case 1: case 2: return "HAL";
			case 3: return "UNV";
			case 4: return "HSP";
			case 5: return "LIB";
			}
			break;
		case 6:
			switch (kvar)
			{
			case 0: return "DTC";
			case 1: return "LAB";
			}
			break;
		}
		return "";
	}

	// a city property's pool (ptype = CW_PropType, -1 = not a property): a bank is a civic Bank, not the old
	// K04 bunker variant PropKit() uses for it.
	static clearscope String CodeFor(int kit, int kvar, int ptype, int seed)
	{
		String c = "";
		if (ptype == PT_BNK) c = "BAN";
		else if (ptype >= PT_OFF && ptype <= PT_RND && kit <= 0) c = OfficeCode(ptype);
		else if (kit > 0) c = KitCode(kit, kvar);
		if (c.IndexOf(",") < 0) return c;
		Array<String> a;
		c.Split(a, ",");
		return a[Hash(seed, 73) % a.Size()];
	}

	static clearscope int Hash(int a, int salt) { return abs(CW_Building.Mix(a, salt)); }

	static clearscope bool Enabled()
	{
		let v = CVar.FindCVar("cw_newsites");
		return !v || v.GetBool();
	}

	// ---- what the pack holds (CWPOOLS: P <code> <title> <count> <markers>) ----------------------------------
	static clearscope String PoolLine(String code)
	{
		int lump = Wads.CheckNumForName("CWPOOLS", Wads.GlobalNamespace);
		if (lump < 0) return "";
		String t = Wads.ReadLump(lump);
		int a = t.IndexOf("\nP\t" .. code .. "\t");
		if (a < 0) return "";
		int e = t.IndexOf("\n", a + 1);
		return e < 0 ? t.Mid(a + 1) : t.Mid(a + 1, e - a - 1);
	}
	static clearscope int PoolCount(String code)
	{
		String l = PoolLine(code);
		if (!l.Length()) return 0;
		Array<String> f;
		l.Split(f, "\t");
		return f.Size() > 3 ? f[3].ToInt(10) : 0;
	}
	static clearscope bool PoolMarked(String code)
	{
		String l = PoolLine(code);
		if (!l.Length()) return false;
		Array<String> f;
		l.Split(f, "\t");
		return f.Size() > 4 && f[4].ToInt(10) != 0;
	}
	static clearscope String PoolTitle(String code)
	{
		String l = PoolLine(code);
		Array<String> f;
		l.Split(f, "\t");
		return f.Size() > 2 ? f[2] : code;
	}

	// the main map of a building: pool index 1..count from the layout seed (the same seed always gets the same layout),
	// or "" when the old kit / office floor applies.
	static clearscope String MapFor(int kit, int kvar, int ptype, int seed)
	{
		if (!Enabled()) return "";
		String code = CodeFor(kit, kvar, ptype, seed);
		if (!code.Length()) return "";
		int n = PoolCount(code);
		if (n <= 0 || !PoolMarked(code)) return "";
		String m = String.Format("S%s%02dA", code, 1 + Hash(seed, 71) % n);
		return LevelInfo.MapExists(m) ? m : "";
	}

	// ---- map names ---------------------------------------------------------------------------------------------
	static clearscope bool IsSiteMap(String m)
	{
		if (m.Length() != 7 || m.ByteAt(0) != 83) return false;          // 'S'
		for (int i = 1; i <= 3; i++) { int c = m.ByteAt(i); if (c < 65 || c > 90) return false; }
		for (int i = 4; i <= 5; i++) { int c = m.ByteAt(i); if (c < 48 || c > 57) return false; }
		int f = m.ByteAt(6);
		return f >= 65 && f <= 74;
	}
	static clearscope String BldOf(String m) { return m.Left(6); }
	static clearscope String CodeOfMap(String m) { return m.Mid(1, 3); }

	// ---- CWSITES -------------------------------------------------------------------------------------------------
	static clearscope CW_SiteBld Load(String bname)
	{
		int lump = Wads.CheckNumForName("CWSITES", Wads.GlobalNamespace);
		if (lump < 0) return null;
		String t = Wads.ReadLump(lump);
		int a = t.IndexOf("\nB\t" .. bname .. "\t");
		if (a < 0) return null;
		int e = t.IndexOf("\nB\t", a + 3);
		String blk = e < 0 ? t.Mid(a + 1) : t.Mid(a + 1, e - a - 1);
		Array<String> lines;
		blk.Split(lines, "\n");
		let b = new("CW_SiteBld");
		for (int i = 0; i < lines.Size(); i++)
		{
			if (lines[i].Length() < 3) continue;
			Array<String> f;
			lines[i].Split(f, "\t");
			String k = f[0];
			if (k == "B" && f.Size() >= 9)
			{
				b.name = f[1]; b.code = f[2]; b.variant = f[3].ToInt(10); b.seed = f[4].ToInt(10);
				b.cluster = f[5].ToInt(10); b.floors = f[6].ToInt(10); b.size = f[7]; b.title = f[8];
			}
			else if (k == "M" && f.Size() >= 4) { b.mMap.Push(f[1]); b.mFloor.Push(f[2].ToInt(10)); b.mRole.Push(f[3]); }
			else if (k == "E" && f.Size() >= 8)
			{
				b.eMap.Push(f.Size() > 8 ? f[8] : f[1]); b.eType.Push(f[2].ToInt(10)); b.eX.Push(f[3].ToInt(10)); b.eY.Push(f[4].ToInt(10));
				b.eZ.Push(f[5].ToInt(10)); b.eAng.Push(f[6].ToInt(10)); b.eVia.Push(f[7]); b.eName.Push(f.Size() > 9 ? f[9] : "");
			}
			else if (k == "K" && f.Size() >= 6)
			{
				b.kMap.Push(f[1]); b.kType.Push(f[2].ToInt(10)); b.kX.Push(f[3].ToInt(10)); b.kY.Push(f[4].ToInt(10));
				b.kZ.Push(f[5].ToInt(10)); b.kNote.Push(f.Size() > 6 ? f[6] : "");
			}
		}
		return b;
	}

	// ---- which entry a visit uses ----------------------------------------------------------------------------------
	// Candidates are the ways in from outside (street / yard / gate / roof). The contract's chosen entry (Intel prep) wins,
	// else the visit's seed picks one. A walk-in (pref 2) goes by the front.
	static clearscope int PickEntry(CW_SiteBld b, int visitSeed, int pref)
	{
		Array<int> cand;
		for (int i = 0; i < b.eMap.Size(); i++) if (b.IsOutside(i)) cand.Push(i);
		if (!cand.Size()) for (int i = 0; i < b.eMap.Size(); i++) cand.Push(i);
		if (!cand.Size()) return -1;
		int pick = cand[Hash(visitSeed, 31) % cand.Size()];
		if (pref >= 2) for (int c = 0; c < cand.Size(); c++) if (b.KindOf(cand[c]) == pref) { pick = cand[c]; break; }
		return pick;
	}

	// the map a mission or visit actually opens: the entry's own map (a roof entry starts on the roof map)
	static clearscope String LaunchMap(String mainMap, int visitSeed, int pref)
	{
		let b = Load(BldOf(mainMap));
		if (!b) return mainMap;
		int e = PickEntry(b, visitSeed, pref);
		return (e >= 0 && b.eMap[e].Length()) ? b.eMap[e] : mainMap;
	}

	// the entry kind names the player sees
	static clearscope String EntryTitle(CW_SiteBld b, int i)
	{
		if (b.eName[i].Length()) return b.eName[i];
		switch (b.KindOf(i))
		{
		case 2: return "the main entrance";
		case 3: return "the back door";
		case 4: return "a service door";
		}
		return "a covert way in";
	}

	// "Bar and lounge #3" for the UI
	static clearscope String Describe(String m)
	{
		if (!IsSiteMap(m)) return m;
		return String.Format("%s #%d", PoolTitle(CodeOfMap(m)), m.Mid(4, 2).ToInt(10));
	}

	// the old kit number (1..6) a pool stands in for: the Kit Test cheats (cw_testkit N) match jobs by it
	static clearscope int KitOfCode(String code)
	{
		static const String k[] = { "BAR,NCL,RST,PWN,CHP,GAM,BPL,DLB,MKT,CNV,MAL", "HKD,CLK,APT,TEN,LUX,HOT", "WHS,DOK,FAB,SUB,PRK,SAL,CON",
			"TUN,TRS,UND,FRM,BUN", "HAL,UNI,JAL,UNV,HSP,LIB,BAN", "DTC,LAB", "OFC,HQT,CLC,STD,TRN,RND" };   // 7 = the office pools
		for (int i = 0; i < 7; i++)
		{
			Array<String> a;
			k[i].Split(a, ",");
			if (a.Find(code) != a.Size()) return i + 1;
		}
		return 0;
	}

	// the pools the loaded pack holds, in CWPOOLS order (debug: cw_sitelist / cw_sitego)
	static clearscope int PoolTotal()
	{
		int lump = Wads.CheckNumForName("CWPOOLS", Wads.GlobalNamespace);
		if (lump < 0) return 0;
		Array<String> ls;
		Wads.ReadLump(lump).Split(ls, "\n");
		int n = 0;
		for (int i = 0; i < ls.Size(); i++) if (ls[i].Left(2) == "P\t") n++;
		return n;
	}
	static clearscope String CodeAt(int idx)
	{
		int lump = Wads.CheckNumForName("CWPOOLS", Wads.GlobalNamespace);
		if (lump < 0) return "";
		Array<String> ls;
		Wads.ReadLump(lump).Split(ls, "\n");
		int n = 0;
		for (int i = 0; i < ls.Size(); i++)
		{
			if (ls[i].Left(2) != "P\t") continue;
			if (n++ == idx) { Array<String> f; ls[i].Split(f, "\t"); return f.Size() > 1 ? f[1] : ""; }
		}
		return "";
	}
}
