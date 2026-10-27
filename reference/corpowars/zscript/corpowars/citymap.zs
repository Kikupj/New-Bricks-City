// =============================================================================
// Corpo Wars — the city as DATA (no geometry): five districts, block grids, lots, roster placement.
// Feeds the HUD city map (citymapui.zs). Ported from the archived walkable city (citygen.zs / citydist.txt):
// same zoning, heights and roster logic, so a campaign seed gives the same city the archived maps had.
//
//   CW_CityMap.Build()  builds everything from: the campaign seed (cw_cityseed, else the ledger's first property
//                       seed, else 7), citydist.txt (blocks + district profiles) and the live CW_City (authored
//                       properties, strongholds, minor turf) or, with no campaign yet, cwcity.txt.
//   Every function is clearscope: the map screen (ui) and the network events (play) both build the same data.
//   Layout seeds: an authored property keeps its campaign seed (CWC_Prop.seed, the same one the contract launcher
//   uses); every other lot gets Mix(district seed, lot id).
//   Debug: netevent cw_mapdump
// =============================================================================
class CWM_Lot
{
	int id, dist;                   // dist 0..4
	int x0, y0, x1, y1;             // footprint, district space (y up)
	int bx, by, cls, zone, wf;      // block cell, size class 0 S 1 M 2 L, zoning, water-front mask
	int storeys, height;
	bool fill, enter, taken;
	bool shellHid;                  // owner is a shell subsidiary with an unknown parent: neutral colour, parent hidden
	String lm;                      // landmark kind or "-"
	String kind;                    // property, stronghold, neutral, landmark, building, filler
	String name, typeName, sub, corpName, owner;
	int corp;                       // 0..5 corp, 6 Meridian receivership, -1 independent
	int minor;                      // stronghold: minor player index, else -1
	int propType;                   // CW_PropType or -1
	int kit, kvar;                  // 1..6 = K01..K06, 0 = G02 office floor
	String map;                     // "K03", "G02" ...
	int seed, theme;
	double cx, cy;                  // centre in city space
}

class CWM_Site
{
	int type;                       // PT_* (-1 = stronghold)
	String name, label, sub, corpName;
	int corp, minor, seed, theme, district;
	bool stronghold;
	bool shellHid;                  // shell subsidiary whose parent the player has not uncovered
	String hname;
}

class CWM_Dist
{
	int idx;                        // 0..4
	String code, name, style;
	double w, h;                    // district size
	double ox, oy;                  // south-west corner in city space
	String eN, eE, eS, eW;          // edge kinds
	String lmKind, lmName;
	int lmK;
	int zw[6], core, htLo[7], htHi[7];
	Array<String> neutralMenu;
	int nbx, nby;
	double blkX0[100], blkY0[100], blkX1[100], blkY1[100];
	Array<CWM_Lot> lots;
	int dseed;
	int turfMinor, turfPct;         // dominant minor player here (turfPct >= 30 to count)
	int nProp, nHold, nNeutral;
	clearscope int Enterable()
	{
		int n = 0;
		for (int i = 0; i < lots.Size(); i++) if (lots[i].enter) n++;
		return n;
	}
}

class CW_CityMap
{
	const Z_EMPTY = 0;
	const Z_TOWER = 1;
	const Z_OFFICE = 2;
	const Z_RES = 3;
	const Z_IND = 4;
	const Z_CIVIC = 5;
	const Z_FILL = 6;
	const Z_LM = 7;
	const Z_YARD = 8;
	const GAP = 2600;
	const HARBOUR = 9000;
	const STOREY = 128;

	int seed;
	bool live;                       // built from the live campaign
	Array<CWM_Dist> dists;
	Array<CWM_Site> sites;
	Array<String> corpShort, corpName;
	Array<String> minorName, minorShort;
	double minX, minY, maxX, maxY;   // land bounds, city space

	// ---------------------------------------------------------------- entry
	static clearscope CW_CityMap Build()
	{
		let m = new("CW_CityMap");
		m.Init();
		return m;
	}

	clearscope int Hs(CWM_Dist d, int a, int salt) { return CW_Building.Mix(d.dseed, a * 131 + salt); }

	clearscope void Init()
	{
		let cv = CVar.FindCVar("cw_cityseed");
		int cs = cv ? cv.GetInt() : 0;
		CW_Ledger lg = null;
		if (players[consoleplayer].mo) lg = CW_Ledger.Of(players[consoleplayer].mo);
		CW_City city = lg ? lg.city : null;
		if (cs != 0) seed = cs;
		else if (city && city.props.Size() > 0) seed = 1 + (city.props[0].seed & 0xffffff);
		else seed = 7;
		live = (city != null);
		LoadDistricts();
		LoadSites(city);
		for (int i = 0; i < dists.Size(); i++) Generate(dists[i]);
		Layout();
	}

	// ---------------------------------------------------------------- data
	clearscope void LoadDistricts()
	{
		dists.Clear();
		for (int i = 0; i < 5; i++)
		{
			let d = new("CWM_Dist");
			d.idx = i;
			d.turfMinor = -1;
			dists.Push(d);
		}
		int lump = Wads.CheckNumForFullName("citydist.txt");
		if (lump < 0) { Console.Printf("\crCW_MAP: citydist.txt missing"); return; }
		String txt = Wads.ReadLump(lump);
		Array<String> lines;
		txt.Split(lines, "\n");
		for (int i = 0; i < 5; i++)
		{
			let d = dists[i];
			for (int q = 0; q < 100; q++) { d.blkX0[q] = 1e9; d.blkY0[q] = 1e9; d.blkX1[q] = -1e9; d.blkY1[q] = -1e9; }
		}
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			if (ln.Length() == 0 || ln.Left(1) == "#") continue;
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 3) continue;
			int di = f[1].ToInt() - 1;
			if (di < 0 || di > 4) continue;
			let d = dists[di];
			String k = f[0];
			if (k == "DIST")
			{
				d.code = f[2]; d.name = f[3]; d.style = f[4];
				d.w = f[5].ToInt(); d.h = f[6].ToInt();
			}
			else if (k == "ZW") { for (int z = 0; z < 6; z++) d.zw[z] = f[2 + z].ToInt(); d.core = f[8].ToInt(); }
			else if (k == "HT")
			{
				int z = 5;
				String zc = f[2];
				if (zc == "T") z = 0; else if (zc == "O") z = 1; else if (zc == "R") z = 2; else if (zc == "I") z = 3; else if (zc == "C") z = 4;
				d.htLo[z] = f[3].ToInt(); d.htHi[z] = f[4].ToInt();
			}
			else if (k == "NEUTRAL") { f[2].Split(d.neutralMenu, ","); }
			else if (k == "LM") { d.lmKind = f[2]; d.lmName = f[3]; d.lmK = f[4].ToInt(); }
			else if (k == "EDGES") { d.eN = f[2]; d.eE = f[3]; d.eS = f[4]; d.eW = f[5]; }
			else if (k == "B")
			{
				let b = new("CWM_Lot");
				b.dist = di;
				b.id = f[2].ToInt(); b.x0 = f[3].ToInt(); b.y0 = f[4].ToInt(); b.x1 = f[5].ToInt(); b.y1 = f[6].ToInt();
				String c = f[8];
				b.cls = c == "S" ? 0 : (c == "M" ? 1 : (c == "L" ? 2 : 3));
				b.bx = f[10].ToInt(); b.by = f[11].ToInt();
				b.fill = f[12].ToInt() != 0;
				b.wf = f[13].ToInt();
				b.lm = f[15];
				b.minor = -1; b.propType = -1; b.corp = -1; b.kit = 0; b.kvar = -1;
				b.kind = "building";
				d.lots.Push(b);
				int bi = b.by * 10 + b.bx;
				d.blkX0[bi] = min(d.blkX0[bi], b.x0); d.blkY0[bi] = min(d.blkY0[bi], b.y0);
				d.blkX1[bi] = max(d.blkX1[bi], b.x1); d.blkY1[bi] = max(d.blkY1[bi], b.y1);
				d.nbx = max(d.nbx, b.bx + 1); d.nby = max(d.nby, b.by + 1);
			}
		}
	}

	static clearscope int CodeToDist(String c)
	{
		if (c ~== "MR") return 0;
		if (c ~== "EG") return 1;
		if (c ~== "IS") return 2;
		if (c ~== "OQ") return 3;
		if (c ~== "HL") return 4;
		return 0;
	}

	static clearscope int TypeOf(String s)
	{
		for (int t = 0; t < PT_COUNT; t++) if (CW_City.TypeCode(t) ~== s) return t;
		return PT_OFF;
	}

	// the authored properties and strongholds: live campaign if there is one, else cwcity.txt
	clearscope void LoadSites(CW_City city)
	{
		sites.Clear(); corpShort.Clear(); corpName.Clear(); minorName.Clear(); minorShort.Clear();
		if (city)
		{
			for (int c = 0; c < city.corps.Size(); c++) { corpShort.Push(city.corps[c].short); corpName.Push(city.corps[c].name); }
			for (int m = 0; m < city.minors.Size(); m++) { minorName.Push(city.minors[m].name); minorShort.Push(city.minors[m].short); }
			for (int i = 0; i < city.props.Size(); i++)
			{
				let pr = city.props[i];
				let s = new("CWM_Site");
				s.type = pr.type; s.label = pr.label; s.district = clamp(pr.district, 0, 4); s.seed = pr.seed;
				s.sub = pr.sub >= 0 ? city.subs[pr.sub].name : "Meridian";
				int c = pr.sub >= 0 ? city.subs[pr.sub].corp : -1;
				s.corp = (c >= 0 && c < 6) ? c : 6;
				s.corpName = s.corp == 6 ? "Meridian receivership" : city.corps[c].name;
				s.name = s.sub;
				s.theme = CW_City.TypeTheme(pr.type, s.corp < 6 ? city.corps[c].theme : 0);
				s.minor = -1;
				s.shellHid = pr.sub >= 0 && city.subs[pr.sub].shell && !city.subs[pr.sub].shellKnown && c != city.patron;   // same rule as the terminal CITY tab
				sites.Push(s);
			}
			for (int h = 0; h < city.holds.Size(); h++)
			{
				let hd = city.holds[h];
				let s = new("CWM_Site");
				s.type = -1; s.stronghold = true; s.hname = hd.name; s.minor = hd.minor; s.district = clamp(hd.district, 0, 4); s.seed = hd.seed;
				s.corp = -1; s.name = hd.name; s.sub = ""; s.corpName = (hd.minor >= 0 && hd.minor < minorName.Size()) ? minorName[hd.minor] : "";
				sites.Push(s);
			}
			for (int i = 0; i < 5; i++)
			{
				int best = -1, bp = 29;
				for (int m = 0; m < city.minors.Size(); m++) if (city.minors[m].turf[i] > bp) { bp = city.minors[m].turf[i]; best = m; }
				dists[i].turfMinor = best; dists[i].turfPct = best >= 0 ? bp : 0;
			}
			return;
		}
		int lump = Wads.CheckNumForFullName("cwcity.txt");
		if (lump < 0) return;
		String txt = Wads.ReadLump(lump);
		Array<String> lines;
		txt.Split(lines, "\n");
		Array<String> corpC, subC, subO, subN, minC;
		Array<int> corpTheme;
		Array<int> turfs;
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			ln.StripRight();
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 4) continue;
			if (f[0] == "CORP") { corpC.Push(f[1]); corpName.Push(f[2]); corpShort.Push(f[3]); corpTheme.Push(f.Size() > 9 ? f[9].ToInt() : 0); }
			else if (f[0] == "SUB") { subC.Push(f[1]); subO.Push(f[2]); subN.Push(f[3]); }
			else if (f[0] == "MINOR" && f.Size() > 10)
			{
				minC.Push(f[1]); minorName.Push(f[2]); minorShort.Push(f[3]);
				for (int t = 0; t < 5; t++) turfs.Push(f[6 + t].ToInt());
			}
		}
		for (int i = 0; i < 5; i++)
		{
			int best = -1, bp = 29;
			for (int m = 0; m < minC.Size(); m++) if (turfs[m * 5 + i] > bp) { bp = turfs[m * 5 + i]; best = m; }
			dists[i].turfMinor = best; dists[i].turfPct = best >= 0 ? bp : 0;
		}
		int n = 0;
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			ln.StripRight();
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 4) continue;
			if (f[0] == "PROP")
			{
				let s = new("CWM_Site");
				s.type = TypeOf(f[2]);
				s.district = CodeToDist(f[3]);
				s.label = f.Size() > 4 ? f[4] : "";
				s.sub = f[1]; s.corp = 6; s.corpName = "Meridian receivership"; s.minor = -1;
				int corpIdx = -1;
				for (int q = 0; q < subC.Size(); q++)
					if (subC[q] == f[1])
					{
						s.sub = subN[q];
						for (int w = 0; w < corpC.Size(); w++) if (corpC[w] == subO[q]) corpIdx = w;
					}
				if (corpIdx >= 0) { s.corp = corpIdx; s.corpName = corpName[corpIdx]; }
				s.name = s.sub;
				s.theme = CW_City.TypeTheme(s.type, corpIdx >= 0 ? corpTheme[corpIdx] : 0);
				s.seed = CW_Building.Mix(7, 5000 + n * 17 + s.district);
				n++;
				sites.Push(s);
			}
			else if (f[0] == "STRONGHOLD")
			{
				let s = new("CWM_Site");
				s.type = -1; s.stronghold = true; s.hname = f[2]; s.name = f[2]; s.district = CodeToDist(f[3]);
				s.minor = -1;
				for (int m = 0; m < minC.Size(); m++) if (minC[m] == f[1]) s.minor = m;
				s.corp = -1; s.corpName = s.minor >= 0 ? minorName[s.minor] : "";
				s.seed = CW_Building.Mix(7, 8000 + n * 17 + s.district);
				n++;
				sites.Push(s);
			}
		}
	}

	// ---------------------------------------------------------------- zoning (ported from CW_CityGen)
	clearscope int PickZone(CWM_Dist d, CWM_Lot b)
	{
		if (b.fill) return Z_FILL;
		if (b.lm != "-") return Z_LM;
		int w[6];
		for (int i = 0; i < 6; i++) w[i] = d.zw[i];
		double dx = (b.bx - (d.nbx - 1) / 2.0) / (d.nbx / 2.0), dy = (b.by - (d.nby - 1) / 2.0) / (d.nby / 2.0);
		double dd = max(abs(dx), abs(dy));
		w[0] += int(d.core * max(0.0, 1.0 - dd * 1.5));
		if (b.cls >= 1) { w[0] /= 3; w[2] /= 2; w[3] = w[3] * 2 + 6; }
		if (b.cls == 2) { w[0] = 0; w[1] /= 2; }
		int tot = 0;
		for (int i = 0; i < 6; i++) tot += w[i];
		if (tot <= 0) return Z_RES;
		int r = Hs(d, b.id, 11) % tot;
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

	clearscope int StoreysFor(CWM_Dist d, int z, int id)
	{
		int hi = 5, lo = 5;
		switch (z)
		{
			case Z_TOWER: lo = d.htLo[0]; hi = d.htHi[0]; break;
			case Z_OFFICE: lo = d.htLo[1]; hi = d.htHi[1]; break;
			case Z_RES: lo = d.htLo[2]; hi = d.htHi[2]; break;
			case Z_IND: lo = d.htLo[3]; hi = d.htHi[3]; break;
			case Z_CIVIC: lo = d.htLo[4]; hi = d.htHi[4]; break;
			case Z_FILL: lo = d.htLo[5]; hi = d.htHi[5]; break;
			case Z_LM: return d.lmK;
			case Z_YARD: return 0;
			case Z_EMPTY: return 0;
		}
		return lo + Hs(d, id, 21) % max(1, hi - lo + 1);
	}

	clearscope void Rezone(CWM_Dist d, CWM_Lot b, int z)
	{
		b.zone = z;
		b.storeys = StoreysFor(d, z, b.id);
		b.height = (z == Z_EMPTY || z == Z_YARD) ? 0 : 136 + STOREY * b.storeys;
	}

	// zones / size classes a property type likes: zone mask | (class mask << 16); class mask S=1 M=2 L=4
	static clearscope int PropWants(int t)
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

	// kit number (0 = G02 office floor) and variant: the SiteKit mapping in cityjobs.zs
	static clearscope void PropKit(int t, out int kit, out int kvar)
	{
		kit = 0; kvar = -1;
		switch (t)
		{
			case PT_DC: kit = 6; kvar = 0; break;
			case PT_LAB: kit = 6; kvar = 1; break;
			case PT_FARM: kit = 4; kvar = 4; break;
			case PT_BNK: kit = 4; kvar = 5; break;
			case PT_WH: kit = 3; kvar = 0; break;
			case PT_DOCK: kit = 3; kvar = 1; break;
			case PT_FAB: kit = 3; kvar = 2; break;
			case PT_PLT: kit = 3; kvar = 3; break;
			case PT_SUB: kit = 3; kvar = 4; break;
			case PT_PARK: kit = 3; kvar = 5; break;
			case PT_SAL: kit = 3; kvar = 6; break;
		}
	}

	// neutral sites: kit, variant, title, preferred zone
	static clearscope bool NeutralInfo(String key, out int kit, out int kvar, out String title, out int zone)
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

	// a minor player's stronghold: kit, variant, preferred zone (the SiteKit mapping)
	static clearscope void HoldKit(String n, out int kit, out int kvar, out int zone)
	{
		kit = 1; kvar = 0; zone = Z_RES;
		if (n.IndexOf("drug lab") >= 0) { kit = 1; kvar = 5; zone = Z_IND; }
		else if (n.IndexOf("bar") >= 0) { kit = 1; kvar = 0; zone = Z_RES; }
		else if (n.IndexOf(" den") >= 0) { kit = 2; kvar = 4; zone = Z_RES; }
		else if (n.IndexOf("union") >= 0) { kit = 5; kvar = 0; zone = Z_CIVIC; }
		else if (n.IndexOf("meeting hall") >= 0) { kit = 5; kvar = 1; zone = Z_CIVIC; }
		else if (n.IndexOf("church") >= 0) { kit = 5; kvar = 2; zone = Z_CIVIC; }
	}

	static clearscope String NeutralName(String key, int h)
	{
		String l = "Corner Place";
		if (key == "bar") l = "The Rusty Anchor,Last Call,Blue Lantern,Two Fingers,The Long Pour,Nightcap,The Dry Dock";
		else if (key == "restaurant") l = "Marlow's,Casa Verde,Noodle Kingdom,The Corner Table,Sal's Kitchen,Golden Wok";
		else if (key == "pawn") l = "Lucky Loan,Second Chance Pawn,Gold & Guns,Fast Cash Pawn,Three Balls";
		else if (key == "market") l = "Night Market,Harbour Stalls,The Bazaar,Canal Street Market,Old Cross Market";
		else if (key == "mall") l = "Meridian Galleria,Skyline Plaza,Parkview Mall,The Arcade,Atrium Centre";
		else if (key == "druglab") l = "Back-room Lab,Basement Kitchen,Cold Storage Lab";
		else if (key == "chopshop") l = "Ace Auto Wrecking,Rico's Parts,Lowrider Garage,Scrap & Sons";
		else if (key == "gambling") l = "The Green Room,Velvet Den,Ace High,Dead Man's Hand";
		else if (key == "tenement") l = "Fulton Tenement,Ash Street Flats,Number 9 Rowhouse,Dockside Tenement,Cobb Row";
		else if (key == "apartments") l = "Riverview Apartments,Linden Court,Parkside Flats,Harbour Gate Apts";
		else if (key == "luxury") l = "The Meridian Residences,Sky Gardens,Aurelia Tower,Crown Heights";
		else if (key == "hotel") l = "Grand Meridian Hotel,The Harbourlight,Hotel Ostrava,The Continental";
		else if (key == "construction") l = "Pier 9 Build Site,Skyward Build Site,Foundation Pit,Site 44";
		else if (key == "underpass") l = "Rail Underpass,Canal Underpass,Kessler Underpass";
		else if (key == "transit") l = "Central Transit Hub,Lower Line Station,Junction Station";
		else if (key == "parking") l = "Ramp Garage,Long-Stay Parking,Level 4 Garage,Depot Car Park";
		else if (key == "unionhall") l = "Dockworkers' Hall,Local Hall,Labor Temple";
		else if (key == "university") l = "Eastgate University,Tech Annex,Faculty Hall";
		else if (key == "hospital") l = "St. Aurelia Hospital,County General,Mercy Wing";
		else if (key == "archive") l = "Records Archive,City Archive,Deeds Office";
		Array<String> a;
		l.Split(a, ",");
		return a[h % a.Size()];
	}

	static clearscope String ZoneName(int z)
	{
		switch (z)
		{
			case Z_TOWER: return "Office tower";
			case Z_OFFICE: return "Office block";
			case Z_RES: return "Apartment block";
			case Z_IND: return "Industrial building";
			case Z_CIVIC: return "Civic building";
			case Z_EMPTY: return "Open ground";
			case Z_YARD: return "Yard";
			case Z_LM: return "Landmark";
		}
		return "Building";
	}

	// ---------------------------------------------------------------- roster
	clearscope void Claim(CWM_Lot b, String kind, String name, String tname, int kit, int kvar, int sd)
	{
		b.taken = true; b.enter = true; b.kind = kind; b.name = name; b.typeName = tname;
		b.kit = kit; b.kvar = kvar;
		b.map = kit > 0 ? String.Format("K%02d", kit) : "G02";
		b.seed = sd != 0 ? sd : 1;
	}

	clearscope void Generate(CWM_Dist d)
	{
		if (d.lots.Size() == 0) return;
		d.dseed = CW_Building.Mix(seed, 7919 * (d.idx + 1) + 13);
		for (int i = 0; i < d.lots.Size(); i++)
		{
			let b = d.lots[i];
			Rezone(d, b, PickZone(d, b));
			if (b.lm == "quad") { b.zone = Z_EMPTY; b.storeys = 0; b.height = 0; }
			if (b.lm == "garrison") { b.storeys = 2; b.height = 136 + STOREY * 2; }
		}
		int waterMask = 0;
		if (d.eN == "harbour") waterMask |= 1;
		if (d.eE == "harbour") waterMask |= 2;
		if (d.eS == "harbour") waterMask |= 4;
		if (d.eW == "harbour") waterMask |= 8;
		Array<int> blkTaken;
		for (int i = 0; i < 100; i++) blkTaken.Push(0);
		// the district's own sites
		Array<int> mine;
		for (int i = 0; i < sites.Size(); i++) if (sites[i].district == d.idx && !sites[i].stronghold) mine.Push(i);
		int n = mine.Size();
		int rot = n > 0 ? Hs(d, 77, 5) % n : 0;
		for (int q = 0; q < n; q++)
		{
			let s = sites[mine[(q + rot) % n]];
			int pw = PropWants(s.type);
			int zm = pw & 0xffff, cmk = pw >> 16;
			int best = -1, bs = -1000;
			for (int i = 0; i < d.lots.Size(); i++)
			{
				let b = d.lots[i];
				if (b.fill || b.taken || b.lm != "-") continue;
				int sc = Hs(d, b.id, 300 + q) % 14 - blkTaken[b.by * 10 + b.bx] * 5;
				if (b.zone == Z_EMPTY) sc -= 4;
				if (zm & (1 << b.zone)) sc += 12;
				if (cmk & (1 << b.cls)) sc += 8; else if (b.cls == 2 && (cmk & 2)) sc += 3;
				if (s.type == PT_DOCK && (b.wf & waterMask)) sc += 14;
				if (s.type != PT_DOCK && (b.wf & waterMask) && (zm & (1 << Z_IND))) sc += 1;
				if (sc > bs) { bs = sc; best = i; }
			}
			if (best < 0) continue;
			let b = d.lots[best];
			if (!(zm & (1 << b.zone)))
			{
				int z = 1;
				while (!(zm & (1 << z)) && z < 9) z++;
				Rezone(d, b, z);
			}
			blkTaken[b.by * 10 + b.bx] += 1;
			int kk, vv;
			PropKit(s.type, kk, vv);
			String tn = s.label.Length() ? s.label : CW_City.TypeName(s.type);
			Claim(b, "property", s.name, tn, kk, vv, s.seed);
			b.propType = s.type; b.corp = s.corp; b.sub = s.sub; b.corpName = s.corpName; b.theme = s.theme;
			b.owner = String.Format("%s (%s)", s.sub, s.corp == 6 ? "Meridian" : corpShort[s.corp]);
			if (s.shellHid) { b.shellHid = true; b.owner = String.Format("%s -> parent unknown", s.sub); b.corpName = "Unknown (shell)"; }
			d.nProp++;
		}
		// minor players' strongholds
		int hn = 0;
		for (int i = 0; i < sites.Size(); i++)
		{
			let s = sites[i];
			if (!s.stronghold || s.district != d.idx) continue;
			int kk, vv, zz;
			HoldKit(s.hname, kk, vv, zz);
			int bestI = -1, bestS = -1000;
			for (int j = 0; j < d.lots.Size(); j++)
			{
				let b = d.lots[j];
				if (b.fill || b.taken || b.lm != "-" || b.zone == Z_EMPTY || b.zone == Z_YARD) continue;
				int sc = Hs(d, b.id, 1500 + hn) % 14 - blkTaken[b.by * 10 + b.bx] * 5;
				if (b.zone == zz) sc += 10;
				if (b.cls == 0) sc += 3;
				if (sc > bestS) { bestS = sc; bestI = j; }
			}
			hn++;
			if (bestI < 0) continue;
			let b = d.lots[bestI];
			blkTaken[b.by * 10 + b.bx] += 1;
			String nm = s.hname;
			if (nm.Length()) nm = nm.Left(1).MakeUpper() .. nm.Mid(1);
			Claim(b, "stronghold", nm, nm, kk, vv, s.seed);
			b.minor = s.minor; b.corp = -1; b.owner = s.corpName; b.corpName = s.corpName;
			d.nHold++;
		}
		// neutral sites from the district's menu (18 per district)
		int made = 0;
		for (int pass = 0; pass < 40 && made < 18; pass++)
		{
			String key = d.neutralMenu.Size() ? d.neutralMenu[pass % d.neutralMenu.Size()] : "bar";
			int kk, vv, zz; String tt;
			if (!NeutralInfo(key, kk, vv, tt, zz)) continue;
			int bestI = -1, bestS = -1000;
			for (int i = 0; i < d.lots.Size(); i++)
			{
				let b = d.lots[i];
				if (b.fill || b.taken || b.lm != "-" || b.zone == Z_EMPTY || b.zone == Z_YARD) continue;
				int sc = Hs(d, b.id, 900 + pass) % 14 - blkTaken[b.by * 10 + b.bx] * 5;
				if (b.zone == zz) sc += 10;
				if (b.cls == 0) sc += 3;
				if (sc > bestS) { bestS = sc; bestI = i; }
			}
			if (bestI < 0) break;
			let b = d.lots[bestI];
			blkTaken[b.by * 10 + b.bx] += 1;
			Claim(b, "neutral", NeutralName(key, Hs(d, b.id, 77)), tt, kk, vv, 0);
			b.owner = "Independent"; b.corpName = "Independent"; b.corp = -1;
			if (d.turfMinor >= 0) b.minor = d.turfMinor;
			made++; d.nNeutral++;
		}
		// everything else, plus the layout seed of the neutral sites
		for (int i = 0; i < d.lots.Size(); i++)
		{
			let b = d.lots[i];
			b.cx = d.ox + (b.x0 + b.x1) * 0.5;   // fixed up in Layout()
			if (b.taken)
			{
				if (b.seed == 1 && b.kind == "neutral") { int sd = Hs(d, b.id, 3) ; b.seed = sd != 0 ? sd : 1; }
				continue;
			}
			b.owner = "";
			if (b.lm != "-")
			{
				b.kind = "landmark"; b.name = d.lmName; b.typeName = d.lmName;
				if (b.lm == "quad") b.typeName = "Open quad";
			}
			else if (b.fill) { b.kind = "filler"; b.name = "Perimeter structure"; b.typeName = "Outer buildings"; }
			else { b.kind = "building"; b.typeName = ZoneName(b.zone); b.name = b.typeName; }
		}
		// neutral seeds: taken above with sd 0 -> Claim stored 1; set now
		for (int i = 0; i < d.lots.Size(); i++)
		{
			let b = d.lots[i];
			if (b.kind == "neutral" && b.seed == 1) { int sd = CW_Building.Mix(d.dseed, b.id * 7 + 3); b.seed = sd != 0 ? sd : 1; }
		}
		// After Hours site pack (sitepool.zs): a lot whose type has a generated pool opens that pool's map; the lot's
		// layout seed fixes the variant, so the same building is always the same layout
		for (int i = 0; i < d.lots.Size(); i++)
		{
			let b = d.lots[i];
			if (!b.taken || !b.enter) continue;
			String sm = CW_SitePool.MapFor(b.kit, b.kvar, b.propType, b.seed);
			if (sm.Length()) b.map = sm;
		}
	}

	// ---------------------------------------------------------------- geographic layout: Meridian in the middle,
	// Eastgate N, Ironside E (waterfront), Old Quarter S, Highline W  (the gateway adjacency of the archived city)
	clearscope void Layout()
	{
		let mr = dists[0], eg = dists[1], iw = dists[2], oq = dists[3], hl = dists[4];
		mr.ox = 0; mr.oy = 0;
		// schematic (not compass) layout so the whole city fills a wide screen: Highline | Meridian | Ironside (harbour east)
		// on the top row, Eastgate and the Old Quarter centred underneath.
		mr.ox = 0; mr.oy = 0;
		iw.ox = mr.w + GAP; iw.oy = mr.h * 0.5 - iw.h * 0.5;
		hl.ox = -GAP - hl.w; hl.oy = mr.h * 0.5 - hl.h * 0.5;
		double rowLo = min(mr.oy, min(iw.oy, hl.oy));
		double spanW = eg.w + GAP + oq.w;
		double cxm = (hl.ox + iw.ox + iw.w) * 0.5;
		eg.ox = cxm - spanW * 0.5; eg.oy = rowLo - GAP - eg.h;
		oq.ox = eg.ox + eg.w + GAP; oq.oy = rowLo - GAP - oq.h;
		minX = 1e9; minY = 1e9; maxX = -1e9; maxY = -1e9;
		for (int i = 0; i < 5; i++)
		{
			let d = dists[i];
			minX = min(minX, d.ox); minY = min(minY, d.oy);
			maxX = max(maxX, d.ox + d.w); maxY = max(maxY, d.oy + d.h);
			for (int j = 0; j < d.lots.Size(); j++)
			{
				let b = d.lots[j];
				b.cx = d.ox + (b.x0 + b.x1) * 0.5;
				b.cy = d.oy + (b.y0 + b.y1) * 0.5;
			}
		}
	}

	// ---------------------------------------------------------------- kit names (for the UI and the launcher)
	static clearscope String KitName(int k)
	{
		static const String n[] = { "Street block", "Residential", "Industrial lot", "Underground", "Civic hall", "Tech interior" };
		return (k >= 1 && k <= 6) ? n[k - 1] : "Office floor";
	}
	static clearscope String VarName(int k, int v)
	{
		String l = "";
		switch (k)
		{
			case 1: l = "club,restaurant,pawn shop,street market,mall,drug lab,chop shop,gambling den"; break;
			case 2: l = "tenement,apartment block,luxury apartments,hotel,hacker den,rooftops"; break;
			case 3: l = "warehouse,sea dock,fabrication plant,power plant,substation,industrial park,salvage yard,construction site"; break;
			case 4: l = "maintenance tunnels,underpass,transit station,parking garage,hydroponic farm,bunker"; break;
			case 5: l = "union hall,meeting hall,church hall,university,hospital,archive"; break;
			case 6: l = "data centre,lab"; break;
		}
		Array<String> a;
		l.Split(a, ",");
		return (v >= 0 && v < a.Size()) ? a[v] : "from the seed";
	}

	clearscope CWM_Lot FindLot(int d, int id)
	{
		if (d < 0 || d > 4) return null;
		let dd = dists[d];
		for (int i = 0; i < dd.lots.Size(); i++) if (dd.lots[i].id == id) return dd.lots[i];
		return null;
	}

	// ---------------------------------------------------------------- debug: netevent cw_mapdump
	clearscope void Dump(bool all = false)
	{
		Console.Printf("CW_MAP seed %d, %s, %d sites in the roster", seed, live ? "live campaign" : "cwcity.txt", sites.Size());
		int tp = 0, th = 0, tn = 0, te = 0, tl = 0;
		for (int i = 0; i < 5; i++)
		{
			let d = dists[i];
			int filler = 0, g02 = 0;
			for (int j = 0; j < d.lots.Size(); j++)
			{
				if (d.lots[j].fill) filler++;
				if (d.lots[j].enter && d.lots[j].kit == 0) g02++;
			}
			Console.Printf("CW_MAP D%d %s (%s) %dx%d blocks, %d lots: %d enterable = %d authored + %d strongholds + %d neutral (%d on G02), %d filler, turf %s",
				i + 1, d.name, d.code, d.nbx, d.nby, d.lots.Size(), d.Enterable(), d.nProp, d.nHold, d.nNeutral, g02, filler,
				d.turfMinor >= 0 ? String.Format("%s %d%%", minorShort[d.turfMinor], d.turfPct) : "none");
			tp += d.nProp; th += d.nHold; tn += d.nNeutral; te += d.Enterable(); tl += d.lots.Size();
		}
		Console.Printf("CW_MAP TOTAL %d lots, %d enterable: %d authored, %d strongholds, %d neutral", tl, te, tp, th, tn);
		// sample lots: the first authored property, stronghold and neutral of a few districts
		for (int i = 0; i < 5; i += 2)
		{
			let d = dists[i];
			int shown = 0;
			for (int j = 0; j < d.lots.Size() && shown < 6; j++)
			{
				let b = d.lots[j];
				if (!b.enter) continue;
				if ((shown % 2) == 0 || b.kind != "neutral")
				{
					Console.Printf("CW_MAP LOT D%d #%d [%s] %s | %s | %s%s | %d storeys | %s v%d %s | seed %d | rect %d,%d-%d,%d",
						i + 1, b.id, b.kind, b.name, b.typeName, b.owner, b.shellHid ? " [SHELLHID]" : "", b.storeys, b.map, b.kvar, b.kit > 0 ? VarName(b.kit, b.kvar) : "office", b.seed, b.x0, b.y0, b.x1, b.y1);
					shown++;
				}
			}
		}
		int nh = 0;
		for (int i = 0; i < 5; i++) for (int j = 0; j < dists[i].lots.Size(); j++)
		{
			let b = dists[i].lots[j];
			if (b.shellHid) { nh++; if (nh <= 4) Console.Printf("CW_MAP SHELLHID D%d #%d %s | %s", i + 1, b.id, b.name, b.owner); }
		}
		Console.Printf("CW_MAP shell-hidden lots: %d", nh);
		// routing: which lots open a site-pack map, which keep the old kit / office floor (cw_newsites)
		{
			int nNew = 0, nKit = 0, nOff = 0;
			Array<String> codes; Array<int> counts;
			for (int i = 0; i < 5; i++) for (int j = 0; j < dists[i].lots.Size(); j++)
			{
				let b = dists[i].lots[j];
				if (!b.enter) continue;
				if (CW_SitePool.IsSiteMap(b.map))
				{
					nNew++;
					String cc = CW_SitePool.CodeOfMap(b.map);
					int at = codes.Find(cc);
					if (at == codes.Size()) { codes.Push(cc); counts.Push(0); }
					counts[codes.Find(cc)]++;
				}
				else if (b.kit > 0) { nKit++; Console.Printf("CW_MAP OLDKIT D%d #%d %s | %s | %s v%d", i + 1, b.id, b.name, b.typeName, b.map, b.kvar); }
				else nOff++;
			}
			if (all)
			for (int i = 0; i < 5; i++) for (int j = 0; j < dists[i].lots.Size(); j++)
			{
				let b = dists[i].lots[j];
				if (b.enter) Console.Printf("CW_MAP ALL D%d #%d %s | %s | %s | %s | seed %d", i + 1, b.id, b.kind, b.name, b.typeName, b.map, b.seed);
			}
		Console.Printf("CW_MAP ROUTE new site-pack maps %d, old kits %d, G02 offices %d (cw_newsites %d)", nNew, nKit, nOff, CW_SitePool.Enabled());
			String ss = "";
			for (int i = 0; i < codes.Size(); i++) ss = ss .. String.Format("%s%s %d", i ? ", " : "", codes[i], counts[i]);
			if (ss.Length()) Console.Printf("CW_MAP POOLS %s", ss);
		}
	}
}
