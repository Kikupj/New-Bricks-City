// =============================================================================
// Corpo Wars — the five city districts (maps C01..C05), round 3 (2x scale).
//   C01 Meridian Row  C02 Eastgate Research Park  C03 Ironside Docks  C04 Old Quarter  C05 Highline
// The geometry comes from CorpoWars_tools/citydist.py (one profile-driven builder) plus the table lump citydist.txt
// (buildings, gateways, per-district zoning). Scale: storey 128, ground floor 128 (floor 8 -> 136), upper storeys 128
// each, sidewalks 112, streets 512-960. The player, cars and NPCs are NOT scaled.
// Every building is 3 sectors: FRAME (podium, floor 136, tag 10000+id), INNER (raised to 136 + 128*k, tag 20000+id)
// and NOTCH (door recess, tag 30000+id). From the campaign seed (cw_cityseed; each district derives its own) this
// handler zones the buildings, raises them, paints facades (ground row on the frame face, storeys above), places the
// authored corp properties from cwcity.txt onto suitable buildings first (by type and size class), fills the rest with
// generated neutral sites, and opens the door recess ONLY for enterable buildings.
// Districts are joined by gateways at the map edges (tunnel mouth, bridge, highway ramp, metro stair): walk or drive
// into the trigger and the neighbouring district loads with you (and your car) at the matching gateway.
//
//   Try it:   map C01..C05     (cw_cityseed 0 = random; the seed is kept across districts)
//   Debug:    netevent cw_district <1-5>   jump to a district         netevent cw_cityenter [building]  enter a kit
//             netevent cw_cityreturn       back to the city           netevent cw_cityperf            counts
// cw_cityalldoors 1 makes every non-empty building enterable.
// =============================================================================
class CW_CityLamp : Actor
{
	Default { Radius 8; Height 64; Scale 2.4; Tag "Street lamp"; }
	States { Spawn: TLMP ABCD 4 Bright; Loop; }
}

// Entrance marker (glowing sign) on the back wall of an enterable building's door recess.
class CW_CityDoor : Actor
{
	int bld;
	String kit;
	String title;
	bool live;
	Vector2 mouth;                    // where the recess meets the sidewalk
	Default { +NOGRAVITY; +NOBLOCKMAP; +WALLSPRITE; Radius 6; Height 16; Scale 2.2; Tag "Building entrance"; }
	States { Spawn: CWEX A -1 Bright; Stop; }
}

// Layer 2 of the distance illusion: a big flat cutout of a lit tower cluster, standing in a ring beyond the
// filler geometry and facing the middle of the city. Sprites CSKYA0..CSKYF0 (sprites/cityskyline/).
class CW_CitySkyline : Actor
{
	Default { +NOINTERACTION; +NOGRAVITY; +WALLSPRITE; +DONTSPLASH; Radius 4; Height 8; Scale 1.7; Tag "Skyline"; }
	States { Spawn: CSKY A -1 Bright; Stop; }
}

// Carries city -> kit -> city and district -> district state across level changes. Server cvars set from play code
// are only applied a tic later (after the level has already changed), so nothing travels through them.
// Not saved with the game: a save/load inside a city-launched kit forgets the way back (prototype limitation).
class CW_CityLink : StaticEventHandler
{
	int door;        // building id + 1 of the door the player went through (0 = none)
	int retDist;     // district that door is in
	int citySeed;    // the campaign city seed (all districts derive from it)
	int kitSeed;     // seed for the kit about to load (0 = none); consumed by CW_Handler
	int kitVar;      // variant for that kit (-1 = from the seed)
	int arrFrom;     // arriving through a gateway: the district we came from (0 = none)
	bool wasCar;     // ... in a car
	int carColour;
	bool hop;        // a deliberate district change: keep the seed
	// HUD city map (citymap.zs): a walk-in visit to a building, no mission
	bool visit;      // true from GO THERE until the player is back in HUB01
	String visitName;
	int visitDist, visitLot;
	int g02Seed, g02Role, g02Theme;   // layout for the G02 office floor about to load (0 = none); consumed by CW_Handler
	// After Hours site pack (sitepool.zs): which building of the pack this visit / mission is in, so a floor change (stairs) is not an insertion
	String siteBld;  // building name (SBAR03) the current visit started in, "" = none; cleared back in HUB01
	int siteTok;     // the visit: the mission's visit seed, 0 for a walk-in
	static clearscope CW_CityLink Get() { return CW_CityLink(StaticEventHandler.Find("CW_CityLink")); }
}

class CWG_Bld play
{
	int id, x0, y0, x1, y1, cx, nl, bx, by, fill, wf;
	String face, lm;
	int cls;            // 0 S, 1 M, 2 L, 3 filler
	int zone;
	int k;              // upper storeys
	int hgt;            // inner floor height
	bool enter;
	int kit, kvar;       // kit number 1..6 and variant, -1 = from the seed
	String title;
	bool taken;         // holds an authored property or a neutral site
	String up, gr;      // facade textures
	int xs;             // x shift of the facade pattern (whole bays), so neighbours differ
}

class CWG_Site play
{
	int type;           // CW_PropType
	String name, label, owner;
}

class CWG_Gate play
{
	String side, type;
	int target;
	double tx0, ty0, tx1, ty1, ax, ay, aang;
}

class CW_CityGen : EventHandler
{
	const SW = 112;
	const SWH = 8;
	const GND = 136;
	const STOREY = 128;
	const NOTCH_W = 128;
	const NOTCH_D = 24;
	const TAGF = 10000;
	const TAGI = 20000;
	const TAGN = 30000;
	const Z_EMPTY = 0;
	const Z_TOWER = 1;
	const Z_OFFICE = 2;
	const Z_RES = 3;
	const Z_IND = 4;
	const Z_CIVIC = 5;
	const Z_FILL = 6;
	const Z_LM = 7;
	const Z_YARD = 8;
	const MAXCARS = 44;
	const POOL_LIGHTS = 12;
	const EXT = 5600;
	const TEST_BLD_DIST = 1;

	bool active;
	int dist;                         // 1..5
	String dcode, dname, dstyle;
	double worldW, worldH, startX, startY;
	int seed, dseed;
	int nbx, nby;
	int zw[6], core;
	int htLo[7], htHi[7];
	Array<String> neutralMenu;
	String edgeN, edgeE, edgeS, edgeW;
	String lmKind, lmName; int lmK;
	Array<CWG_Bld> blds;
	Array<CWG_Gate> gates;
	Array<CWG_Site> sites;
	double blkX0[100], blkY0[100], blkX1[100], blkY1[100];
	Array<int> secBld;                // sector index -> building id (-1)
	Array<int> secKind;               // 1 frame, 2 inner, 3 notch
	int retBld;                       // building to reappear in front of (-1 = none)
	bool bounceHome;
	int carsMade, lampsMade, doorsMade, skyMade, propsPlaced, neutralPlaced;
	Array<double> candX;
	Array<double> candY;
	Array<double> candZ;
	Array<int> candKind;
	Array<CW_LightSource> pool;
	bool gateBusy;

	// ---------------------------------------------------------------- helpers
	int Hs(int a, int salt) { return CW_Building.Mix(dseed, a * 131 + salt); }

	static TextureID Tex(String name, String fallback)
	{
		TextureID t = TexMan.CheckForTexture(name, TexMan.Type_Any);
		if (!t.IsValid()) t = TexMan.CheckForTexture(fallback, TexMan.Type_Any);
		return t;
	}

	static String DistMap(int d) { return String.Format("C%02d", d); }

	static String Roof(int z, int k)
	{
		static const String roofs[] = { "CWCONCF", "CWTILEF", "ADFMARG", "ADFGRAT" };
		if (z == Z_EMPTY) return k % 3 == 0 ? "GRASS1" : "FLOOR0_6";
		if (z == Z_YARD) return "CWRAILB";
		return roofs[k % 4];
	}

	// ---------------------------------------------------------------- data
	void LoadData()
	{
		blds.Clear(); gates.Clear(); neutralMenu.Clear();
		int lump = Wads.CheckNumForFullName("citydist.txt");
		if (lump < 0) { Console.Printf("\crCW_CITY: citydist.txt missing"); return; }
		String txt = Wads.ReadLump(lump);
		Array<String> lines;
		txt.Split(lines, "\n");
		String dd = String.Format("%d", dist);
		for (int i = 0; i < 100; i++) { blkX0[i] = 1e9; blkY0[i] = 1e9; blkX1[i] = -1e9; blkY1[i] = -1e9; }
		nbx = 0; nby = 0;
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			if (ln.Length() == 0 || ln.Left(1) == "#") continue;
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 3 || f[1] != dd) continue;
			String k = f[0];
			if (k == "DIST")
			{
				dcode = f[2]; dname = f[3]; dstyle = f[4];
				worldW = f[5].ToInt(); worldH = f[6].ToInt(); startX = f[7].ToInt(); startY = f[8].ToInt();
			}
			else if (k == "ZW") { for (int z = 0; z < 6; z++) zw[z] = f[2 + z].ToInt(); core = f[8].ToInt(); }
			else if (k == "HT")
			{
				int z = 0;
				String zc = f[2];
				if (zc == "T") z = 0; else if (zc == "O") z = 1; else if (zc == "R") z = 2; else if (zc == "I") z = 3; else if (zc == "C") z = 4; else z = 5;
				htLo[z] = f[3].ToInt(); htHi[z] = f[4].ToInt();
			}
			else if (k == "NEUTRAL") { f[2].Split(neutralMenu, ","); }
			else if (k == "LM") { lmKind = f[2]; lmName = f[3]; lmK = f[4].ToInt(); }
			else if (k == "EDGES") { edgeN = f[2]; edgeE = f[3]; edgeS = f[4]; edgeW = f[5]; }
			else if (k == "B")
			{
				let b = new("CWG_Bld");
				b.id = f[2].ToInt(); b.x0 = f[3].ToInt(); b.y0 = f[4].ToInt(); b.x1 = f[5].ToInt(); b.y1 = f[6].ToInt();
				b.face = f[7];
				String c = f[8];
				b.cls = c == "S" ? 0 : (c == "M" ? 1 : (c == "L" ? 2 : 3));
				b.nl = f[9].ToInt(); b.bx = f[10].ToInt(); b.by = f[11].ToInt(); b.fill = f[12].ToInt(); b.wf = f[13].ToInt(); b.cx = f[14].ToInt();
				b.lm = f[15];
				b.kit = 0; b.kvar = -1;
				blds.Push(b);
				int bi = b.by * 10 + b.bx;
				blkX0[bi] = min(blkX0[bi], b.x0); blkY0[bi] = min(blkY0[bi], b.y0);
				blkX1[bi] = max(blkX1[bi], b.x1); blkY1[bi] = max(blkY1[bi], b.y1);
				nbx = max(nbx, b.bx + 1); nby = max(nby, b.by + 1);
			}
			else if (k == "GATE")
			{
				let g = new("CWG_Gate");
				g.side = f[2]; g.type = f[3]; g.target = f[4].ToInt();
				g.tx0 = f[5].ToInt(); g.ty0 = f[6].ToInt(); g.tx1 = f[7].ToInt(); g.ty1 = f[8].ToInt();
				g.ax = f[9].ToInt(); g.ay = f[10].ToInt(); g.aang = f[11].ToInt();
				gates.Push(g);
			}
		}
	}

	// the authored properties of this district: from the live campaign if there is one, else from cwcity.txt
	void LoadSites()
	{
		sites.Clear();
		let pm = players[consoleplayer].mo;
		let lg = pm ? CW_Ledger.Of(pm) : null;
		if (lg && lg.city)
		{
			let c = lg.city;
			for (int i = 0; i < c.props.Size(); i++)
			{
				let pr = c.props[i];
				if (pr.district != dist - 1) continue;
				let s = new("CWG_Site");
				s.type = pr.type;
				s.name = pr.sub >= 0 ? c.subs[pr.sub].name : "Meridian";
				s.label = pr.label;
				s.owner = pr.sub >= 0 ? c.SubOwnerLabel(pr.sub) : "Meridian";
				sites.Push(s);
			}
			return;
		}
		int lump = Wads.CheckNumForFullName("cwcity.txt");
		if (lump < 0) return;
		String txt = Wads.ReadLump(lump);
		Array<String> lines;
		txt.Split(lines, "\n");
		Array<String> corpN, corpC, subC, subN, subO;
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 4) continue;
			if (f[0] == "CORP") { corpC.Push(f[1]); corpN.Push(f[3]); }
			else if (f[0] == "SUB") { subC.Push(f[1]); subO.Push(f[2]); subN.Push(f[3]); }
		}
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			ln.StripRight();
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 4 || f[0] != "PROP") continue;
			if (!(f[3] ~== dcode)) continue;
			let s = new("CWG_Site");
			s.type = CW_City.TypeFromCode(f[2]);
			s.name = f[1];
			s.owner = "";
			for (int q = 0; q < subC.Size(); q++)
				if (subC[q] == f[1])
				{
					s.name = subN[q];
					for (int w = 0; w < corpC.Size(); w++) if (corpC[w] == subO[q]) s.owner = corpN[w];
				}
			s.label = f.Size() > 4 ? f[4] : "";
			sites.Push(s);
		}
	}

	// ---------------------------------------------------------------- zoning, heights, roster
	int PickZone(CWG_Bld b)
	{
		if (b.fill) return Z_FILL;
		if (b.lm != "-") return Z_LM;
		int w[6];
		for (int i = 0; i < 6; i++) w[i] = zw[i];
		double dx = (b.bx - (nbx - 1) / 2.0) / (nbx / 2.0), dy = (b.by - (nby - 1) / 2.0) / (nby / 2.0);
		double d = max(abs(dx), abs(dy));
		w[0] += int(core * max(0.0, 1.0 - d * 1.5));
		if (b.cls >= 1) { w[0] /= 3; w[2] /= 2; w[3] = w[3] * 2 + 6; }
		if (b.cls == 2) { w[0] = 0; w[1] /= 2; }
		int tot = 0;
		for (int i = 0; i < 6; i++) tot += w[i];
		if (tot <= 0) return Z_RES;
		int r = Hs(b.id, 11) % tot;
		for (int i = 0; i < 6; i++)
		{
			if (r < w[i])
			{
				static const int zmap[] = { Z_TOWER, Z_OFFICE, Z_RES, Z_IND, Z_CIVIC, Z_EMPTY };
				return zmap[i];
			}
			r -= w[i];
		}
		return Z_RES;
	}

	int StoreysFor(int z, int id)
	{
		int hi = 5, lo = 5;
		switch (z)
		{
			case Z_TOWER: lo = htLo[0]; hi = htHi[0]; break;
			case Z_OFFICE: lo = htLo[1]; hi = htHi[1]; break;
			case Z_RES: lo = htLo[2]; hi = htHi[2]; break;
			case Z_IND: lo = htLo[3]; hi = htHi[3]; break;
			case Z_CIVIC: lo = htLo[4]; hi = htHi[4]; break;
			case Z_FILL: lo = htLo[5]; hi = htHi[5]; break;
			case Z_LM: return lmK;
			case Z_YARD: return 0;
		}
		return lo + Hs(id, 21) % max(1, hi - lo + 1);
	}

	// zones / size classes a property type likes, packed: zone mask | (class mask << 16); class mask S=1 M=2 L=4
	static int PropWants(int t)
	{
		int zT = 1 << Z_TOWER, zO = 1 << Z_OFFICE, zR = 1 << Z_RES, zI = 1 << Z_IND, zC = 1 << Z_CIVIC;
		int zm = zO, cm = 3;
		if (t == PT_OFF || t == PT_HQ) zm = zT | zO;
		else if (t == PT_CLN) zm = zO | zC | zR;
		else if (t == PT_STU) zm = zC | zO;
		else if (t == PT_TRN) zm = zC | zI;
		else if (t == PT_RND) zm = zO | zI;
		else if (t == PT_LAB) zm = zO | zC;
		else if (t == PT_DC) zm = zO | zI;
		else if (t == PT_FARM) zm = zR | zI;
		else if (t == PT_BNK) { zm = zC | zI; cm = 1; }
		else if (t == PT_WH) { zm = zI; cm = 6; }
		else if (t == PT_DOCK) { zm = zI; cm = 4; }
		else if (t == PT_FAB) { zm = zI; cm = 6; }
		else if (t == PT_PLT) { zm = zI; cm = 4; }
		else if (t == PT_SUB) { zm = zI | zC; cm = 1; }
		else if (t == PT_PARK) { zm = 1 << Z_YARD; cm = 4; }
		else if (t == PT_SAL) { zm = 1 << Z_YARD; cm = 6; }
		return zm | (cm << 16);
	}

	// kit number 1..6 and variant for a property type (the SiteKit mapping in cityjobs.zs; office-like types use the tower kit)
	static void PropKit(int t, out int kit, out int kvar)
	{
		kit = 6; kvar = -1;
		switch (t)
		{
			case PT_DC: kit = 6; kvar = 0; break;
			case PT_LAB: case PT_RND: kit = 6; kvar = 1; break;
			case PT_FARM: kit = 4; kvar = 4; break;
			case PT_BNK: kit = 4; kvar = 5; break;
			case PT_WH: kit = 3; kvar = 0; break;
			case PT_DOCK: kit = 3; kvar = 1; break;
			case PT_FAB: kit = 3; kvar = 2; break;
			case PT_PLT: kit = 3; kvar = 3; break;
			case PT_SUB: kit = 3; kvar = 4; break;
			case PT_PARK: kit = 3; kvar = 5; break;
			case PT_SAL: kit = 3; kvar = 6; break;
			case PT_CLN: kit = 5; kvar = 4; break;
			case PT_STU: kit = 5; kvar = 1; break;
			case PT_TRN: kit = 5; kvar = 0; break;
		}
	}

	// neutral sites: kit, variant, title, preferred zone
	static bool NeutralInfo(String key, out int kit, out int kvar, out String title, out int zone)
	{
		kit = 1; kvar = 0; title = key; zone = Z_RES;
		if (key == "bar") { kit = 1; kvar = 0; title = "Bar"; zone = Z_RES; }
		else if (key == "restaurant") { kit = 1; kvar = 1; title = "Restaurant"; zone = Z_RES; }
		else if (key == "pawn") { kit = 1; kvar = 2; title = "Pawn shop"; zone = Z_RES; }
		else if (key == "market") { kit = 1; kvar = 3; title = "Street market"; zone = Z_RES; }
		else if (key == "mall") { kit = 1; kvar = 4; title = "Mall"; zone = Z_OFFICE; }
		else if (key == "druglab") { kit = 1; kvar = 5; title = "Back-room lab"; zone = Z_IND; }
		else if (key == "chopshop") { kit = 1; kvar = 6; title = "Chop shop"; zone = Z_IND; }
		else if (key == "gambling") { kit = 1; kvar = 7; title = "Gambling den"; zone = Z_RES; }
		else if (key == "tenement") { kit = 2; kvar = 0; title = "Tenement"; zone = Z_RES; }
		else if (key == "apartments") { kit = 2; kvar = 1; title = "Apartment block"; zone = Z_RES; }
		else if (key == "luxury") { kit = 2; kvar = 2; title = "Luxury apartments"; zone = Z_TOWER; }
		else if (key == "hotel") { kit = 2; kvar = 3; title = "Hotel"; zone = Z_OFFICE; }
		else if (key == "construction") { kit = 3; kvar = 7; title = "Construction site"; zone = Z_IND; }
		else if (key == "underpass") { kit = 4; kvar = 1; title = "Underpass"; zone = Z_IND; }
		else if (key == "transit") { kit = 4; kvar = 2; title = "Transit hub"; zone = Z_CIVIC; }
		else if (key == "parking") { kit = 4; kvar = 3; title = "Parking structure"; zone = Z_IND; }
		else if (key == "unionhall") { kit = 5; kvar = 0; title = "Union hall"; zone = Z_CIVIC; }
		else if (key == "university") { kit = 5; kvar = 3; title = "University"; zone = Z_CIVIC; }
		else if (key == "hospital") { kit = 5; kvar = 4; title = "Hospital"; zone = Z_CIVIC; }
		else if (key == "archive") { kit = 5; kvar = 5; title = "Records archive"; zone = Z_CIVIC; }
		else return false;
		return true;
	}

	void Rezone(CWG_Bld b, int z)
	{
		b.zone = z;
		b.k = StoreysFor(z, b.id);
		b.hgt = z == Z_EMPTY ? SWH : (z == Z_YARD ? SWH + 16 : GND + STOREY * b.k);
	}

	void PlaceRoster(bool allDoors)
	{
		int waterMask = 0;
		if (edgeN == "harbour") waterMask |= 1;
		if (edgeE == "harbour") waterMask |= 2;
		if (edgeS == "harbour") waterMask |= 4;
		if (edgeW == "harbour") waterMask |= 8;
		let dc = CVar.FindCVar("cw_citydebug");
		bool dbg = dc && dc.GetBool();
		Array<int> blkTaken;
		for (int i = 0; i < 100; i++) blkTaken.Push(0);
		int n = sites.Size();
		int rot = n > 0 ? Hs(77, 5) % n : 0;
		for (int q = 0; q < n; q++)
		{
			let s = sites[(q + rot) % n];
			int pw = PropWants(s.type);
			int zm = pw & 0xffff, cmk = pw >> 16;
			int best = -1, bs = -1000;
			for (int i = 0; i < blds.Size(); i++)
			{
				let b = blds[i];
				if (b.fill || b.taken || b.lm != "-") continue;
				int sc = Hs(b.id, 300 + q) % 14 - blkTaken[b.by * 10 + b.bx] * 5;
				if (b.zone == Z_EMPTY) sc -= 4;
				if (zm & (1 << b.zone)) sc += 12;
				if (cmk & (1 << b.cls)) sc += 8; else if (b.cls == 2 && (cmk & 2)) sc += 3;
				if (s.type == PT_DOCK && (b.wf & waterMask)) sc += 14;
				if (s.type != PT_DOCK && (b.wf & waterMask) && (zm & (1 << Z_IND))) sc += 1;
				if (sc > bs) { bs = sc; best = i; }
			}
			if (best < 0) continue;
			let b = blds[best];
			if (dbg) Console.Printf("ROSTER %s type %d zm %d cm %d -> bld %d zone %d score %d", s.name, s.type, zm, cmk, b.id, b.zone, bs);
			if (!(zm & (1 << b.zone)))
			{
				int z = 1;
				while (!(zm & (1 << z)) && z < 9) z++;
				Rezone(b, z);
			}
			b.taken = true; b.enter = true; blkTaken[b.by * 10 + b.bx] += 1;
			int kk, vv;
			PropKit(s.type, kk, vv);
			b.kit = kk; b.kvar = vv;
			String tn = s.label.Length() ? s.label : CW_City.TypeName(s.type);
			b.title = String.Format("%s - %s%s", s.name, CW_City.TypeCode(s.type), s.owner.Length() ? " (" .. s.owner .. ")" : "");
			if (s.label.Length()) b.title = b.title .. ", " .. s.label;
			propsPlaced++;
		}
		// neutral sites from the district's menu (or every non-empty building with cw_cityalldoors)
		int want = allDoors ? 9999 : 18;
		int made = 0;
		for (int pass = 0; pass < 40 && made < want; pass++)
		{
			int bestI = -1, bestS = -1000;
			String key = neutralMenu.Size() ? neutralMenu[pass % neutralMenu.Size()] : "bar";
			int kk, vv, zz; String tt;
			if (!NeutralInfo(key, kk, vv, tt, zz)) continue;
			for (int i = 0; i < blds.Size(); i++)
			{
				let b = blds[i];
				if (b.fill || b.taken || b.lm != "-" || b.zone == Z_EMPTY || b.zone == Z_YARD) continue;
				int sc = Hs(b.id, 900 + pass) % 14 - blkTaken[b.by * 10 + b.bx] * 5;
				if (b.zone == zz) sc += 10;
				if (b.cls == 0) sc += 3;
				if (sc > bestS) { bestS = sc; bestI = i; }
			}
			if (bestI < 0) break;
			let b = blds[bestI];
			b.taken = true; b.enter = true; b.kit = kk; b.kvar = vv; b.title = tt; blkTaken[b.by * 10 + b.bx] += 1;
			made++; neutralPlaced++;
		}
		if (allDoors)
		{
			for (int i = 0; i < blds.Size(); i++)
			{
				let b = blds[i];
				if (b.fill || b.taken || b.lm != "-" || b.zone == Z_EMPTY || b.zone == Z_YARD) continue;
				int kk, vv, zz; String tt;
				NeutralInfo(neutralMenu.Size() ? neutralMenu[b.id % neutralMenu.Size()] : "bar", kk, vv, tt, zz);
				b.taken = true; b.enter = true; b.kit = kk; b.kvar = vv; b.title = tt;
			}
		}
	}

	String UpperTex(CWG_Bld b)
	{
		static const String letter[] = { "F", "A", "B", "C", "D", "E", "F", "A", "D" };
		String l = letter[b.zone];
		if (b.zone == Z_LM)
		{
			if (b.lm == "garrison" || b.lm == "stack") l = "D";
			else if (b.lm == "clock") l = "E";
			else if (b.lm == "quad") l = "E";
		}
		return "CWU" .. dstyle .. l;
	}
	String GroundTex(CWG_Bld b)
	{
		static const String letter[] = { "A", "B", "B", "A", "C", "B", "C", "B", "C" };
		String l = letter[b.zone];
		if (b.zone == Z_FILL) l = (b.id % 2) ? "A" : "C";
		return "CWG" .. dstyle .. l;
	}

	// ---------------------------------------------------------------- geometry edits
	void FloorTo(int tag, double h)
	{
		let it = level.CreateSectorTagIterator(tag);
		int s;
		while ((s = it.Next()) >= 0)
		{
			Sector sec = level.sectors[s];
			double dz = h - sec.floorplane.ZAtPoint(sec.centerspot);
			if (dz == 0) continue;
			sec.MoveFloor(abs(dz) + 1, sec.floorplane.PointToDist(sec.centerspot, h), -1, dz > 0 ? 1 : -1, false);
		}
	}

	// paint one line: texture on both sides + a world-continuous x offset so the window rhythm flows around corners
	void PaintLine(Line ln, TextureID t, double xshift = 0)
	{
		double dx = ln.v2.p.x - ln.v1.p.x, dy = ln.v2.p.y - ln.v1.p.y;
		bool horiz = abs(dx) > abs(dy);
		double w1 = horiz ? ln.v1.p.x : ln.v1.p.y, w2 = horiz ? ln.v2.p.x : ln.v2.p.y;
		bool plus = (w2 > w1);
		for (int k = 0; k < 2; k++)
		{
			if (!ln.sidedef[k]) continue;
			ln.sidedef[k].SetTexture(Side.bottom, t);
			double org, dirPlus;
			if (k == 0) { org = w1; dirPlus = plus ? 1 : -1; }
			else { org = w2; dirPlus = plus ? -1 : 1; }
			double off = (dirPlus > 0 ? org : -org) + xshift;
			ln.sidedef[k].SetTextureXOffset(Side.bottom, off);
			ln.sidedef[k].SetTextureYOffset(Side.bottom, 0);
		}
	}

	void PaintBuilding(CWG_Bld b)
	{
		TextureID up = Tex(b.up, "STARGR1");
		TextureID gr = Tex(b.gr, "STARG3");
		TextureID doorT = Tex("CWDOORWL", "DOOR3");
		TextureID doorS = Tex("CWDOORSD", "STARG3");
		double frontY = b.face == "S" ? b.y0 + NOTCH_D : b.y1 - NOTCH_D;
		for (int kind = 1; kind <= 3; kind++)
		{
			int tag = (kind == 1 ? TAGF : (kind == 2 ? TAGI : TAGN)) + b.id;
			let it = level.CreateSectorTagIterator(tag);
			int s;
			while ((s = it.Next()) >= 0)
			{
				Sector sec = level.sectors[s];
				double fh = sec.floorplane.ZAtPoint(sec.centerspot);
				for (int l = 0; l < sec.lines.Size(); l++)
				{
					Line ln = sec.lines[l];
					if (!ln.sidedef[0] || !ln.sidedef[1]) continue;
					Sector other = (ln.frontsector == sec) ? ln.backsector : ln.frontsector;
					if (!other) continue;
					double oh = other.floorplane.ZAtPoint(other.centerspot);
					int os = other.Index();
					bool sameBld = (secBld[os] == b.id);
					if (kind == 2)
					{
						if (oh < fh && b.zone != Z_YARD) PaintLine(ln, up, b.xs);
					}
					else if (kind == 1)
					{
						if (sameBld) continue;                        // inner / notch lines are painted by their own sector
						if (oh < fh) PaintLine(ln, gr, b.xs);
					}
					else
					{
						if (sameBld)
						{
							if (!b.enter) continue;
							bool back = (abs(ln.v1.p.y - frontY) < 0.5 && abs(ln.v2.p.y - frontY) < 0.5);
							if (oh > fh) PaintLine(ln, back ? doorT : doorS, 0);
						}
						else if (oh < fh) PaintLine(ln, gr, b.xs);           // closed recess: the mouth is plain ground-floor wall
					}
				}
			}
		}
	}

	// ---------------------------------------------------------------- generation
	override void WorldLoaded(WorldEvent e)
	{
		active = false;
		dist = 0;
		String mn = level.MapName;
		if (mn.Length() == 3 && mn.Left(2) ~== "C0") dist = mn.Mid(2, 1).ToInt();
		active = (dist >= 1 && dist <= 5);
		retBld = -1;
		bounceHome = false;
		gateBusy = false;
		let lk = CW_CityLink.Get();
		if (!active)
		{
			// a kit mission launched from the city ends in HUB01: send the player on back to the city
			let au = CVar.FindCVar("cw_cityauto");
			if (level.MapName ~== "HUB01" && lk && lk.door > 0 && au && au.GetBool()) bounceHome = true;
			return;
		}
		LoadData();
		if (blds.Size() == 0) { active = false; return; }
		let cvs = CVar.FindCVar("cw_cityseed");
		let act = CVar.FindCVar("cw_cityseedact");
		seed = cvs ? cvs.GetInt() : 0;
		if (seed == 0) seed = (lk && lk.citySeed != 0 && (lk.door > 0 || lk.arrFrom > 0 || lk.hop)) ? lk.citySeed : Random(1, 0x7ffffff);
		if (lk) lk.citySeed = seed;
		if (act) act.SetInt(seed);
		dseed = CW_Building.Mix(seed, 7919 * dist + 13);
		retBld = (lk && lk.door > 0 && lk.retDist == dist) ? lk.door - 1 : -1;
		let ad = CVar.FindCVar("cw_cityalldoors");
		bool allDoors = ad && ad.GetBool();

		// zones, heights, roster
		for (int i = 0; i < blds.Size(); i++)
		{
			let b = blds[i];
			Rezone(b, PickZone(b));
			if (b.lm != "-" && b.lm == "quad") { b.zone = Z_EMPTY; b.hgt = SWH; b.k = 0; }
			if (b.lm != "-" && b.lm == "garrison") { b.hgt = GND + STOREY * 2; b.k = 2; }
		}
		LoadSites();
		PlaceRoster(allDoors);

		// map every sector to its building
		secBld.Clear(); secKind.Clear();
		for (int s = 0; s < level.sectors.Size(); s++) { secBld.Push(-1); secKind.Push(0); }
		for (int i = 0; i < blds.Size(); i++)
		{
			let b = blds[i];
			for (int kind = 1; kind <= 3; kind++)
			{
				int tag = (kind == 1 ? TAGF : (kind == 2 ? TAGI : TAGN)) + b.id;
				let it = level.CreateSectorTagIterator(tag);
				int s;
				while ((s = it.Next()) >= 0) { secBld[s] = b.id; secKind[s] = kind; }
			}
		}
		// raise / lower, texture, light
		for (int i = 0; i < blds.Size(); i++)
		{
			let b = blds[i];
			b.up = UpperTex(b); b.gr = GroundTex(b);
			b.xs = 64 * (Hs(b.id, 55) % 4);
			String roof = Roof(b.zone, Hs(b.id, 900));
			bool open = (b.zone == Z_EMPTY);
			if (open) FloorTo(TAGF + b.id, SWH);
			FloorTo(TAGI + b.id, b.hgt);
			if (b.enter || open) FloorTo(TAGN + b.id, SWH);
			for (int kind = 1; kind <= 3; kind++)
			{
				int tag = (kind == 1 ? TAGF : (kind == 2 ? TAGI : TAGN)) + b.id;
				let it = level.CreateSectorTagIterator(tag);
				int s;
				while ((s = it.Next()) >= 0)
				{
					Sector sec = level.sectors[s];
					if (kind == 3 && b.enter) { sec.SetLightLevel(170); continue; }
					sec.SetTexture(Sector.floor, Tex(roof, "FLAT1"));
					sec.SetLightLevel(open ? 150 : (kind == 1 ? 100 : 70));
				}
			}
		}
		for (int i = 0; i < blds.Size(); i++) PaintBuilding(blds[i]);
		SpawnLampsAndDoors();
		SpawnCars();
		SpawnSkyline();
		for (int i = 0; i < POOL_LIGHTS; i++)
		{
			let l = CW_LightSource.Make((candX.Size() ? candX[0] : 0, candY.Size() ? candY[0] : 0, candZ.Size() ? candZ[0] : 0), 255, 214, 150, 380);
			pool.Push(l);
		}
		UpdateLights();
		Console.Printf("CW_CITY %s (%s) seed %d: %d buildings, %d authored properties + %d neutral sites enterable, %d gateways", dname, DistMap(dist), seed, blds.Size(), propsPlaced, neutralPlaced, gates.Size());
	}

	void AddCand(Vector3 p, int kind) { candX.Push(p.x); candY.Push(p.y); candZ.Push(p.z); candKind.Push(kind); }

	void SpawnLampsAndDoors()
	{
		for (int by = 0; by < nby; by++)
			for (int bx = 0; bx < nbx; bx++)
			{
				int bi = by * 10 + bx;
				if (blkX0[bi] > 1e8) continue;
				if (Hs(1500 + bi, 3) % 100 >= 75) continue;
				double x = blkX0[bi] - SW / 2, y = blkY0[bi] - SW / 2;
				Actor.Spawn("CW_CityLamp", (x, y, SWH));
				AddCand((x, y, SWH + 190), 0);
				lampsMade++;
				if (Hs(1600 + bi, 4) % 100 < 40)
				{
					double x2 = (blkX0[bi] + blkX1[bi]) / 2, y2 = blkY0[bi] - SW / 2;
					Actor.Spawn("CW_CityLamp", (x2, y2, SWH));
					AddCand((x2, y2, SWH + 190), 0);
					lampsMade++;
				}
			}
		// quay / bridge lamps on water sides
		for (int side = 0; side < 4; side++)
		{
			String ed = side == 0 ? edgeN : (side == 1 ? edgeE : (side == 2 ? edgeS : edgeW));
			if (ed != "harbour" && ed != "canal") continue;
			double len = (side == 0 || side == 2) ? worldW : worldH;
			for (double u = 640; u < len - 400; u += 960)
			{
				double px, py;
				if (side == 0) { px = u; py = worldH + 96; }
				else if (side == 1) { px = worldW + 96; py = u; }
				else if (side == 2) { px = u; py = -96; }
				else { px = -96; py = u; }
				Actor.Spawn("CW_CityLamp", (px, py, SWH));
				AddCand((px, py, SWH + 190), 0);
				lampsMade++;
			}
		}
		// gateway approaches: a lamp on each side of the roadway every ~560 units from the arrival point to the trigger
		for (int g = 0; g < gates.Size(); g++)
		{
			let gt = gates[g];
			Vector2 a0 = (gt.ax, gt.ay), a1 = ((gt.tx0 + gt.tx1) / 2, (gt.ty0 + gt.ty1) / 2);
			Vector2 dv = a1 - a0;
			double ln = dv.Length();
			if (ln < 100) continue;
			dv /= ln;
			Vector2 pv = (-dv.y, dv.x);
			for (double d = 240; d < ln - 60; d += 560)
				for (int sd = -1; sd <= 1; sd += 2)
				{
					Vector2 p = a0 + dv * d + pv * (176 * sd);
					double fz = level.PointInSector(p).floorplane.ZAtPoint(p);
					Actor.Spawn("CW_CityLamp", (p.x, p.y, fz));
					AddCand((p.x, p.y, fz + 190), 0);
					lampsMade++;
				}
		}
		// entrance signs: ONLY enterable buildings get one (glowing sign on the back wall of the door recess) + a light
		for (int i = 0; i < blds.Size(); i++)
		{
			let b = blds[i];
			if (!b.enter) continue;
			double mouthY = b.face == "S" ? b.y0 : b.y1;
			double ang = b.face == "S" ? 270 : 90;              // pointing out of the building
			Vector2 sp = (b.cx, mouthY) + Actor.AngleToVector(ang + 180, NOTCH_D - 2);
			let d = CW_CityDoor(Actor.Spawn("CW_CityDoor", (sp.x, sp.y, SWH + 108)));
			if (!d) continue;
			d.bld = b.id; d.kit = "K0" .. b.kit; d.title = b.title;
			d.angle = ang;
			d.live = true;
			d.mouth = (b.cx, mouthY);
			Vector2 lp = d.mouth + Actor.AngleToVector(ang, 12);
			AddCand((lp.x, lp.y, SWH + 90), 1);
			doorsMade++;
		}
	}

	void UpdateLights()
	{
		if (pool.Size() == 0 || candX.Size() == 0) return;
		Actor v = players[consoleplayer].mo;
		if (players[consoleplayer].camera) v = players[consoleplayer].camera;
		if (!v) return;
		Array<int> taken;
		for (int i = 0; i < pool.Size(); i++)
		{
			int best = -1; double bd = 1e13;
			for (int c = 0; c < candX.Size(); c++)
			{
				if (taken.Find(c) != taken.Size()) continue;
				double d = ((candX[c], candY[c]) - v.pos.xy).LengthSquared();
				if (candKind[c] == 1) d *= 0.3;
				if (d < bd) { bd = d; best = c; }
			}
			if (best < 0 || !pool[i]) continue;
			taken.Push(best);
			let l = pool[i];
			l.SetOrigin((candX[best], candY[best], candZ[best]), false);
			if (candKind[best] == 1) { l.args[DynamicLight.LIGHT_RED] = 255; l.args[DynamicLight.LIGHT_GREEN] = 226; l.args[DynamicLight.LIGHT_BLUE] = 150; l.args[DynamicLight.LIGHT_INTENSITY] = 200; }
			else { l.args[DynamicLight.LIGHT_RED] = 255; l.args[DynamicLight.LIGHT_GREEN] = 206; l.args[DynamicLight.LIGHT_BLUE] = 140; l.args[DynamicLight.LIGHT_INTENSITY] = 420; }
		}
	}

	CW_Car MakeCar(double x, double y, double ang, int colour)
	{
		let c = CW_Car(Actor.Spawn("CW_Car", (x, y, SWH)));
		if (!c) return null;
		c.angle = ang;
		c.SetColour(colour);
		carsMade++;
		return c;
	}

	void SpawnCars()
	{
		// two beside the start crossing
		MakeCar(startX + 90, startY + 300, 90, 1);
		MakeCar(startX - 90, startY + 520, 270, 6);
		// along the streets: north-south streets between block columns, east-west between block rows
		for (int k = 0; k <= nbx; k++)
		{
			double xa = k == 0 ? 0 : blkX1[0 * 10 + k - 1], xb = k == nbx ? worldW : blkX0[0 * 10 + k];
			double mid = (xa + xb) / 2, lane = (xb - xa - 2 * SW) / 4;
			for (int by = 0; by < nby; by++)
				for (int slot = 0; slot < 3; slot++)
				{
					int h = Hs(2000 + k * 40 + by * 3 + slot, 8);
					if (carsMade >= MAXCARS || h % 100 >= 14) continue;
					int side = ((h >> 8) & 1) ? 1 : -1;
					MakeCar(mid + side * lane, blkY0[by * 10] + 200 + slot * 330, side > 0 ? 90 : 270, h >> 12);
				}
		}
		for (int k = 0; k <= nby; k++)
		{
			double ya = k == 0 ? 0 : blkY1[(k - 1) * 10], yb = k == nby ? worldH : blkY0[k * 10];
			double mid = (ya + yb) / 2, lane = (yb - ya - 2 * SW) / 4;
			for (int bx = 0; bx < nbx; bx++)
				for (int slot = 0; slot < 3; slot++)
				{
					int h = Hs(4000 + k * 40 + bx * 3 + slot, 9);
					if (carsMade >= MAXCARS || h % 100 >= 14) continue;
					int side = ((h >> 8) & 1) ? 1 : -1;
					MakeCar(blkX0[bx] + 200 + slot * 330, mid + side * lane, side > 0 ? 180 : 0, h >> 12);
				}
		}
	}

	void MakeSky(double x, double y, double z, double ang, int variant, double sc)
	{
		let b = Actor.Spawn("CW_CitySkyline", (x, y, z));
		if (!b) return;
		b.frame = abs(variant) % 6;
		b.angle = ang;
		b.scale = (sc, sc);
		skyMade++;
	}

	// Skyline billboards: two rings beyond the filler geometry (on land: far ground on every side, the far shore across
	// the harbour), each a flat cutout facing the middle of the city.
	void SpawnSkyline()
	{
		int n = 0;
		for (int row = 0; row < 2; row++)
		{
			double sc = row == 0 ? 1.8 : 2.5;
			double step = 2048 * sc * 0.92;
			double off = row == 0 ? 4750 : 5400;
			double z = 4;
			double lo = -off, hiW = worldW + off, hiH = worldH + off;
			int cnt = int((hiW - lo) / step) + 1;
			for (int i = 0; i < cnt; i++)
			{
				double x = lo + i * step + row * step * 0.5;
				MakeSky(x, worldH + off, z, 270, Hs(6000 + n, 1), sc); n++;
				MakeSky(x, -off, z, 90, Hs(6000 + n, 1), sc); n++;
			}
			cnt = int((hiH - lo) / step) + 1;
			for (int i = 0; i < cnt; i++)
			{
				double y = lo + i * step + row * step * 0.5;
				MakeSky(-off, y, z, 0, Hs(6000 + n, 1), sc); n++;
				MakeSky(worldW + off, y, z, 180, Hs(6000 + n, 1), sc); n++;
			}
		}
	}

	// ---------------------------------------------------------------- doors, gateways, returning, debug events
	void EnterKit(int bi, int pn)
	{
		if (bi < 0 || bi >= blds.Size()) return;
		let b = blds[bi];
		if (!b.enter) return;
		int ks = Hs(bi, 9000);
		if (ks == 0) ks = 1;
		let lk = CW_CityLink.Get();
		if (lk) { lk.kitSeed = ks; lk.kitVar = b.kvar; lk.door = bi + 1; lk.retDist = dist; lk.citySeed = seed; }
		String kit = "K0" .. b.kit;
		Console.Printf("CW_CITY %s building %d (%s) -> %s v%d, seed %d", DistMap(dist), bi, b.title, kit, b.kvar, ks);
		level.ChangeLevel(kit, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}

	void PlaceAtDoor(int bi)
	{
		if (bi < 0 || bi >= blds.Size()) return;
		let b = blds[bi];
		double mouthY = b.face == "S" ? b.y0 : b.y1;
		double ang = b.face == "S" ? 270 : 90;
		Vector2 p = (b.cx, mouthY) + Actor.AngleToVector(ang, 44);
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo) continue;
			let pm = players[i].mo;
			pm.SetOrigin((p + Actor.AngleToVector(ang + 90, 24 * i), SWH), false);
			pm.angle = ang + 180;
			pm.vel = (0, 0, 0);
		}
	}

	void GoDistrict(int target, int fromDist, bool car, int carColour)
	{
		if (target < 1 || target > 5) return;
		let lk = CW_CityLink.Get();
		if (lk)
		{
			lk.arrFrom = fromDist; lk.wasCar = car; lk.carColour = carColour; lk.citySeed = seed; lk.hop = true; lk.door = 0;
		}
		gateBusy = true;
		Console.Printf("CW_CITY gateway: %s -> %s%s", DistMap(dist), DistMap(target), car ? " (driving)" : "");
		level.ChangeLevel(DistMap(target), 0, CHANGELEVEL_NOINTERMISSION);
	}

	void ArriveAtGateway()
	{
		let lk = CW_CityLink.Get();
		if (!lk || lk.arrFrom <= 0) return;
		CWG_Gate g = null;
		for (int i = 0; i < gates.Size(); i++) if (gates[i].target == lk.arrFrom) g = gates[i];
		if (!g) { lk.arrFrom = 0; return; }
		bool car = lk.wasCar; int col = lk.carColour;
		lk.arrFrom = 0; lk.wasCar = false;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo) continue;
			let pm = players[i].mo;
			pm.SetOrigin((g.ax, g.ay, SWH), false);
			pm.angle = g.aang;
			pm.vel = (0, 0, 0);
			if (car && i == consoleplayer)
			{
				let c = MakeCar(g.ax, g.ay, g.aang, col);
				if (c) c.Enter(players[i]);
			}
		}
	}

	override void WorldTick()
	{
		if (bounceHome && level.time == 6)
		{
			bounceHome = false;
			let lk = CW_CityLink.Get();
			int rd = (lk && lk.retDist >= 1 && lk.retDist <= 5) ? lk.retDist : 1;
			Console.Printf("CW_CITY back to the city (%s)", DistMap(rd));
			level.ChangeLevel(DistMap(rd), 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
			return;
		}
		if (!active) return;
		if (level.time == 3)
		{
			if (retBld >= 0)
			{
				PlaceAtDoor(retBld);
				retBld = -1;
				let lk = CW_CityLink.Get();
				if (lk) lk.door = 0;
			}
			else ArriveAtGateway();
		}
		if (level.time % 8 == 0) UpdateLights();
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo) continue;
			PlayerInfo p = players[i];
			if (p.mo.health <= 0) continue;
			let car = CW_Car.DrivenBy(p);
			// gateways: walking or driving into the trigger
			if (!gateBusy && level.time > 10)
			{
				for (int g = 0; g < gates.Size(); g++)
				{
					let gt = gates[g];
					Vector2 q = p.mo.pos.xy;
					if (q.x >= gt.tx0 && q.x <= gt.tx1 && q.y >= gt.ty0 && q.y <= gt.ty1)
					{
						int col = 0;
						bool drv = false;
						if (car) { drv = true; col = car.colour; car.Exit(true); }
						GoDistrict(gt.target, dist, drv, col);
						return;
					}
				}
			}
			if (car != null) continue;
			// nearest entrance (only enterable buildings have one)
			let it = ThinkerIterator.Create("CW_CityDoor");
			CW_CityDoor d;
			CW_CityDoor best = null;
			double bd = 110;
			while (d = CW_CityDoor(it.Next()))
			{
				double dd = (d.mouth - p.mo.pos.xy).Length();
				if (dd < bd && abs(SWH - p.mo.pos.z) < 72) { bd = dd; best = d; }
			}
			if (!best) continue;
			if (CW_Car.Find(p.mo, 60) != null) continue;
			if ((level.time % 35) == 0 && i == consoleplayer)
				Console.MidPrint(SmallFont, "[USE] Enter " .. best.title .. "  [" .. best.kit .. "]");
			bool press = (p.cmd.buttons & BT_USE) && !(p.oldbuttons & BT_USE);
			if (!press) continue;
			EnterKit(best.bld, i);
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "cw_cityreturn")
		{
			let lk = CW_CityLink.Get();
			if (active) { PlaceAtDoor(lk && lk.door > 0 ? lk.door - 1 : 0); return; }
			level.ChangeLevel(DistMap(lk && lk.retDist >= 1 ? lk.retDist : 1), 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
		}
		else if (e.Name ~== "cw_district")
		{
			int n = e.Args[0];
			if (n < 1 || n > 5) { Console.Printf("cw_district <1-5>"); return; }
			let lk = CW_CityLink.Get();
			if (lk) { lk.arrFrom = 0; lk.door = 0; lk.wasCar = false; lk.hop = true; if (active) lk.citySeed = seed; }
			level.ChangeLevel(DistMap(n), 0, CHANGELEVEL_NOINTERMISSION);
		}
		else if (e.Name ~== "cw_cityenter" && active)
		{
			int bi = e.Args[0];
			if (bi <= 0)      // no argument: the first enterable building
			{
				for (int i = 0; i < blds.Size(); i++) if (blds[i].enter) { bi = i; break; }
			}
			EnterKit(bi, e.Player);
		}
		else if (e.Name ~== "cw_citylist" && active)
		{
			for (int i = 0; i < blds.Size(); i++) if (blds[i].enter) Console.Printf("bld %d cls %d zone %d k %d at %d,%d face %s: %s [K0%d v%d]", i, blds[i].cls, blds[i].zone, blds[i].k, blds[i].cx, (blds[i].face == "S" ? blds[i].y0 : blds[i].y1), blds[i].face, blds[i].title, blds[i].kit, blds[i].kvar);
		}
		else if (e.Name ~== "cw_cityperf")
		{
			int things = 0, cars = 0, lamps = 0, lights = 0, sky = 0, doors = 0;
			let it = ThinkerIterator.Create("Actor");
			Actor a;
			while (a = Actor(it.Next()))
			{
				things++;
				if (a is "CW_Car") cars++;
				else if (a is "CW_CityLamp") lamps++;
				else if (a is "CW_CitySkyline") sky++;
				else if (a is "CW_CityDoor") doors++;
				else if (a is "DynamicLight") lights++;
			}
			Console.Printf("CW_CITYPERF %s: sectors %d, lines %d, sides %d, vertexes %d | actors %d (cars %d, lamps %d, skyline billboards %d, door signs %d, dynamic lights %d) | buildings %d, gates %d | tic %d",
				level.MapName, level.sectors.Size(), level.lines.Size(), level.sides.Size(), level.vertexes.Size(), things, cars, lamps, sky, doors, lights, blds.Size(), gates.Size(), level.time);
		}
	}
}
