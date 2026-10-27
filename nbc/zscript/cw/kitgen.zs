// Ported from Corpo Wars (reference/corpowars/zscript/corpowars/kitgen.zs) for PLAN.md M2b: the carving engine only.
// NBC: renamed to NBC_ because the mission layer is cut. The Bricks kits' layouts are new (nbc/zscript/nbc/kit_*.zs, M2c).
// =============================================================================
// Corpo Wars — site kits: the shared generator (design: Design Docs/building-types.md, kit notes in
// Design Docs/site-kits.md)
//
// Every kit map (K01..K06, built by genmap.build_kit) is a blank grid of cells with closed 16u wall strips
// between them and closed 16u posts where four cells meet. A kit lays out ROOMS (sets of cells, indoor or
// outdoor) and LINKS between them (door, archway, wide opening, window, fence, vent); this base class carves
// the grid, paints it, hangs doors and lights, and places the mission: entries, extraction, objectives,
// guards and bystanders. Kits only decide what goes where.
//
// Bare-minimum mechanics on purpose: no maglocks, passes, cover pass, dark rooms or scenarios yet. Those
// hook in later the way they did on the office floor (G02).
//
// NBC: the mission layer is cut (AGENTS.md). No CW guards, bystanders, patrol points, drop crate, ledger,
// passes or contract objectives. In their place the generator records:
//   - spawn spots (spotX/Y/Role) the RunManager fills with the raiding gang (role 0 ground, 1 perch)
//   - resident spots (NBC_ResidentSpot markers, empty until M9) in RF_CIV rooms
//   - objective markers (NBC_ObjectiveMarker) in the planned objective rooms
//   - the exit: the entry farthest from the insertion, with an NBC_KitExit on it
//   - rubble piles and loose debris in RF_RUBBLE rooms
// Doors are 96 high (PLAN.md §4.4 scale). All randomness comes from the seed the caller passes in.
// =============================================================================
class NBC_KitGen play
{
	const WALL = 16;
	const DOOR_H = 68;           // NBC: 2.1 m against a 56-unit (1.8 m) person; PLAN.md §4.4
	const SKY_H = 384;
	const SAFE_R = 480;          // no gang spawn spots this close to the insertion point

	// the objective kinds the planner places (were Corpo Wars' contract objectives)
	const OBJ_STEAL = 1;         // something to seize: evidence, a stash
	const OBJ_DESTROY = 2;       // something to wreck: a cook station, an alarm panel
	const OBJ_TURN = 3;          // someone to reach: an informant, a lieutenant

	// NBC: the Bricks kits (layouts written for New Bricks City, nbc/zscript/nbc/kit_*.zs)
	enum EKit { KIT_NONE, KIT_TOWER, KIT_STREET, KIT_BASEMENT, KIT_ROOF, KIT_COUNT }
	enum ELink { E_DOOR, E_ARCH, E_WIDE, E_WINDOW, E_FENCE, E_VENT }
	enum ERoomFlag
	{
		RF_OUT = 1,          // outdoors: sky ceiling
		RF_CIV = 2,          // bystanders hang around here
		RF_VALUE = 4,        // somewhere worth stealing from
		RF_TECH = 8,         // machinery / servers: sabotage target
		RF_PEOPLE = 16,      // where the people who matter sit (recruit target)
		RF_PATROL = 32,      // guards walk through here
		RF_NOGUARD = 64,     // never post a guard here
		RF_DARK = 128,       // lights off
		RF_WATER = 256,      // not walkable (water, pits)
		RF_RUBBLE = 512      // NBC: derelict or outdoor: rubble piles and loose debris
	}
	enum EEntryKind { EK_ANY, EK_GARAGE, EK_FRONT, EK_BACK, EK_SERVICE, EK_ROOF }

	int kit, variant;
	int rng, seed0, civs;
	int entryPref;               // EK_* the raid asked for (0 = any)
	String siteName;             // what the banner calls this place
	int NX, NY;
	Array<int> colw, rowh, colX, rowY;
	Array<int> roomOf;           // cell -> room, -1 = solid
	Array<String> cellFac;       // facade of a solid cell, seen from outside ("" = the kit's edge texture)
	// rooms
	Array<int> rtype, rflags, rF, rC, rLight;
	Array<String> rFloorT, rCeilT, rWallT, rFacT, rName;
	// links between rooms
	Array<int> lI, lJ, lVert, lKind;
	Array<double> lX, lY;
	Array<int> vOpen, hOpen;     // edge state: 0 closed, 1 part open, 2 full open; -1 fence
	// entries (every one is an exit too)
	Array<double> enX, enY, enA;
	Array<int> enKind, enRoom;
	Array<String> enName;
	int insertIdx;
	Vector2 insertPos;
	double insertAng;
	String insertName;
	int objRoom[4];
	Array<NBC_KitDoor> doors;
	// NBC: what the raid needs once the floor is built
	Array<double> spotX, spotY;
	Array<int> spotRole;         // 0 ground, 1 perch (outdoors: fire escapes, roofs, yards)
	int exitIdx;
	Vector2 exitPos;
	int rubblePiles, loosePieces;
	Array<int> topTags;          // sectors carved as free-standing structures (sky above)
	String doorTex, jambTex, edgeTex;
	// sector lookup (filled after carving): role 1 cell, 2 v-strip, 3 h-strip, 4 post; idx = cell / edge / corner
	Array<int> secRole, secIdx, secK;

	// ================================================================ factory
	// NBC: the template map of each kit (tools/make_kit_maps.py builds them)
	static clearscope int KitOfMap(String m)
	{
		static const String names[] = { "NBC_KT", "NBC_KS", "NBC_KB", "NBC_KR" };
		for (int k = 0; k < 4; k++) if (m ~== names[k]) return k + 1;
		return 0;
	}
	static clearscope String MapOfKit(int k)
	{
		static const String names[] = { "", "NBC_KT", "NBC_KS", "NBC_KB", "NBC_KR" };
		return names[clamp(k, 0, 4)];
	}
	// "tower" / "street" / "basement" / "roof" (or the map name) -> the kit number (0 = none)
	static clearscope int KitByName(String s)
	{
		s = s.MakeLower();
		if (s == "tower" || s == "nbc_kt") return KIT_TOWER;
		if (s == "street" || s == "nbc_ks") return KIT_STREET;
		if (s == "basement" || s == "nbc_kb") return KIT_BASEMENT;
		if (s == "roof" || s == "nbc_kr") return KIT_ROOF;
		return KIT_NONE;
	}
	static NBC_KitGen Make(int k)
	{
		static const String cls[] = { "", "NBC_KitTower", "NBC_KitStreet", "NBC_KitBasement", "NBC_KitRoof" };
		if (k < 1 || k > 4) return null;
		String cn = cls[k];
		if (cn == "") return null;
		class<NBC_KitGen> c = cn;   // looked up at run time: a kit that isn't built yet just isn't there
		if (!c) return null;
		let g = NBC_KitGen(new(c));
		g.kit = k;
		g.Setup();
		return g;
	}

	// ---- kit hooks
	virtual void Setup() {}
	virtual void Layout() {}
	virtual void Dress(int r) {}
	virtual void Outdoors() {}               // street lamps, parked cars, yard clutter
	virtual String VariantName() { return "site"; }
	virtual int VariantCount() { return 1; }
	virtual int Bystanders() { return 3; }
	virtual int ObjScore(int r, int k)
	{
		int f = rflags[r];
		if (f & (RF_OUT | RF_WATER)) return 0;
		if (k == OBJ_STEAL) return (f & RF_VALUE) ? 60 : 5;
		if (k == OBJ_DESTROY) return (f & RF_TECH) ? 60 : 3;
		return (f & RF_PEOPLE) ? 60 : 4;
	}

	// ================================================================ RNG
	int Rand(int lo, int hi)
	{
		rng = rng * 1103515245 + 12345;
		int r = (rng >>> 16) & 0x7fff;
		return hi <= lo ? lo : lo + r % (hi - lo + 1);
	}
	bool Chance(int pct) { return Rand(0, 99) < pct; }

	// ================================================================ grid
	void Grid(int ncols, int nrows)
	{
		NX = ncols; NY = nrows;
		colX.Clear(); rowY.Clear();
		int x = 0;
		for (int i = 0; i < NX; i++) { colX.Push(x); x += colw[i] + WALL; }
		int y = 0;
		for (int j = 0; j < NY; j++) { rowY.Push(y); y += rowh[j] + WALL; }
		roomOf.Clear();
		for (int k = 0; k < NX * NY; k++) { roomOf.Push(-1); cellFac.Push(""); }
		vOpen.Clear(); hOpen.Clear();
		for (int k = 0; k < NX * NY; k++) { vOpen.Push(0); hOpen.Push(0); }
	}
	int VTag(int i, int j, int k) { return 1000 + (j * (NX - 1) + i) * 3 + k; }
	int HTag(int i, int j, int k) { return 4000 + (j * NX + i) * 3 + k; }
	int CTag(int i, int j) { return 7000 + j * NX + i; }
	int PTag(int i, int j) { return 11000 + j * (NX - 1) + i; }
	Vector2 CellCenter(int i, int j) { return (colX[i] + colw[i] / 2, rowY[j] + rowh[j] / 2); }
	Vector2 MapCenter() { return ((colX[NX - 1] + colw[NX - 1]) / 2, (rowY[NY - 1] + rowh[NY - 1]) / 2); }
	int CellI(double x) { for (int i = 0; i < NX; i++) if (x >= colX[i] && x < colX[i] + colw[i]) return i; return -1; }
	int CellJ(double y) { for (int j = 0; j < NY; j++) if (y >= rowY[j] && y < rowY[j] + rowh[j]) return j; return -1; }
	bool InGrid(int i, int j) { return i >= 0 && j >= 0 && i < NX && j < NY; }
	int At(int i, int j) { return InGrid(i, j) ? roomOf[j * NX + i] : -1; }
	static bool Three(int len) { return len > 96; }

	// ================================================================ rooms
	int Room(int type, int flags, int f, int c, int light, String ft, String ct, String wt, String name = "")
	{
		rtype.Push(type); rflags.Push(flags); rF.Push(f); rC.Push(c); rLight.Push(light);
		rFloorT.Push(ft); rCeilT.Push(ct); rWallT.Push(wt); rFacT.Push(""); rName.Push(name);
		return rtype.Size() - 1;
	}
	void Claim(int r, int i, int j) { if (InGrid(i, j)) roomOf[j * NX + i] = r; }
	void Rect(int r, int i0, int j0, int i1, int j1)
	{
		for (int j = min(j0, j1); j <= max(j0, j1); j++) for (int i = min(i0, i1); i <= max(i0, i1); i++) Claim(r, i, j);
	}
	bool IsOut(int r) { return r >= 0 && (rflags[r] & RF_OUT); }
	bool Has(int r, int f) { return r >= 0 && (rflags[r] & f); }
	double CeilOf(int r) { return IsOut(r) ? SkyH() : rC[r]; }
	// the sky height over outdoor spaces: how tall the buildings round them look
	virtual double SkyH() { return SKY_H; }
	// >0: sealed wall strips / posts / solid cells that face the outdoors are raised to this height, so a
	// street facade is two textures: the ground floor (bottom) and the storeys above it (top, UpperFacade)
	virtual double GroundFloorH() { return 0; }
	virtual String UpperFacade(String ground) { return ground; }
	void CellsOf(int r, Array<int> ci, Array<int> cj)
	{
		ci.Clear(); cj.Clear();
		for (int j = 0; j < NY; j++) for (int i = 0; i < NX; i++) if (At(i, j) == r) { ci.Push(i); cj.Push(j); }
	}
	int CellCount(int r) { int n = 0; for (int k = 0; k < roomOf.Size(); k++) if (roomOf[k] == r) n++; return n; }
	bool IsType(int r, int t) { return r >= 0 && rtype[r] == t; }
	Vector2 RoomCenter(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		if (!ci.Size()) return (0, 0);
		Vector2 s = (0, 0);
		for (int k = 0; k < ci.Size(); k++) s += CellCenter(ci[k], cj[k]);
		s /= ci.Size();
		// the centre cell of an L-shaped room may not be in the room: take the room cell nearest the mean
		double bd = 1e9; Vector2 best = s;
		for (int k = 0; k < ci.Size(); k++) { double d = (CellCenter(ci[k], cj[k]) - s).Length(); if (d < bd) { bd = d; best = CellCenter(ci[k], cj[k]); } }
		return best;
	}

	// ================================================================ layout helpers
	int Depth(int i, int j) { return min(min(i, j), min(NX - 1 - i, NY - 1 - j)); }
	// the cells of ring d, walked round from the south-west corner (south row east, east column north, ...)
	void Ring(int d, Array<int> ci, Array<int> cj)
	{
		ci.Clear(); cj.Clear();
		for (int i = d; i <= NX - 1 - d; i++) { ci.Push(i); cj.Push(d); }
		for (int j = d + 1; j <= NY - 1 - d; j++) { ci.Push(NX - 1 - d); cj.Push(j); }
		for (int i = NX - 2 - d; i >= d; i--) { ci.Push(i); cj.Push(NY - 1 - d); }
		for (int j = NY - 2 - d; j > d; j--) { ci.Push(d); cj.Push(j); }
	}
	// an entry at the outer wall of cell (i,j) on side d (0 east, 1 west, 2 north, 3 south), facing in
	void WallEntry(int i, int j, int d, String name, int kind)
	{
		Vector2 n = (DX[d], DY[d]);
		double half = (d < 2 ? colw[i] : rowh[j]) / 2;
		AddEntry(CellCenter(i, j) + n * (half - 36), VectorAngle(-n.x, -n.y), name, kind);
	}
	// the outer side of an edge cell (or -1)
	int OuterSide(int i, int j)
	{
		if (j == 0) return 3;
		if (j == NY - 1) return 2;
		if (i == 0) return 1;
		if (i == NX - 1) return 0;
		return -1;
	}
	// a random cell of a room
	bool AnyCell(int r, out int i, out int j)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		if (!ci.Size()) return false;
		int k = Rand(0, ci.Size() - 1);
		i = ci[k]; j = cj[k];
		return true;
	}
	// cars: the voxel pack's collision is only the middle, so block the nose and tail too
	Actor Car(Vector2 p, double ang, String cls = "")
	{
		// NBC: the Bricks' cars are older and dirtier; now and then a dead squad car
		static const String CARS[] = { "ModernCarDarkRed", "ModernCarDarkBlue", "ModernCarDirtyGreen", "ModernCarBrown",
			"HatchBackDarkRed", "HatchBackDirtyGreen", "HatchBackBrown", "PickupDirtyGreen", "PickupDarkBlue", "PickupBrown",
			"VanWhite", "VanDirtyGreen", "VanDarkRed", "SuvDarkBlue", "SuvDirtyGreen", "ModernTaxi", "ModernCopOff" };
		if (!cls.Length()) cls = CARS[Rand(0, CARS.Size() - 1)];
		if (!Clear(p, 60)) return null;
		let car = Actor.Spawn(cls, (p, FloorAt(p)));
		if (!car) return null;
		car.angle = ang;
		Vector2 ax = Actor.AngleToVector(ang);
		for (int k = -1; k <= 1; k += 2) { let b = Actor.Spawn("CW_Blocker", (p + ax * 40 * k, FloorAt(p))); if (b) b.A_SetSize(20, 44); }
		return car;
	}

	// ================================================================ links
	bool EdgeBetween(int i1, int j1, int i2, int j2, out int ei, out int ej, out bool vert)
	{
		if (j1 == j2 && abs(i1 - i2) == 1) { ei = min(i1, i2); ej = j1; vert = true; return true; }
		if (i1 == i2 && abs(j1 - j2) == 1) { ei = i1; ej = min(j1, j2); vert = false; return true; }
		return false;
	}
	Vector2 EdgeCenter(int ei, int ej, bool vert)
	{
		if (vert) return (colX[ei] + colw[ei] + WALL / 2, rowY[ej] + rowh[ej] / 2);
		return (colX[ei] + colw[ei] / 2, rowY[ej] + rowh[ej] + WALL / 2);
	}
	int EdgeLen(int ei, int ej, bool vert) { return vert ? rowh[ej] : colw[ei]; }

	bool Link(int i1, int j1, int i2, int j2, int kind)
	{
		int ei, ej; bool vert;
		if (!EdgeBetween(i1, j1, i2, j2, ei, ej, vert)) return false;
		for (int k = 0; k < lI.Size(); k++) if (lI[k] == ei && lJ[k] == ej && lVert[k] == (vert ? 1 : 0)) { lKind[k] = kind; return true; }
		lI.Push(ei); lJ.Push(ej); lVert.Push(vert ? 1 : 0); lKind.Push(kind);
		Vector2 p = EdgeCenter(ei, ej, vert);
		lX.Push(p.x); lY.Push(p.y);
		return true;
	}

	// Link two rooms through one of their shared edges (the one nearest `near`, or a random one).
	bool LinkRooms(int a, int b, int kind, Vector2 near = (-1, -1))
	{
		static const int dx[] = { 1, -1, 0, 0 };
		static const int dy[] = { 0, 0, 1, -1 };
		Array<int> ci, cj, di;
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				if (At(i, j) != a) continue;
				for (int d = 0; d < 4; d++)
					if (At(i + dx[d], j + dy[d]) == b) { ci.Push(i); cj.Push(j); di.Push(d); }
			}
		if (!ci.Size()) return false;
		int pick = Rand(0, ci.Size() - 1);
		if (near.x >= 0)
		{
			double bd = 1e9;
			for (int k = 0; k < ci.Size(); k++)
			{
				int ei, ej; bool v;
				EdgeBetween(ci[k], cj[k], ci[k] + dx[di[k]], cj[k] + dy[di[k]], ei, ej, v);
				double d = (EdgeCenter(ei, ej, v) - near).Length();
				if (d < bd) { bd = d; pick = k; }
			}
		}
		return Link(ci[pick], cj[pick], ci[pick] + dx[di[pick]], cj[pick] + dy[di[pick]], kind);
	}
	// every edge the two rooms share gets the same treatment (streets meeting sidewalks, fences along a yard)
	int LinkAll(int a, int b, int kind)
	{
		int n = 0;
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				if (At(i, j) != a) continue;
				if (At(i + 1, j) == b && Link(i, j, i + 1, j, kind)) n++;
				if (At(i - 1, j) == b && Link(i, j, i - 1, j, kind)) n++;
				if (At(i, j + 1) == b && Link(i, j, i, j + 1, kind)) n++;
				if (At(i, j - 1) == b && Link(i, j, i, j - 1, kind)) n++;
			}
		return n;
	}
	// A kit's room by type (kits that use Blocks override this with their MakeRoom).
	virtual int KitRoom(int t) { return Room(t, 0, 0, 128, 128, "CWCONCF", "CEIL5_1", "CWCONCW", "room"); }
	bool FreeCell(int i, int j) { return InGrid(i, j) && roomOf[j * NX + i] < 0 && !cellFac[j * NX + i].Length(); }
	// Fill the free cells of a box with rooms of up to maxW x maxH cells, types taken in turn from the bag.
	// Each gets a door to `hub` when it touches it, else to a neighbour; EnsureConnected mends the rest.
	int Blocks(int i0, int j0, int i1, int j1, Array<int> bag, int maxW, int maxH, int hub, int kind = E_DOOR, int hub2 = -1)
	{
		int made = 0, b = bag.Size() ? Rand(0, bag.Size() - 1) : 0;
		Array<int> madeRooms;
		for (int j = j0; j <= j1; j++)
			for (int i = i0; i <= i1; i++)
			{
				if (!FreeCell(i, j) || !bag.Size()) continue;
				int w = Rand(min(2, maxW), maxW), h = Rand(min(2, maxH), maxH);
				// shrink to the free run
				int fw = 0; while (fw < w && i + fw <= i1 && FreeCell(i + fw, j)) fw++;
				w = max(1, fw);
				int fh = 0;
				while (fh < h && j + fh <= j1)
				{
					bool ok = true;
					for (int x = i; x < i + w; x++) if (!FreeCell(x, j + fh)) { ok = false; break; }
					if (!ok) break;
					fh++;
				}
				h = max(1, fh);
				// a lone cell joins a room this call already made, rather than being a cupboard of its own
				if (w == 1 && h == 1)
				{
					int join = -1;
					for (int d = 0; d < 4 && join < 0; d++)
					{
						int o = At(i + DX[d], j + DY[d]);
						if (o >= 0 && madeRooms.Find(o) < madeRooms.Size() && CellCount(o) < maxW * maxH + 2) join = o;
					}
					if (join >= 0) { Claim(join, i, j); continue; }
				}
				int r = KitRoom(bag[b % bag.Size()]); b++;
				madeRooms.Push(r);
				Rect(r, i, j, i + w - 1, j + h - 1);
				made++;
				if (hub >= 0 && LinkRooms(r, hub, kind)) continue;
				if (hub2 >= 0 && LinkRooms(r, hub2, kind)) continue;
				// a neighbour instead
				Array<int> nb;
				for (int y = j - 1; y <= j + h; y++)
					for (int x = i - 1; x <= i + w; x++)
					{
						if ((x < i || x >= i + w) == (y < j || y >= j + h)) continue;   // edge neighbours only, no corners
						int o = At(x, y);
						if (o >= 0 && o != r && !Has(o, RF_WATER) && nb.Find(o) == nb.Size()) nb.Push(o);
					}
				if (nb.Size()) LinkRooms(r, nb[Rand(0, nb.Size() - 1)], kind);
			}
		return made;
	}
	bool Adjacent(int a, int b)
	{
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
				if (At(i, j) == a && (At(i + 1, j) == b || At(i - 1, j) == b || At(i, j + 1) == b || At(i, j - 1) == b)) return true;
		return false;
	}
	int LinkKindBetween(int a, int b)
	{
		for (int k = 0; k < lI.Size(); k++)
		{
			int i2 = lVert[k] ? lI[k] + 1 : lI[k], j2 = lVert[k] ? lJ[k] : lJ[k] + 1;
			int ra = At(lI[k], lJ[k]), rb = At(i2, j2);
			if ((ra == a && rb == b) || (ra == b && rb == a)) return lKind[k];
		}
		return -1;
	}
	bool LinkOutdoor(int k)
	{
		int i2 = lVert[k] ? lI[k] + 1 : lI[k], j2 = lVert[k] ? lJ[k] : lJ[k] + 1;
		return IsOut(At(lI[k], lJ[k])) && IsOut(At(i2, j2));
	}
	static bool Walkable(int kind) { return kind == E_DOOR || kind == E_ARCH || kind == E_WIDE; }

	// rooms reachable from `from` (guards: doors, arches, wide openings; the player also fits windows and vents)
	void Reach(int from, Array<int> depth, bool player)
	{
		depth.Clear();
		for (int r = 0; r < rtype.Size(); r++) depth.Push(-1);
		if (from < 0) return;
		depth[from] = 0;
		Array<int> q; q.Push(from);
		for (int h = 0; h < q.Size(); h++)
		{
			int a = q[h];
			for (int k = 0; k < lI.Size(); k++)
			{
				int kind = lKind[k];
				if (!(Walkable(kind) || (player && (kind == E_WINDOW || kind == E_VENT)))) continue;
				int i2 = lVert[k] ? lI[k] + 1 : lI[k], j2 = lVert[k] ? lJ[k] : lJ[k] + 1;
				int ra = At(lI[k], lJ[k]), rb = At(i2, j2);
				int o = ra == a ? rb : (rb == a ? ra : -1);
				if (o < 0 || depth[o] >= 0 || Has(o, RF_WATER)) continue;
				depth[o] = depth[a] + 1;
				q.Push(o);
			}
		}
	}

	// Safety net for every kit: any room the guards can't walk to gets a door to a neighbour that they can.
	void EnsureConnected(int from)
	{
		for (int pass = 0; pass < rtype.Size() + 4; pass++)
		{
			Array<int> depth;
			Reach(from, depth, false);
			bool changed = false, missing = false;
			for (int r = 0; r < rtype.Size() && !changed; r++)
			{
				if (depth[r] >= 0 || Has(r, RF_WATER) || !CellCount(r)) continue;
				missing = true;
				for (int o = 0; o < rtype.Size(); o++)
				{
					if (depth[o] < 0 || !Adjacent(r, o)) continue;
					if (LinkRooms(r, o, IsOut(r) && IsOut(o) ? E_WIDE : E_DOOR)) { changed = true; break; }
				}
			}
			if (!missing || !changed) return;
		}
	}

	// ================================================================ entries
	void AddEntry(Vector2 p, double ang, String name, int kind, int room = -1)
	{
		enX.Push(p.x); enY.Push(p.y); enA.Push(ang); enName.Push(name); enKind.Push(kind);
		enRoom.Push(room >= 0 ? room : At(CellI(p.x), CellJ(p.y)));
	}

	void PickInsertion()
	{
		int n = enX.Size();
		if (!n) { AddEntry(RoomCenter(0), 0, "the site", EK_FRONT); n = 1; }
		insertIdx = Rand(0, n - 1);
		if (entryPref >= 2) for (int e = 0; e < n; e++) if (enKind[e] == entryPref) { insertIdx = e; break; }
		insertPos = (enX[insertIdx], enY[insertIdx]);
		insertAng = enA[insertIdx];
		insertName = enName[insertIdx];
	}

	// ================================================================ planes
	void CeilTo(int tag, double h)
	{
		let it = level.CreateSectorTagIterator(tag);
		int s;
		while ((s = it.Next()) >= 0)
		{
			Sector sec = level.sectors[s];
			double dz = h - sec.ceilingplane.ZAtPoint(sec.centerspot);
			if (dz == 0) continue;
			sec.MoveCeiling(abs(dz) + 1, sec.ceilingplane.PointToDist(sec.centerspot, h), -1, dz > 0 ? 1 : -1, false);
		}
	}
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
	// ceiling first so a raised floor never runs into a closed ceiling
	void Planes(int tag, double f, double c)
	{
		if (c >= 0) { CeilTo(tag, max(c, f)); FloorTo(tag, f); }
		else { FloorTo(tag, f); CeilTo(tag, max(c, f)); }
	}
	void Segs(int ei, int ej, bool vert, int k0, int k1, double f, double c)
	{
		if (!Three(EdgeLen(ei, ej, vert))) { k0 = 1; k1 = 1; }
		for (int k = k0; k <= k1; k++) Planes(vert ? VTag(ei, ej, k) : HTag(ei, ej, k), f, c);
	}
	void SetEdgeState(int ei, int ej, bool vert, int st)
	{
		if (vert) vOpen[ej * NX + ei] = st; else hOpen[ej * NX + ei] = st;
	}
	int EdgeState(int ei, int ej, bool vert) { return vert ? vOpen[ej * NX + ei] : hOpen[ej * NX + ei]; }

	// ================================================================ carve
	void Carve()
	{
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				int r = At(i, j);
				if (r < 0)
				{
					double top = SolidTop(i, j);
					if (top > 0) { Planes(CTag(i, j), top, SkyH()); topTags.Push(CTag(i, j)); }
					else Planes(CTag(i, j), 0, 0);
					continue;
				}
				Planes(CTag(i, j), rF[r], CeilOf(r));
			}
		// same-room neighbours: the whole strip opens
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				int r = At(i, j);
				if (r < 0) continue;
				if (i + 1 < NX && At(i + 1, j) == r) { Segs(i, j, true, 0, 2, rF[r], CeilOf(r)); SetEdgeState(i, j, true, 2); }
				if (j + 1 < NY && At(i, j + 1) == r) { Segs(i, j, false, 0, 2, rF[r], CeilOf(r)); SetEdgeState(i, j, false, 2); }
			}
		for (int k = 0; k < lI.Size(); k++) CarveLink(k);
		// posts: open where all four cells are one space (same room or fully open between them)
		for (int j = 0; j + 1 < NY; j++)
			for (int i = 0; i + 1 < NX; i++)
			{
				int a = At(i, j), b = At(i + 1, j), c = At(i, j + 1), d = At(i + 1, j + 1);
				if (a < 0 || b < 0 || c < 0 || d < 0) continue;
				int e0 = EdgeState(i, j, true), e1 = EdgeState(i, j + 1, true), e2 = EdgeState(i, j, false), e3 = EdgeState(i + 1, j, false);
				double f = max(max(rF[a], rF[b]), max(rF[c], rF[d]));
				double cc = min(min(CeilOf(a), CeilOf(b)), min(CeilOf(c), CeilOf(d)));
				if (e0 == 2 && e1 == 2 && e2 == 2 && e3 == 2) { Planes(PTag(i, j), f, cc); continue; }
				// NBC: outdoors, where fences (and gates) meet, the post is a fence post: fence height, sky above.
				// Left sealed it would be raised as building facade: a thin column standing up out of the fence.
				if (IsOut(a) && IsOut(b) && IsOut(c) && IsOut(d)
					&& (e0 == 2 || e0 == -1) && (e1 == 2 || e1 == -1) && (e2 == 2 || e2 == -1) && (e3 == 2 || e3 == -1))
				{
					double top = f + max(max(FenceH(a, b), FenceH(c, d)), max(FenceH(a, c), FenceH(b, d)));
					Planes(PTag(i, j), top, SkyH());
				}
			}
	}

	// NBC: a solid cell with a SolidTop is a free-standing structure (the Wall): its strips and posts toward
	// other such cells or open ground stand at the same height, open to the sky, instead of being raised as facade.
	virtual double SolidTop(int i, int j) { return 0; }
	double TopOrOpen(int i, int j)    // >0 the structure's height; 0 open ground; -1 anything else
	{
		if (!InGrid(i, j)) return -1;
		int r = At(i, j);
		if (r < 0) { double t = SolidTop(i, j); return t > 0 ? t : -1; }
		return IsOut(r) ? 0 : -1;
	}
	void CarveSolidTops()
	{
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				for (int d = 0; d < 2; d++)
				{
					int i2 = d == 0 ? i + 1 : i, j2 = d == 0 ? j : j + 1;
					if (!InGrid(i2, j2)) continue;
					double a = TopOrOpen(i, j), b = TopOrOpen(i2, j2);
					if (a < 0 || b < 0 || (a <= 0 && b <= 0)) continue;
					double h = max(a, b);
					bool vert = d == 0;
					for (int k = 0; k < 3; k++)
					{
						if (!Three(EdgeLen(i, j, vert)) && k != 1) continue;
						int tag = vert ? VTag(i, j, k) : HTag(i, j, k);
						Planes(tag, h, SkyH()); topTags.Push(tag);
					}
				}
				if (i + 1 < NX && j + 1 < NY)
				{
					double a = TopOrOpen(i, j), b = TopOrOpen(i + 1, j), c = TopOrOpen(i, j + 1), e = TopOrOpen(i + 1, j + 1);
					if (a < 0 || b < 0 || c < 0 || e < 0) continue;
					double h = max(max(a, b), max(c, e));
					if (h <= 0) continue;
					Planes(PTag(i, j), h, SkyH()); topTags.Push(PTag(i, j));
				}
			}
	}

	// NBC: two outdoor spaces that touch without a link would be split by a sealed strip, which rises as
	// facade like a building wall. Give every such edge a fence instead.
	void FenceOpenGround()
	{
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				int a = At(i, j);
				if (!IsOut(a)) continue;
				int r = At(i + 1, j);
				if (IsOut(r) && r != a && LinkKindAt(i, j, true) < 0) Link(i, j, i + 1, j, E_FENCE);
				r = At(i, j + 1);
				if (IsOut(r) && r != a && LinkKindAt(i, j, false) < 0) Link(i, j, i, j + 1, E_FENCE);
			}
	}
	int LinkKindAt(int ei, int ej, bool vert)
	{
		for (int k = 0; k < lI.Size(); k++) if (lI[k] == ei && lJ[k] == ej && (lVert[k] == 1) == vert) return lKind[k];
		return -1;
	}

	// sealed sectors next to an outdoor space rise to the ground-floor height (see GroundFloorH)
	void RaiseFacades()
	{
		double h = GroundFloorH();
		if (h <= 0) return;
		Array<int> outSec;
		for (int s = 0; s < level.sectors.Size(); s++)
		{
			Sector sec = level.sectors[s];
			if (sec.ceilingplane.ZAtPoint(sec.centerspot) > sec.floorplane.ZAtPoint(sec.centerspot) + 1) continue;
			bool faces = false;
			for (int l = 0; l < sec.lines.Size() && !faces; l++)
			{
				Line ln = sec.lines[l];
				Sector o = ln.frontsector == sec ? ln.backsector : ln.frontsector;
				if (!o) continue;
				int r = SecRoomRaw(o.Index());
				if (r >= 0 && IsOut(r) && o.ceilingplane.ZAtPoint(o.centerspot) > o.floorplane.ZAtPoint(o.centerspot) + 1) faces = true;
			}
			if (faces) outSec.Push(s);
		}
		for (int k = 0; k < outSec.Size(); k++)
		{
			Sector sec = level.sectors[outSec[k]];
			double f = sec.floorplane.ZAtPoint(sec.centerspot);
			sec.MoveCeiling(abs(h - f) + 1, sec.ceilingplane.PointToDist(sec.centerspot, h), -1, 1, false);
			sec.MoveFloor(abs(h - f) + 1, sec.floorplane.PointToDist(sec.centerspot, h), -1, 1, false);
		}
	}
	// SecRoom before Paint has indexed the sectors
	int SecRoomRaw(int s)
	{
		if (!secRole.Size()) IndexSectors();
		return SecRoom(s);
	}

	void CarveLink(int k)
	{
		int ei = lI[k], ej = lJ[k]; bool vert = lVert[k] == 1;
		int i2 = vert ? ei + 1 : ei, j2 = vert ? ej : ej + 1;
		int a = At(ei, ej), b = At(i2, j2);
		if (a < 0 || b < 0 || a == b) return;
		double f = max(rF[a], rF[b]);
		double c = min(CeilOf(a), CeilOf(b));
		switch (lKind[k])
		{
		case E_DOOR:
		{
			double top = min(c, f + DOOR_H);
			Segs(ei, ej, vert, 1, 1, f, top);
			SetEdgeState(ei, ej, vert, 1);
			let dr = NBC_KitDoor(Actor.Spawn("NBC_KitDoor", ((lX[k], lY[k]), f)));
			if (dr)
			{
				dr.doorTag = vert ? VTag(ei, ej, 1) : HTag(ei, ej, 1);
				dr.shutZ = f; dr.openZ = top; dr.doorIdx = doors.Size();
				doors.Push(dr);
			}
			break;
		}
		case E_ARCH:
			Segs(ei, ej, vert, 1, 1, f, min(c, f + DOOR_H + 16));
			SetEdgeState(ei, ej, vert, 1);
			break;
		case E_WIDE:
			Segs(ei, ej, vert, 0, 2, f, c);
			SetEdgeState(ei, ej, vert, 2);
			break;
		case E_WINDOW:   // crawl through crouched (guards don't fit)
			Segs(ei, ej, vert, 1, 1, f + 24, f + 24 + 40);
			SetEdgeState(ei, ej, vert, 1);
			break;
		case E_VENT:
			Segs(ei, ej, vert, 1, 1, min(rF[a], rF[b]), min(rF[a], rF[b]) + 32);
			SetEdgeState(ei, ej, vert, 1);
			break;
		case E_FENCE:    // a low wall you can see over but not cross
			Segs(ei, ej, vert, 0, 2, f + FenceH(a, b), (IsOut(a) || IsOut(b)) ? SkyH() : c);
			SetEdgeState(ei, ej, vert, -1);
			// NBC: a rail over a drop must hold: its edges block, so nobody steps or jumps onto it
			if (Has(a, RF_WATER) || Has(b, RF_WATER)) BlockSegs(ei, ej, vert);
			break;
		}
	}

	// ================================================================ paint
	void IndexSectors()
	{
		int n = level.sectors.Size();
		secRole.Clear(); secIdx.Clear(); secK.Clear();
		for (int s = 0; s < n; s++) { secRole.Push(0); secIdx.Push(-1); secK.Push(0); }
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				Tag1(CTag(i, j), 1, j * NX + i, 0);
				for (int k = 0; k < 3; k++)
				{
					if (i + 1 < NX) Tag1(VTag(i, j, k), 2, j * NX + i, k);
					if (j + 1 < NY) Tag1(HTag(i, j, k), 3, j * NX + i, k);
				}
				if (i + 1 < NX && j + 1 < NY) Tag1(PTag(i, j), 4, j * NX + i, 0);
			}
		Tag1(12000, 5, 0, 0);
	}
	void Tag1(int tag, int role, int idx, int k)
	{
		let it = level.CreateSectorTagIterator(tag);
		int s;
		while ((s = it.Next()) >= 0) { secRole[s] = role; secIdx[s] = idx; secK[s] = k; }
	}
	// the two rooms either side of a strip sector (-1 = solid / outside)
	void StripRooms(int s, out int a, out int b)
	{
		int idx = secIdx[s], i = idx % NX, j = idx / NX;
		a = At(i, j);
		b = secRole[s] == 2 ? At(i + 1, j) : At(i, j + 1);
	}
	// the cell on the other side of strip sector s from cell index here (-1 = none)
	int FarCell(int s, int here)
	{
		if (secRole[s] != 2 && secRole[s] != 3) return -1;
		int idx = secIdx[s];
		int other = secRole[s] == 2 ? idx + 1 : idx + NX;
		return here == idx ? other : (here == other ? idx : -1);
	}
	int SecRoom(int s)
	{
		if (s < 0 || s >= secRole.Size()) return -1;
		if (secRole[s] == 1) return roomOf[secIdx[s]];
		if (secRole[s] == 2 || secRole[s] == 3)
		{
			int a, b; StripRooms(s, a, b);
			if (a >= 0 && !IsOut(a)) return a;
			return a >= 0 ? a : b;
		}
		if (secRole[s] == 4) { int idx = secIdx[s]; return At(idx % NX, idx / NX); }
		return -1;
	}
	bool IsDoorStrip(int s)
	{
		if (secRole[s] != 2 && secRole[s] != 3) return false;
		if (secK[s] != 1 && Three(secRole[s] == 2 ? rowh[secIdx[s] / NX] : colw[secIdx[s] % NX])) return false;
		int idx = secIdx[s], ei = idx % NX, ej = idx / NX;
		bool vert = secRole[s] == 2;
		for (int k = 0; k < lI.Size(); k++) if (lI[k] == ei && lJ[k] == ej && (lVert[k] == 1) == vert && lKind[k] == E_DOOR) return true;
		return false;
	}

	TextureID Tx(String name, String fallback = "CWCONCW")
	{
		TextureID t = TexMan.CheckForTexture(name, TexMan.Type_Any);
		if (!t.IsValid()) t = TexMan.CheckForTexture(fallback, TexMan.Type_Any);
		return t;
	}

	String FacadeFor(int r) { return (r >= 0 && rFacT[r].Length()) ? rFacT[r] : edgeTex; }
	// the view band beyond the map edge: height and look (kits at ground level lower it to the street)
	double bandFloor;
	String bandTex;
	double bandCeil;            // >0: the band's sky height (ground-level kits: the roofline of the buildings across the street)
	Array<String> bandWalls;
	int bandLight;
	String kerbTex;             // the step between an open outdoor edge and the band (a kerb)              // >0: the band's light level    // the band's outer wall (the buildings across the street); empty = edgeTex
	virtual bool EdgeOpen(int r) { return false; }   // true: this outdoor room's edge is a railing / fence with the view beyond
	// NBC: how high a fence or rail between two rooms stands (chain-link 64; a balcony rail is lower)
	virtual double FenceH(int a, int b) { return 64; }
	// NBC: make every line round a strip's pieces block (a rail over a drop)
	void BlockSegs(int ei, int ej, bool vert)
	{
		int n = Three(EdgeLen(ei, ej, vert)) ? 3 : 1;
		for (int k = 0; k < 3; k++)
		{
			if (n == 1 && k != 1) continue;
			let it = level.CreateSectorTagIterator(vert ? VTag(ei, ej, k) : HTag(ei, ej, k));
			int s;
			while ((s = it.Next()) >= 0)
			{
				Sector sec = level.sectors[s];
				for (int l = 0; l < sec.lines.Size(); l++) sec.lines[l].flags |= Line.ML_BLOCKING;
			}
		}
	}
	// NBC: the inside face of an indoor room's outer wall (a tower flat's windows onto the city)
	virtual String EdgeWall(int r) { return rWallT[r]; }
	// NBC: the far wall of the view band at this point (towers across the street, the Wall ...)
	virtual String BandWall(Vector2 at) { return bandWalls.Size() ? bandWalls[Rand(0, bandWalls.Size() - 1)] : edgeTex; }

	// A boundary line between the grid and the view band. Indoors: a wall (wrapped mid texture). Outdoors:
	// open (a railing you can't cross) or a wall, as the kit decides. Solid cells: the building's face.
	bool PaintEdge(Line ln)
	{
		int s0 = ln.sidedef[0].sector.Index(), s1 = ln.sidedef[1].sector.Index();
		int zb = secRole[s0] == 5 ? 0 : (secRole[s1] == 5 ? 1 : -1);
		if (zb < 0) return false;
		Side band = ln.sidedef[zb], inner = ln.sidedef[1 - zb];
		int si = inner.sector.Index();
		if (!secRole[si]) return false;     // NBC: the band's outer edge meets the template's scenery, not the grid
		int r = SecRoom(si);
		Sector isec = inner.sector;
		bool closed = isec.ceilingplane.ZAtPoint(isec.centerspot) <= isec.floorplane.ZAtPoint(isec.centerspot) + 1;
		String face = edgeTex;
		if (secRole[si] == 1 && roomOf[secIdx[si]] < 0 && cellFac[secIdx[si]].Length()) face = cellFac[secIdx[si]];
		else if (r >= 0 && !IsOut(r)) face = FacadeFor(r);
		band.SetTexture(Side.top, Tx(face)); band.SetTexture(Side.bottom, Tx(face));
		inner.SetTexture(Side.top, Tx(face)); inner.SetTexture(Side.bottom, Tx(face));
		if (closed || r < 0) return true;
		if (IsOut(r) && EdgeOpen(r))
		{
			inner.SetTexture(Side.mid, TexMan.CheckForTexture("-", TexMan.Type_Any));
			if (kerbTex.Length()) { inner.SetTexture(Side.bottom, Tx(kerbTex)); band.SetTexture(Side.bottom, Tx(kerbTex)); }
			return true;
		}
		inner.SetTexture(Side.mid, Tx(IsOut(r) ? face : EdgeWall(r)));
		ln.flags |= Line.ML_WRAP_MIDTEX;
		return true;
	}

	void Paint()
	{
		IndexSectors();
		int n = level.sectors.Size();
		for (int s = 0; s < n; s++)
		{
			int role = secRole[s];
			if (!role) continue;
			Sector sec = level.sectors[s];
			if (role == 1)
			{
				int r = roomOf[secIdx[s]];
				if (r < 0) continue;
				sec.SetTexture(Sector.floor, Tx(rFloorT[r], "FLAT5_4"));
				if (IsOut(r)) sec.SetTexture(Sector.ceiling, skyflatnum); else sec.SetTexture(Sector.ceiling, Tx(rCeilT[r], "CEIL1_1"));
				sec.SetLightLevel(rLight[r]);
				continue;
			}
			// strips and posts take the look of the space they open into
			int a = -1, b = -1;
			if (role == 4) { int idx = secIdx[s]; a = At(idx % NX, idx / NX); b = At(idx % NX + 1, idx / NX + 1); }
			else StripRooms(s, a, b);
			int ind = (a >= 0 && !IsOut(a)) ? a : ((b >= 0 && !IsOut(b)) ? b : (a >= 0 ? a : b));
			if (ind < 0) continue;
			sec.SetTexture(Sector.floor, Tx(rFloorT[ind], "FLAT5_4"));
			// only an OPEN strip between two outdoor spaces may have a sky ceiling: a sky on a sealed one makes the
			// engine skip the wall above it, and the sky shows through the building
			bool open = sec.ceilingplane.ZAtPoint(sec.centerspot) > sec.floorplane.ZAtPoint(sec.centerspot) + 1;
			if (open && IsOut(a) && IsOut(b)) sec.SetTexture(Sector.ceiling, skyflatnum);
			else sec.SetTexture(Sector.ceiling, IsOut(ind) ? Tx("CEIL1_1") : Tx(rCeilT[ind], "CEIL1_1"));
			int la = a >= 0 ? rLight[a] : 0, lb = b >= 0 ? rLight[b] : 0;
			sec.SetLightLevel(max(la, lb));
		}
		// NBC: free-standing structures are open to the sky, with a concrete top
		for (int k = 0; k < topTags.Size(); k++)
		{
			let it = level.CreateSectorTagIterator(topTags[k]);
			int ts;
			while ((ts = it.Next()) >= 0) { level.sectors[ts].SetTexture(Sector.ceiling, skyflatnum); level.sectors[ts].SetTexture(Sector.floor, Tx("CWCONCF")); }
		}
		FloorTo(12000, bandFloor);
		if (bandCeil > 0) CeilTo(12000, bandCeil);
		{
			let it = level.CreateSectorTagIterator(12000);
			int bs = it.Next();
			if (bs >= 0) level.sectors[bs].SetTexture(Sector.floor, Tx(bandTex, "ADFCITY"));
			if (bs >= 0 && bandLight > 0) level.sectors[bs].SetLightLevel(bandLight);
		}
		TextureID door = Tx(doorTex, "DOOR3"), jamb = Tx(jambTex, "CWCONCW");
		for (int l = 0; l < level.lines.Size(); l++)
		{
			Line ln = level.lines[l];
			if (!ln.sidedef[1])
			{
				// the edge of the map: outside walls
				Side sd = ln.sidedef[0];
				int si = sd.sector.Index();
				if (secRole[si] == 5 && (bandWalls.Size() || BandWall((ln.v1.p + ln.v2.p) / 2) != edgeTex))
				{
					sd.SetTexture(Side.mid, Tx(BandWall((ln.v1.p + ln.v2.p) / 2), edgeTex));
					ln.flags |= Line.ML_DONTPEGBOTTOM;       // windows line up from the pavement
					continue;
				}
				int r = SecRoom(si);
				sd.SetTexture(Side.mid, Tx(r >= 0 && !IsOut(r) ? rWallT[r] : edgeTex));
				continue;
			}
			if (PaintEdge(ln)) continue;
			for (int z = 0; z < 2; z++)
			{
				Side sd = ln.sidedef[z];
				int s = sd.sector.Index(), o = ln.sidedef[1 - z].sector.Index();
				int rs = secRole[s], ro = secRole[o];
				if (rs == 1)
				{
					int r = roomOf[secIdx[s]];
					if (r < 0) continue;
					if (IsDoorStrip(o))
					{
						sd.SetTexture(Side.top, door);
						ln.flags &= ~Line.ML_DONTPEGTOP;
						// NBC: doors are smaller than the door art: squeeze the whole door onto the opening
						int tw, th;
						[tw, th] = TexMan.GetSize(door);
						double len = ln.delta.Length();
						if (tw > 0 && th > 0 && len > 0)
						{
							sd.SetTextureXScale(Side.top, tw / len);
							sd.SetTextureYScale(Side.top, th / double(DOOR_H));
						}
						sd.SetTextureYOffset(Side.top, 0);
						sd.SetTexture(Side.bottom, Tx(rWallT[r]));
						continue;
					}
					String t = rWallT[r];
					if (IsOut(r))
					{
						// from outside, a closed wall is the face of whatever is behind it
						int fc = FarCell(o, secIdx[s]);
						int far = fc >= 0 ? roomOf[fc] : -1;
						if (far >= 0 && !IsOut(far)) t = FacadeFor(far);
						else if (far >= 0) t = rWallT[r];
						else t = (fc >= 0 && cellFac[fc].Length()) ? cellFac[fc] : edgeTex;
					}
					sd.SetTexture(Side.top, Tx(IsOut(r) ? UpperFacade(t) : t)); sd.SetTexture(Side.bottom, Tx(t));
				}
				else if (rs >= 2 && ro >= 2)
				{
					// door jambs and post faces
					int rr = SecRoom(s);
					TextureID tj = jamb;
					if (rr >= 0 && IsOut(rr)) tj = Tx(FacadeFor(SecRoom(o)));
					sd.SetTexture(Side.top, tj); sd.SetTexture(Side.bottom, tj);
				}
			}
		}
	}

	// ================================================================ things
	double FloorAt(Vector2 p) { return level.PointInSector(p).floorplane.ZAtPoint(p); }
	double CeilAt(Vector2 p) { return level.PointInSector(p).ceilingplane.ZAtPoint(p); }

	// Free floor for something of radius r at p: inside a room cell, clear of closed walls, doorways,
	// entries and anything solid.
	bool Clear(Vector2 p, double r)
	{
		int i = CellI(p.x), j = CellJ(p.y);
		if (i < 0 || j < 0) return false;
		int rm = At(i, j);
		if (rm < 0 || Has(rm, RF_WATER)) return false;
		double x0 = colX[i], x1 = colX[i] + colw[i], y0 = rowY[j], y1 = rowY[j] + rowh[j];
		if (!(i + 1 < NX && At(i + 1, j) == rm && EdgeState(i, j, true) == 2) && p.x + r > x1 - 2) return false;
		if (!(i > 0 && At(i - 1, j) == rm && EdgeState(i - 1, j, true) == 2) && p.x - r < x0 + 2) return false;
		if (!(j + 1 < NY && At(i, j + 1) == rm && EdgeState(i, j, false) == 2) && p.y + r > y1 - 2) return false;
		if (!(j > 0 && At(i, j - 1) == rm && EdgeState(i, j - 1, false) == 2) && p.y - r < y0 + 2) return false;
		for (int k = 0; k < lX.Size(); k++)
		{
			// keep doorways clear (open ground between two outdoor spaces doesn't count)
			if (lKind[k] == E_FENCE) continue;
			if (lKind[k] == E_WIDE && LinkOutdoor(k)) continue;
			if ((p - (lX[k], lY[k])).Length() < 44 + r) return false;
		}
		for (int e = 0; e < enX.Size(); e++) if ((p - (enX[e], enY[e])).Length() < 44 + r) return false;
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, r + 48, false);
		while (it.Next()) if (it.thing.bSOLID && (it.thing.pos.xy - p).Length() < it.thing.radius + r + 4) return false;
		return true;
	}

	Actor Put(Class<Actor> cls, Vector2 p, double ang = 0, bool check = true)
	{
		let def = GetDefaultByType(cls);
		double r = def.radius;
		if (cls is "CW_Furniture") r = max(r, CW_Furniture.HalfSize((class<CW_Furniture>)(cls)));
		if (check && !Clear(p, r)) return null;
		let a = Actor.Spawn(cls, (p, def.bSPAWNCEILING ? CeilAt(p) - def.height : FloorAt(p)));
		if (!a) return null;
		a.angle = ang;
		let f = CW_Furniture(a);
		if (f) f.MakeBlockers();
		return a;
	}

	// somewhere in the cell: centre first, then the corners, then along the walls
	Actor PutInCell(Class<Actor> cls, int i, int j, double ang = 0)
	{
		Vector2 c = CellCenter(i, j);
		let def = GetDefaultByType(cls);
		double r = def.radius;
		if (cls is "CW_Furniture") r = max(r, CW_Furniture.HalfSize((class<CW_Furniture>)(cls)));
		double hx = colw[i] / 2 - r - 8, hy = rowh[j] / 2 - r - 8;
		if (hx < 0 || hy < 0) return null;
		static const double ox[] = { 0, -1, 1, -1, 1, 0, 0, -1, 1 };
		static const double oy[] = { 0, -1, -1, 1, 1, -1, 1, 0, 0 };
		for (int k = 0; k < 9; k++)
		{
			let a = Put(cls, c + (ox[k] * hx, oy[k] * hy), ang);
			if (a) return a;
		}
		return null;
	}

	// anywhere in the room
	Actor PutInRoom(Class<Actor> cls, int r, double ang = -1)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		if (!ci.Size()) return null;
		int s = Rand(0, ci.Size() - 1);
		for (int n = 0; n < ci.Size(); n++)
		{
			int k = (s + n) % ci.Size();
			let a = PutInCell(cls, ci[k], cj[k], ang < 0 ? Rand(0, 3) * 90 : ang);
			if (a) return a;
		}
		return null;
	}

	// against a closed wall of the cell (d: 0 east, 1 west, 2 north, 3 south), facing into the room
	static const int DX[] = { 1, -1, 0, 0 };
	static const int DY[] = { 0, 0, 1, -1 };
	bool SideClosed(int i, int j, int d)
	{
		int ni = i + DX[d], nj = j + DY[d];
		int r = At(i, j);
		if (!InGrid(ni, nj)) return true;
		int ei, ej; bool v;
		EdgeBetween(i, j, ni, nj, ei, ej, v);
		return At(ni, nj) != r && EdgeState(ei, ej, v) <= 0;
	}
	Actor PutWall(Class<Actor> cls, int i, int j, int d, double slide = 0)
	{
		if (!SideClosed(i, j, d)) return null;
		let def = GetDefaultByType(cls);
		double depth = def.radius;
		let fd = CW_Furniture(def);
		if (fd && fd.fDepth > 0) depth = fd.fDepth / 2;
		Vector2 c = CellCenter(i, j);
		Vector2 n = (DX[d], DY[d]);
		double half = (d < 2 ? colw[i] : rowh[j]) / 2;
		Vector2 p = c + n * (half - depth - 3) + (-n.y, n.x) * slide;
		return Put(cls, p, VectorAngle(-n.x, -n.y));
	}
	// along every closed wall of the room, spaced `gap` apart
	int LineWalls(Class<Actor> cls, int r, double gap, int maxN = 99)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		int n = 0;
		for (int k = 0; k < ci.Size() && n < maxN; k++)
			for (int d = 0; d < 4 && n < maxN; d++)
			{
				if (!SideClosed(ci[k], cj[k], d)) continue;
				double half = (d < 2 ? rowh[cj[k]] : colw[ci[k]]) / 2;
				for (double t = -half + gap / 2; t <= half - gap / 2 + 0.1 && n < maxN; t += gap)
					if (PutWall(cls, ci[k], cj[k], d, t)) n++;
			}
		return n;
	}
	// rows of pieces across the room (racks, pews, beds, stalls)
	int Rows(Class<Actor> cls, int r, double spacing, bool alongX, double ang, int maxN = 99)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		int n = 0;
		for (int k = 0; k < ci.Size() && n < maxN; k++)
		{
			Vector2 c = CellCenter(ci[k], cj[k]);
			double w = colw[ci[k]], h = rowh[cj[k]];
			double span = alongX ? h : w;
			for (double t = -span / 2 + spacing / 2; t < span / 2 && n < maxN; t += spacing)
			{
				Vector2 p = alongX ? c + (0, t) : c + (t, 0);
				if (Put(cls, p, ang)) n++;
			}
		}
		return n;
	}

	// NBC: one class per fixture style (each has its own model in MODELDEF.txt)
	void Lamp(int i, int j, int style = 0, bool unlit = false)
	{
		static const String LAMPS[] = { "NBC_CeilingLight", "NBC_CeilingLightPendant", "NBC_CeilingLightStrip", "NBC_CeilingLightDown" };
		let l = NBC_CeilingLight(Put(LAMPS[clamp(style, 0, 3)], CellCenter(i, j), 0, false));
		if (l) l.unlit = unlit;
	}
	// every other cell of an indoor room gets a fixture (small rooms get one)
	void LightRoom(int r, int style = 0)
	{
		if (r < 0 || IsOut(r)) return;
		Array<int> ci, cj; CellsOf(r, ci, cj);
		bool dark = Has(r, RF_DARK);
		int placed = 0;
		for (int k = 0; k < ci.Size(); k++)
			if (ci.Size() <= 2 || (ci[k] + cj[k]) % 2 == 0) { Lamp(ci[k], cj[k], style, dark); placed++; }
		if (!placed && ci.Size()) Lamp(ci[0], cj[0], style, dark);
	}
	// an outdoor light on a pole (the pole is a prop; the light is what the guards see you by)
	void PoleLight(Vector2 p, int radius = 200, int r = 255, int g = 214, int b = 150)
	{
		if (!Put("CW_FLampPost", p, 0)) return;
		NBC_LightSource.Make((p, FloorAt(p) + 112), r, g, b, radius);
	}

	// ================================================================ people (NBC: spots, not guards)
	// a free point in the room for a spot (cell centres first)
	Vector2 rp;   // RoomPoint's answer (Vector2 out-parameters aren't safe in ZScript)
	bool RoomPoint(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		if (!ci.Size()) return false;
		int s = Rand(0, ci.Size() - 1);
		for (int n = 0; n < ci.Size(); n++)
		{
			int k = (s + n) % ci.Size();
			if (CellPoint(ci[k], cj[k])) return true;
		}
		return false;
	}
	// a free point in one cell (its centre, then a ring round it)
	bool CellPoint(int i, int j)
	{
		Vector2 c = CellCenter(i, j);
		for (int t = 0; t < 17; t++)
		{
			Vector2 q = c + (t ? Actor.AngleToVector(t * 45 + 22.5) * (t <= 8 ? 40 : 64) : (0, 0));
			if (Clear(q, 22)) { rp = q; return true; }
		}
		return false;
	}

	bool Safe(Vector2 p) { return (p - insertPos).Length() >= SAFE_R; }

	// Spawn spots for the raiding gang: one per walkable cell of every room the crew can reach (outdoor
	// cells are perches), away from the insertion. The RunManager decides how many it fills.
	void CollectSpots()
	{
		Array<int> depth;
		int home = At(CellI(insertPos.x), CellJ(insertPos.y));
		Reach(home, depth, false);
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				int r = At(i, j);
				if (r < 0 || depth[r] < 0 || Has(r, RF_NOGUARD | RF_WATER)) continue;
				if (!CellPoint(i, j) || !Safe(rp)) continue;
				spotX.Push(rp.x); spotY.Push(rp.y); spotRole.Push(IsOut(r) ? 1 : 0);
				// NBC: a second spot in the same cell when there's room, well apart from the first
				Vector2 first = rp, c = CellCenter(i, j);
				for (int t = 0; t < 8; t++)
				{
					Vector2 q = c + Actor.AngleToVector(t * 45 + 22.5) * 36;
					if ((q - first).Length() >= 48 && Clear(q, 20)) { spotX.Push(q.x); spotY.Push(q.y); spotRole.Push(IsOut(r) ? 1 : 0); break; }
				}
			}
	}

	double FaceNearestLink(Vector2 p)
	{
		double bd = 1e9; Vector2 best = MapCenter();
		for (int k = 0; k < lX.Size(); k++)
		{
			if (!Walkable(lKind[k])) continue;
			double d = (p - (lX[k], lY[k])).Length();
			if (d < bd) { bd = d; best = (lX[k], lY[k]); }
		}
		Vector2 v = best - p;
		return v.Length() > 1 ? VectorAngle(v.x, v.y) : 0;
	}

	// Residents (M9) stand at these markers; until then they're only marks for nbc_debug_kit.
	void PlaceResidents()
	{
		int want = Bystanders();
		Array<int> pool;
		for (int r = 0; r < rtype.Size(); r++) if (Has(r, RF_CIV) && CellCount(r)) pool.Push(r);
		if (!pool.Size()) return;
		for (int n = 0; n < want * 3 && civs < want; n++)
		{
			int r = pool[Rand(0, pool.Size() - 1)];
			if (!RoomPoint(r) || (rp - insertPos).Length() < 200) continue;
			if (Put("NBC_ResidentSpot", rp, Rand(0, 7) * 45, false)) civs++;
		}
	}

	// Rubble piles and loose debris for the quick-throw (§2.3) in derelict and outdoor rooms.
	void PlaceDebris()
	{
		static const String LOOSE[] = { "NBC_LooseBrick", "NBC_LooseBrick", "NBC_LooseHalfBrick", "NBC_LooseConcrete", "NBC_LooseBottle" };
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (!Has(r, RF_RUBBLE) || Has(r, RF_WATER) || !CellCount(r)) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 10)
				{
					// piles are solid: against a closed wall, so a corridor stays wide enough for the squad
					int d0 = Rand(0, 3);
					for (int d = 0; d < 4; d++)
						if (PutWall("NBC_RubblePile", ci[k], cj[k], (d0 + d) % 4, Rand(-30, 30))) { rubblePiles++; break; }
				}
				else if (roll < 32 && CellPoint(ci[k], cj[k]))
				{
					if (Put(LOOSE[Rand(0, LOOSE.Size() - 1)], rp, Rand(0, 7) * 45, false)) loosePieces++;
				}
			}
		}
	}

	// The exit is the entry the crew would least expect you to leave by: the farthest one from the insertion.
	void PickExit()
	{
		exitIdx = insertIdx;
		double best = -1;
		for (int e = 0; e < enX.Size(); e++)
		{
			if (e == insertIdx) continue;
			double d = ((enX[e], enY[e]) - insertPos).Length();
			if (d > best) { best = d; exitIdx = e; }
		}
		exitPos = (enX[exitIdx], enY[exitIdx]);
		let ex = Actor.Spawn("NBC_KitExit", (exitPos, FloorAt(exitPos)));
		if (ex) ex.angle = enA[exitIdx] + 180;
	}

	// ================================================================ objectives
	void PlanObjectives()
	{
		Array<int> depth;
		int home = At(CellI(insertPos.x), CellJ(insertPos.y));
		Reach(home, depth, true);
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int best = -1, bs = -1;
			for (int r = 0; r < rtype.Size(); r++)
			{
				if (depth[r] < 0 || !CellCount(r)) continue;
				int s = ObjScore(r, k);
				if (s <= 0) continue;
				s += depth[r] * 12 + Rand(0, 20);
				for (int q = OBJ_STEAL; q < k; q++) if (objRoom[q] == r) s -= 90;   // spread them out
				if (r == home) s -= 100;
				if (s > bs) { bs = s; best = r; }
			}
			objRoom[k] = best;
		}
	}
	// NBC: a marker in each planned room; the objectives themselves (M4, M9) read them
	void PlaceObjectives()
	{
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int r = objRoom[k];
			if (r < 0) continue;
			let a = PutInRoom("NBC_ObjectiveMarker", r, 0);
			if (a) a.args[0] = k;
			else if (developer) Console.Printf("\cgKit: objective %d has no room to stand in (%s)", k, rName[r]);
		}
	}

	// ================================================================ the pipeline
	void Generate(int seed, int vari)
	{
		rng = seed; seed0 = seed;
		variant = vari;
		for (int k = 0; k < 4; k++) objRoom[k] = -1;
		if (!doorTex.Length()) doorTex = "DOOR3";
		if (!jambTex.Length()) jambTex = "CWCONCW";
		if (!edgeTex.Length()) edgeTex = "BRICK7";
		if (!bandTex.Length()) { bandTex = "ADFCITY"; bandFloor = -768; }
		Layout();
		PickInsertion();
		int home = At(CellI(insertPos.x), CellJ(insertPos.y));
		EnsureConnected(home);
		{
			Array<int> depth;
			Reach(home, depth, true);
			for (int r = 0; r < rtype.Size(); r++)
				if (depth[r] < 0 && CellCount(r) && !Has(r, RF_WATER)) Console.Printf("\cgKit: %s is unreachable", rName[r]);
		}
		FenceOpenGround();
		Carve();
		CarveSolidTops();
		RaiseFacades();
		Paint();
		for (int r = 0; r < rtype.Size(); r++) if (CellCount(r)) { Dress(r); if (!IsOut(r)) LightRoom(r, LampStyle(r)); }
		Outdoors();
		PickExit();
		PlanObjectives();
		PlaceObjectives();
		PlaceDebris();
		CollectSpots();
		PlaceResidents();
		if (developer) Console.Printf("\cfKit %s (%s): seed %d, %d rooms, %d links, %d doors, %d spawn spots, %d resident spots, %d rubble piles, %d loose pieces, in: %s, out: %s",
			MapOfKit(kit), VariantName(), seed, rtype.Size(), lI.Size(), doors.Size(), spotX.Size(), civs, rubblePiles, loosePieces, insertName, enName[exitIdx]);
	}
	virtual int LampStyle(int r) { return 0; }

	void Insert(PlayerPawn pm)
	{
		if (!pm) return;
		pm.SetOrigin((insertPos, FloorAt(insertPos)), false);
		pm.angle = insertAng;
		pm.vel = (0, 0, 0);
	}

	// one line per room and entry, for nbc_debug_kit
	void Describe()
	{
		Console.Printf("Kit %s, %s, seed %d. In by %s, out by %s.", MapOfKit(kit), VariantName(), seed0, insertName, enName[exitIdx]);
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (!CellCount(r)) continue;
			String tags = "";
			if (IsOut(r)) tags = tags .. " out";
			if (Has(r, RF_CIV)) tags = tags .. " civ";
			if (Has(r, RF_RUBBLE)) tags = tags .. " rubble";
			for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (objRoom[k] == r) tags = tags .. String.Format(" objective%d", k);
			Console.Printf("  room %d: %s (%d cells)%s", r, rName[r], CellCount(r), tags);
		}
		for (int e = 0; e < enX.Size(); e++)
			Console.Printf("  entry %d: %s%s%s", e, enName[e], e == insertIdx ? "  [in]" : "", e == exitIdx ? "  [exit]" : "");
		int perches = 0;
		for (int k = 0; k < spotRole.Size(); k++) if (spotRole[k] == 1) perches++;
		Console.Printf("  %d spawn spots (%d perches), %d resident spots, %d rubble piles, %d loose pieces", spotX.Size(), perches, civs, rubblePiles, loosePieces);
	}
}
