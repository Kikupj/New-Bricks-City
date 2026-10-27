// =============================================================================
// Corpo Wars — office floor generator (G02): centre-core "racetrack" floor plate
//
// One floor of a commercial tower, not the whole building. Grid (11 x 11), ring by ring:
//   depth 0  perimeter offices (corner execs)        176
//   depth 1  open-plan aisle ring                     144
//   depth 2  interior band: conference, pantry, lab,  176
//            server, storage, IT, janitor + crawl duct
//   depth 3  racetrack corridor around the core       128
//   depth 4+ service core 3x3: elevator lobby, passenger + freight elevator,
//            two remote stairwells, restrooms          160
// The floor role (ground / typical / top) decides which entry points exist; the
// mission inserts at a random one and extracts at the farthest other one.
// Keep SZ in sync with genmap.G02_SIZES.
// =============================================================================
class CW_FloorGen play
{
	const GN = 11;   // grid is GN x GN
	const WALL = 16;
	static const int SZ[] = { 176, 144, 176, 128, 160, 160, 160, 128, 176, 144, 176 };   // roomier interior band and core (playtest)
	static const int SDX[] = { 1, -1, 0, 0 };    // cell sides: 0 east, 1 west, 2 north, 3 south
	static const int SDY[] = { 0, 0, 1, -1 };
	const SPEED = 255;
	const DOOR_H = 80;       // Doom-scale doorway (Doom's own doors are 72)
	const ROOM_H = 100;
	const DUCT_H = 40;
	const VENT_H = 32;
	const SAFE_R = 520;      // no guards this close to the insertion point

	enum EFloorRole { FR_GROUND, FR_TYPICAL, FR_TOP }
	enum EFloorRoom
	{
		FT_HALL, FT_OPEN, FT_OFFICE, FT_EXEC, FT_CONF, FT_PANTRY, FT_STORAGE, FT_SERVER, FT_LAB,
		FT_IT, FT_JANITOR, FT_DUCT, FT_BATH, FT_STAIR, FT_ELEV, FT_FREIGHT, FT_CORELOBBY, FT_RECEPTION
	}
	enum EEntry { EN_ELEV, EN_FREIGHT, EN_STAIR_A, EN_STAIR_B, EN_RECEPTION, EN_ROOF }

	int rng, role, guards;
	// city layer (SetupSite): the property's guard force / tech level, neutral-site rules, this visit's entry
	int siteForce, siteTech, visitSeed, entryPref;
	bool neutralSite, siteSet;
	int roomOf[121];
	Array<int> rtype;
	Array<int> dI, dJ, dVert, dFull, dSec;   // dSec: 1 = maglocked (secured) door
	Array<int> vI, vJ, vVert;
	Array<double> doorX, doorY, ventX, ventY;   // ventX/ventY: read by the handler for the duct prompt
	Array<int> enKind, enI, enJ;
	int insertIdx, extractIdx;
	Vector2 insertPos;
	double insertAng;
	String insertName, extractName;
	int coreRot;
	int seed0;
	Array<int> rDark;   // 1 = the lights are off in this room (after hours): the stealth player's friend

	// ---------------------------------------------------------------- RNG
	int Rand(int lo, int hi)
	{
		rng = rng * 1103515245 + 12345;
		int r = (rng >>> 16) & 0x7fff;
		return hi <= lo ? lo : lo + r % (hi - lo + 1);
	}

	// ---------------------------------------------------------------- geometry
	static int VTag(int i, int j, int k) { return 1000 + (j * (GN - 1) + i) * 3 + k; }
	static int HTag(int i, int j, int k) { return 4000 + (j * GN + i) * 3 + k; }
	static int CTag(int i, int j) { return 7000 + j * GN + i; }
	static int ChTag(int i, int j) { return 8000 + j * GN + i; }   // 64u crawl channel inside interior-band cells
	static int PanTag(int i, int j) { return 9000 + j * GN + i; }  // 16u tread ring inside the outer ring
	static int InTag(int i, int j) { return 10000 + j * GN + i; }  // centre panel inside the tread ring
	const PANEL = 20;        // outer ring width (genmap.build_floor PANEL)
	const TREAD = 16;        // tread ring width (genmap.build_floor TREAD)

	// interior-band cells are split into outer bands + a channel instead of ring + panel
	static bool IsChannel(int i, int j)
	{
		int d = min(min(i, j), min(GN - 1 - i, GN - 1 - j));
		if (d != 2) return false;
		if ((j == 2 || j == GN - 3) && i >= 3 && i <= GN - 4) return true;
		if ((i == 2 || i == GN - 3) && j >= 3 && j <= GN - 4) return true;
		return false;
	}

	// Planes are set instantly (no movers): the level is built before anything moves, and movers ran into
	// ordering trouble (a floor raised in the same tic as its ceiling was clamped by the still-closed ceiling).
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
			sec.MoveFloor(abs(dz) + 1, sec.floorplane.PointToDist(sec.centerspot, h), -1, dz > 0 ? 1 : -1, false);   // dest is a plane distance
		}
	}
	int Pos(int i) { int x = 0; for (int k = 0; k < i; k++) x += SZ[k] + WALL; return x; }
	Vector2 CellCenter(int i, int j) { return (Pos(i) + SZ[i] / 2, Pos(j) + SZ[j] / 2); }
	Vector2 FloorCenter() { return CellCenter(GN / 2, GN / 2); }
	int Depth(int i, int j) { return min(min(i, j), min(GN - 1 - i, GN - 1 - j)); }
	int RoomAt(int i, int j) { return roomOf[j * GN + i]; }
	void Claim(int r, int i, int j) { roomOf[j * GN + i] = r; }
	int NewRoom(int t) { rtype.Push(t); return rtype.Size() - 1; }

	void Raise(int tag, int h) { CeilTo(tag, h); }

	// every G02 edge is > 96 long, so every strip is side / 64 door / side
	void OpenEdge(int i, int j, bool vert, bool full, int h = -1)
	{
		if (h < 0) h = full ? ROOM_H : DOOR_H;
		for (int k = full ? 0 : 1; k <= (full ? 2 : 1); k++)
			Raise(vert ? VTag(i, j, k) : HTag(i, j, k), h);
	}

	bool EdgeBetween(int i1, int j1, int i2, int j2, out int ei, out int ej, out bool vert)
	{
		if (j1 == j2 && abs(i1 - i2) == 1) { ei = min(i1, i2); ej = j1; vert = true; return true; }
		if (i1 == i2 && abs(j1 - j2) == 1) { ei = i1; ej = min(j1, j2); vert = false; return true; }
		return false;
	}

	Vector2 EdgeCenter(int ei, int ej, bool vert)
	{
		Vector2 c = CellCenter(ei, ej);
		if (vert) return (Pos(ei) + SZ[ei] + WALL / 2, c.y);
		return (c.x, Pos(ej) + SZ[ej] + WALL / 2);
	}

	void Link(int i1, int j1, int i2, int j2, bool full = false)
	{
		int ei, ej; bool vert;
		if (!EdgeBetween(i1, j1, i2, j2, ei, ej, vert)) return;
		dI.Push(ei); dJ.Push(ej); dVert.Push(vert ? 1 : 0); dFull.Push(full ? 1 : 0); dSec.Push(0);
		Vector2 p = EdgeCenter(ei, ej, vert);
		doorX.Push(p.x); doorY.Push(p.y);
	}

	void Vent(int i1, int j1, int i2, int j2)
	{
		int ei, ej; bool vert;
		if (!EdgeBetween(i1, j1, i2, j2, ei, ej, vert)) return;
		vI.Push(ei); vJ.Push(ej); vVert.Push(vert ? 1 : 0);
		Vector2 p = EdgeCenter(ei, ej, vert);
		ventX.Push(p.x); ventY.Push(p.y);
	}

	// Side s (0 = south, 1 = east, 2 = north, 3 = west) walked counter-clockwise; t along it, dd = ring depth.
	void SideCell(int s, int t, int dd, out int i, out int j)
	{
		switch (s)
		{
		case 0:  i = t;             j = dd;            break;
		case 1:  i = GN - 1 - dd;    j = t;             break;
		case 2:  i = GN - 1 - t;     j = GN - 1 - dd;    break;
		default: i = dd;            j = GN - 1 - t;     break;
		}
	}

	// Core cell (a, b) in 0..2, rotated by coreRot.
	void CoreCell(int a, int b, out int i, out int j)
	{
		switch (coreRot)
		{
		case 0:  i = 4 + a; j = 4 + b; break;
		case 1:  i = 4 + b; j = 6 - a; break;
		case 2:  i = 6 - a; j = 6 - b; break;
		default: i = 6 - b; j = 4 + a; break;
		}
	}

	// A corridor-ring neighbour of (i, j), if any.
	bool HallNeighbor(int i, int j, out int hi, out int hj)
	{
		static const int ddx[] = { 1, -1, 0, 0 };
		static const int ddy[] = { 0, 0, 1, -1 };
		for (int d = 0; d < 4; d++)
		{
			int ni = i + ddx[d], nj = j + ddy[d];
			if (ni < 0 || nj < 0 || ni >= GN || nj >= GN) continue;
			if (Depth(ni, nj) == 3) { hi = ni; hj = nj; return true; }
		}
		return false;
	}

	void LinkHall(int i, int j, bool full = false)
	{
		int hi, hj;
		if (HallNeighbor(i, j, hi, hj)) Link(i, j, hi, hj, full);
	}

	void AddEntry(int kind, int i, int j) { enKind.Push(kind); enI.Push(i); enJ.Push(j); }

	// ---------------------------------------------------------------- layout
	void Layout()
	{
		for (int k = 0; k < GN * GN; k++) roomOf[k] = -1;
		pitI = pitJ = -1;

		// racetrack corridor
		int hall = NewRoom(FT_HALL);
		for (int j = 0; j < GN; j++) for (int i = 0; i < GN; i++) if (Depth(i, j) == 3) Claim(hall, i, j);

		PlanCore();
		PlanPerimeter();
		PlanInterior();

		// everything left in rings 1-2 is one open-plan floor; its inner-band cells open onto the corridor
		int open = NewRoom(FT_OPEN);
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
			{
				if (RoomAt(i, j) >= 0) continue;
				Claim(open, i, j);
				if (Depth(i, j) == 2) LinkHall(i, j, true);
			}
	}

	// exit sign over the stairwell door (the door LinkHall just added), hung on the corridor side
	Array<double> stairDoorX, stairDoorY, stairDoorA;
	void MarkStairDoor(int i, int j)
	{
		int last = doorX.Size() - 1;
		if (last < 0) return;
		Vector2 dp = (doorX[last], doorY[last]);
		Vector2 away = (dp - CellCenter(i, j)).Unit();
		Vector2 at = dp + away * 12;
		stairDoorX.Push(at.x); stairDoorY.Push(at.y); stairDoorA.Push(VectorAngle(-away.x, -away.y));
	}

	void PlanCore()
	{
		static const int CORE[] = {
			FT_STAIR, FT_ELEV,      FT_BATH,
			FT_CORELOBBY, FT_CORELOBBY, FT_CORELOBBY,
			FT_BATH,  FT_FREIGHT,   FT_STAIR };
		coreRot = Rand(0, 3);
		int lobby = NewRoom(FT_CORELOBBY);
		int ci, cj;
		for (int b = 0; b < 3; b++)
			for (int a = 0; a < 3; a++)
			{
				CoreCell(a, b, ci, cj);
				int t = CORE[b * 3 + a];
				if (t == FT_CORELOBBY) { Claim(lobby, ci, cj); continue; }
				Claim(NewRoom(t), ci, cj);
			}
		// lobby runs straight through the core, open to the corridor at both ends
		CoreCell(0, 1, ci, cj); LinkHall(ci, cj, true);
		CoreCell(2, 1, ci, cj); LinkHall(ci, cj, true);
		int li, lj; CoreCell(1, 1, li, lj);
		// passenger elevator opens into the lobby; freight, stairs and restrooms open onto the corridor
		CoreCell(1, 0, ci, cj); Link(ci, cj, li, lj); AddEntry(EN_ELEV, ci, cj);
		CoreCell(1, 2, ci, cj); LinkHall(ci, cj); AddEntry(EN_FREIGHT, ci, cj);
		CoreCell(0, 0, ci, cj); LinkHall(ci, cj); AddEntry(EN_STAIR_A, ci, cj); MarkStairDoor(ci, cj); stairI[0] = ci; stairJ[0] = cj;
		CoreCell(2, 2, ci, cj); LinkHall(ci, cj); AddEntry(role == FR_TOP ? EN_ROOF : EN_STAIR_B, ci, cj); MarkStairDoor(ci, cj); stairI[1] = ci; stairJ[1] = cj;
		CoreCell(2, 0, ci, cj); LinkHall(ci, cj);
		CoreCell(0, 2, ci, cj); LinkHall(ci, cj);
	}

	void PlanPerimeter()
	{
		int i, j, i2, j2;
		// street lobby with reception on the ground floor (south facade)
		if (role == FR_GROUND)
		{
			int rec = NewRoom(FT_RECEPTION);
			for (int t = 4; t <= 6; t++) { SideCell(0, t, 0, i, j); Claim(rec, i, j); }
			SideCell(0, 5, 0, i, j); SideCell(0, 5, 1, i2, j2); Link(i, j, i2, j2, true);
			pitI = i; pitJ = j;   // sunken seating pit in the middle of the lobby
			AddEntry(EN_RECEPTION, i, j);
		}
		// corner executive offices: corner cell + one neighbour, door from the neighbour into the aisle
		for (int c = 0; c < 4; c++)
		{
			int r = NewRoom(FT_EXEC);
			SideCell(c, 0, 0, i, j); Claim(r, i, j);
			int s = c, t = 1;
			if (Rand(0, 1)) { s = (c + 3) % 4; t = GN - 2; }
			SideCell(s, t, 0, i, j);
			if (RoomAt(i, j) >= 0) { s = c; t = 1; SideCell(s, t, 0, i, j); }
			Claim(r, i, j);
			SideCell(s, t, 1, i2, j2); Link(i, j, i2, j2);
		}
		// private offices along each facade: 1-3 cells wide, with the odd open lounge alcove left for the open plan
		for (int s = 0; s < 4; s++)
		{
			int t = 1;
			while (t <= GN - 2)
			{
				SideCell(s, t, 0, i, j);
				if (RoomAt(i, j) >= 0) { t++; continue; }
				if (Rand(0, 99) < 12) { t++; continue; }   // lounge alcove: stays open to the aisle
				int roll = Rand(0, 99);
				int w = roll < 35 ? 1 : roll < 75 ? 2 : 3;
				w = FitRun(s, t, 0, w, GN - 2, -1);
				int r = NewRoom(FT_OFFICE);
				for (int k = 0; k < w; k++) { SideCell(s, t + k, 0, i2, j2); Claim(r, i2, j2); }
				int dt = t + Rand(0, w - 1);
				SideCell(s, dt, 0, i, j); SideCell(s, dt, 1, i2, j2); Link(i, j, i2, j2);
				t += w;
			}
		}
	}

	// Longest run <= w of free cells along side s from t (ring dd), stopping at tmax / the reserved cell.
	int FitRun(int s, int t, int dd, int w, int tmax, int reserved)
	{
		int n = 0, i, j;
		while (n < w)
		{
			int tt = t + n;
			if (tt > tmax || tt == reserved) break;
			SideCell(s, tt, dd, i, j);
			if (RoomAt(i, j) >= 0) break;
			n++;
		}
		return max(n, 1);
	}

	void PlanInterior()
	{
		// support rooms in the inner band (ring 2, t = 3..7 on each side), each opening onto the corridor
		static const int POOLT[] = { FT_LAB, FT_CONF, FT_PANTRY, FT_CONF, FT_STORAGE, FT_IT, FT_CONF, FT_STORAGE };
		static const int POOLW[] = { 2,      2,       1,         2,       1,          1,     2,       1 };
		int pi = 0, i, j, i2, j2;
		int chainSide = Rand(0, 3);
		for (int s = 0; s < 4; s++)
		{
			int openT = s == chainSide ? 3 : Rand(3, 7);   // every side keeps a way from the corridor to the open plan
			if (s == chainSide)
			{
				// janitor closet -> crawl duct -> server room
				int ja, jb, da, db, sa, sb;
				SideCell(s, 5, 2, ja, jb); SideCell(s, 6, 2, da, db); SideCell(s, 7, 2, sa, sb);
				Claim(NewRoom(FT_JANITOR), ja, jb);
				Claim(NewRoom(FT_DUCT), da, db);
				Claim(NewRoom(FT_SERVER), sa, sb);
				LinkHall(ja, jb);
				LinkHall(sa, sb);
				Vent(ja, jb, da, db);
				Vent(da, db, sa, sb);
			}
			int t = 3;
			while (t <= 7)
			{
				SideCell(s, t, 2, i, j);
				if (t == openT || RoomAt(i, j) >= 0 || (pi > 0 && Rand(0, 99) < 25)) { t++; continue; }
				int typ = POOLT[pi % 8], w = POOLW[pi % 8];
				pi++;
				if (typ == FT_CONF) w = Rand(2, 3);          // meeting room .. boardroom (no 1-cell huddle rooms: too cramped)
				else if (typ == FT_LAB) w = Rand(2, 3);
				w = FitRun(s, t, 2, w, 7, openT);
				int r = NewRoom(typ);
				for (int k = 0; k < w; k++) { SideCell(s, t + k, 2, i2, j2); Claim(r, i2, j2); }
				LinkHall(i, j);
				if (typ == FT_CONF && Rand(0, 1)) { SideCell(s, t, 1, i2, j2); Link(i, j, i2, j2); }
				t += w;
			}
		}
	}

	// ---------------------------------------------------------------- entry points
	void PickEntries()
	{
		insertIdx = Rand(0, enKind.Size() - 1);
		// a property keeps its layout between visits; where you come in changes every time (or you choose it)
		if (visitSeed) insertIdx = CW_Building.Mix(visitSeed, 31) % enKind.Size();
		if (entryPref >= 2)
		{
			for (int e = 0; e < enKind.Size(); e++)
			{
				int k = enKind[e];
				bool ok = (entryPref == 2 && k == EN_RECEPTION) || (entryPref == 3 && (k == EN_STAIR_A || k == EN_STAIR_B))
					|| (entryPref == 4 && (k == EN_ELEV || k == EN_FREIGHT)) || (entryPref == 5 && k == EN_ROOF);
				if (ok) { insertIdx = e; break; }
			}
		}
		Vector2 a = CellCenter(enI[insertIdx], enJ[insertIdx]);
		double best = -1;
		extractIdx = insertIdx;
		for (int e = 0; e < enKind.Size(); e++)
		{
			if (e == insertIdx) continue;
			double d = (CellCenter(enI[e], enJ[e]) - a).Length() + Rand(0, 200);
			if (d > best) { best = d; extractIdx = e; }
		}
		insertPos = a;
		Vector2 toCentre = FloorCenter() - a;
		int k = enKind[insertIdx];
		// elevators and the street lobby face into the floor; stairwells face out to the corridor
		bool inward = k == EN_ELEV || k == EN_RECEPTION;
		insertAng = inward ? VectorAngle(toCentre.x, toCentre.y) : VectorAngle(-toCentre.x, -toCentre.y);
		insertAng = floor((insertAng + 45) / 90) * 90;
		insertName = EntryName(enKind[insertIdx]);
		extractName = "any exit (elevator, stairwell, lobby)";
	}

	static String EntryName(int k)
	{
		switch (k)
		{
		case EN_ELEV:      return "the passenger elevator";
		case EN_FREIGHT:   return "the freight elevator";
		case EN_STAIR_A:   return "stairwell A";
		case EN_STAIR_B:   return "stairwell B";
		case EN_RECEPTION: return "the street lobby";
		case EN_ROOF:      return "the roof access stair";
		}
		return "the site";
	}

	static String RoleName(int r)
	{
		if (r == FR_GROUND) return "ground floor";
		if (r == FR_TOP) return "top floor";
		return "office floor";
	}

	// ---------------------------------------------------------------- carve + theme
	// per-room heights (absolute): floor, ring ceiling, panel ceiling, panel floor offset
	Array<int> rF, rRing, rPanel, rPanelDF;
	int pitI, pitJ;

	void PlanHeights()
	{
		for (int r = 0; r < rtype.Size(); r++)
		{
			Style(rtype[r]);
			rF.Push(sFloor); rRing.Push(sRing); rPanel.Push(sPanel); rPanelDF.Push(sPanelDF);
		}
	}

	// zone inside a cell: 0 outer ring, 1 tread ring, 2 centre panel (channel cells: 0 outer bands, 2 channel)
	int CellFloor(int i, int j, int zone)
	{
		int r = RoomAt(i, j);
		int f = rF[r];
		if (zone == 0 || IsChannel(i, j)) return f;
		int df = rPanelDF[r];
		if (rtype[r] == FT_RECEPTION && !(i == pitI && j == pitJ)) df = 0;
		return zone == 1 ? f + df / 2 : f + df;
	}

	int CellCeil(int i, int j, int zone)
	{
		int r = RoomAt(i, j);
		if (zone == 0) return rRing[r];
		if (zone == 2 || IsChannel(i, j)) return rPanel[r];
		return (rRing[r] + rPanel[r]) / 8 * 4;   // tread: halfway, on a 4u grid
	}

	// Door and opening strips: floor halfway between the two rooms (a step each side), top no higher than either room.
	void OpenBetween(int i1, int j1, int i2, int j2, bool full, int h = -1)
	{
		int ei, ej; bool vert;
		if (!EdgeBetween(i1, j1, i2, j2, ei, ej, vert)) return;
		int a = RoomAt(i1, j1), b = RoomAt(i2, j2);
		int fl = (rF[a] + rF[b]) / 2;
		int top = min(rRing[a], rRing[b]);
		if (!full) top = min(top, fl + DOOR_H);   // doorway height measured from its own (stepped) floor
		if (h >= 0) top = h;
		for (int k = full ? 0 : 1; k <= (full ? 2 : 1); k++)
		{
			int tag = vert ? VTag(ei, ej, k) : HTag(ei, ej, k);
			Raise(tag, top);          // ceiling first: a floor can't rise through a closed strip
			FloorTo(tag, fl);
		}
	}

	void Carve()
	{
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
			{
				int r = RoomAt(i, j);
				if (rtype[r] == FT_DUCT)
				{
					Raise(CTag(i, j), 0); Raise(ChTag(i, j), DUCT_H);   // close the outer bands, keep a narrow crawlway
					continue;
				}
				CeilTo(CTag(i, j), rRing[r]);
				FloorTo(CTag(i, j), rF[r]);
				if (IsChannel(i, j))
				{
					CeilTo(ChTag(i, j), rPanel[r]); FloorTo(ChTag(i, j), rF[r]);
				}
				else
				{
					CeilTo(PanTag(i, j), CellCeil(i, j, 1)); FloorTo(PanTag(i, j), CellFloor(i, j, 1));
					CeilTo(InTag(i, j), CellCeil(i, j, 2)); FloorTo(InTag(i, j), CellFloor(i, j, 2));
				}
				if (i + 1 < GN && RoomAt(i + 1, j) == r) OpenBetween(i, j, i + 1, j, true);
				if (j + 1 < GN && RoomAt(i, j + 1) == r) OpenBetween(i, j, i, j + 1, true);
			}
		for (int d = 0; d < dI.Size(); d++)
		{
			int i1 = dI[d], j1 = dJ[d];
			int i2 = dVert[d] ? i1 + 1 : i1, j2 = dVert[d] ? j1 : j1 + 1;
			OpenBetween(i1, j1, i2, j2, dFull[d] == 1);
			if (!dFull[d]) MakeDoor(d, i1, j1, i2, j2);
		}
		for (int v = 0; v < vI.Size(); v++) OpenEdge(vI[v], vJ[v], vVert[v] == 1, false, VENT_H);
	}

	// Functional door: the strip starts open (so the nav graph can see through it); a CW_Door actor
	// shuts it once the level is running and handles opening for guards / auto-closing.
	void MakeDoor(int d, int i1, int j1, int i2, int j2)
	{
		int a = RoomAt(i1, j1), b = RoomAt(i2, j2);
		int tag = dVert[d] ? VTag(dI[d], dJ[d], 1) : HTag(dI[d], dJ[d], 1);
		let dr = CW_Door(Actor.Spawn("CW_Door", ((doorX[d], doorY[d]), 0)));
		if (!dr) return;
		dr.doorTag = tag;
		dr.secured = dSec[d] == 1;
		dr.doorIdx = d;
		if (dr.secured) secDoors.Push(dr);
		doorActors.Push(dr);
		dr.shutZ = (rF[a] + rF[b]) / 2;
		dr.openZ = min(min(rRing[a], rRing[b]), dr.shutZ + DOOR_H);
		// 3D casing: wood for offices / suites / meeting rooms, brushed steel elsewhere
		int ta = rtype[a], tb = rtype[b];
		bool wood = ta == FT_OFFICE || tb == FT_OFFICE || ta == FT_EXEC || tb == FT_EXEC || ta == FT_CONF || tb == FT_CONF;
		let fr = Actor.Spawn(wood ? "CW_FDoorFrameW" : "CW_FDoorFrame", ((doorX[d], doorY[d]), dr.shutZ));
		if (fr) fr.angle = dVert[d] ? 0 : 90;
		if (dr.secured)
		{
			// keypad on each face, beside the latch-side jamb
			Vector2 n = dVert[d] ? (1, 0) : (0, 1), along = (-n.y, n.x);
			for (int f = -1; f <= 1; f += 2)
			{
				Vector2 kp = (doorX[d], doorY[d]) + n * (f * (WALL / 2 + 1)) + along * 44;
				let pad = Actor.Spawn("CW_Keypad", (kp, dr.shutZ));
				if (pad) { pad.angle = VectorAngle(n.x * f, n.y * f); dr.pads.Push(pad); }
			}
		}
	}

	TextureID Tex(String name, String fallback)
	{
		TextureID t = TexMan.CheckForTexture(name, TexMan.Type_Any);
		if (!t.IsValid()) t = TexMan.CheckForTexture(fallback, TexMan.Type_Any);
		return t;
	}

	// Room style: wall (upper textures facing closed strips), floor, ring + panel ceilings, trim between them,
	// light, and heights. (results go in fields: ZScript out-parameters don't support strings reliably)
	String wallTex, flr, ceil, panelTex, trimTex;
	int light, sFloor, sRing, sPanel, sPanelDF;
	int themeIdx;
	Array<String> ts;   // the theme's texture slots (CW_Themes.ESlot)
	String T(int slot) { return ts[slot]; }
	void Style(int t)
	{
		wallTex = T(CW_Themes.TS_WALL); flr = T(CW_Themes.TS_CARP); ceil = T(CW_Themes.TS_CEIL); panelTex = T(CW_Themes.TS_PANEL);
		trimTex = T(CW_Themes.TS_TRIM); light = 160;
		sFloor = 0; sRing = 100; sPanel = 108; sPanelDF = 0;
		switch (t)
		{
		case FT_HALL:      wallTex = T(CW_Themes.TS_HALLW); panelTex = T(CW_Themes.TS_PANELF); light = 104; sRing = 96; sPanel = 104; break;
		case FT_OPEN:      light = 128; sRing = 96; break;
		case FT_OFFICE:    flr = T(CW_Themes.TS_CARP2); panelTex = T(CW_Themes.TS_PANELC); light = 120; break;
		case FT_EXEC:      wallTex = T(CW_Themes.TS_EXECW); flr = T(CW_Themes.TS_EXECF); panelTex = T(CW_Themes.TS_PANELR); light = 100; sRing = 104; sPanel = 136; break;
		case FT_CONF:      wallTex = T(CW_Themes.TS_CONFW); flr = T(CW_Themes.TS_CARP2); panelTex = T(CW_Themes.TS_PANELC); light = 112; sPanel = 120; break;
		case FT_PANTRY:    wallTex = T(CW_Themes.TS_WETW); flr = T(CW_Themes.TS_TILEF); light = 132; break;
		case FT_STORAGE:   wallTex = T(CW_Themes.TS_SERVW); flr = T(CW_Themes.TS_SERVF); ceil = T(CW_Themes.TS_CEILD); panelTex = "CWDUCT"; trimTex = "CWDUCT"; light = 60; sRing = 104; sPanel = 88; break;
		case FT_SERVER:    wallTex = T(CW_Themes.TS_TECHW); flr = T(CW_Themes.TS_GRATEF); ceil = "CWDUCT"; panelTex = T(CW_Themes.TS_CEILD); trimTex = "CWDUCT"; light = 72; sRing = 96; sPanel = 112; break;
		case FT_LAB:       wallTex = T(CW_Themes.TS_LABW); flr = T(CW_Themes.TS_TILEF); panelTex = T(CW_Themes.TS_PANELF); light = 140; sPanel = 120; break;
		case FT_IT:        wallTex = T(CW_Themes.TS_TECHW2); flr = T(CW_Themes.TS_GRATEF); ceil = "CWDUCT"; panelTex = T(CW_Themes.TS_CEILD); trimTex = "CWDUCT"; light = 80; sRing = 96; sPanel = 112; break;
		case FT_JANITOR:   wallTex = T(CW_Themes.TS_SERVW); flr = T(CW_Themes.TS_SERVF); ceil = T(CW_Themes.TS_CEILD); panelTex = "CWDUCT"; trimTex = "CWDUCT"; light = 60; sRing = 104; sPanel = 88; break;
		case FT_DUCT:      wallTex = "METAL";   flr = "FLAT23";  ceil = "FLAT23"; panelTex = "FLAT23"; trimTex = "METAL"; light = 40; sRing = 0; sPanel = DUCT_H; break;
		case FT_BATH:      wallTex = T(CW_Themes.TS_LABW); flr = T(CW_Themes.TS_TILEF); panelTex = T(CW_Themes.TS_PANELR); light = 128; break;
		case FT_STAIR:     wallTex = T(CW_Themes.TS_STAIRW); flr = "CWSTAIF"; ceil = T(CW_Themes.TS_CEILD); panelTex = T(CW_Themes.TS_CEILD); trimTex = T(CW_Themes.TS_STAIRW); light = 72; sRing = 112; sPanel = 120; break;
		case FT_ELEV:      wallTex = T(CW_Themes.TS_METALW); flr = T(CW_Themes.TS_LOBBYF); panelTex = T(CW_Themes.TS_PANELC); light = 144; break;
		case FT_FREIGHT:   wallTex = T(CW_Themes.TS_FREIGHTW); flr = T(CW_Themes.TS_GRATEF); ceil = T(CW_Themes.TS_CEILD); panelTex = "CWDUCT"; trimTex = "CWDUCT"; light = 92; sRing = 112; sPanel = 104; break;
		case FT_CORELOBBY: wallTex = T(CW_Themes.TS_LOBBYW); flr = T(CW_Themes.TS_LOBBYF); ceil = T(CW_Themes.TS_CEILD); panelTex = T(CW_Themes.TS_PANELC); light = 136; sRing = 104; sPanel = 136; break;
		case FT_RECEPTION: wallTex = T(CW_Themes.TS_LOBBYW); flr = T(CW_Themes.TS_RECEPF); ceil = T(CW_Themes.TS_CEILD); panelTex = T(CW_Themes.TS_PANELR); light = 144; sRing = 112; sPanel = 176; sPanelDF = -16; break;
		}
	}

	// All sectors making up cell (i, j): interior-band cells are three (outer / channel / outer).
	void CellSectors(int i, int j, Array<Sector> secs)
	{
		secs.Clear();
		Vector2 c = CellCenter(i, j);
		double qx = SZ[i] / 2 - 8, qy = SZ[j] / 2 - 8;
		static const double ins[] = { 8, PANEL + 8, 1000 };
		for (int q = -1; q <= 1; q += 2)
			for (int k = 0; k < 3; k++)
			{
				double ox = max(SZ[i] / 2 - ins[k], 0), oy = max(SZ[j] / 2 - ins[k], 0);
				Sector found = level.PointInSector(c + (q * ox, q * oy));
				if (secs.Find(found) == secs.Size()) secs.Push(found);
			}
	}

	int CellIdx(double v)
	{
		for (int k = 0; k < GN; k++) if (v >= Pos(k) && v < Pos(k) + SZ[k]) return k;
		return -1;
	}

	void Theme(int r)
	{
		Style(rtype[r]);
		TextureID tw = Tex(wallTex, "STARGR1");
		TextureID tf = Tex(flr, "FLAT5_4");
		TextureID tc = Tex(ceil, "CEIL1_1");
		TextureID tp = Tex(panelTex, "CEIL1_1");
		TextureID ttrim = Tex(trimTex, "STARGR1");
		TextureID tstep = Tex(T(CW_Themes.TS_STEP), "STARGR1");
		// posts and door jambs: brushed-metal cladding (bare concrete in the service spaces)
		int rt = rtype[r];
		bool service = rt == FT_STORAGE || rt == FT_JANITOR || rt == FT_STAIR || rt == FT_FREIGHT || rt == FT_DUCT;
		TextureID tpost = Tex(service ? T(CW_Themes.TS_SERVW) : T(CW_Themes.TS_POST), "STARGR1");
		TextureID trug = Tex(T(CW_Themes.TS_RUG), "FLAT5_4");
		bool dark = rDark[r] != 0;
		Color tint = RoomTint(rt);
		// Reflective floors only in the lobbies and elevator halls: every reflective sector is a mirror portal for
		// the renderer, and hundreds of them on screen (a polished-concrete theme reflects every office) crashed
		// some GPUs mid-mission. cw_floorreflect 0 turns them off entirely.
		bool showcase = rt == FT_CORELOBBY || rt == FT_RECEPTION || rt == FT_ELEV;
		double gloss = (showcase && CVar.FindCVar("cw_floorreflect").GetBool()) ? CW_Themes.Gloss(flr) : 0;
		Array<Sector> secs;
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
			{
				if (RoomAt(i, j) != r) continue;
				CellSectors(i, j, secs);
				bool win = false;
				for (int d = 0; d < 4; d++) if (SideKind(i, j, d) == SK_FACADE) win = true;
				for (int q = 0; q < secs.Size(); q++)
				{
					Sector sec = secs[q];
					// the cell's centre (panel or channel) gets the feature ceiling; the ring keeps the plain one
					bool centre = secs.Size() > 1 && sec == level.PointInSector(CellCenter(i, j));
					sec.SetTexture(Sector.floor, (centre && rt == FT_EXEC) ? trug : tf);   // area rug in the executive suites
					sec.SetTexture(Sector.ceiling, centre ? tp : tc);
					// light pools: the wall ring sits a little darker than the middle of the room (also good shadow to hide in)
					bool ring = !IsChannel(i, j) && secs.Size() > 1 && sec == level.PointInSector(CellCenter(i, j) + (SZ[i] / 2 - 6, SZ[j] / 2 - 6));
					// dark rooms: moonlight through the windows, nothing else
					int lv = dark ? (win ? 60 : 44) : light - 16;
					sec.SetLightLevel(ring ? lv - (dark ? 8 : 24) : lv);
					sec.SetColor(dark ? (win ? Color(150, 172, 232) : Color(138, 150, 196)) : tint);
					if (gloss > 0) sec.SetPlaneReflectivity(Sector.floor, (centre || !dark) ? gloss : gloss * 0.6);
					for (int l = 0; l < sec.lines.Size(); l++)
					{
						Line ln = sec.lines[l];
						for (int s = 0; s < 2; s++)
						{
							Side sd = ln.sidedef[s];
							if (!sd) continue;
							if (sd.sector == sec)
							{
								Side far = ln.sidedef[1 - s];
								bool inner = far && secs.Find(far.sector) != secs.Size();   // ring <-> panel inside this cell
								sd.SetTexture(Side.top, inner ? ttrim : tw);
								sd.SetTexture(Side.bottom, inner ? tstep : tw);
								if (!ln.sidedef[1]) sd.SetTexture(Side.mid, tw);
							}
							else if (sd.sector && secs.Find(sd.sector) == secs.Size())
							{
								// the strip on the far side: pick up the light, and theme its end faces (the posts)
								Sector strip = sd.sector;
								strip.SetLightLevel(max(strip.lightlevel, light));
								for (int e = 0; e < strip.lines.Size(); e++)
								{
									Line sl = strip.lines[e];
									if (!sl.sidedef[1]) { sl.sidedef[0].SetTexture(Side.mid, tpost); continue; }
									// door jambs / strip faces seen through an opening
									for (int z = 0; z < 2; z++)
										if (sl.sidedef[z].sector == strip) { sl.sidedef[z].SetTexture(Side.top, tpost); sl.sidedef[z].SetTexture(Side.bottom, tpost); }
								}
							}
						}
					}
				}
			}
	}

	// Which opening, if any, the edge between two cells has: 0 closed, 1 door, 2 full, 3 vent.
	int EdgeState(int i1, int j1, int i2, int j2)
	{
		int ei, ej; bool vert;
		if (!EdgeBetween(i1, j1, i2, j2, ei, ej, vert)) return 0;
		int vv = vert ? 1 : 0;
		for (int d = 0; d < dI.Size(); d++) if (dI[d] == ei && dJ[d] == ej && dVert[d] == vv) return dFull[d] ? 2 : 1;
		for (int d = 0; d < vI.Size(); d++) if (vI[d] == ei && vJ[d] == ej && vVert[d] == vv) return 3;
		return 0;
	}

	String DoorTex(int a, int b)
	{
		if (a == FT_STAIR || b == FT_STAIR) return "CWDOORF";
		if (a == FT_ELEV || b == FT_ELEV || a == FT_FREIGHT || b == FT_FREIGHT) return "CWDOORE";
		if (a == FT_SERVER || b == FT_SERVER || a == FT_IT || b == FT_IT || a == FT_JANITOR || b == FT_JANITOR || a == FT_STORAGE || b == FT_STORAGE) return "CWDOORS";
		if (a == FT_EXEC || b == FT_EXEC) return "CWDOOR2";
		if (a == FT_BATH || b == FT_BATH || a == FT_LAB || b == FT_LAB) return "CWDOORT";
		return "CWDOOR1";
	}

	String Poster()
	{
		switch (Rand(0, 4))
		{
		case 0: return "CWPOST1";
		case 1: return "CWPOST2";
		case 2: return "CWPOST3";
		case 3: return "CWPOST4";
		}
		return "CWLOGO1";
	}

	bool IsType(int r, int t) { return r >= 0 && rtype[r] == t; }

	// Second pass over every 64u door-segment wall: door headers, elevator banks, wayfinding signs,
	// corporate posters. Uses the grid, not sector heights (the ceilings are still moving).
	void DecorWalls()
	{
		TextureID head = Tex("CWWALLH", "STARGR1");
		TextureID metal = Tex("METAL", "STARGR1");
		Array<Sector> secs;
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
			{
				int r = RoomAt(i, j);
				int tr = rtype[r];
				Vector2 c = CellCenter(i, j);
				CellSectors(i, j, secs);
				for (int q = 0; q < secs.Size(); q++)
				{
					Sector sec = secs[q];
					for (int l = 0; l < sec.lines.Size(); l++)
					{
						Line ln = sec.lines[l];
						if (!ln.sidedef[1] || abs(ln.delta.Length() - 64) > 1) continue;
						Side sd = ln.sidedef[0].sector == sec ? ln.sidedef[0] : ln.sidedef[1];
						Vector2 m = (ln.v1.p + ln.v2.p) / 2;
						Vector2 nrm = (ln.delta.y, -ln.delta.x).Unit();
						if ((m - c) dot nrm < 0) nrm = -nrm;
						Vector2 probe = m + nrm * (WALL + 24);
						int ni = CellIdx(probe.x), nj = CellIdx(probe.y);
						if (ni < 0 || nj < 0) continue;
						int o = RoomAt(ni, nj);
						if (o == r) continue;
						int st = EdgeState(i, j, ni, nj);
						if (st == 1)
						{
							sd.SetTexture(Side.top, Tex(DoorTex(tr, rtype[o]), "DOOR3"));
							// door textures are 64x128: a 48-row lintel over an 80-row door. Pin the painted door
							// to the doorway (floor .. floor+80) so it lines up with the 3D frame, whatever the
							// room's ceiling height; when the door is open the band above shows the lintel.
							// (lower-pegged upper texture: its bottom rides the door's own ceiling, so when shut the
							// painted door sits exactly floor .. floor+80 and slides up into the lintel when opened)
							ln.flags &= ~Line.ML_DONTPEGTOP;
							sd.SetTextureYOffset(Side.top, -8);   // the painted door is ~86 rows: tuck its top under the frame header
							continue;
						}
						if (st == 3) { sd.SetTexture(Side.top, metal); continue; }
						if (st != 0) continue;
						String pick = "";
						if (tr == FT_CORELOBBY && (IsType(o, FT_STAIR) || IsType(o, FT_BATH))) pick = "CWELEVD";
						else if (tr == FT_HALL)
						{
							if (IsType(o, FT_STAIR)) pick = "CWSGSTAI";
							else if (IsType(o, FT_BATH)) pick = "CWSGREST";
							else if (IsType(o, FT_ELEV)) pick = "CWSGELEV";
							else if (IsType(o, FT_JANITOR) || IsType(o, FT_IT) || IsType(o, FT_SERVER) || IsType(o, FT_STORAGE)) pick = Rand(0, 1) ? "CWSGSERV" : "";
							else if (Rand(0, 99) < 30) pick = Poster();
						}
						else if (tr == FT_OPEN && Rand(0, 99) < 30) pick = Poster();
						else if ((tr == FT_RECEPTION || tr == FT_CONF) && Rand(0, 99) < 60) pick = "CWLOGO2";
						else if (tr == FT_STAIR && Rand(0, 1)) pick = "";
						if (pick.Length()) sd.SetTexture(Side.top, Tex(pick, "STARGR1"));
					}
				}
			}
	}
	// Glass fronts: private offices and conference rooms get interior glazing (sill 32, head 84) on the
	// segments of their walls that face the aisle / corridor, executive suites get sidelights beside the door.
	// Glass blocks movement, bullets and projectiles but not sight: guards see into lit offices, and so do you.
	Array<int> gI, gJ, gD;    // glazed cell sides (both faces recorded)
	const SILL_H = 32;
	const HEAD_H = 84;

	bool IsGlass(int i, int j, int d)
	{
		for (int k = 0; k < gI.Size(); k++) if (gI[k] == i && gJ[k] == j && gD[k] == d) return true;
		return false;
	}

	void Glazing()
	{
		TextureID glass = Tex("CWGLASS", "MIDGRATE");
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
			{
				int r = RoomAt(i, j), t = rtype[r];
				if (t != FT_OFFICE && t != FT_CONF && t != FT_EXEC) continue;
				for (int d = 0; d < 4; d++)
				{
					int ni = i + SDX[d], nj = j + SDY[d];
					if (ni < 0 || nj < 0 || ni >= GN || nj >= GN) continue;
					int o = RoomAt(ni, nj);
					if (o == r || (rtype[o] != FT_OPEN && rtype[o] != FT_HALL)) continue;
					int st = EdgeState(i, j, ni, nj);
					if (st != 0 && st != 1) continue;
					if (t == FT_EXEC && st != 1) continue;           // execs: sidelights only
					int ei, ej; bool vert;
					EdgeBetween(i, j, ni, nj, ei, ej, vert);
					for (int k = 0; k <= 2; k++)
					{
						if (k == 1 && st == 1) continue;                // the door itself
						int tag = vert ? VTag(ei, ej, k) : HTag(ei, ej, k);
						CeilTo(tag, HEAD_H); FloorTo(tag, SILL_H);
						let it = level.CreateSectorTagIterator(tag);
						int si;
						while ((si = it.Next()) >= 0) GlazeStrip(level.sectors[si], glass, t);
					}
					gI.Push(i); gJ.Push(j); gD.Push(d);
					gI.Push(ni); gJ.Push(nj); gD.Push(Opp(d));
				}
			}
	}

	void GlazeStrip(Sector strip, TextureID glass, int roomType)
	{
		TextureID frame = Tex(T(CW_Themes.TS_POST), "STARGR1");
		bool done = false;
		for (int l = 0; l < strip.lines.Size(); l++)
		{
			Line ln = strip.lines[l];
			if (!ln.sidedef[1]) { ln.sidedef[0].SetTexture(Side.mid, frame); continue; }
			Sector a = ln.sidedef[0].sector, b = ln.sidedef[1].sector;
			Sector other = a == strip ? b : a;
			if (other.lightlevel == 0 && other.ceilingplane.ZAtPoint(other.centerspot) <= other.floorplane.ZAtPoint(other.centerspot)) continue;
			bool roomFace = ln.delta.Length() > 20;   // the long faces; short ones are joints to the next segment
			if (!roomFace) continue;
			for (int z = 0; z < 2; z++)
			{
				Side sd = ln.sidedef[z];
				if (sd.sector != strip)
				{
					// the room's own wall finish above and below the glass (clears any poster that was hung there)
					Vector2 cs = sd.sector.centerspot;
					int ci2 = CellIdx(cs.x), cj2 = CellIdx(cs.y);
					if (ci2 >= 0 && cj2 >= 0) Style(rtype[RoomAt(ci2, cj2)]);
					sd.SetTexture(Side.top, Tex(wallTex, "STARGR1")); sd.SetTexture(Side.bottom, Tex(wallTex, "STARGR1"));
				}
				else { sd.SetTexture(Side.top, frame); sd.SetTexture(Side.bottom, frame); }
			}
			if (!done)
			{
				// one glass pane per segment, on the first long face
				ln.sidedef[0].SetTexture(Side.mid, glass); ln.sidedef[1].SetTexture(Side.mid, glass);
				ln.alpha = 0.3;
				ln.flags |= Line.ML_BLOCKING | Line.ML_BLOCKPROJECTILE | Line.ML_BLOCKHITSCAN | Line.ML_WRAP_MIDTEX | Line.ML_BLOCKUSE;
				done = true;
			}
		}
		// the sill and head faces seen from inside the strip are part of the frame
		strip.SetTexture(Sector.floor, frame); strip.SetTexture(Sector.ceiling, frame);
	}

	// Openings read as part of the floor plan: a same-room joint takes the room's floor and ceiling, a wide
	// opening between rooms takes the corridor's finish, and a doorway gets an aluminium threshold and a
	// plain header soffit. (The generic strip finish left carpet seams through wood and marble rooms.)
	void ThemeStrips()
	{
		TextureID thres = Tex("CWTHRES", "FLAT23"), head = Tex("CWWALLH", "STARGR1");
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
				for (int d = 0; d < 2; d++)
				{
					int ni = i + (d == 0 ? 1 : 0), nj = j + (d == 1 ? 1 : 0);
					if (ni >= GN || nj >= GN) continue;
					int a = RoomAt(i, j), b = RoomAt(ni, nj);
					int st = a == b ? 2 : EdgeState(i, j, ni, nj);
					if (st != 1 && st != 2) continue;
					int src = a;
					if (a != b && (rtype[b] == FT_HALL || rtype[b] == FT_OPEN) && rtype[a] != FT_HALL) src = b;
					Style(rtype[src]);
					TextureID tf = Tex(flr, "FLAT5_4"), tc = Tex(ceil, "CEIL1_1");
					for (int k = 0; k <= 2; k++)
					{
						if (st == 1 && k != 1) continue;
						int tag = d == 0 ? VTag(i, j, k) : HTag(i, j, k);
						let it = level.CreateSectorTagIterator(tag);
						int si;
						while ((si = it.Next()) >= 0)
						{
							Sector sec = level.sectors[si];
							sec.SetTexture(Sector.floor, st == 1 ? thres : tf);
							sec.SetTexture(Sector.ceiling, st == 1 ? head : tc);
						}
					}
				}
	}

	void ThemeVents()
	{
		TextureID tm = Tex("METAL", "STARGR1");
		for (int v = 0; v < vI.Size(); v++)
		{
			Sector sec = level.PointInSector((ventX[v], ventY[v]));
			for (int l = 0; l < sec.lines.Size(); l++)
			{
				Line ln = sec.lines[l];
				if (ln.sidedef[1]) continue;
				if (ln.sidedef[0] && ln.sidedef[0].sector == sec) ln.sidedef[0].SetTexture(Side.mid, tm);
			}
		}
	}

	// ---------------------------------------------------------------- objectives: three ways in
	// Every objective room gets (1) a FRONT door that is maglocked - open it with a security pass, during Nyx's
	// blackout, by tailgating a guard, or force it (hold USE, loud); (2) a SIDE way in that costs something
	// else - the server room keeps its crawl duct from the janitor's closet, the other rooms get an unlocked
	// door through a neighbouring room (witnesses, a longer walk); (3) INFORMATION - a security pass lies in a
	// staff room elsewhere on the floor and one patrolling guard carries another (take him down, quietly or not).
	int objRoom[4];                  // room holding each objective kind (OBJ_STEAL / DESTROY / TURN), -1 = none
	int sideDoor[4];                 // door index of the side entry, -1 = duct / none
	bool entered[4];
	int lastDuctTic;
	Array<CW_Door> secDoors, doorActors;
	Vector2 passPos;

	static String RoomName(int t)
	{
		switch (t)
		{
		case FT_OFFICE: return "private office"; case FT_EXEC: return "executive suite"; case FT_CONF: return "conference room";
		case FT_PANTRY: return "pantry"; case FT_STORAGE: return "storage room"; case FT_SERVER: return "server room";
		case FT_LAB: return "lab"; case FT_IT: return "IT room"; case FT_JANITOR: return "janitor's closet";
		case FT_OPEN: return "open-plan floor"; case FT_RECEPTION: return "lobby"; case FT_HALL: return "corridor";
		case FT_DUCT: return "air duct";
		}
		return "room";
	}

	int RoomFarthest(int t, Vector2 from, int skip = -1)
	{
		int best = -1; double bd = -1;
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (rtype[r] != t || r == skip) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			double d = (CellCenter(ci[0], cj[0]) - from).Length();
			if (d > bd) { bd = d; best = r; }
		}
		return best;
	}

	// Room of type t maximising the distance to the nearest of: the insertion point and the rooms in 'taken'.
	int RoomSpread(int t, Array<int> taken)
	{
		int best = -1; double bd = -1;
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (rtype[r] != t || taken.Find(r) != taken.Size()) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			Vector2 p = CellCenter(ci[0], cj[0]);
			double d = (p - insertPos).Length();
			for (int k = 0; k < taken.Size(); k++)
			{
				Array<int> ti, tj; CellsOf(taken[k], ti, tj);
				d = min(d, (p - CellCenter(ti[0], tj[0])).Length() * 1.2);
			}
			if (d > bd) { bd = d; best = r; }
		}
		return best;
	}

	// Quadrants with no guard (and not the insertion quadrant) get a guard walking between the
	// quadrant's corridor corner and its open-plan corner, so the floor is covered all round.
	void BalanceGuards()
	{
		Vector2 fc = FloorCenter();
		int cnt[4];
		for (int q = 0; q < 4; q++) cnt[q] = 0;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next())) cnt[Quad(g.pos.xy, fc)]++;
		int added = 0;
		for (int c = 0; c < 4 && added < 2; c++)
		{
			int i3, j3, i1, j1;
			SideCell(c, 3, 3, i3, j3);     // corridor-ring corner of side c
			SideCell(c, 1, 1, i1, j1);     // aisle-ring corner
			Vector2 a = CellCenter(i3, j3), b = CellCenter(i1, j1);
			if (cnt[Quad(a, fc)] > 0) continue;
			if (!Safe(a)) { Vector2 t = a; a = b; b = t; }      // start at the open-plan end instead
			if (!Safe(a)) { Console.Printf("balance: side %d unsafe", c); continue; }
			Array<double> px, py;
			px.Push(a.x); py.Push(a.y); px.Push(b.x); py.Push(b.y);
			int before = guards;
			Patrol(px, py, 90);
			if (guards > before) { cnt[Quad(a, fc)]++; added++; }
			else Console.Printf("balance: side %d patrol failed at %.0f %.0f", c, a.x, a.y);
		}
		Console.Printf("\cfGuards by quadrant: %d %d %d %d", cnt[0], cnt[1], cnt[2], cnt[3]);
	}
	static int Quad(Vector2 p, Vector2 c) { return (p.x >= c.x ? 1 : 0) + (p.y >= c.y ? 2 : 0); }

	// The STEAL item isn't always in the corner executive suite: any room that plausibly holds something
	// worth taking, in the far part of the floor from the insertion point (weighted: suites most likely).
	int PickStealRoom()
	{
		double maxD = 0;
		Array<int> cand; Array<int> wt;
		for (int r = 0; r < rtype.Size(); r++)
		{
			Array<int> ci, cj; CellsOf(r, ci, cj);
			if (ci.Size()) maxD = max(maxD, (CellCenter(ci[0], cj[0]) - insertPos).Length());
		}
		int total = 0;
		for (int r = 0; r < rtype.Size(); r++)
		{
			int w;
			switch (rtype[r])
			{
			case FT_EXEC: w = 4; break;
			case FT_OFFICE: case FT_CONF: w = 3; break;
			case FT_STORAGE: case FT_IT: case FT_LAB: w = 2; break;
			default: w = 0;
			}
			if (!w) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			if ((CellCenter(ci[0], cj[0]) - insertPos).Length() < maxD * 0.55) continue;
			cand.Push(r); wt.Push(w); total += w;
		}
		if (!cand.Size()) return RoomFarthest(FT_EXEC, insertPos);
		int roll = Rand(0, total - 1);
		for (int k = 0; k < cand.Size(); k++) { roll -= wt[k]; if (roll < 0) return cand[k]; }
		return cand[0];
	}

	// The item in a room that isn't a suite (suites place it on the desk while dressing).
	void PlaceStealItem()
	{
		if (protoRoom < 0 || rtype[protoRoom] == FT_EXEC) return;
		Array<int> ci, cj; CellsOf(protoRoom, ci, cj);
		int start = Rand(0, ci.Size() - 1);
		for (int n = 0; n < ci.Size(); n++)
		{
			int k = (start + n) % ci.Size();
			if (PutInCell("CW_Prototype", ci[k], cj[k]) || PutCorner("CW_Prototype", ci[k], cj[k]))
			{
				if (Rand(0, 99) < 50) Post(ci[k], cj[k], -1);   // sometimes someone's watching it
				return;
			}
		}
	}

	// ---------------------------------------------------------------- city security profile
	// Guard force 6-16 / tech level 1-4 (city.zs). The layout's patrols and posts are the baseline for a
	// force of ~10; a smaller force stands some guards down (posts first, never the supervisor), a bigger one
	// adds posts in KeyPosts. Tech 4 guards see further; tech 1 guards see less.
	// guards on this floor for the site's force (6 -> 7 ... 16 -> 12); a multi-floor site spreads them out
	int SiteTarget()
	{
		int t = clamp(4 + siteForce * 55 / 100, 5, 12);
		if (floors > 1) t--;
		return t;
	}

	void ApplySecurity()
	{
		if (!siteSet) return;
		Array<CW_Guard> gs;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next())) gs.Push(g);
		int target = SiteTarget();
		int removed = 0;
		for (int pass = 0; pass < 2 && gs.Size() > target; pass++)
		{
			for (int i = gs.Size() - 1; i >= 0 && gs.Size() > target; i--)
			{
				let x = gs[i];
				if (x is "CW_SecuritySupervisor") continue;
				if (pass == 0 && x.args[0]) continue;           // posts go first, patrols only if still too many
				x.Destroy();
				gs.Delete(i);
				guards--; removed++;
			}
		}
		double sight = siteTech >= 4 ? 1.12 : (siteTech <= 1 ? 0.9 : 1.0);
		for (int i = 0; i < gs.Size(); i++) gs[i].sightRange *= sight;
		Console.Printf("\cfSite security: force %d, tech %d -> %d guards on this floor (%d stood down)%s", siteForce, siteTech, gs.Size(), removed, neutralSite ? ", neutral site" : "");
	}

	// One random guard on the floor is the security supervisor (longer sight), not always the first one placed.
	void PromoteSupervisor()
	{
		Array<CW_Guard> gs;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next())) gs.Push(g);
		if (!gs.Size()) return;
		let o = gs[Rand(0, gs.Size() - 1)];
		let sv = CW_Guard(Actor.Spawn("CW_SecuritySupervisor", o.pos));
		if (!sv) return;
		sv.angle = o.angle;
		for (int a = 0; a < 5; a++) sv.args[a] = o.args[a];
		o.Destroy();
	}

	void PlanObjectives()
	{
		for (int k = 0; k < 4; k++) { objRoom[k] = -1; sideDoor[k] = -1; entered[k] = false; }
		protoRoom = PickStealRoom();
		objRoom[OBJ_STEAL] = protoRoom;
		// the other objective rooms: far from the insertion point AND from each other, so the floor's
		// security (posts in objective rooms) isn't all piled on one side
		Array<int> taken; if (protoRoom >= 0) taken.Push(protoRoom);
		objRoom[OBJ_DESTROY] = RoomSpread(FT_SERVER, taken);
		if (objRoom[OBJ_DESTROY] >= 0) taken.Push(objRoom[OBJ_DESTROY]);
		int lab = RoomSpread(FT_LAB, taken);
		objRoom[OBJ_TURN] = lab >= 0 ? lab : RoomSpread(FT_OFFICE, taken);
		// multi-floor: only the objectives that live on this floor
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (!(objHere & (1 << k))) objRoom[k] = -1;
		protoRoom = objRoom[OBJ_STEAL];
	}

	bool IsObjRoom(int r) { return r >= 0 && (r == objRoom[OBJ_STEAL] || r == objRoom[OBJ_DESTROY] || r == objRoom[OBJ_TURN]); }

	void DoorRooms(int d, out int a, out int b)
	{
		int i1 = dI[d], j1 = dJ[d];
		int i2 = dVert[d] ? i1 + 1 : i1, j2 = dVert[d] ? j1 : j1 + 1;
		a = RoomAt(i1, j1); b = RoomAt(i2, j2);
	}

	void SecureObjectives()
	{
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int r = objRoom[k];
			if (r < 0) continue;
			// neutral sites (bars, hotels, union halls on the G02 fallback): ordinary locks, no maglocks
			if (neutralSite) { if (rtype[r] != FT_SERVER) sideDoor[k] = AddSideEntry(r); continue; }
			// front: every ordinary door into the room is maglocked
			for (int d = 0; d < dI.Size(); d++)
			{
				if (dFull[d]) continue;
				int a, b; DoorRooms(d, a, b);
				if ((a == r) != (b == r)) dSec[d] = 1;
			}
			// side: the server room already has its crawl duct; everything else gets a door through a neighbour
			if (rtype[r] != FT_SERVER) sideDoor[k] = AddSideEntry(r);
		}
	}

	// An unlocked door from the room into a neighbouring staff room (preferred) or the open plan.
	int AddSideEntry(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		int bestScore = 0, bi = -1, bj = -1, bni = -1, bnj = -1;
		for (int k = 0; k < ci.Size(); k++)
			for (int d = 0; d < 4; d++)
			{
				int i = ci[k], j = cj[k], ni = i + SDX[d], nj = j + SDY[d];
				if (ni < 0 || nj < 0 || ni >= GN || nj >= GN) continue;
				int o = RoomAt(ni, nj);
				if (o == r || IsObjRoom(o) || EdgeState(i, j, ni, nj) != 0) continue;
				int score;
				switch (rtype[o])
				{
				case FT_OFFICE: case FT_STORAGE: case FT_JANITOR: case FT_IT: case FT_PANTRY: score = 30; break;
				case FT_CONF: case FT_LAB: score = 20; break;
				case FT_OPEN: case FT_RECEPTION: score = Depth(ni, nj) == 1 ? 5 : 10; break;   // the aisle itself is barely a side way
				default: score = 0;
				}
				if (!score) continue;
				score += Rand(0, 4);
				if (score > bestScore) { bestScore = score; bi = i; bj = j; bni = ni; bnj = nj; }
			}
		if (bi < 0) return -1;
		Link(bi, bj, bni, bnj);
		return dI.Size() - 1;
	}

	String AccessSummary(int k)
	{
		int r = objRoom[k];
		int front = 0;
		for (int d = 0; d < dI.Size(); d++) if (dSec[d]) { int a, b; DoorRooms(d, a, b); if (a == r || b == r) front++; }
		String side = "air duct";
		if (sideDoor[k] >= 0)
		{
			int a, b; DoorRooms(sideDoor[k], a, b);
			side = "side door via the " .. RoomName(rtype[a == r ? b : a]);
		}
		else if (rtype[r] != FT_SERVER) side = "none";
		return String.Format("%d maglocked door(s), %s", front, side);
	}

	// Information route: a pass in a staff room away from the insertion point, and a guard who carries one.
	void PlaceSecurityPasses()
	{
		passPos = (0, 0);
		if (neutralSite) return;   // nothing to swipe at a neutral site
		int best = -1, bestScore = -1;
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (IsObjRoom(r)) continue;
			int score;
			switch (rtype[r])
			{
			case FT_IT: case FT_RECEPTION: score = 30; break;
			case FT_OFFICE: score = 20; break;
			case FT_PANTRY: case FT_CONF: score = 10; break;
			default: score = 0;
			}
			if (!score) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			if ((CellCenter(ci[0], cj[0]) - insertPos).Length() < 400) continue;
			score += Rand(0, 14);
			if (score > bestScore) { bestScore = score; best = r; }
		}
		if (best >= 0)
		{
			Array<int> ci, cj; CellsOf(best, ci, cj);
			for (int k = 0; k < ci.Size() && passPos == (0, 0); k++)
			{
				Actor a = PutInCell("CW_SecurityPass", ci[k], cj[k]);
				if (!a) a = PutCorner("CW_SecurityPass", ci[k], cj[k]);
				if (a) { passPos = a.pos.xy; let sp = CW_SecurityPass(a); if (sp) sp.tier = mapIdx; }
			}
		}
		// one patrolling guard carries a pass (drops it when downed, lethal or not)
		Array<CW_Guard> gs;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next())) if (g.args[0]) gs.Push(g);
		if (gs.Size()) gs[Rand(0, gs.Size() - 1)].hasPass = true;
	}

	// How the player first got into each objective room (for the debrief). Called by the handler every tic.
	void Watch(Actor pm, CW_Ledger l)
	{
		if (!pm || level.maptime % 4) return;
		int i = CellIdx(pm.pos.x), j = CellIdx(pm.pos.y);
		if (i < 0 || j < 0) return;
		int r = RoomAt(i, j);
		if (rtype[r] == FT_DUCT) { lastDuctTic = level.maptime; return; }
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			if (entered[k] || objRoom[k] != r) continue;
			entered[k] = true;
			String how = DescribeEntry(pm, r);
			if (l && l.missionActive) l.approachNotes.Push(String.Format("%s	%s", RoomName(rtype[r]), how));
		}
	}

	String DescribeEntry(Actor pm, int r)
	{
		if (level.maptime - lastDuctTic < 105) return "air duct";
		// nearest door of this room
		int best = -1; double bd = 1e9;
		for (int d = 0; d < dI.Size(); d++)
		{
			if (dFull[d]) continue;
			int a, b; DoorRooms(d, a, b);
			if (a != r && b != r) continue;
			double dd = (pm.pos.xy - (doorX[d], doorY[d])).Length();
			if (dd < bd) { bd = dd; best = d; }
		}
		if (best < 0) return "open floor";
		if (!dSec[best])
		{
			int a, b; DoorRooms(best, a, b);
			return "side door (" .. RoomName(rtype[a == r ? b : a]) .. ")";
		}
		for (int k = 0; k < doorActors.Size(); k++)
		{
			let dr = doorActors[k];
			if (!dr || dr.doorIdx != best) continue;
			switch (dr.openedBy)
			{
			case CW_Door.OB_PASS:     return "front door, security pass";
			case CW_Door.OB_BLACKOUT: return "front door, maglock down (blackout)";
			case CW_Door.OB_FORCED:   return "front door, forced";
			case CW_Door.OB_HACKED:   return "front door, hacked the maglock";
			case CW_Door.OB_BYPASS:   return "front door, bypass device";
			case CW_Door.OB_BREACHED: return "front door, blown open";
			case CW_Door.OB_GUARD:    return "front door, tailgated a guard";
			}
		}
		return "front door";
	}

	// ---------------------------------------------------------------- cover budget along the patrol loops
	// Walk the ring's centre line (where the patrols walk). Wherever more than COVER_GAP units pass with no
	// crouch-high cover (furniture or props >= 28u tall) or unlocked doorway within COVER_REACH, drop a low
	// cabinet against a solid side wall there. Mirrors CorpoWars_tools/qa/cover.py.
	const COVER_REACH = 64;
	const COVER_GAP = 192;

	bool HasCoverNear(Vector2 p)
	{
		for (int d = 0; d < doorX.Size(); d++)
			if (!dSec[d] && !dFull[d] && (p - (doorX[d], doorY[d])).Length() < COVER_REACH + 24) return true;   // duck through a door
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, COVER_REACH + 48, false);
		while (it.Next())
		{
			let t = it.thing;
			if (!t.bSOLID || t.height < 28 || t is "CW_Guard" || t is "CW_Civilian" || t is "PlayerPawn") continue;
			if ((t.pos.xy - p).Length() - t.radius < COVER_REACH) return true;
		}
		return false;
	}

	void CoverPass(int dd)
	{
		Array<double> cx, cy;
		for (int c = 0; c < 4; c++) { int i, j; SideCell(c, dd, dd, i, j); Vector2 p = CellCenter(i, j); cx.Push(p.x); cy.Push(p.y); }
		for (int c = 0; c < 4; c++)
		{
			Vector2 a = (cx[c], cy[c]), b = (cx[(c + 1) % 4], cy[(c + 1) % 4]);
			Vector2 dir = (b - a).Unit();
			double len = (b - a).Length(), run = 0;
			for (double t = 0; t <= len; t += 32)
			{
				Vector2 p = a + dir * t;
				if (HasCoverNear(p)) { run = 0; continue; }
				run += 32;
				if (run < COVER_GAP) continue;
				if (AddCoverAt(p, dir)) run = 0;
			}
		}
	}

	bool AddCoverAt(Vector2 p, Vector2 dir)
	{
		int i = CellIdx(p.x), j = CellIdx(p.y);
		if (i < 0 || j < 0) return false;
		// the two walls running alongside the path, nearest-solid first; slide to the sample's spot along the wall
		int s1 = abs(dir.x) > 0.5 ? 2 : 0, s2 = s1 + 1;
		Vector2 c = CellCenter(i, j);
		double along = abs(dir.x) > 0.5 ? p.x - c.x : p.y - c.y;
		for (int k = 0; k < 2; k++)
		{
			int d = (k + Rand(0, 1)) % 2 == 0 ? s1 : s2;
			Vector2 dv = DirV(d);
			double sl = along * (((-dv.y, dv.x) dot (abs(dir.x) > 0.5 ? (1, 0) : (0, 1))));
			double lim = HalfAcross(i, j, d) - 36;
			sl = clamp(sl, -lim, lim);
			if (PutWall("CW_FCredenza", i, j, d, sl)) return true;
			if (PutWall("CW_FCredenza", i, j, d, sl > 0 ? sl - 40 : sl + 40)) return true;
		}
		// no wall to put it against (open bays, doors): a freestanding planter beside the walkway
		for (int k = 0; k < 2; k++)
		{
			int d = k == 0 ? s1 : s2;
			let pl = PutF("CW_FPlanter", p + DirV(d) * 46, DirA(d));
			if (pl) { Put("CW_Plant", pl.pos.xy, 0, false); return true; }
		}
		return false;
	}

	// ---------------------------------------------------------------- dressing helpers
	bool Clear(Vector2 p, double r)
	{
		for (int d = 0; d < doorX.Size(); d++)
			if ((p - (doorX[d], doorY[d])).Length() < 44 + r) return false;
		for (int d = 0; d < ventX.Size(); d++)
			if ((p - (ventX[d], ventY[d])).Length() < 56 + r) return false;
		if ((p - insertPos).Length() < 36 + r) return false;
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, r + 48, false);
		while (it.Next()) if (it.thing.bSOLID && (it.thing.pos.xy - p).Length() < it.thing.radius + r + 4) return false;
		return true;
	}

	int Zone(Vector2 p, int i, int j)
	{
		Vector2 c = CellCenter(i, j);
		if (IsChannel(i, j))
		{
			bool horiz = j == 2 || j == GN - 3;
			return (horiz ? abs(p.y - c.y) < 32 : abs(p.x - c.x) < 32) ? 2 : 0;
		}
		double dx = SZ[i] / 2 - abs(p.x - c.x), dy = SZ[j] / 2 - abs(p.y - c.y);
		double d = min(dx, dy);
		return d < PANEL ? 0 : d < PANEL + TREAD ? 1 : 2;
	}

	double FloorAt(Vector2 p)
	{
		int i = CellIdx(p.x), j = CellIdx(p.y);
		if (i < 0 || j < 0) return level.PointInSector(p).floorplane.ZAtPoint(p);
		return CellFloor(i, j, Zone(p, i, j));
	}

	double CeilAt(Vector2 p)
	{
		int i = CellIdx(p.x), j = CellIdx(p.y);
		if (i < 0 || j < 0) return ROOM_H;
		return CellCeil(i, j, Zone(p, i, j));
	}

	Actor Put(Class<Actor> cls, Vector2 p, double ang = 0, bool check = true)
	{
		let def = GetDefaultByType(cls);
		if (check && !Clear(p, def.radius)) return null;
		let a = Actor.Spawn(cls, (p, def.bSPAWNCEILING ? CeilAt(p) - def.height : FloorAt(p)));
		if (a) a.angle = ang;
		return a;
	}

	// centre first, then the cell's corners
	Actor PutInCell(Class<Actor> cls, int i, int j, double ang = 0)
	{
		Vector2 c = CellCenter(i, j);
		let def = GetDefaultByType(cls);
		double hx = SZ[i] / 2 - def.radius - 10, hy = SZ[j] / 2 - def.radius - 10;
		if (hx < 0 || hy < 0) return null;
		static const double ox[] = { 0, -1, 1, -1, 1 };
		static const double oy[] = { 0, -1, -1, 1, 1 };
		for (int k = 0; k < 5; k++)
		{
			let a = Put(cls, c + (ox[k] * hx, oy[k] * hy), ang);
			if (a) return a;
		}
		return null;
	}

	// For an aisle cell (ring 1): direction toward the interior band if that side is a closed room wall.
	// (returns the vector: ZScript can't pass vectors as out parameters)
	Vector2 AisleWall(int i, int j, int openRoom)   // (0,0) = no solid wall
	{
		int s, t;
		if (j == 1) { s = 0; t = i; }
		else if (i == GN - 2) { s = 1; t = j; }
		else if (j == GN - 2) { s = 2; t = GN - 1 - i; }
		else { s = 3; t = GN - 1 - j; }
		int ii, jj;
		SideCell(s, t, 2, ii, jj);
		if (RoomAt(ii, jj) == openRoom) return (0, 0);
		return (CellCenter(ii, jj) - CellCenter(i, j)).Unit();
	}

	// Place against the cell wall in direction dir, leaving the rest of the cell as walkway.
	Actor PutAgainst(Class<Actor> cls, int i, int j, Vector2 dir, double ang = 0)
	{
		let def = GetDefaultByType(cls);
		double half = min(SZ[i], SZ[j]) / 2 - def.radius - 6;
		if (half < 0) return null;
		Vector2 side = (-dir.y, dir.x);
		static const double slide[] = { 0, -1, 1 };
		for (int k = 0; k < 3; k++)
		{
			let a = Put(cls, CellCenter(i, j) + dir * half + side * slide[k] * half * 0.6, ang);
			if (a) return a;
		}
		return null;
	}

	bool FreeOfSolids(Vector2 p, double r)
	{
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, r + 48, false);
		while (it.Next()) if (it.thing.bSOLID && (it.thing.pos.xy - p).Length() < it.thing.radius + r + 2) return false;
		return true;
	}

	bool Safe(Vector2 p) { return (p - insertPos).Length() >= SAFE_R; }

	void Patrol(Array<double> px, Array<double> py, int wait)
	{
		if (px.Size() < 2 || !Safe((px[0], py[0]))) return;
		Array<int> tids;
		for (int k = 0; k < px.Size(); k++) tids.Push(level.FindUniqueTid());
		for (int k = 0; k < px.Size(); k++)
		{
			let pp = Actor.Spawn("CW_PatrolPoint", (px[k], py[k], 0));
			pp.ChangeTid(tids[k]);
			pp.args[0] = tids[(k + 1) % tids.Size()];
			pp.args[1] = wait;
		}
		let g = CW_Guard(Actor.Spawn("CW_Guard", (px[0], py[0], 0)));
		if (g) { g.args[0] = tids[1]; guards++; }
	}

	// ang < 0: face the room's nearest doorway (the way anyone would come in)
	void Post(int i, int j, double ang)
	{
		if (!Safe(CellCenter(i, j))) return;
		if (ang < 0) ang = FaceNearestDoor(CellCenter(i, j));
		class<CW_Guard> guardClass = "CW_Guard";
		if (PutInCell(guardClass, i, j, ang)) { guards++; return; }
		// furnished room: try a ring of spots between the furniture
		Vector2 c = CellCenter(i, j);
		for (int k = 0; k < 8; k++)
		{
			Vector2 p = c + Actor.AngleToVector(k * 45) * min(SZ[i], SZ[j]) * 0.3;
			if (Put(guardClass, p, ang)) { guards++; return; }
		}
	}

	double FaceNearestDoor(Vector2 p)
	{
		double bd = 1e9; Vector2 best = FloorCenter();
		for (int d = 0; d < doorX.Size(); d++)
		{
			double dd = (p - (doorX[d], doorY[d])).Length();
			if (dd < bd) { bd = dd; best = (doorX[d], doorY[d]); }
		}
		Vector2 v = best - p;
		return v.Length() > 1 ? VectorAngle(v.x, v.y) : 0;
	}

	// guards already in p's quadrant of the floor (keeps posts from piling onto one side)
	int QuadGuards(Vector2 p)
	{
		Vector2 fc = FloorCenter();
		int q = Quad(p, fc), n = 0;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next())) if (Quad(g.pos.xy, fc) == q) n++;
		return n;
	}

	// Stationary guards at key spots: beside maglocked objective doors (watching the approach), in the
	// elevator hall, and at corridor corners. Up to two per floor, always in the emptiest part of the floor,
	// never near the insertion point.
	void KeyPosts()
	{
		Array<double> cx, cy, ca;
		for (int d = 0; d < dI.Size(); d++)
		{
			if (dSec[d] != 1) continue;
			int i1 = dI[d], j1 = dJ[d];
			int i2 = dVert[d] ? i1 + 1 : i1, j2 = dVert[d] ? j1 : j1 + 1;
			bool in1 = IsObjRoom(RoomAt(i1, j1));
			Vector2 dp = (doorX[d], doorY[d]);
			Vector2 v = CellCenter(in1 ? i2 : i1, in1 ? j2 : j1) - dp;
			if (v.Length() < 1) continue;
			v /= v.Length();
			for (int side = -1; side <= 1; side += 2)
			{
				Vector2 p = dp + v * 52 + (-v.y, v.x) * 44 * side;   // beside the doorway, clear of its swing
				cx.Push(p.x); cy.Push(p.y); ca.Push(VectorAngle(v.x, v.y));
			}
		}
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (rtype[r] != FT_ELEV && rtype[r] != FT_CORELOBBY) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			for (int k = 0; k < ci.Size(); k++)
			{
				Vector2 c = CellCenter(ci[k], cj[k]);
				Vector2 away = c - FloorCenter();
				cx.Push(c.x); cy.Push(c.y); ca.Push(VectorAngle(away.x, away.y));
			}
		}
		for (int c = 0; c < 4; c++)
		{
			int i3, j3; SideCell(c, 3, 3, i3, j3);
			Vector2 p = CellCenter(i3, j3);
			Vector2 inw = FloorCenter() - p;
			cx.Push(p.x); cy.Push(p.y); ca.Push(VectorAngle(inw.x, inw.y) + 180);
		}
		int extra = 0, want = Rand(1, 2);
		if (siteSet) want = clamp(SiteTarget() - guards, 0, 5);   // the site's guard force decides how many posts
		if (want > 2)
		{
			// a big guard force also posts people along the corridor loop and the open-plan aisle
			for (int c = 0; c < 4; c++)
				for (int t = 5; t <= 7; t += 2)
					for (int dd = 1; dd <= 3; dd += 2)
					{
						int i3, j3; SideCell(c, t, dd, i3, j3);
						Vector2 p = CellCenter(i3, j3);
						Vector2 inw = FloorCenter() - p;
						cx.Push(p.x); cy.Push(p.y); ca.Push(VectorAngle(inw.x, inw.y) + (dd == 3 ? 90 : 0));
					}
		}
		for (int tries = 0; tries < 6 + want * 3 && extra < want && cx.Size(); tries++)
		{
			int best = -1, bn = 99;
			for (int k = 0; k < cx.Size(); k++)
			{
				Vector2 p = (cx[k], cy[k]);
				if (!Safe(p)) continue;
				int n = QuadGuards(p) * 10 + Rand(0, 9);
				if (n < bn) { bn = n; best = k; }
			}
			if (best < 0) break;
			class<CW_Guard> gc = "CW_Guard";
			if (Put(gc, (cx[best], cy[best]), ca[best])) { guards++; extra++; }
			cx.Delete(best); cy.Delete(best); ca.Delete(best);
		}
		Console.Printf("\cfKey posts: %d", extra);
	}

	void CellsOf(int r, Array<int> ci, Array<int> cj)
	{
		ci.Clear(); cj.Clear();
		for (int j = 0; j < GN; j++) for (int i = 0; i < GN; i++) if (RoomAt(i, j) == r) { ci.Push(i); cj.Push(j); }
	}

	// ---------------------------------------------------------------- dressing
	int protoRoom;

	// Direction from cell (i, j) toward a solid wall (facade first, then closed walls to other rooms).
	Vector2 WallDir(int i, int j, int r)
	{
		static const int ddx[] = { 1, -1, 0, 0 };
		static const int ddy[] = { 0, 0, 1, -1 };
		for (int d = 0; d < 4; d++)
		{
			int ni = i + ddx[d], nj = j + ddy[d];
			if (ni < 0 || nj < 0 || ni >= GN || nj >= GN) return (ddx[d], ddy[d]);
		}
		int start = Rand(0, 3);
		for (int k = 0; k < 4; k++)
		{
			int d = (start + k) % 4;
			int ni = i + ddx[d], nj = j + ddy[d];
			if (RoomAt(ni, nj) != r && EdgeState(i, j, ni, nj) == 0) return (ddx[d], ddy[d]);
		}
		return (0, 0);
	}

	// Corners only (decor that should hug the room edges).
	Actor PutCorner(Class<Actor> cls, int i, int j, double ang = 0)
	{
		Vector2 c = CellCenter(i, j);
		let def = GetDefaultByType(cls);
		double hx = SZ[i] / 2 - def.radius - 8, hy = SZ[j] / 2 - def.radius - 8;
		if (hx < 0 || hy < 0) return null;
		int start = Rand(0, 3);
		for (int k = 0; k < 4; k++)
		{
			int q = (start + k) % 4;
			let a = Put(cls, c + ((q & 1) ? hx : -hx, (q & 2) ? hy : -hy), ang);
			if (a) return a;
		}
		return null;
	}

	// ---------------------------------------------------------------- lighting
	// Hash of the floor seed (independent of the layout RNG, so lighting never reshuffles the furniture).
	int Hash(int a)
	{
		int h = seed0 ^ (a * 374761393 + 668265263);
		h = (h ^ (h >>> 13)) * 1274126177;
		return (h ^ (h >>> 16)) & 0x7fff;
	}

	// After hours, a share of the floor has its lights off. Dark rooms are where you hide, read the room
	// by monitor glow and window light, and where guards' flashlights matter. Circulation (halls, core,
	// reception) is always lit so the floor stays legible; service rooms are the most often dark.
	void PlanLighting()
	{
		rDark.Clear();
		for (int r = 0; r < rtype.Size(); r++)
		{
			int pct = 0;
			switch (rtype[r])
			{
			case FT_OFFICE: case FT_CONF: pct = 45; break;
			case FT_EXEC: pct = 40; break;
			case FT_STORAGE: case FT_JANITOR: pct = 60; break;
			case FT_OPEN: pct = 25; break;
			case FT_PANTRY: case FT_IT: case FT_LAB: pct = 30; break;
			case FT_SERVER: pct = 50; break;
			}
			rDark.Push(Hash(r * 7 + 1) % 100 < pct ? 1 : 0);
		}
	}

	Color RoomTint(int t)
	{
		switch (t)
		{
		case FT_EXEC: case FT_CONF: case FT_RECEPTION: return Color(255, 226, 190);
		case FT_PANTRY: return Color(255, 236, 206);
		case FT_SERVER: case FT_IT: return Color(170, 196, 255);
		case FT_LAB: case FT_BATH: return Color(220, 236, 255);
		case FT_STAIR: return Color(255, 188, 176);
		case FT_STORAGE: case FT_JANITOR: case FT_FREIGHT: return Color(236, 222, 186);
		case FT_ELEV: case FT_CORELOBBY: return Color(240, 238, 250);
		}
		return Color(250, 246, 236);
	}

	bool IsDark(Vector2 p)
	{
		int i = CellIdx(p.x), j = CellIdx(p.y);
		if (i < 0 || j < 0) return false;
		int r = RoomAt(i, j);
		return r >= 0 && r < rDark.Size() && rDark[r];
	}

	bool Sconce(int i, int j, int d, double slide, bool emergency = false)
	{
		if (d < 0 || SideKind(i, j, d) != SK_WALL || IsGlass(i, j, d)) return false;
		Vector2 p = WallSpot(i, j, d, 0, slide, 0.5);
		for (int k = 0; k < doorX.Size(); k++) if ((p - (doorX[k], doorY[k])).Length() < 44) return false;
		for (int t = 0; t < 2; t++) if (vestDoor[t] && (p - vestDoor[t].pos.xy).Length() < 48) return false;
		let sc = CW_WallSconce(Actor.Spawn("CW_WallSconce", (p, FloorAt(p) + 50)));
		if (!sc) return false;
		sc.angle = DirA(Opp(d));
		sc.emergency = emergency;
		return true;
	}

	// Accent lighting after the furniture is in: monitor glow in the dark rooms, server-rack LEDs, vending
	// fronts, wall sconces along the corridors and in the suites, red emergency lamps in the stair cores.
	void AccentLights()
	{
		let it = ThinkerIterator.Create("CW_Furniture");
		CW_Furniture f;
		int n = 0;
		while (f = CW_Furniture(it.Next()))
		{
			n++;
			bool dark = IsDark(f.pos.xy);
			Vector3 fwd = (Actor.AngleToVector(f.angle), 0);
			if (f is "CW_FDeskWork" || f is "CW_FDeskCode" || f is "CW_FDeskExec" || f is "CW_FReception")
			{
				// someone left their screen on: a cold pool at the desk (and it gives you away if you sit in it)
				if (dark && Hash(n) % 100 < 70) CW_LightSource.Make(f.pos + (0, 0, 44) - fwd * 6, 70, 120, 200, 44, true);
			}
			else if (f is "CW_FServerRack")
			{
				if (n % 2 == 0) CW_LightSource.Make(f.pos + (0, 0, 44) + fwd * 16, 40, 110, 255, 56, true);
			}
			else if (f is "CW_FVending")
				CW_LightSource.Make(f.pos + (0, 0, 44) + fwd * 20, 200, 230, 255, 56, true);
		}
		for (int j = 0; j < GN; j++)
			for (int i = 0; i < GN; i++)
			{
				int r = RoomAt(i, j);
				if (r < 0 || rDark[r]) continue;
				int t = rtype[r];
				int h = Hash(1000 + j * GN + i);
				if (t == FT_STAIR) { for (int k = 0; k < 4; k++) if (Sconce(i, j, (h + k) % 4, 0, true)) break; continue; }
				bool suite = t == FT_EXEC || t == FT_CONF || t == FT_RECEPTION || t == FT_CORELOBBY || t == FT_ELEV;
				if (t == FT_HALL ? h % 3 != 0 : !suite) continue;
				for (int k = 0; k < 4; k++)
				{
					int d = (h + k) % 4;
					if (SideKind(i, j, d) != SK_WALL) continue;
					double half = HalfAcross(i, j, d) - 22;
					if (t == FT_HALL) { Sconce(i, j, d, 0); break; }
					Sconce(i, j, d, -half); Sconce(i, j, d, half);
					break;
				}
			}
	}

	// ---------------------------------------------------------------- stair towers
	// Keep in sync with genmap.STAIR_TOWERS / stair_tower (L 64, K 224, landing heights -160 0 160 320).
	static const double TOWER_X[] = { 2400, 2400 };
	static const double TOWER_Y[] = { 0, 800 };
	int stairI[2], stairJ[2];
	int floorNum;
	// multi-floor building (CW_Building): this map's index, the floor count, the mission seed, the
	// objective kinds on this floor (bits), and every map's floor number
	int mapIdx, floors, bldSeed, objHere;
	int floorNums[3];
	bool IsMissionFloor(int n, out int m)
	{
		for (m = 0; m < floors; m++) if (m != mapIdx && floorNums[m] == n) return true;
		m = -1;
		return false;
	}
	Vector3 spawnAt; double spawnAng; bool spawnInTower;
	CW_StairDoor vestDoor[2];
	Vector3 plateDest[2]; double plateAng[2];   // just inside the fire door on this floor (multi-floor arrivals)

	// Landing k of tower t: centre, and the door spot / facing (towards the door) on its outer wall.
	Vector3 LandingPos(int t, int k)
	{
		static const double lx[] = { 32, 320, 320, 32 };
		static const double ly[] = { 32, 32, 320, 320 };
		static const double lz[] = { -160, 0, 160, 320 };
		return (TOWER_X[t] + lx[k], TOWER_Y[t] + ly[k], lz[k]);
	}
	static double DoorFacing(int k) { return (k == 0 || k == 3) ? 180 : 0; }   // C0/C3 doors west, C1/C2 east

	// Label index for CW_FloorSign: 0 B1, 1..40 floors, 41 roof, 42 plant room.
	int LandingLabel(int k)
	{
		int n = floorNum + k - 1;
		if (role == FR_TOP && k >= 2) return k == 2 ? 41 : 42;
		if (n <= 0) return 0;
		return min(n, 40);
	}
	static String LabelText(int idx)
	{
		if (idx == 0) return "Level B1 (parking)";
		if (idx == 41) return "Roof access";
		if (idx == 42) return "Plant room";
		return String.Format("Floor %d", idx);
	}

	void StairTowers()
	{
		floorNum = role == FR_GROUND ? 1 : role == FR_TOP ? 30 + Hash(31) % 9 : 4 + Hash(17) % 22;
		if (floors > 1) floorNum = floorNums[mapIdx];
		for (int t = 0; t < 2; t++)
		{
			int i = stairI[t], j = stairJ[t];
			// plate side: the fire door on the vestibule wall opposite the corridor door
			int door = -1;
			for (int d = 0; d < 4; d++) if (SideKind(i, j, d) == SK_DOOR) door = d;
			int fd = door >= 0 ? Opp(door) : -1;
			if (fd < 0 || SideKind(i, j, fd) != SK_WALL) fd = PickWall(i, j, 0, 1, 2, 3);
			if (fd < 0) continue;
			Vector2 wallMid = CellCenter(i, j) + DirV(fd) * HalfAlong(i, j, fd);
			SetWallSegmentTex(i, j, wallMid, "CWDOORF");
			Vector2 vp = wallMid - DirV(fd) * 14;
			Vector3 c1 = LandingPos(t, 1);
			double inAng = DirA(Opp(fd));
			vestDoor[t] = CW_StairDoor(Actor.Spawn("CW_StairDoor", (vp, FloorAt(vp))));
			Vector2 fdv = DirV(fd);
			Vector2 lat = (-fdv.y, fdv.x);
			Vector2 sp = wallMid - fdv * 0.5 + lat * 44;
			let vs = CW_FloorSign(Actor.Spawn("CW_FloorSign", (sp, FloorAt(sp) + 58)));
			if (vs) { vs.idx = min(floorNum, 40); vs.angle = DirA(Opp(fd)); }
			let vd = vestDoor[t];
			if (vd)
			{
				vd.label = String.Format("Stairwell %s", t == 0 ? "A" : "B");
				vd.dest = (c1.xy - Actor.AngleToVector(DoorFacing(1)) * 12, c1.z);
				vd.destAng = DoorFacing(1) + 180;
			}
			// wall-mounted handrails along the three flights (core wall and outer wall)
			double ox = TOWER_X[t], oy = TOWER_Y[t];
			static const double rx[] = { 64, 288, 288 };
			static const double ry[] = { 64, 64, 288 };
			static const double ra[] = { 0, 90, 180 };
			for (int f = 0; f < 3; f++)
			{
				let rl = Actor.Spawn("CW_StairRail", (ox + rx[f], oy + ry[f], -160 + 160 * f));
				if (rl) rl.angle = ra[f];
			}
			// a wall light halfway up each flight (the core is solid, so each flight is its own lit shaft)
			static const double mx[] = { 176, 320, 176 };
			static const double my[] = { 32, 176, 320 };
			for (int f = 0; f < 3; f++) CW_LightSource.Make((ox + mx[f], oy + my[f], -160 + 160 * f + 80 + 100), 220, 226, 236, 96);
			// tower side: one door per landing
			for (int k = 0; k < 4; k++)
			{
				Vector3 lp = LandingPos(t, k);
				Vector2 fwd = Actor.AngleToVector(DoorFacing(k));
				Vector2 dp = lp.xy + fwd * 18;
				let sd = CW_StairDoor(Actor.Spawn("CW_StairDoor", (dp, lp.z)));
				int lab = LandingLabel(k);
				int mi;
				if (sd)
				{
					sd.label = LabelText(lab);
					if (k == 1)
					{
						sd.label = String.Format("Floor %d", floorNum);
						sd.dest = (vp - DirV(fd) * 34, FloorAt(vp));
						sd.destAng = inAng;
						plateDest[t] = sd.dest; plateAng[t] = inAng;
					}
					else if (floors > 1 && IsMissionFloor(floorNum + k - 1, mi))
					{
						sd.targetMap = CW_Building.MapName(mi);
						sd.tower = t;
						sd.label = String.Format("Floor %d (on the contract)", floorNum + k - 1);
					}
					else if (lab == 41) sd.lockText = "Roof door: alarmed. Your way off this building is on the plan.";
					else if (lab == 42) sd.lockText = "Plant room: chained shut.";
					else sd.lockText = String.Format("%s: another tenant's floor. Not on this contract.", LabelText(lab));
				}
				// floor plate beside the door, and a caged batten over the landing
				Vector2 sw = (k < 2) ? (0, -1) : (0, 1);   // the solid side wall next to the door
				let sg = CW_FloorSign(Actor.Spawn("CW_FloorSign", (lp.xy + sw * 31.5 - fwd * 4, lp.z + 58)));
				if (sg) { sg.idx = lab; sg.angle = VectorAngle(-sw.x, -sw.y); }
				let l = CW_CeilingLight(Actor.Spawn("CW_CeilingLight", (lp.xy, lp.z + 128 - 19)));
				if (l) { l.style = 2; l.frame = 2; l.bSPAWNCEILING = false; }
				CW_LightSource.Make((lp.xy - fwd * 20, lp.z + 100), 200, 40, 30, 40, true);   // red emergency lamp over the landing
			}
		}
		// stairwell insertions start in the tower: came up from the floor below, or down from above
		int ek = enKind[insertIdx];
		spawnInTower = false;
		if (ek == EN_STAIR_A || ek == EN_STAIR_B || ek == EN_ROOF)
		{
			int t = ek == EN_STAIR_A ? 0 : 1;
			int k = ek == EN_ROOF ? 2 : (Hash(5) % 2 ? 0 : 2);
			Vector3 lp = LandingPos(t, k);
			spawnAt = (lp.xy - Actor.AngleToVector(DoorFacing(k)) * 12, lp.z);
			spawnAng = k == 0 ? 0 : 270;   // facing along the flight towards this floor's landing
			spawnInTower = true;
		}
	}

	// Retexture the 64u wall segment of cell (i, j) whose middle is at m (the side facing the cell).
	void SetWallSegmentTex(int i, int j, Vector2 m, String tex)
	{
		Array<Sector> secs;
		CellSectors(i, j, secs);
		TextureID tx = Tex(tex, "DOOR3");
		for (int q = 0; q < secs.Size(); q++)
			for (int l = 0; l < secs[q].lines.Size(); l++)
			{
				Line ln = secs[q].lines[l];
				if (!ln.sidedef[1] || abs(ln.delta.Length() - 64) > 1) continue;
				if (((ln.v1.p + ln.v2.p) / 2 - m).Length() > 4) continue;
				Side sd = ln.sidedef[0].sector == secs[q] ? ln.sidedef[0] : ln.sidedef[1];
				sd.SetTexture(Side.top, tx);
				sd.SetTexture(Side.bottom, tx);
			}
	}

	// Fixture style per room: 0 troffer, 1 pendant, 2 industrial batten, 3 downlight
	int LampStyle(int t)
	{
		switch (t)
		{
		case FT_EXEC: case FT_CONF: case FT_RECEPTION: case FT_PANTRY: return 1;
		case FT_STORAGE: case FT_JANITOR: case FT_SERVER: case FT_IT: case FT_FREIGHT: case FT_STAIR: return 2;
		case FT_HALL: case FT_CORELOBBY: case FT_BATH: case FT_ELEV: return 3;
		}
		return 0;
	}
	// Corner farthest from a point (keeps decor out of the way between bays).
	Actor PutCornerAway(Class<Actor> cls, int i, int j, Vector2 from)
	{
		Vector2 c = CellCenter(i, j);
		let def = GetDefaultByType(cls);
		double hx = SZ[i] / 2 - def.radius - 8, hy = SZ[j] / 2 - def.radius - 8;
		int best = -1; double bd = -1;
		for (int q = 0; q < 4; q++)
		{
			Vector2 p = c + ((q & 1) ? hx : -hx, (q & 2) ? hy : -hy);
			double dd = (p - from).Length();
			if (dd > bd && Clear(p, def.radius)) { bd = dd; best = q; }
		}
		if (best < 0) return null;
		return Put(cls, c + ((best & 1) ? hx : -hx, (best & 2) ? hy : -hy), Rand(0, 3) * 90);
	}

	void Lamp(int i, int j)
	{
		let l = CW_CeilingLight(Put("CW_CeilingLight", CellCenter(i, j), 0, false));
		if (l) { int r = RoomAt(i, j); l.style = LampStyle(rtype[r]); l.frame = l.style; l.unlit = r < rDark.Size() && rDark[r]; }
	}

	Actor Against(Class<Actor> cls, int i, int j, int r, double ang = -1)
	{
		Vector2 dir = WallDir(i, j, r);
		if (dir.Length() < 0.5) return PutCorner(cls, i, j, max(ang, 0));
		// face away from the wall unless told otherwise
		return PutAgainst(cls, i, j, dir, ang >= 0 ? ang : VectorAngle(-dir.x, -dir.y));
	}

	// ================================================================ furniture layout
	// Sides of a cell: 0 east (+x), 1 west, 2 north (+y), 3 south.
	enum ESideKind { SK_OPEN, SK_WALL, SK_FACADE, SK_DOOR, SK_WIDE, SK_VENT }

	int SideKind(int i, int j, int d)
	{
		int ni = i + SDX[d], nj = j + SDY[d];
		if (ni < 0 || nj < 0 || ni >= GN || nj >= GN) return SK_FACADE;
		if (RoomAt(ni, nj) == RoomAt(i, j)) return SK_OPEN;
		int st = EdgeState(i, j, ni, nj);
		return st == 0 ? SK_WALL : st == 1 ? SK_DOOR : st == 2 ? SK_WIDE : SK_VENT;
	}
	bool Solid(int i, int j, int d) { int k = SideKind(i, j, d); return k == SK_WALL || k == SK_FACADE; }
	static int Opp(int d) { return d ^ 1; }
	static int Cw(int d) { static const int n[] = { 3, 2, 0, 1 }; return n[d]; }    // turn right (east -> south)
	static int Ccw(int d) { static const int n[] = { 2, 3, 1, 0 }; return n[d]; }   // turn left (east -> north)
	static Vector2 DirV(int d) { static const int dx[] = { 1, -1, 0, 0 }; static const int dy[] = { 0, 0, 1, -1 }; return (dx[d], dy[d]); }
	static double DirA(int d) { static const double a[] = { 0, 180, 90, 270 }; return a[d]; }
	double HalfAlong(int i, int j, int d) { return d < 2 ? SZ[i] / 2 : SZ[j] / 2; }   // centre -> wall on side d
	double HalfAcross(int i, int j, int d) { return d < 2 ? SZ[j] / 2 : SZ[i] / 2; }  // half length of wall d

	// A solid side among the given preference order, or -1.
	int PickWall(int i, int j, int d0, int d1 = -1, int d2 = -1, int d3 = -1)
	{
		if (d0 >= 0 && Solid(i, j, d0)) return d0;
		if (d1 >= 0 && Solid(i, j, d1)) return d1;
		if (d2 >= 0 && Solid(i, j, d2)) return d2;
		if (d3 >= 0 && Solid(i, j, d3)) return d3;
		return -1;
	}
	int AnyWall(int i, int j, bool facadeOk = true)
	{
		int s = Rand(0, 3);
		for (int k = 0; k < 4; k++)
		{
			int d = (s + k) % 4;
			int kind = SideKind(i, j, d);
			if (kind == SK_WALL || (facadeOk && kind == SK_FACADE)) return d;
		}
		return -1;
	}

	// Rectangle clearance: doorways/vents/insertion keep an approach zone, and no overlap with solid things.
	bool ClearRect(Vector2 p, double ang, double dep, double wid)
	{
		Vector2 f = Actor.AngleToVector(ang), s = Actor.AngleToVector(ang + 90);
		for (int d = 0; d < doorX.Size(); d++)
		{
			Vector2 q = (doorX[d], doorY[d]) - p;
			if (abs(q dot f) < dep / 2 + 40 && abs(q dot s) < wid / 2 + 40) return false;
		}
		for (int d = 0; d < ventX.Size(); d++)
		{
			Vector2 q = (ventX[d], ventY[d]) - p;
			if (abs(q dot f) < dep / 2 + 48 && abs(q dot s) < wid / 2 + 48) return false;
		}
		{
			Vector2 q = insertPos - p;
			if (abs(q dot f) < dep / 2 + 36 && abs(q dot s) < wid / 2 + 36) return false;
		}
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, max(dep, wid) / 2 + 48, false);
		while (it.Next())
		{
			let t = it.thing;
			if (!t.bSOLID) continue;
			Vector2 q = t.pos.xy - p;
			if (abs(q dot f) < dep / 2 + t.radius + 2 && abs(q dot s) < wid / 2 + t.radius + 2) return false;
		}
		return true;
	}

	Actor PutF(Class<CW_Furniture> cls, Vector2 p, double ang, bool check = true)
	{
		let def = CW_Furniture(GetDefaultByType(cls));
		if (check && !ClearRect(p, ang, def.fDepth, def.fWidth)) return null;
		let a = CW_Furniture(Actor.Spawn(cls, (p, FloorAt(p))));
		if (a) { a.angle = ang; a.MakeBlockers(); }
		return a;
	}

	// Back against wall d of cell (i, j), front facing into the room; slide moves it along the wall.
	Vector2 WallSpot(int i, int j, int d, double depth, double slide, double gap = 2)
	{
		Vector2 dir = DirV(d), side = (-dir.y, dir.x);
		return CellCenter(i, j) + dir * (HalfAlong(i, j, d) - depth / 2 - gap) + side * slide;
	}
	Actor PutWall(Class<CW_Furniture> cls, int i, int j, int d, double slide = 0, double gap = 2)
	{
		if (d < 0 || !Solid(i, j, d)) return null;             // only against a real wall (never across an opening)
		let def = CW_Furniture(GetDefaultByType(cls));
		if (def.Height > SILL_H + 2 && IsGlass(i, j, d)) return null;   // nothing tall against interior glazing
		return PutF(cls, WallSpot(i, j, d, def.fDepth, slide, gap), DirA(Opp(d)));
	}
	// Wall-mounted (whiteboard, screen): flat on the wall, no clearance test except doors.
	Actor PutMount(Class<CW_Furniture> cls, int i, int j, int d, double slide = 0)
	{
		if (d < 0 || SideKind(i, j, d) != SK_WALL || IsGlass(i, j, d)) return null;
		Vector2 p = WallSpot(i, j, d, 2, slide, 0);
		for (int k = 0; k < doorX.Size(); k++) if ((p - (doorX[k], doorY[k])).Length() < 56) return null;
		let a = Actor.Spawn(cls, (p, FloorAt(p)));
		if (a) a.angle = DirA(Opp(d));
		return a;
	}
	// Row of pieces along wall d, as many as fit, skipping blocked slots (doorways). Returns how many.
	int FillWall(Class<CW_Furniture> cls, int i, int j, int d, int maxN = 99, double gapBetween = 2)
	{
		if (d < 0) return 0;
		let def = CW_Furniture(GetDefaultByType(cls));
		double len = HalfAcross(i, j, d) * 2 - 8;
		int n = min(maxN, int((len + gapBetween) / (def.fWidth + gapBetween)));
		int placed = 0;
		for (int k = 0; k < n; k++)
		{
			double slide = (k - (n - 1) / 2.0) * (def.fWidth + gapBetween);
			if (PutWall(cls, i, j, d, slide)) placed++;
		}
		return placed;
	}

	// Desk against wall d, chair tucked in front of it (the chair is decoration: no collision).
	Actor Workstation(Class<CW_Furniture> desk, int i, int j, int d, double slide = 0, bool staff = false)
	{
		let a = PutWall(desk, i, j, d, slide);
		if (!a) return null;
		let def = CW_Furniture(GetDefaultByType(desk));
		Vector2 fwd = Actor.AngleToVector(a.angle);
		PutF("CW_FChair", a.pos.xy + fwd * (def.fDepth / 2 + 6), a.angle + 180, false);
		if (staff && Rand(0, 99) < 45)
			Put("CW_Civilian", a.pos.xy + fwd * (def.fDepth / 2 + 22) + Actor.AngleToVector(a.angle + 90) * 20, a.angle + 180);
		return a;
	}

	// Freestanding pod: two desks back to back across a cubicle screen, centred at p, running along 'ang'.
	void DeskPod(Vector2 p, double ang)
	{
		Vector2 f = Actor.AngleToVector(ang);
		if (!ClearRect(p, ang, 68, 64)) return;
		PutF("CW_FPartition", p, ang, false);
		PutF(Rand(0, 1) ? "CW_FDeskWork" : "CW_FDeskCode", p + f * 17, ang, false);
		PutF(Rand(0, 1) ? "CW_FDeskWork" : "CW_FDeskCode", p - f * 17, ang + 180, false);
		PutF("CW_FChair", p + f * 38, ang + 180, false);
		PutF("CW_FChair", p - f * 38, ang, false);
		if (Rand(0, 99) < 35) Put("CW_Civilian", p + f * 50 + Actor.AngleToVector(ang + 90) * 20, ang + 180);
	}

	// Lounge corner: sofa against wall d, coffee table in front, armchair facing it when there's room.
	int SameRoomSides(int i, int j) { int n = 0; for (int d = 0; d < 4; d++) if (SideKind(i, j, d) == SK_OPEN) n++; return n; }

	void Lounge(int i, int j, int d)
	{
		let s = PutWall("CW_FSofa", i, j, d);
		if (!s) return;
		Vector2 fwd = Actor.AngleToVector(s.angle);
		let t = PutF("CW_FCoffeeTable", s.pos.xy + fwd * 42, s.angle);
		// the armchair only where the bay isn't a walk-through to the next bay of the same room
		if (t && HalfAlong(i, j, d) * 2 >= 170 && SameRoomSides(i, j) == 0) PutF("CW_FArmchair", s.pos.xy + fwd * 90, s.angle + 180);
	}

	// Conference table centred in the cell along axis d (0/1 = x, 2/3 = y), chairs down both long sides.
	void MeetingTable(int i, int j, int axis)
	{
		double ang = DirA(axis);
		Vector2 c = CellCenter(i, j), f = Actor.AngleToVector(ang), s = Actor.AngleToVector(ang + 90);
		let t = PutF("CW_FConfTable", c, ang);
		if (!t) { PutF("CW_FRoundTable", c, 0); return; }
		for (int k = -1; k <= 1; k++)
		{
			PutF("CW_FChairExec", c + f * (k * 28) + s * 28, ang - 90, false);
			PutF("CW_FChairExec", c + f * (k * 28) - s * 28, ang + 90, false);
		}
	}

	// Scatter a sprite prop (crates, plants, cases) into a free corner.
	void CornerProp(Class<Actor> cls, int i, int j) { PutCorner(cls, i, j, Rand(0, 3) * 90); }

	void Dress(int r)
	{
		Array<int> ci, cj;
		CellsOf(r, ci, cj);
		int n = ci.Size();
		if (n == 0) return;
		int mid = n / 2;
		switch (rtype[r])
		{
		case FT_HALL:
			for (int k = 0; k < n; k++)
			{
				int i = ci[k], j = cj[k];
				if ((i - 3) % 2 == 0 && (j - 3) % 2 == 0) Lamp(i, j);
				bool corner = (i == 3 || i == 7) && (j == 3 || j == 7);
				if (corner) PutCorner("CW_Plant", i, j);
				else if (Rand(0, 99) < 14) PutCorner("CW_FBin", i, j);
			}
			for (int k = 0; k < stairDoorX.Size(); k++) Put("CW_ExitSign", (stairDoorX[k], stairDoorY[k]), stairDoorA[k], false);
			DressRing(3, Rand(0, 99) < 55, 0);
			break;
		case FT_OPEN:
		{
			int copiers = 0, coolers = 0;
			for (int k = 0; k < n; k++)
			{
				int i = ci[k], j = cj[k];
				bool corner = (i == 1 || i == GN - 2) && (j == 1 || j == GN - 2);
				if ((i + j) % 2 == 0) Lamp(i, j);
				if (corner)
				{
					PutCorner("CW_Plant", i, j);
					if (copiers < 2 && Rand(0, 99) < 50) { let cp = PutWall("CW_FCopier", i, j, AnyWall(i, j, false), Rand(-20, 20)); if (cp) copiers++; }
					continue;
				}
				if (Depth(i, j) == 2)
				{
					// open bay in the interior band: these bays are the walkways between the corridor and the
					// aisle, so the middle stays clear; desks or a breakout sofa go against the bay's side walls
					int placedHere = 0;
					for (int d = 0; d < 4; d++)
					{
						if (SideKind(i, j, d) != SK_WALL) continue;
						if (placedHere == 0 && Rand(0, 99) < 35) Lounge(i, j, d);
						else Workstation(Rand(0, 1) ? "CW_FDeskWork" : "CW_FDeskCode", i, j, d, 0, true);
						placedHere++;
					}
					if (placedHere == 0) PutCorner("CW_Plant", i, j);
					continue;
				}
				// the aisle ring is a walkway: workstations only along a solid interior-band wall, never mid-aisle
				Vector2 dir = AisleWall(i, j, r);
				if (dir.Length() < 0.5) { if (Rand(0, 99) < 40) PutCorner("CW_Plant", i, j); continue; }
				int d = abs(dir.x) > 0.5 ? (dir.x > 0 ? 0 : 1) : (dir.y > 0 ? 2 : 3);
				int roll = Rand(0, 99);
				if (roll < 10 && coolers < 2) { if (PutWall("CW_FWaterCooler", i, j, d, Rand(-40, 40))) coolers++; }
				else if (roll < 18 && copiers < 3) { if (PutWall("CW_FCopier", i, j, d, Rand(-30, 30))) copiers++; }
				else if (roll < 88)
				{
					Workstation(Rand(0, 1) ? "CW_FDeskWork" : "CW_FDeskCode", i, j, d, -31, true);
					Workstation(Rand(0, 1) ? "CW_FDeskWork" : "CW_FDeskCode", i, j, d, 31, true);
				}
				else PutWall("CW_FFileCabinet", i, j, d, Rand(-40, 40));
			}
			DressRing(1, true, 2);   // the aisle guards start on the opposite side from the corridor guards
			break;
		}
		case FT_OFFICE:
		{
			// fac = facade side of the row; the door is on the opposite (aisle) side
			int fac = -1;
			for (int d = 0; d < 4 && fac < 0; d++) if (SideKind(ci[0], cj[0], d) == SK_FACADE) fac = d;
			if (fac < 0) fac = 0;
			for (int k = 0; k < n; k++)
			{
				int i = ci[k], j = cj[k];
				int sideA = Solid(i, j, Ccw(fac)) ? Ccw(fac) : Solid(i, j, Cw(fac)) ? Cw(fac) : -1;
				if (k == 0 || (k == n - 1 && n == 3))
				{
					// desk on a side wall near the window, shelving along the same wall toward the door
					if (sideA >= 0)
					{
						double toWin = HalfAcross(i, j, sideA) - 36;
						Vector2 facV = DirV(fac), av = DirV(sideA);
						Vector2 sv = (-av.y, av.x);
						double sl = (sv dot facV) * toWin;
						Workstation(Rand(0, 2) ? "CW_FDeskWork" : "CW_FDeskCode", i, j, sideA, sl, true);
						PutWall("CW_FBookshelf", i, j, sideA, -sl * 0.9);
						PutWall("CW_FFileCabinet", i, j, Opp(sideA), sl);
						if (Solid(i, j, Opp(sideA))) PutF("CW_FChairGuest", CellCenter(i, j) + DirV(sideA) * 10, DirA(sideA));
					}
					else Workstation("CW_FDeskWork", i, j, fac, 0, true);
				}
				else if (k == 1)
				{
					// second bay: meeting nook or lounge
					if (Rand(0, 1))
					{
						PutF("CW_FRoundTable", CellCenter(i, j), 0);
						for (int q = 0; q < 3; q++) PutF("CW_FChairGuest", CellCenter(i, j) + Actor.AngleToVector(q * 120) * 24, q * 120 + 180, false);
					}
					else Lounge(i, j, fac);
				}
				else PutWall("CW_FBookshelf", i, j, fac, 0);
				if (SameRoomSides(i, j) < 2) CornerProp("CW_Plant", i, j);
			}
			Lamp(ci[mid], cj[mid]);
			if (r == objRoom[OBJ_TURN]) PutInCell("CW_Scientist", ci[mid], cj[mid], Rand(0, 3) * 90);   // no lab on this floor
			break;
		}
		case FT_EXEC:
		{
			// corner cell: executive desk looking into the suite with the corner windows behind the chair
			int i = ci[0], j = cj[0];
			int w1 = -1, w2 = -1;
			for (int d = 0; d < 4; d++) if (SideKind(i, j, d) == SK_FACADE) { if (w1 < 0) w1 = d; else w2 = d; }
			// the desk's back window is the suite's end wall (parallel to the run toward the second bay),
			// so the executive looks down the length of the suite
			int back = w1;
			if (n > 1 && w2 >= 0)
			{
				Vector2 run = CellCenter(ci[n - 1], cj[n - 1]) - CellCenter(i, j);
				back = abs(run dot DirV(w1)) > 1 ? w1 : w2;
			}
			Vector2 c = CellCenter(i, j), bv = DirV(back);
			double h = HalfAlong(i, j, back);
			let dk = PutF("CW_FDeskExec", c + bv * (h - 18 - 30), DirA(back));
			if (dk)
			{
				PutF("CW_FChairExec", dk.pos.xy + bv * 30, DirA(Opp(back)), false);
				Vector2 sv = (-bv.y, bv.x);
				PutF("CW_FChairGuest", dk.pos.xy - bv * 34 + sv * 20, DirA(back), false);
				PutF("CW_FChairGuest", dk.pos.xy - bv * 34 - sv * 20, DirA(back), false);
			}
			int other = back == w1 ? w2 : w1;
			if (other >= 0) PutWall("CW_FFileCabinet", i, j, other, 0);
			int inner = PickWall(i, j, Opp(back), Opp(other >= 0 ? other : back));
			// one bookcase, slid away from the second bay so the way between the bays stays wide
			Vector2 runV = n > 1 ? (CellCenter(ci[n - 1], cj[n - 1]) - CellCenter(i, j)).Unit() : (0, 0);
			if (inner >= 0)
			{
				Vector2 iv = DirV(inner);
				double sl = ((-iv.y, iv.x) dot runV) > 0 ? -34 : 34;
				PutWall("CW_FBookshelf", i, j, inner, sl);
			}
			if (r == protoRoom) { PutInCell("CW_Prototype", i, j); }
			Lamp(i, j);
			PutCornerAway("CW_Plant", i, j, CellCenter(i, j) + runV * 200);
			if (n > 1)
			{
				int i2 = ci[n - 1], j2 = cj[n - 1];
				int f2 = -1;
				for (int d = 0; d < 4; d++) if (SideKind(i2, j2, d) == SK_FACADE) f2 = d;
				Lounge(i2, j2, f2 >= 0 ? f2 : AnyWall(i2, j2));
				PutMount("CW_FWallTV", i2, j2, PickWall(i2, j2, Cw(f2 >= 0 ? f2 : 0), Ccw(f2 >= 0 ? f2 : 0)));
				CornerProp("CW_Plant", i2, j2);
				if (r == protoRoom) Post(i2, j2, -1);
			}
			else if (r == protoRoom) Post(i, j, -1);
			break;
		}
		case FT_CONF:
		{
			// tables line up along the room's run; whiteboard and screen on the end walls
			int axis = 0;
			if (n > 1) axis = cj[1] != cj[0] ? 2 : 0;
			else axis = (IsChannel(ci[0], cj[0]) && (cj[0] == 2 || cj[0] == GN - 3)) ? 0 : 2;
			for (int k = 0; k < n; k++) { MeetingTable(ci[k], cj[k], axis); }
			int e0 = axis == 0 ? 1 : 3, e1 = Opp(e0);
			PutMount("CW_FWhiteboard", ci[0], cj[0], e0);
			PutMount("CW_FWallTV", ci[n - 1], cj[n - 1], e1);
			// the side aisles past the tables are the only way through a long boardroom: decor and people only
			// in single-bay rooms, and then in the far corner from the door
			if (!PutMount("CW_FWhiteboard", ci[0], cj[0], PickWall(ci[0], cj[0], axis == 0 ? 2 : 0, axis == 0 ? 3 : 1)) && n == 1)
				CornerProp("CW_Plant", ci[0], cj[0]);
			if (n == 1 && Rand(0, 99) < 35) PutInCell("CW_Civilian", ci[0], cj[0], Rand(0, 3) * 90);
			Lamp(ci[0], cj[0]);
			break;
		}
		case FT_PANTRY:
		{
			int i = ci[0], j = cj[0];
			int w = AnyWall(i, j, false);
			PutWall("CW_FCounter", i, j, w);
			int w2 = PickWall(i, j, w >= 0 ? Cw(w) : 0, w >= 0 ? Ccw(w) : 1, w >= 0 ? Opp(w) : 2);
			PutWall("CW_FVending", i, j, w2, -26); PutWall("CW_FVending", i, j, w2, 12);
			PutWall("CW_FWaterCooler", i, j, w2, 44);
			Vector2 c = CellCenter(i, j) - (w >= 0 ? DirV(w) * 16 : (0, 0));
			if (PutF("CW_FRoundTable", c, 0))
				for (int q = 0; q < 2; q++) PutF("CW_FChairGuest", c + Actor.AngleToVector(q * 180 + 45) * 24, q * 180 + 225, false);
			PutCorner("CW_FBin", i, j);
			if (Rand(0, 99) < 45) PutInCell("CW_Civilian", i, j, Rand(0, 3) * 90);
			Lamp(i, j);
			break;
		}
		case FT_STORAGE:
			for (int k = 0; k < n; k++)
			{
				int i = ci[k], j = cj[k];
				int w = AnyWall(i, j, false);
				FillWall("CW_FShelving", i, j, w);
				FillWall("CW_FShelving", i, j, w >= 0 ? PickWall(i, j, Opp(w)) : -1);
				CornerProp(Rand(0, 1) ? "CW_CrateStack" : "CW_CaseBlack", i, j);
				CornerProp("CW_CrateBig", i, j);
			}
			Lamp(ci[0], cj[0]);
			break;
		case FT_JANITOR:
		{
			int i = ci[0], j = cj[0];
			int w = AnyWall(i, j, false);
			PutWall("CW_FShelving", i, j, w);
			PutCorner("CW_JanitorCart", i, j);
			PutCorner("CW_FBin", i, j);
			Lamp(i, j);
			break;
		}
		case FT_SERVER:
		{
			int i = ci[0], j = cj[0];
			if (r == objRoom[OBJ_DESTROY]) PutInCell("CW_Server", i, j);   // the other server rooms are just racks
			// two facing rows of racks on the walls without openings
			int placed = 0;
			for (int d = 0; d < 4; d++) if (SideKind(i, j, d) == SK_WALL) placed += FillWall("CW_FServerRack", i, j, d, 4, 0);
			if (placed == 0) for (int d = 0; d < 4; d++) placed += FillWall("CW_FServerRack", i, j, d, 4, 0);
			Lamp(i, j);
			Post(i, j, -1);
			break;
		}
		case FT_IT:
		{
			int i = ci[0], j = cj[0];
			int w = AnyWall(i, j, false);
			FillWall("CW_FServerRack", i, j, w, 3, 0);
			int w2 = w >= 0 ? PickWall(i, j, Opp(w), Cw(w), Ccw(w)) : -1;
			Workstation("CW_FDeskCode", i, j, w2, 0, true);
			PutCorner("CW_CaseSmall", i, j);
			Lamp(i, j);
			break;
		}
		case FT_LAB:
			for (int k = 0; k < n; k++)
			{
				int i = ci[k], j = cj[k];
				int w = AnyWall(i, j, false);
				PutWall("CW_FLabBench", i, j, w);
				if (w >= 0) PutWall("CW_FLabBench", i, j, PickWall(i, j, Opp(w)));
				PutCorner("CW_CaseSmall", i, j);
			}
			if (r == objRoom[OBJ_TURN]) PutInCell("CW_Scientist", ci[n - 1], cj[n - 1], 180);
			else PutInCell("CW_Civilian", ci[n - 1], cj[n - 1], 180);
			if (n > 1) PutInCell("CW_Civilian", ci[0], cj[0], 90);
			Lamp(ci[0], cj[0]);
			break;
		case FT_BATH:
		{
			int i = ci[0], j = cj[0];
			int w = AnyWall(i, j, false);
			PutWall("CW_FStalls", i, j, w);
			PutWall("CW_FVanity", i, j, w >= 0 ? PickWall(i, j, Opp(w), Cw(w), Ccw(w)) : -1);
			PutCorner("CW_FBin", i, j);
			Lamp(i, j);
			if (Rand(0, 99) < 30) PutInCell("CW_Civilian", i, j, Rand(0, 3) * 90);
			break;
		}
		case FT_RECEPTION:
		{
			// counter in an end bay, staff facing the street; sunken lounge in the pit; planters along the glass
			int fac = 3;   // the street lobby is on the south facade
			int ri = ci[0], rj = cj[0];
			Vector2 rc = CellCenter(ri, rj);
			let desk = PutF("CW_FReception", rc - DirV(fac) * 6, DirA(fac) + 180);
			if (desk)
			{
				PutF("CW_FChair", desk.pos.xy - DirV(fac) * 30, DirA(fac), false);
				Put("CW_Civilian", desk.pos.xy - DirV(fac) * 34 + (20, 0), DirA(fac));
			}
			PutMount("CW_FWallTV", ri, rj, PickWall(ri, rj, Opp(fac)));
			// sunken seating: coffee table in the pit, two armchairs across it (the pit is a walk-through bay)
			Vector2 pc = CellCenter(pitI, pitJ);
			PutF("CW_FCoffeeTable", pc, 90, false);
			PutF("CW_FArmchair", pc + (-44, 0), 0, false);
			PutF("CW_FArmchair", pc + (44, 0), 180, false);
			int oi = ci[n - 1], oj = cj[n - 1];
			let pl = PutWall("CW_FPlanter", oi, oj, fac, 0, 6);
			if (pl) Put("CW_Plant", pl.pos.xy, 0, false);
			Lounge(oi, oj, PickWall(oi, oj, Opp(fac), 0, 1));
			for (int k = 0; k < n; k++) Lamp(ci[k], cj[k]);   // (no corner plants: the lobby bays are walk-throughs)
			Post(ri, rj, -1);
			break;
		}
		case FT_CORELOBBY:
			for (int k = 0; k < n; k++)
			{
				if (k == mid) continue;
				int w = PickWall(ci[k], cj[k], 0, 1, 2, 3);
				let pl = PutWall("CW_FPlanter", ci[k], cj[k], w, 0, 4);
				if (pl) Put("CW_Plant", pl.pos.xy, 0, false); else PutCorner("CW_Plant", ci[k], cj[k]);
			}
			PutCorner("CW_FBin", ci[mid], cj[mid]);
			Lamp(ci[mid], cj[mid]);
			break;
		case FT_STAIR:
		{
			// the flight climbs away from the door along a side wall; the landing stays clear
			int i = ci[0], j = cj[0];
			int door = -1;
			for (int d = 0; d < 4; d++) if (SideKind(i, j, d) == SK_DOOR) door = d;
			// (the stairs themselves are in the tower behind the fire door: see StairTowers)
			if (door >= 0) PutCorner("CW_FBin", i, j);
			Lamp(i, j);
			break;
		}
		case FT_ELEV:
		case FT_FREIGHT:
		{
			int i = ci[mid], j = cj[mid];
			int door = -1;
			for (int d = 0; d < 4; d++) { int k = SideKind(i, j, d); if (k == SK_DOOR || k == SK_WIDE) door = d; }
			if (door >= 0)
			{
				Vector2 p = WallSpot(i, j, Opp(door), 2, 0, 0);
				let rail = Actor.Spawn("CW_FElevRail", (p, FloorAt(p)));
				if (rail) rail.angle = DirA(door);
				if (rtype[r] == FT_FREIGHT) { CornerProp("CW_CrateStack", i, j); CornerProp("CW_CrateBig", i, j); }
			}
			Lamp(i, j);
			break;
		}
		case FT_DUCT:
			break;
		}
	}

	// Patrol a ring (1 = open-plan aisle, 3 = corridor) corner to corner, starting at the corner farthest
	// from the insertion point; optionally a second guard walking the other way.
	void DressRing(int dd, bool second, int phase = 0)
	{
		Array<double> cx, cy;
		int far = 0; double best = -1;
		for (int c = 0; c < 4; c++)
		{
			int i, j; SideCell(c, dd, dd, i, j);
			Vector2 p = CellCenter(i, j);
			cx.Push(p.x); cy.Push(p.y);
			double d = (p - insertPos).Length();
			if (d > best) { best = d; far = c; }
		}
		Array<double> px, py;
		far = (far + phase) % 4;
		// the first corner can't be next to the insertion point: step round until it's safe
		for (int n = 0; n < 4 && !Safe((cx[far], cy[far])); n++) far = (far + 1) % 4;
		for (int k = 0; k < 4; k++) { px.Push(cx[(far + k) % 4]); py.Push(cy[(far + k) % 4]); }
		Patrol(px, py, 60);
		if (!second) return;
		px.Clear(); py.Clear();
		int opp = (far + 2) % 4;
		for (int n = 0; n < 4 && !Safe((cx[opp], cy[opp])); n++) opp = (opp + 1) % 4;
		for (int k = 0; k < 4; k++) { px.Push(cx[(opp + 4 - k) % 4]); py.Push(cy[(opp + 4 - k) % 4]); }
		Patrol(px, py, 60);
	}

	// ---------------------------------------------------------------- entry point
	void SetupBuilding(int missionSeed, int nFloors, int idx, CW_Contract c)
	{
		bldSeed = missionSeed; floors = max(1, nFloors); mapIdx = clamp(idx, 0, floors - 1);
		objHere = 0;
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
			if (CW_Building.ObjFloor(bldSeed, floors, c, k) == mapIdx) objHere |= 1 << k;
		for (int m = 0; m < 3; m++) floorNums[m] = CW_Building.FloorNum(bldSeed, floors, m);
	}

	void SetupSite(int force, int tech, bool neutral, int visit, int pref)
	{
		siteSet = true;
		siteForce = force; siteTech = tech; neutralSite = neutral; visitSeed = visit; entryPref = pref;
	}

	void Generate(int seed, int forcedRole = -1, int forcedTheme = -1)
	{
		if (floors < 1) { floors = 1; objHere = ~0; }
		if (floors > 1) { seed = CW_Building.Mix(seed, 104729 + mapIdx); forcedRole = FR_TYPICAL; }
		rng = seed;
		seed0 = seed;
		themeIdx = forcedTheme >= 0 ? forcedTheme % CW_Themes.COUNT : Hash(99991) % CW_Themes.COUNT;
		CW_Themes.Load(themeIdx, ts);
		role = forcedRole >= 0 ? clamp(forcedRole, 0, 2) : Rand(0, 99) < 20 ? FR_GROUND : Rand(0, 99) < 25 ? FR_TOP : FR_TYPICAL;
		Layout();
		PickEntries();
		PlanObjectives();
		PlanLighting();
		SecureObjectives();
		PlanHeights();
		Carve();
		for (int r = 0; r < rtype.Size(); r++) Theme(r);
		DecorWalls();
		ThemeStrips();
		ThemeVents();
		Glazing();

		// insertion kit and extraction point
		Vector2 ep = CellCenter(enI[extractIdx], enJ[extractIdx]);
		// every way into the building is a way out: elevators, stairwells, the lobby, the roof stair
		if (mapIdx == 0) for (int e = 0; e < enKind.Size(); e++) Put("CW_Extraction", CellCenter(enI[e], enJ[e]), 0, false);
		for (int r = 0; r < rtype.Size(); r++) Dress(r);
		CoverPass(1);   // aisle ring
		CoverPass(3);   // corridor loop
		StairTowers();
		ElevatorButtons();
		AccentLights();

		// field resupply crate: a free corner of the insertion cell (after dressing, so it never lands in furniture)
		double hx = SZ[enI[insertIdx]] / 2 - 28, hy = SZ[enJ[insertIdx]] / 2 - 28;
		static const double cxs[] = { 1, -1, 1, -1 };
		static const double cys[] = { 1, 1, -1, -1 };
		// the free corner farthest from every doorway
		int bestK = -1; double bestD = -1;
		for (int k = 0; k < 4; k++)
		{
			Vector2 p = insertPos + (cxs[k] * hx, cys[k] * hy);
			if (!FreeOfSolids(p, 26)) continue;
			double dmin = 1e9;
			for (int d = 0; d < doorX.Size(); d++) dmin = min(dmin, (p - (doorX[d], doorY[d])).Length());
			if (dmin > bestD) { bestD = dmin; bestK = k; }
		}
		if (bestK < 0) bestK = 0;
		if (mapIdx == 0) Put("CW_TransportAccess", insertPos + (cxs[bestK] * hx, cys[bestK] * hy), 0, false);
		PlaceStealItem();
		BalanceGuards();
		KeyPosts();
		PromoteSupervisor();   // after balancing: posts go where the floor is still thinnest
		ApplySecurity();
		PlaceSecurityPasses();
		Console.Printf("\cfInterior: %s", CW_Themes.Name(themeIdx));
		Console.Printf("\cfFloor generated: seed %d, %s, %d rooms, %d doors, %d vents, %d guards", seed, RoleName(role), rtype.Size(), dI.Size(), vI.Size(), guards);
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
			if (objRoom[k] >= 0) Console.Printf("\cfObjective %d in %s: %s", k, RoomName(rtype[objRoom[k]]), AccessSummary(k));
	}

	// Move the player to the insertion point (called on the first tick).
	void Insert(PlayerPawn pm)
	{
		if (!pm) return;
		pm.TakeInventory("CW_SecurityPass", 99);     // passes belong to this mission's building
		let l = CW_Ledger.Of(pm);
		if (l) { l.passMask = 0; l.arriveTower = -1; l.ApplyAccessPrep(pm); }
		if (spawnInTower) { pm.SetOrigin(spawnAt, false); pm.angle = spawnAng; }
		else { pm.SetOrigin((insertPos, 0), false); pm.angle = insertAng; }
		String more = floors > 1 ? "\n" .. BuildingNote() : "";
		String site = (l && l.job) ? "\cg" .. l.job.target.MakeUpper() .. "\n" : "";
		pm.A_Print(String.Format("%s\cf%s  -  FLOOR %d\n\cj%s\n\cjInsertion: %s\n\cdExtraction: %s%s", site, RoleName(role).MakeUpper(), floorNum, CW_Themes.Name(themeIdx), insertName, extractName, more), 6);
	}

	// Which objective is on which floor ("Floor 12: STEAL, SABOTAGE").
	String BuildingNote()
	{
		String s = "\cj";
		for (int m = 0; m < floors; m++)
		{
			String o = "";
			if (m == mapIdx) { for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (objRoom[k] >= 0) o = o .. (o.Length() ? ", " : "") .. CW_Contract.KindTag(k); }
			s = s .. String.Format("%sFloor %d%s", m ? "   " : "", floorNums[m], m == mapIdx ? " (here)" : "");
		}
		return s;
	}

	// Multi-floor elevators: one button per other contract floor on the back wall of the passenger and
	// freight cars. Riding one arrives in the same car on the other floor (Arrive with t = 2 / 3).
	void ElevatorButtons()
	{
		// garage runs: the passenger car on the insertion floor also goes down to B1
		let lg = CW_Ledger.Of(players[consoleplayer].mo);
		if (mapIdx == 0 && lg && lg.missionActive && (lg.garageRun || lg.rerouted))
			for (int e = 0; e < enKind.Size(); e++)
			{
				if (enKind[e] != EN_ELEV) continue;
				int i = enI[e], j = enJ[e];
				int open = -1;
				for (int d = 0; d < 4; d++) if (SideKind(i, j, d) != SK_WALL && SideKind(i, j, d) != SK_FACADE) open = d;
				int back = open >= 0 ? Opp(open) : 0;
				Vector2 bv = DirV(back), lat = (-bv.y, bv.x);
				Vector2 wall = CellCenter(i, j) + bv * HalfAlong(i, j, back);
				Vector2 p = wall - bv * 12 + lat * 44;
				let b = CW_StairDoor(Actor.Spawn("CW_StairDoor", (p, FloorAt(p))));
				if (b) { b.A_SetSize(6, 72); b.elevator = true; b.targetMap = "G05"; b.tower = 9; b.label = "garage (B1)"; }
				let pad = Actor.Spawn("CW_Keypad", (wall - bv * 1 + lat * 44, FloorAt(p)));
				if (pad) { pad.angle = VectorAngle(-bv.x, -bv.y); pad.frame = 1; }
			}
		if (floors < 2) return;
		for (int e = 0; e < enKind.Size(); e++)
		{
			int kind = enKind[e];
			if (kind != EN_ELEV && kind != EN_FREIGHT) continue;
			int i = enI[e], j = enJ[e];
			int open = -1;
			for (int d = 0; d < 4; d++) if (SideKind(i, j, d) != SK_WALL && SideKind(i, j, d) != SK_FACADE) open = d;
			int back = open >= 0 ? Opp(open) : 0;
			Vector2 bv = DirV(back), lat = (-bv.y, bv.x);
			Vector2 wall = CellCenter(i, j) + bv * HalfAlong(i, j, back);
			int n = 0;
			for (int m = 0; m < floors; m++)
			{
				if (m == mapIdx) continue;
				Vector2 p = wall - bv * 12 + lat * (n == 0 ? -20 : 20);
				n++;
				let b = CW_StairDoor(Actor.Spawn("CW_StairDoor", (p, FloorAt(p))));
				if (!b) continue;
				b.A_SetSize(6, 72);
				b.elevator = true;
				b.targetMap = CW_Building.MapName(m);
				b.tower = kind == EN_ELEV ? 2 : 3;
				b.label = String.Format("floor %d%s", floorNums[m], m == 0 ? " (exits)" : "");
				let pad = Actor.Spawn("CW_Keypad", (wall - bv * 1 + lat * (n == 1 ? -20 : 20), FloorAt(p)));
				if (pad) { pad.angle = VectorAngle(-bv.x, -bv.y); pad.frame = 1; }
			}
		}
	}

	// Multi-floor: put the player on this floor's landing in the tower they came through (t 0/1), or in the
	// elevator car they rode (t 2 passenger, 3 freight).
	void Arrive(PlayerPawn pm, int t)
	{
		if (!pm) return;
		if (t >= 2)
		{
			int want = t == 2 ? EN_ELEV : EN_FREIGHT;
			for (int e = 0; e < enKind.Size(); e++)
			{
				if (enKind[e] != want) continue;
				int i = enI[e], j = enJ[e];
				int open = -1;
				for (int d = 0; d < 4; d++) if (SideKind(i, j, d) != SK_WALL && SideKind(i, j, d) != SK_FACADE) open = d;
				Vector2 c = CellCenter(i, j);
				pm.SetOrigin((c, FloorAt(c)), false);
				pm.angle = open >= 0 ? DirA(open) : 0;   // facing out of the car
				pm.vel = (0, 0, 0);
				pm.A_Print(String.Format("\cfFLOOR %d", floorNum), 2);
				return;
			}
		}
		t = clamp(t, 0, 1);
		// A landing door marked "Floor N" leads onto floor N: you step out of the stairwell onto that floor's
		// plate (its stair vestibule), exactly like using your own floor's landing door. You never arrive in
		// another copy of the stair tower.
		if (plateDest[t] != (0, 0, 0)) { pm.SetOrigin(plateDest[t], false); pm.angle = plateAng[t]; }   // back to the fire door, facing the vestibule door onto the floor
		else { pm.SetOrigin((insertPos, 0), false); pm.angle = insertAng; }
		pm.vel = (0, 0, 0);
		String here = "";
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (objRoom[k] >= 0) here = here .. (here.Length() ? ", " : "") .. CW_Contract.KindTag(k);
		pm.A_Print(String.Format("\cfFLOOR %d\n\cj%s\n%s", floorNum, here.Length() ? "Objectives here: " .. here : "No objectives on this floor", mapIdx == 0 ? "\cdExtraction: " .. extractName : ""), 4);
	}
}

// =============================================================================
// Functional door on a generated floor. Lives in the doorway strip (tag doorTag).
// - The strip starts open so the nav graph links through it; the door shuts itself after the graph is built.
// - USE on either face opens it (line special set up here), guards open it when they walk up,
//   and it closes again after a few seconds once the doorway is clear (never on anyone).
// =============================================================================
// Functional door on a generated floor. Lives in the doorway strip (tag doorTag).
// - The strip starts open so the nav graph links through it; the door shuts itself after the graph is built.
// - USE on either face opens it (line special set up here), guards open it when they walk up,
//   and it closes again after a few seconds once the doorway is clear (never on anyone).
// - SECURED doors (objective rooms) are maglocked: no line special. The player opens one with a security
//   pass, while Nyx's blackout has the power down, or by holding USE for 3 s to force it (loud, repeated
//   noise; the lock stays broken). Guards carry passes, so slipping through behind one works too.
// =============================================================================
class CW_Door : Actor
{
	int doorTag;
	double shutZ, openZ;
	int idle;
	bool isOpen;         // last commanded state
	bool primed;         // first (silent) close after level start has happened
	bool secured;        // maglocked
	int doorIdx;         // index in the generator's door list
	int openedBy;        // how the player got through the last time it opened (for the debrief)
	Array<Actor> pads;   // keypad panels (maglocked doors)
	bool jammed;         // lock was forced: the door is stuck open for the rest of the mission
	double lastTop;
	bool useWasHeld;     // edge detection for USE (player.oldbuttons is already updated when doors tick)

	enum EOpenedBy { OB_NONE, OB_PASS, OB_BLACKOUT, OB_FORCED, OB_GUARD, OB_PLAIN, OB_HACKED, OB_BYPASS, OB_BREACHED }

	Default { +NOBLOCKMAP; +NOGRAVITY; +NOSECTOR; +DONTSPLASH; Radius 8; Height 8; }

	const SPEED = 48;
	const USE_SPECIAL = 47;   // Ceiling_MoveToValue

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		Sector strip = level.PointInSector(pos.xy);
		if (strip) { strip.seqType = -1; strip.SeqName = 'CWDoorSilent'; }   // no looping ceiling grind
		SetUsable(!secured);
		isOpen = true;
	}

	// both 64u faces of the doorway strip become usable from either side (players) and by monsters bumping them
	virtual void SetUsable(bool usable)
	{
		Sector strip = level.PointInSector(pos.xy);
		for (int l = 0; l < strip.lines.Size(); l++)
		{
			Line ln = strip.lines[l];
			if (!ln.sidedef[1] || ln.delta.Length() < 48) continue;
			if (!usable) { ln.special = 0; continue; }
			ln.special = USE_SPECIAL;
			ln.args[0] = doorTag; ln.args[1] = SPEED; ln.args[2] = int(openZ); ln.args[3] = 0;
			ln.activation = SPAC_Use | SPAC_UseBack | SPAC_MUse;
			ln.flags |= Line.ML_REPEAT_SPECIAL | Line.ML_MONSTERSCANACTIVATE;
		}
	}

	double CurTop() { return level.PointInSector(pos.xy).ceilingplane.ZAtPoint(pos.xy); }
	bool IsShut() { return CurTop() <= shutZ + 4; }

	virtual void SetDoor(bool open)
	{
		level.ExecuteSpecial(USE_SPECIAL, null, null, 0, doorTag, SPEED, abs(int(open ? openZ : shutZ)), (open ? openZ : shutZ) < 0 ? 1 : 0);
		if (primed) DoorSound(open);
		primed = true;
		isOpen = open;
		idle = 0;
		if (!open) openedBy = OB_NONE;
	}

	// Office doors: quieter, short range, and never the same pitch twice in a row, so a busy floor
	// doesn't sound like one door slamming on repeat.
	void DoorSound(bool open)
	{
		A_StartSound(open ? "doors/dr1_open" : "doors/dr1_clos", CHAN_BODY, 0, open ? 0.45 : 0.35, 2.2, frandom(0.82, 1.12));
	}

	// The console player at the lock: close, facing the door.
	PlayerPawn AtLock()
	{
		let pm = players[consoleplayer].mo;
		if (!pm || pm.health <= 0) return null;
		if (pm.Distance2D(self) > 60) return null;
		if (abs(DeltaAngle(pm.angle, pm.AngleTo(self))) > 60) return null;
		return pm;
	}

	static bool Blackout()
	{
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		return h && h.blackoutTics > 0;
	}

	int hackLock;        // tics left of the lockout after a tripped hack
	int useTics;         // how long USE has been held at the lock (tap = hack, hold = bypass device)
	const BYPASS_TICS = 105;
	const HOLD_TICS = 12;

	void LockLogic()
	{
		if (hackLock > 0) hackLock--;
		let pm = AtLock();
		if (!pm || isOpen || !secured) { useTics = 0; useWasHeld = pm && (pm.player.cmd.buttons & BT_USE); return; }
		bool held = (pm.player.cmd.buttons & BT_USE) != 0, pressed = held && !useWasHeld;
		bool released = !held && useWasHeld;
		useWasHeld = held;
		if (pressed && CW_SecurityPass.Has(pm))
		{
			A_StartSound("misc/keytry", CHAN_VOICE, 0, 0.6);
			openedBy = OB_PASS; SetDoor(true); return;
		}
		if (pressed && Blackout())
		{
			openedBy = OB_BLACKOUT; SetDoor(true); return;
		}
		let l = CW_Ledger.Of(pm);
		bool device = l && l.CountIn(2, CW_Items.IT_BYPASS) > 0;
		if (held)
		{
			useTics++;
			if (device && useTics >= HOLD_TICS)
			{
				if ((useTics - HOLD_TICS) % 20 == 0) A_StartSound("misc/keytry", CHAN_VOICE, 0, 0.15);   // quiet clicks
				if (useTics - HOLD_TICS >= BYPASS_TICS)
				{
					l.ConsumeOne(2, CW_Items.IT_BYPASS);
					useTics = 0;
					openedBy = OB_BYPASS; Unlock();
				}
			}
			return;
		}
		if (released && useTics > 0 && useTics < HOLD_TICS)
		{
			useTics = 0;
			if (hackLock > 0) return;
			let h = CW_Handler(EventHandler.Find("CW_Handler"));
			if (h) h.RequestHack(self);
			return;
		}
		useTics = 0;
	}

	// The hack minigame reported back.
	void HackResult(int res, Actor pm)
	{
		if (res == 1 && secured) { A_StartSound("misc/keytry", CHAN_VOICE, 0, 0.5); openedBy = OB_HACKED; Unlock(); return; }
		if (res == 0)
		{
			// tripped: the keypad shrieks and locks out
			hackLock = 35 * 20;
			A_StartSound("misc/keytry", CHAN_VOICE, 0, 1.0, 0.3);
			A_StartSound("plats/pt1_stop", CHAN_BODY, 0, 1.0, 0.4);
			CW_Handler.EmitNoise(pm ? pm : Actor(self), pos, 800, 0.8);
		}
	}

	// Hacked or bypassed: the maglock stays released for the rest of the mission (keypad green). The door
	// still swings shut on its own, but USE opens it like any other door.
	void Unlock()
	{
		secured = false;
		SetUsable(true);
		SetDoor(true);
		for (int k = 0; k < pads.Size(); k++) if (pads[k]) { pads[k].frame = 1; pads[k].bBRIGHT = true; }
	}

	// Blown open by a breaching charge: stuck open for the rest of the mission, keypads dead.
	void Breached(Actor by)
	{
		if (!secured) { if (!isOpen) SetDoor(true); return; }
		secured = false; jammed = true;
		SetUsable(false);
		openedBy = OB_BREACHED; SetDoor(true);
		for (int k = 0; k < pads.Size(); k++) if (pads[k]) { pads[k].frame = 2; pads[k].bBRIGHT = false; }
		let l = by ? CW_Ledger.Of(by) : null;
		if (l && l.missionActive) l.doorsForced++;
	}

	override void Tick()
	{
		// no Super.Tick(): stationary logic only
		if (secured && level.maptime >= 40) LockLogic();
		if (level.maptime % 4) return;
		if (pads.Size())
		{
			int f = (jammed || Blackout()) ? 2 : ((isOpen || !secured) ? 1 : 0);   // released locks stay green
			for (int k = 0; k < pads.Size(); k++) if (pads[k]) { pads[k].frame = f; pads[k].bBRIGHT = f != 2; }
		}
		double top = CurTop();
		bool rising = top > lastTop + 1;
		lastTop = top;
		if (jammed) return;
		if (rising && !isOpen) { isOpen = true; idle = 0; openedBy = OB_PLAIN; DoorSound(true); }   // a player used it

		bool someone = false, guardComing = false;
		let it = BlockThingsIterator.Create(self, 112);
		while (it.Next())
		{
			let t = it.thing;
			if (!t || t == self || !(t.bSOLID || t.bCORPSE || t.player)) continue;
			double d = (t.pos.xy - pos.xy).Length();
			if (d < t.radius + 28) someone = true;
			// a guard walking up opens it (they carry passes); one standing post beside it doesn't hold it open
			if (t is "CW_Guard" && t.health > 0 && d < 104 && t.vel.xy.Length() > 0.3) guardComing = true;
		}
		if (guardComing && !isOpen) { openedBy = OB_GUARD; SetDoor(true); return; }
		if (!isOpen) return;
		if (someone || guardComing) { idle = 0; return; }
		if (level.maptime < 40) return;          // let the nav graph (built at tic 12) see through first
		if (++idle >= 20) SetDoor(false);           // ~3 s clear -> close
	}
}
