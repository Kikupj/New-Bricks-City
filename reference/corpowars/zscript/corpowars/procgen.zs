// =============================================================================
// Corpo Wars — runtime procedural site generator (proof of concept)
//
// Works on a blank modular grid map (G01, built by genmap.build_grid): every
// wall strip between cells starts closed; we carve rooms, open doorways, theme
// each room (textures / light) and dress it with a prefab routine (props, NPCs,
// patrols, objectives). Deterministic per seed, so a contract always rebuilds
// the same site and savegames stay consistent.
// =============================================================================
class CW_ProcGen play
{
	// ---- grid constants: keep in sync with genmap.build_grid (GRID_COLW / GRID_ROWH)
	const NX = 10;
	const NY = 9;
	const WALL = 16;
	static const int COLW[] = { 240, 240, 240, 240, 112, 240, 240, 240, 240, 240 };
	static const int ROWH[] = { 240, 240, 64, 240, 112, 240, 240, 64, 240 };
	const SPINE = 4;        // corridor row
	const BRANCH = 4;       // optional branch-corridor column (north block)
	const LANE_S = 2;       // service lane rows
	const LANE_N = 7;
	const SPEED = 255;
	const DOOR_H = 112;
	const ROOM_H = 128;
	const DUCT_H = 40;       // crawlspace ceiling: crouched player (28) fits, guards (56) don't
	const VENT_H = 32;       // vent opening height at floor level

	enum ERoom { RT_DOCK, RT_HALL, RT_OFFICE, RT_STORAGE, RT_SERVER, RT_EXEC, RT_LAB, RT_LOBBY, RT_BATH, RT_DUCT }

	int rng;
	int roomOf[90];          // NX * NY
	Array<int> rx0, ry0, rx1, ry1, rtype;
	Array<int> dI, dJ, dVert;            // doors: cell (i,j) and direction (1 = to i+1, 0 = to j+1)
	Array<double> doorX, doorY;          // world centres of doorways (for prop clearance)
	int guards;
	Array<int> vI, vJ, vVert;            // vents: crawl-height openings
	Array<double> ventX, ventY;

	// ---------------------------------------------------------------- RNG
	int Rand(int lo, int hi)
	{
		rng = rng * 1103515245 + 12345;
		int r = (rng >>> 16) & 0x7fff;
		return hi <= lo ? lo : lo + r % (hi - lo + 1);
	}

	// ---------------------------------------------------------------- geometry helpers
	static int VTag(int i, int j, int k) { return 1000 + (j * (NX - 1) + i) * 3 + k; }
	static int HTag(int i, int j, int k) { return 4000 + (j * NX + i) * 3 + k; }
	static int CTag(int i, int j) { return 7000 + j * NX + i; }
	int ColX(int i) { int x = 0; for (int k = 0; k < i; k++) x += COLW[k] + WALL; return x; }
	int RowY(int j) { int y = 0; for (int k = 0; k < j; k++) y += ROWH[k] + WALL; return y; }
	Vector2 CellCenter(int i, int j) { return (ColX(i) + COLW[i] / 2, RowY(j) + ROWH[j] / 2); }
	bool Big(int i, int j) { return COLW[i] >= 200 && ROWH[j] >= 200; }
	// edges longer than 96 are split side/door/side; short edges are one segment (k = 1)
	bool Split3(int len) { return len > 96; }

	void Raise(int tag, int h) { level.ExecuteSpecial(47 /* Ceiling_MoveToValue */, null, null, 0, tag, SPEED, h); }

	// Open the wall between (i,j) and its neighbour: full = whole strip, else just the door segment.
	void OpenEdge(int i, int j, bool vert, bool full, int h = -1)
	{
		if (h < 0) h = full ? ROOM_H : DOOR_H;
		int len = vert ? ROWH[j] : COLW[i];
		bool three = Split3(len);
		for (int k = (full && three) ? 0 : 1; k <= ((full && three) ? 2 : 1); k++)
			Raise(vert ? VTag(i, j, k) : HTag(i, j, k), h);
	}

	// Canonical wall edge between two neighbouring cells.
	bool EdgeBetween(int i1, int j1, int i2, int j2, out int ei, out int ej, out bool vert)
	{
		if (j1 == j2 && abs(i1 - i2) == 1) { ei = min(i1, i2); ej = j1; vert = true; return true; }
		if (i1 == i2 && abs(j1 - j2) == 1) { ei = i1; ej = min(j1, j2); vert = false; return true; }
		return false;
	}

	// Find a wall edge shared by rooms a and b (the middle-most one); returns its canonical edge.
	bool Adjacent(int a, int b, out int ei, out int ej, out bool vert)
	{
		static const int ddx[] = { 1, -1, 0, 0 };
		static const int ddy[] = { 0, 0, 1, -1 };
		int found = 0, pick = 0;
		for (int pass = 0; pass < 2; pass++)
		{
			int n = 0;
			for (int j = ry0[a]; j <= ry1[a]; j++)
				for (int i = rx0[a]; i <= rx1[a]; i++)
				{
					for (int d = 0; d < 4; d++)
					{
						int ni = i + ddx[d], nj = j + ddy[d];
						if (ni < 0 || nj < 0 || ni >= NX || nj >= NY || roomOf[nj * NX + ni] != b) continue;
						if (pass == 1 && n == pick) return EdgeBetween(i, j, ni, nj, ei, ej, vert);
						n++;
					}
				}
			if (n == 0) return false;
			found = n; pick = n / 2;
		}
		return false;
	}

	void AddDoor(int i, int j, bool vert)
	{
		dI.Push(i); dJ.Push(j); dVert.Push(vert ? 1 : 0);
		Vector2 c = CellCenter(i, j);
		if (vert) { doorX.Push(ColX(i) + COLW[i] + WALL / 2); doorY.Push(c.y); }
		else { doorX.Push(c.x); doorY.Push(RowY(j) + ROWH[j] + WALL / 2); }
	}

	void AddVent(int i, int j, bool vert)
	{
		vI.Push(i); vJ.Push(j); vVert.Push(vert ? 1 : 0);
		Vector2 c = CellCenter(i, j);
		if (vert) { ventX.Push(ColX(i) + COLW[i] + WALL / 2); ventY.Push(c.y); }
		else { ventX.Push(c.x); ventY.Push(RowY(j) + ROWH[j] + WALL / 2); }
	}

	int NewRoom(int x0, int y0, int x1, int y1, int t)
	{
		rx0.Push(x0); ry0.Push(y0); rx1.Push(x1); ry1.Push(y1); rtype.Push(t);
		int id = rx0.Size() - 1;
		for (int j = y0; j <= y1; j++) for (int i = x0; i <= x1; i++) roomOf[j * NX + i] = id;
		return id;
	}

	int Cells(int r) { return (rx1[r] - rx0[r] + 1) * (ry1[r] - ry0[r] + 1); }

	// ---------------------------------------------------------------- layout: office floor plan
	// Corridor spine across the floor (+ optional branch north). Rooms are slices 1-3 columns wide
	// running from the corridor to the outer wall; some split into a front room + back room (suite).
	// The south block may carry a service duct along its lane under a run of back rooms.

	// Slice columns [c0..c1] into widths of 1-3 and call back with each span.
	void SliceCols(int c0, int c1, int r0, int r1, int t, bool suites, int laneRow)
	{
		int c = c0;
		while (c <= c1)
		{
			int w = min(Rand(1, 3), c1 - c + 1);
			if (suites && r1 - r0 >= 2 && Rand(0, 99) < 40)
			{
				// front room next to the corridor, back room against the outer wall (lane goes to the back)
				bool south = r1 < SPINE;
				int fr0 = south ? laneRow + 1 : r0, fr1 = south ? r1 : laneRow - 1;
				int br0 = south ? r0 : laneRow, br1 = south ? laneRow : r1;
				NewRoom(c, fr0, c + w - 1, fr1, t);
				NewRoom(c, br0, c + w - 1, br1, t);
			}
			else NewRoom(c, r0, c + w - 1, r1, t);
			c += w;
		}
	}

	int ductRoom, ductA, ductB, execRoom, bathRoom;
	Array<int> halls;

	bool IsHall(int r) { return halls.Find(r) != halls.Size(); }

	void Layout()
	{
		for (int k = 0; k < NX * NY; k++) roomOf[k] = -1;
		ductRoom = execRoom = bathRoom = -1;

		// corridors
		halls.Push(NewRoom(0, SPINE, NX - 1, SPINE, RT_HALL));
		bool hasBranch = Rand(0, 99) < 70;
		if (hasBranch) halls.Push(NewRoom(BRANCH, SPINE + 1, BRANCH, NY - 1, RT_HALL));

		// insertion dock: SW corner, full south depth
		NewRoom(0, 0, 1, SPINE - 1, RT_DOCK);

		// south block (cols 2..9, rows 0..3), optionally with a service duct under a run of back rooms
		bool duct = Rand(0, 99) < 75;
		if (duct)
		{
			ductA = Rand(3, 5);
			ductB = min(ductA + Rand(2, 3), NX - 2);
			// front rooms: row 3 only
			SliceCols(2, NX - 1, LANE_S + 1, SPINE - 1, RT_OFFICE, false, LANE_S);
			// back rooms: outside the duct run they include the lane, above it they don't
			SliceCols(2, ductA - 1, 0, LANE_S, RT_OFFICE, false, LANE_S);
			execRoom = NewRoom(ductA, 0, ductB, LANE_S - 1, RT_EXEC);
			SliceCols(ductB + 1, NX - 1, 0, LANE_S, RT_OFFICE, false, LANE_S);
			ductRoom = NewRoom(ductA, LANE_S, ductB, LANE_S, RT_DUCT);
			// washroom: the front room under one end of the duct
			int bi = Rand(0, 1) ? ductA : ductB;
			bathRoom = roomOf[(LANE_S + 1) * NX + bi];
			rtype[bathRoom] = RT_BATH;
			// vents: duct -> exec (middle of the run), duct -> washroom
			int mid = (ductA + ductB) / 2;
			AddVent(mid, LANE_S - 1, false);   // edge between (mid, lane-1) and (mid, lane)
			AddVent(bi, LANE_S, false);        // edge between (bi, lane) and (bi, lane+1)
		}
		else SliceCols(2, NX - 1, 0, SPINE - 1, RT_OFFICE, true, LANE_S);

		// north block (rows 5..8), split by the hasBranch corridor if present
		if (hasBranch)
		{
			SliceCols(0, BRANCH - 1, SPINE + 1, NY - 1, RT_OFFICE, true, LANE_N);
			SliceCols(BRANCH + 1, NX - 1, SPINE + 1, NY - 1, RT_OFFICE, true, LANE_N);
		}
		else SliceCols(0, NX - 1, SPINE + 1, NY - 1, RT_OFFICE, true, LANE_N);

		AssignTypes();
		Connect();
	}

	void AssignTypes()
	{
		Array<int> pool;
		for (int r = 0; r < rx0.Size(); r++)
			if (rtype[r] == RT_OFFICE) pool.Push(r);
		static const int wanted[] = { RT_EXEC, RT_SERVER, RT_LAB, RT_STORAGE, RT_LOBBY };
		for (int w = 0; w < 5 && pool.Size() > 0; w++)
		{
			if (wanted[w] == RT_EXEC && execRoom >= 0) continue;
			int best = 0, bestScore = -100000;
			for (int k = 0; k < pool.Size(); k++)
			{
				int r = pool[k];
				int score = (rx0[r] + rx1[r]) * 4 + Rand(0, 12);
				if (wanted[w] == RT_LOBBY || wanted[w] == RT_STORAGE) score = 60 - score;   // near the entry
				if (Cells(r) < 2 && wanted[w] != RT_STORAGE) score -= 40;
				if (score > bestScore) { bestScore = score; best = k; }
			}
			rtype[pool[best]] = wanted[w];
			if (wanted[w] == RT_EXEC) execRoom = pool[best];
			pool.Delete(best);
		}
	}

	// Every room gets a door onto a corridor if it touches one, otherwise into a connected neighbour.
	// Exec suites and ducts never serve as pass-through rooms.
	void Connect()
	{
		// spine <-> branch: fully open
		if (halls.Size() > 1)
		{
			OpenEdge(BRANCH, SPINE, false, true);
		}
		Array<bool> linked;
		for (int r = 0; r < rx0.Size(); r++) linked.Push(IsHall(r) || rtype[r] == RT_DUCT);
		int ci, cj; bool vert;
		for (int r = 0; r < rx0.Size(); r++)
		{
			if (linked[r]) continue;
			for (int h = 0; h < halls.Size(); h++)
				if (Adjacent(r, halls[h], ci, cj, vert)) { AddDoor(ci, cj, vert); linked[r] = true; break; }
		}
		for (int pass = 0; pass < 10; pass++)
			for (int r = 0; r < rx0.Size(); r++)
			{
				if (linked[r]) continue;
				for (int o = 0; o < rx0.Size(); o++)
					if (linked[o] && !IsHall(o) && rtype[o] != RT_EXEC && rtype[o] != RT_DUCT && Adjacent(r, o, ci, cj, vert))
					{ AddDoor(ci, cj, vert); linked[r] = true; break; }
			}
		// occasional adjoining door between side-by-side rooms in the same band
		for (int r = 0; r < rx0.Size(); r++)
			for (int o = r + 1; o < rx0.Size(); o++)
			{
				if (IsHall(r) || IsHall(o)) continue;
				if (rtype[r] == RT_EXEC || rtype[o] == RT_EXEC || rtype[r] == RT_DUCT || rtype[o] == RT_DUCT) continue;
				if (ry0[r] != ry0[o] || ry1[r] != ry1[o]) continue;
				if (Rand(0, 99) < 8 && Adjacent(r, o, ci, cj, vert)) AddDoor(ci, cj, vert);
			}
	}

	// ---------------------------------------------------------------- carve + theme
	void Carve()
	{
		for (int j = 0; j < NY; j++)
			for (int i = 0; i < NX; i++)
			{
				int r = roomOf[j * NX + i];
				bool isDuct = rtype[r] == RT_DUCT;
				if (isDuct) Raise(CTag(i, j), DUCT_H);
				if (i + 1 < NX && roomOf[j * NX + i + 1] == r) OpenEdge(i, j, true, true, isDuct ? DUCT_H : ROOM_H);
				if (j + 1 < NY && roomOf[(j + 1) * NX + i] == r) OpenEdge(i, j, false, true, isDuct ? DUCT_H : ROOM_H);
			}
		for (int d = 0; d < dI.Size(); d++) OpenEdge(dI[d], dJ[d], dVert[d] == 1, false);
		for (int v = 0; v < vI.Size(); v++) OpenEdge(vI[v], vJ[v], vVert[v] == 1, false, VENT_H);
	}

	void Theme(int r)
	{
		String wallTex = "STARGR1", flr = "FLAT5_4", ceil = "CEIL1_1";
		int light = 150;
		switch (rtype[r])
		{
		case RT_DOCK:    wallTex = "STARG3";   flr = "FLOOR4_8"; ceil = "CEIL3_5"; light = 96;  break;
		case RT_HALL:    light = 144; break;
		case RT_OFFICE:  light = 160; break;
		case RT_STORAGE: wallTex = "BROWN1";   flr = "FLOOR4_8"; ceil = "CEIL3_5"; light = 44;  break;
		case RT_SERVER:  wallTex = "COMPTALL"; light = 104; break;
		case RT_EXEC:    wallTex = "WOOD1";    light = 118; break;
		case RT_LAB:     wallTex = "STARTAN2"; light = 140; break;
		case RT_LOBBY:   wallTex = "STARGR1";  light = 176; break;
		case RT_BATH:    wallTex = "GRAY7";    flr = "FLOOR0_3"; light = 150; break;
		case RT_DUCT:    wallTex = "METAL";    flr = "FLAT23";   ceil = "FLAT23"; light = 24; break;
		}
		TextureID tw = TexMan.CheckForTexture(wallTex, TexMan.Type_Any);
		TextureID tf = TexMan.CheckForTexture(flr, TexMan.Type_Any);
		TextureID tc = TexMan.CheckForTexture(ceil, TexMan.Type_Any);
		for (int j = ry0[r]; j <= ry1[r]; j++)
			for (int i = rx0[r]; i <= rx1[r]; i++)
			{
				Sector sec = level.PointInSector(CellCenter(i, j));
				sec.SetTexture(Sector.floor, tf);
				sec.SetTexture(Sector.ceiling, tc);
				sec.SetLightLevel(light);
				for (int l = 0; l < sec.lines.Size(); l++)
				{
					Line ln = sec.lines[l];
					for (int s = 0; s < 2; s++)
					{
						Side sd = ln.sidedef[s];
						if (sd && sd.sector == sec)
						{
							// two-sided edges (into wallTex strips / doorways) only get upper/lower textures:
							// a mid texture there would draw a fake wallTex across an open passage
							sd.SetTexture(Side.top, tw);
							sd.SetTexture(Side.bottom, tw);
							if (!ln.sidedef[1]) sd.SetTexture(Side.mid, tw);
						}
						// the far side of an opened strip picks up the room light too
						else if (sd && sd.sector) sd.sector.SetLightLevel(max(sd.sector.lightlevel, light));
					}
				}
			}
	}

	void ThemeVents()
	{
		TextureID tm = TexMan.CheckForTexture("METAL", TexMan.Type_Any);
		for (int v = 0; v < vI.Size(); v++)
		{
			Sector sec = level.PointInSector((ventX[v], ventY[v]));
			for (int l = 0; l < sec.lines.Size(); l++)
			{
				Line ln = sec.lines[l];
				if (ln.sidedef[1]) continue;              // only the solid jambs of the vent opening
				if (ln.sidedef[0] && ln.sidedef[0].sector == sec) ln.sidedef[0].SetTexture(Side.mid, tm);
			}
		}
	}

	// ---------------------------------------------------------------- dressing helpers
	bool Clear(Vector2 p, double r)
	{
		for (int d = 0; d < doorX.Size(); d++)
			if ((p - (doorX[d], doorY[d])).Length() < 96 + r) return false;
		for (int d = 0; d < ventX.Size(); d++)
			if ((p - (ventX[d], ventY[d])).Length() < 72 + r) return false;
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, r + 48, false);
		while (it.Next()) if (it.thing.bSOLID && (it.thing.pos.xy - p).Length() < it.thing.radius + r + 4) return false;
		return true;
	}

	Actor Put(Class<Actor> cls, Vector2 p, double ang = 0, bool check = true)
	{
		let def = GetDefaultByType(cls);
		if (check && !Clear(p, def.radius)) return null;
		let a = Actor.Spawn(cls, (p, def.bSPAWNCEILING ? ROOM_H - def.height : 0));
		if (a) a.angle = ang;
		return a;
	}

	// Try the cell's centre, then its corners, until something fits.
	Actor PutInCell(Class<Actor> cls, int i, int j, double ang = 0)
	{
		if (!Big(i, j)) return null;   // corridors / service lanes stay clear
		Vector2 c = CellCenter(i, j);
		static const double ox[] = { 0, -70, 70, -70, 70, 0, 0, -70, 70 };
		static const double oy[] = { 0, -70, -70, 70, 70, -70, 70, 0, 0 };
		for (int k = 0; k < 9; k++)
		{
			let a = Put(cls, c + (ox[k], oy[k]), ang);
			if (a) return a;
		}
		return null;
	}

	void Patrol(Array<double> px, Array<double> py, int wait)
	{
		if (px.Size() < 2) return;
		Array<int> tids;
		for (int k = 0; k < px.Size(); k++) tids.Push(level.FindUniqueTid());
		for (int k = 0; k < px.Size(); k++)
		{
			let pp = Actor.Spawn("CW_PatrolPoint", (px[k], py[k], 0));
			pp.ChangeTid(tids[k]);
			pp.args[0] = tids[(k + 1) % tids.Size()];
			pp.args[1] = wait;
		}
		let g = CW_Guard(Actor.Spawn(guards == 0 ? "CW_SecuritySupervisor" : "CW_Guard", (px[0], py[0], 0)));
		if (g) { g.args[0] = tids[1]; guards++; }
	}

	void Post(int i, int j, double ang)
	{
		let g = PutInCell(guards == 0 ? "CW_SecuritySupervisor" : "CW_Guard", i, j, ang);
		if (g) guards++;
	}

	// ---------------------------------------------------------------- prefab dressers
	void Dress(int r)
	{
		int x0 = rx0[r], y0 = ry0[r], x1 = rx1[r], y1 = ry1[r];
		int mi = (x0 + x1) / 2, mj = (y0 + y1) / 2;
		Vector2 c0 = CellCenter(x0, y0), c1 = CellCenter(x1, y1);
		Array<double> px, py;
		switch (rtype[r])
		{
		case RT_DOCK:
			Put("CW_Extraction", CellCenter(0, 0) + (0, -60), 0, false);
			PutInCell("CW_TransportAccess", 1, 0);
			PutInCell("CW_CrateStack", 1, y1);
			PutInCell("CW_CrateBig", 0, y1);
			break;
		case RT_HALL:
			if (y0 == y1)   // spine
			{
				for (int i = x0 + 1; i <= x1; i += 3) Put("CW_CeilingLight", CellCenter(i, y0), 0, false);
				// patrol the far half so nobody is waiting outside the insertion dock
				Vector2 mid = CellCenter(NX / 2 + 1, y0);
				px.Push(mid.x); py.Push(mid.y); px.Push(c1.x - 40); py.Push(c1.y);
				Patrol(px, py, 70);
			}
			else            // branch
			{
				Put("CW_CeilingLight", CellCenter(x0, (y0 + y1) / 2), 0, false);
				if (Rand(0, 99) < 60) { px.Push(c0.x); py.Push(c0.y); px.Push(c1.x); py.Push(c1.y - 40); Patrol(px, py, 70); }
			}
			break;
		case RT_OFFICE:
			for (int j = y0; j <= y1; j++)
				for (int i = x0; i <= x1; i++)
				{
					if (!Big(i, j)) continue;
					PutInCell((i + j) % 2 ? "CW_DeskRound" : "CW_DeskTarget", i, j);
					if (Rand(0, 99) < 35) PutInCell("CW_Civilian", i, j, Rand(0, 3) * 90);
				}
			Put("CW_CeilingLight", CellCenter(mi, mj), 0, false);
			if (Cells(r) >= 3) { px.Push(c0.x); py.Push(c0.y); px.Push(c1.x); py.Push(c1.y); Patrol(px, py, 50); }
			break;
		case RT_STORAGE:
			for (int j = y0; j <= y1; j++)
				for (int i = x0; i <= x1; i++)
					PutInCell(Rand(0, 1) ? "CW_CrateStack" : "CW_Shelf", i, j);
			if (Cells(r) >= 2) { px.Push(c0.x); py.Push(c0.y); px.Push(c1.x); py.Push(c1.y); Patrol(px, py, 90); }
			break;
		case RT_SERVER:
			Put("CW_CeilingLight", CellCenter(mi, mj) + (0, 60), 0, false);
			PutInCell("CW_Server", mi, mj);
			for (int j = y0; j <= y1; j++)
				for (int i = x0; i <= x1; i++)
				{
					if (!Big(i, j)) continue;
					Put("CW_ServerRack", CellCenter(i, j) + (-80, 70), 0);
					Put("CW_ServerRack", CellCenter(i, j) + (80, 70), 0);
					Put("CW_ServerRack", CellCenter(i, j) + (-80, -70), 0);
				}
			Post(x1, y1, 180);
			break;
		case RT_EXEC:
			PutInCell("CW_DeskTarget", x1, y1);
			PutInCell("CW_FileCabinet", x0, y1);
			PutInCell("CW_Prototype", x1, y0);
			Put("CW_CeilingLight", CellCenter(mi, mj), 0, false);
			Post(x0, y0, 0);
			break;
		case RT_LAB:
			PutInCell("CW_Workbench", mi, y1);
			PutInCell("CW_MapTable", mi, mj);
			PutInCell("CW_Scientist", x1, mj, 180);
			PutInCell("CW_Civilian", x0, y0, 90);
			Put("CW_CeilingLight", CellCenter(mi, mj), 0, false);
			if (Cells(r) >= 2) { px.Push(c0.x); py.Push(c0.y); px.Push(c1.x); py.Push(c1.y); Patrol(px, py, 60); }
			else Post(x0, y0, 90);
			break;
		case RT_BATH:
			Put("CW_CeilingLight", CellCenter(mi, mj), 0, false);
			if (Rand(0, 99) < 40) PutInCell("CW_Civilian", mi, mj, Rand(0, 3) * 90);
			break;
		case RT_DUCT:
			break;
		case RT_LOBBY:
			PutInCell("CW_DeskTarget", mi, y1);
			PutInCell("CW_Civilian", mi, mj, 270);
			Put("CW_CeilingLight", CellCenter(mi, mj), 0, false);
			Post(x1, y0, 180);
			break;
		}
	}

	// ---------------------------------------------------------------- entry point
	void Generate(int seed)
	{
		rng = seed;
		Layout();
		Carve();
		for (int r = 0; r < rx0.Size(); r++) Theme(r);
		ThemeVents();
		for (int r = 0; r < rx0.Size(); r++) Dress(r);
		Console.Printf("\cfSite generated: seed %d, %d rooms, %d doors, %d vents, %d guards", seed, rx0.Size(), dI.Size(), vI.Size(), guards);
	}
}
