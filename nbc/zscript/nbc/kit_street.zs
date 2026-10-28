// The street (PLAN.md §4.4, §6.7, M2c): a few blocks at the foot of the towers in the Bricks.
//
// Template NBC_KS (tools/make_kit_maps.py): an even grid of 22 x 17 cells of 128 (3.5 m). The top row is the
// Wall (8 m, free-standing concrete; towers rise beyond it). Below it every floor lays its own street plan:
//
//   - the main road, two cells wide, across the map at a random row, a sidewalk either side
//   - none, one or two side streets (two cells wide) at random columns, running north to the Wall, south to
//     the canal, or both ways (a T or a crossroads)
//   - sometimes a canal walk along the south edge
//
// What's left are blocks. Each faces its best street; along that frontage it's cut into parcels 2-5 cells wide:
// shops (a shop floor, one or two back rooms), walk-ups (a stair hall and the ground-floor flat), auto shops,
// parking lots, vacant lots, an alleyway, a little square, or a closed building. A deep block gets an alley
// behind its front parcels, with yards, garages and closed buildings behind that. A building has one front
// door, and at most one back or side door. The variant adds its landmark on the main road: the base of a
// tower (a fenced court and the lobby), a chop lot, or the elevated line over the road; corner stores always
// get a side street and a crew's back room.
//
// Ground floors are one storey (112, 3.6 m); above them the facades show the flats upstairs. Past the south
// and west edges the canal, past the east edge a retaining wall, and tower blocks all round (the template).
class NBC_KitStreet : NBC_KitGen
{
	enum EVar { V_TOWER, V_CORNER, V_LOT, V_UNDER, V_COUNT }
	enum ERoom
	{
		S_ROAD, S_WALK, S_ALLEY, S_COURT, S_PLAY, S_LOT, S_UNDER, S_PARKING, S_PLAZA, S_PROM, S_YARD, S_VACANT,
		S_LOBBY, S_LIFTS, S_TSTAIR, S_SUPER,
		S_BODEGA, S_LAUNDROMAT, S_CHECKS, S_TAKEOUT, S_BARBER, S_BAR, S_PAWN, S_BOARDED,
		S_STORE, S_OFFICE, S_HANGOUT, S_HALL, S_FLAT, S_FBED, S_GARAGE, S_AUTO
	}
	const CELLS_X = 22;
	const CELLS_Y = 17;
	const ROW_WALL = 16;
	const WALL_TEX = "CWWALLD";      // the Wall's concrete
	const WALL_H = 256;              // and its height: 8 m, the towers beyond rise over it
	static const String FRONTS[] = { "BRICK1", "BRICK12", "BIGBRIK1", "STUCCO1", "BRICK6", "BRICK11", "ADBRICK", "STONE2" };
	static const String UPPER[] = { "CWNRESA", "CWNRESB", "CWNRESC" };

	int roadR, walkR, promR, underR;
	int mainRow;                 // the main road takes rows mainRow and mainRow + 1
	Array<int> sideCol;          // each side street takes columns c and c + 1
	bool plazaDone, walkupEntry;
	int alleys;
	// the block being filled: its box, the side that faces its street (0 east, 1 west, 2 north, 3 south),
	// its width along that street and its depth away from it. Parcels are laid out in (u along, v deep).
	int bI0, bJ0, bI1, bJ1, bFd, bW, bD;
	Array<int> blkI0, blkJ0, blkI1, blkJ1;

	override void Setup()
	{
		for (int i = 0; i < CELLS_X; i++) colw.Push(128);
		for (int j = 0; j < CELLS_Y; j++) rowh.Push(128);
		Grid(CELLS_X, CELLS_Y);
		doorTex = "ADDOOR3"; jambTex = "SUPPORT3"; edgeTex = "ADBRICK";
		// past the edges: the embankment and the canal, the towers beyond (the template's scenery, make_kit_maps.py)
		bandFloor = 0; bandTex = "CWPAVE"; bandCeil = 640; bandLight = 128;
		kerbTex = "CWCONCW";
	}
	override double SkyH() { return 640; }
	override double GroundFloorH() { return 112; }
	// above a shopfront, the flats upstairs (the same facade over the same storefront); the Wall stays concrete
	override String UpperFacade(String ground)
	{
		if (ground == WALL_TEX) return "CWWALLD";
		if (ground == "CWVIADUC" || ground.Length() == 0) return ground.Length() ? ground : "ADBRICK";
		return UPPER[(ground.Length() + ground.ByteAt(ground.Length() - 1)) % UPPER.Size()];
	}
	// the Wall stands free, open to the sky above it
	override double SolidTop(int i, int j) { return cellFac[j * NX + i] == WALL_TEX ? WALL_H : 0; }
	override bool EdgeOpen(int r) { return IsOut(r); }
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "tower entrance", "corner stores", "chop lot", "under the el" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 12, 12, 5, 13 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}

	int MakeRoom(int t)
	{
		switch (t)
		{
		case S_ROAD:       return Room(t, RF_OUT, -8, 0, 120, "CWASPH", "F_SKY1", "ADBRICK", "the street");
		case S_WALK:       return Room(t, RF_OUT | RF_CIV | RF_RUBBLE, 0, 0, 128, "CWPAVE", "F_SKY1", "ADBRICK", "the sidewalk");
		case S_ALLEY:      return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 104, "MFLR8_1", "F_SKY1", "BRICK6", "the alley");
		case S_COURT:      return Room(t, RF_OUT | RF_CIV | RF_PATROL | RF_RUBBLE, 0, 0, 120, "CWPAVE", "F_SKY1", "ADBRICK", "the tower's courtyard");
		case S_PLAY:       return Room(t, RF_OUT | RF_CIV | RF_RUBBLE, 0, 0, 120, "CWCONCF", "F_SKY1", "ADBRICK", "the playground");
		case S_LOT:        return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 112, "FLOOR4_8", "F_SKY1", "BRICK6", "the car lot");
		case S_PARKING:    return Room(t, RF_OUT | RF_PATROL | RF_CIV, -8, 0, 120, "CWASPH", "F_SKY1", "BRICK6", "a parking lot");
		case S_PLAZA:      return Room(t, RF_OUT | RF_CIV | RF_PATROL, 0, 0, 128, "CWPAVE", "F_SKY1", "ADBRICK", "the little square");
		case S_PROM:       return Room(t, RF_OUT | RF_CIV | RF_PATROL, 0, 0, 120, "CWPAVE", "F_SKY1", "ADBRICK", "the canal walk");
		case S_YARD:       return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 104, "FLOOR4_8", "F_SKY1", "BRICK6", "a back yard");
		case S_VACANT:     return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 112, "FLOOR4_8", "F_SKY1", "BRICK6", "a vacant lot");
		case S_UNDER:      return Room(t, RF_PATROL | RF_CIV, -8, 176, 104, "CWASPH", "CWDECKUN", "CWVIADUC", "under the el");
		case S_LOBBY:      return Room(t, RF_CIV | RF_PATROL, 0, 112, 144, "CWTILEF", "CWCEILL", "ADGREYW", "the tower lobby");
		case S_LIFTS:      return Room(t, RF_CIV | RF_PATROL, 0, 112, 136, "CWTILEF", "CWCEILL", "CWELEVD", "the lift lobby");
		case S_TSTAIR:     return Room(t, RF_NOGUARD, 0, 112, 112, "CWSTAIF", "ADFLUOR", "ADGREY2", "the tower stairs");
		case S_SUPER:      return Room(t, RF_PEOPLE | RF_VALUE, 0, 112, 112, "CWCONCF", "CWCEILT", "CWWALLD", "the super's office");
		case S_BODEGA:     return Room(t, RF_CIV, 0, 112, 160, "CWTILEF", "CWCEILT", "CWWALL1", "the bodega");
		case S_LAUNDROMAT: return Room(t, RF_CIV, 0, 112, 160, "CWTILEF", "CWCEILT", "CWTILEW", "the laundromat");
		case S_CHECKS:     return Room(t, RF_CIV | RF_VALUE, 0, 112, 152, "CWCARP2", "CWCEILT", "ADGREYW", "the check cashing place");
		case S_TAKEOUT:    return Room(t, RF_CIV, 0, 112, 152, "CWTILEF", "CWCEILT", "CWWALL2", "the takeout");
		case S_BARBER:     return Room(t, RF_CIV | RF_PEOPLE, 0, 112, 152, "CWTILEF", "CWCEILT", "CWWALL1", "the barbershop");
		case S_BAR:        return Room(t, RF_CIV | RF_PEOPLE, 0, 112, 112, "FLOOR4_8", "CWCEILT", "CWWALL2", "the bar");
		case S_PAWN:       return Room(t, RF_CIV | RF_VALUE, 0, 112, 144, "CWCARP2", "CWCEILT", "ADGREYW", "the pawn shop");
		case S_BOARDED:    return Room(t, RF_DARK | RF_RUBBLE | RF_PATROL, 0, 112, 72, "CWCONCF", "ADFLUOR", "CWWALLD", "a boarded-up store");
		case S_STORE:      return Room(t, RF_VALUE, 0, 112, 112, "FLOOR4_8", "ADFLUOR", "CEMENT7", "a stockroom");
		case S_OFFICE:     return Room(t, RF_VALUE | RF_PEOPLE, 0, 112, 120, "CWCARP2", "CWCEILT", "CWWALLD", "the back office");
		case S_HANGOUT:    return Room(t, RF_PEOPLE | RF_PATROL | RF_RUBBLE, 0, 112, 96, "CWCONCF", "ADFLUOR", "CWWALLD", "the crew's back room");
		case S_HALL:       return Room(t, RF_CIV | RF_NOGUARD, 0, 112, 104, "CWSTAIF", "ADFLUOR", "ADGREY2", "a walk-up stair hall");
		case S_FLAT:       return Room(t, RF_CIV | RF_PEOPLE, 0, 112, 128, "CWCARP1", "CWCEILT", "CWWALL1", "a ground-floor flat");
		case S_FBED:       return Room(t, RF_VALUE, 0, 112, 112, "CWCARP1", "CWCEILT", "CWWALL1", "a bedroom");
		case S_GARAGE:     return Room(t, RF_TECH | RF_PATROL | RF_RUBBLE, 0, 128, 112, "CWCONCF", "ADFLUOR", "SHAWN02", "the chop garage");
		case S_AUTO:       return Room(t, RF_TECH | RF_PATROL, 0, 128, 120, "CWCONCF", "ADFLUOR", "SHAWN02", "an auto shop");
		}
		return Room(t, 0, 0, 112, 128, "FLOOR4_8", "CWCEILT", "CEMENT7", "a room");
	}

	// ---------------------------------------------------------------- block coordinates
	int CI(int u, int v) { if (bFd >= 2) return bI0 + u; return bFd == 1 ? bI0 + v : bI1 - v; }
	int CJ(int u, int v) { if (bFd < 2) return bJ0 + u; return bFd == 3 ? bJ0 + v : bJ1 - v; }
	int AtUV(int u, int v) { return At(CI(u, v), CJ(u, v)); }
	void RectUV(int r, int u0, int v0, int u1, int v1)
	{
		for (int v = min(v0, v1); v <= max(v0, v1); v++) for (int u = min(u0, u1); u <= max(u0, u1); u++) Claim(r, CI(u, v), CJ(u, v));
	}
	bool LinkUV(int u1, int v1, int u2, int v2, int kind) { return Link(CI(u1, v1), CJ(u1, v1), CI(u2, v2), CJ(u2, v2), kind); }
	void ShutUV(int u0, int v0, int u1, int v1, String tex)
	{
		for (int v = v0; v <= v1; v++) for (int u = u0; u <= u1; u++) if (InGrid(CI(u, v), CJ(u, v))) cellFac[CJ(u, v) * NX + CI(u, v)] = tex;
	}
	Vector2 CenterUV(int u, int v) { return CellCenter(CI(u, v), CJ(u, v)); }
	// the angle that looks from the street into the block (+v)
	double IntoAngle() { static const double a[] = { 180, 0, 270, 90 }; return a[bFd]; }
	bool MainWalkRow(int j) { return j == mainRow - 1 || j == mainRow + 2; }

	// ---------------------------------------------------------------- layout
	override void Layout()
	{
		sideCol.Clear(); blkI0.Clear(); blkJ0.Clear(); blkI1.Clear(); blkJ1.Clear();
		promR = -1; underR = -1; plazaDone = false; walkupEntry = false; alleys = 0;
		for (int i = 0; i < NX; i++) cellFac[ROW_WALL * NX + i] = WALL_TEX;      // the Wall closes the north
		bool prom = Chance(40);
		int south0 = prom ? 1 : 0;
		mainRow = Rand(5, 8);
		roadR = MakeRoom(S_ROAD);
		Rect(roadR, 0, mainRow, NX - 1, mainRow + 1);
		// side streets: none, one or two, far enough apart for a block between them
		int want = variant == V_CORNER ? Rand(1, 2) : Rand(0, 2);
		for (int t = 0; t < 40 && sideCol.Size() < want; t++)
		{
			int c = Rand(3, NX - 5);
			bool ok = true;
			for (int k = 0; k < sideCol.Size(); k++) if (abs(sideCol[k] - c) < 8) ok = false;
			if (ok) sideCol.Push(c);
		}
		for (int k = 0; k < sideCol.Size(); k++)
		{
			int c = sideCol[k];
			int ext = (variant == V_CORNER && k == 0) ? 2 : Rand(0, 2);        // 0 north, 1 south, 2 both
			if (ext != 1) Rect(roadR, c, mainRow + 2, c + 1, ROW_WALL - 1);
			if (ext != 0) Rect(roadR, c, south0, c + 1, mainRow - 1);
			if (ext != 1) AddEntry(CellCenter(c, ROW_WALL - 1) + (32, 0), 270, "the side street", EK_BACK, roadR);
			if (ext != 0) AddEntry(CellCenter(c, south0) + (32, 0), 90, "the bottom of the side street", EK_SERVICE, roadR);
		}
		if (prom)
		{
			promR = MakeRoom(S_PROM);
			for (int i = 0; i < NX; i++) if (At(i, 0) < 0) Claim(promR, i, 0);
			AddEntry(CellCenter(0, 0), 0, "the canal walk", EK_SERVICE, promR);
		}
		// sidewalks round every road cell (diagonals too, so the corners are paved)
		walkR = MakeRoom(S_WALK);
		for (int j = 0; j < ROW_WALL; j++)
			for (int i = 0; i < NX; i++)
			{
				if (At(i, j) != roadR) continue;
				for (int dj = -1; dj <= 1; dj++)
					for (int di = -1; di <= 1; di++)
						if (InGrid(i + di, j + dj) && j + dj < ROW_WALL && FreeCell(i + di, j + dj)) Claim(walkR, i + di, j + dj);
			}
		if (variant == V_UNDER)
		{
			// the elevated line runs over the main road: under it the road is covered, the side streets aren't
			underR = MakeRoom(S_UNDER);
			Rect(underR, 0, mainRow, NX - 1, mainRow + 1);
			rFacT[underR] = "CWVIADUC";
			LinkAll(underR, roadR, E_WIDE);
			LinkAll(underR, walkR, E_WIDE);
		}
		LinkAll(roadR, walkR, E_WIDE);
		if (promR >= 0) { LinkAll(promR, walkR, E_WIDE); LinkAll(promR, roadR, E_WIDE); }
		int mainR = underR >= 0 ? underR : roadR;
		AddEntry(CellCenter(0, mainRow) + (0, 32), 0, "the west end of the street", EK_FRONT, mainR);
		AddEntry(CellCenter(NX - 1, mainRow) + (0, 32), 180, "the east end of the street", EK_ANY, mainR);

		// the blocks: every free rectangle left over
		for (int j = 0; j < ROW_WALL; j++)
			for (int i = 0; i < NX; i++)
			{
				if (!FreeCell(i, j) || InBlock(i, j)) continue;
				int i1 = i; while (i1 + 1 < NX && FreeCell(i1 + 1, j) && !InBlock(i1 + 1, j)) i1++;
				int j1 = j;
				while (j1 + 1 < ROW_WALL)
				{
					bool ok = true;
					for (int x = i; x <= i1 && ok; x++) if (!FreeCell(x, j1 + 1) || InBlock(x, j1 + 1)) ok = false;
					if (!ok) break;
					j1++;
				}
				blkI0.Push(i); blkJ0.Push(j); blkI1.Push(i1); blkJ1.Push(j1);
			}
		// the landmark goes in the widest block north of the main road
		int land = -1, lw = 0;
		if (variant == V_TOWER || variant == V_LOT)
			for (int b = 0; b < blkI0.Size(); b++)
			{
				int w = blkI1[b] - blkI0[b] + 1, d = blkJ1[b] - blkJ0[b] + 1;
				if (blkJ0[b] == mainRow + 3 && d >= (variant == V_TOWER ? 5 : 4) && w >= 6 && w > lw) { land = b; lw = w; }
			}
		for (int b = 0; b < blkI0.Size(); b++) FillBlock(b, b == land);
		if (variant == V_CORNER) Hangout();
	}
	bool InBlock(int i, int j)
	{
		for (int b = 0; b < blkI0.Size(); b++) if (i >= blkI0[b] && i <= blkI1[b] && j >= blkJ0[b] && j <= blkJ1[b]) return true;
		return false;
	}

	// which side of the box faces its best street: the main road over a side street over the canal walk
	int Frontage(int i0, int j0, int i1, int j1)
	{
		int best = -1, bs = 0;
		for (int d = 0; d < 4; d++)
		{
			int sc = 0;
			int n = d < 2 ? j1 - j0 + 1 : i1 - i0 + 1;
			for (int k = 0; k < n; k++)
			{
				int i = d == 0 ? i1 + 1 : (d == 1 ? i0 - 1 : i0 + k);
				int j = d == 2 ? j1 + 1 : (d == 3 ? j0 - 1 : j0 + k);
				int r = At(i, j);
				if (r == walkR) sc += MainWalkRow(j) && d >= 2 ? 4 : 2;
				else if (r >= 0 && r == promR) sc += 1;
			}
			if (sc > bs) { bs = sc; best = d; }
		}
		return best;
	}

	void FillBlock(int b, bool landmark)
	{
		bI0 = blkI0[b]; bJ0 = blkJ0[b]; bI1 = blkI1[b]; bJ1 = blkJ1[b];
		bFd = Frontage(bI0, bJ0, bI1, bJ1);
		if (bFd < 0)
		{
			// no street at all: a closed building
			for (int j = bJ0; j <= bJ1; j++) for (int i = bI0; i <= bI1; i++) cellFac[j * NX + i] = FRONTS[Rand(0, FRONTS.Size() - 1)];
			return;
		}
		bW = bFd >= 2 ? bI1 - bI0 + 1 : bJ1 - bJ0 + 1;
		bD = bFd >= 2 ? bJ1 - bJ0 + 1 : bI1 - bI0 + 1;
		// a deep block gets an alley behind the parcels on the street
		int df = bD, alley = -1;
		int need = landmark ? (variant == V_TOWER ? 5 : 4) : 0;
		if (bD >= 7) df = Rand(3, min(5, bD - 3));
		if (df < need) df = bD - need - 1 >= 2 ? need : bD;
		if (df < bD)
		{
			alley = MakeRoom(S_ALLEY);
			RectUV(alley, 0, df, bW - 1, df);
			LinkAll(alley, walkR, E_WIDE);
			if (promR >= 0) LinkAll(alley, promR, E_WIDE);
			if (alleys++ < 2) AddEntry(CenterUV(0, df), IntoAngle() + (bFd >= 2 ? 90 : -90), "the alley", EK_BACK, alley);
		}
		// an alley shut in at both ends needs a way through from the street
		int through = -1;
		if (alley >= 0)
		{
			int e0 = AtUV(-1, df), e1 = AtUV(bW, df);
			if (!(e0 == walkR || (e0 >= 0 && e0 == promR) || e1 == walkR || (e1 >= 0 && e1 == promR))) through = Rand(1, max(1, bW - 2));
		}
		int landU = -1, landW = 0;
		if (landmark) { landW = 5; landU = Rand(1, max(1, bW - landW - 1)); }
		if (through >= landU && through < landU + landW) through = landU + landW < bW ? landU + landW : max(0, landU - 1);
		int u = 0;
		while (u < bW)
		{
			if (u == landU) { Landmark(u, df, alley); u += landW; continue; }
			if (u == through) { Alleyway(u, df, alley); u++; continue; }
			int left = bW - u;
			int w = min(Rand(2, 5), left);
			if (left - w == 1) w = w < 5 ? w + 1 : w - 1;
			if (landU > u && u + w > landU) w = landU - u;
			if (through > u && u + w > through) w = through - u;
			Parcel(u, max(1, w), df, alley);
			u += max(1, w);
		}
		if (alley >= 0) RearParcels(df + 1, bD - 1, alley);
	}

	// ---------------------------------------------------------------- parcels on the street
	void Parcel(int u, int w, int d, int alley)
	{
		String front = FRONTS[Rand(0, FRONTS.Size() - 1)];
		if (w == 1)
		{
			if (Chance(55)) Alleyway(u, d, alley); else ShutUV(u, 0, u, d - 1, front);
			return;
		}
		bool onMain = bFd >= 2 && MainWalkRow(CJ(u, -1));
		int roll = Rand(0, 99);
		if (variant == V_CORNER) roll = roll * 2 / 3 + 33;      // the corner-store street: mostly shops
		if (roll < 12) ShutUV(u, 0, u + w - 1, d - 1, Chance(30) ? "CWPLANK" : front);
		else if (roll < 20 && onMain && w >= 3 && !plazaDone) Plaza(u, w, d, alley);
		else if (roll < 31 && w >= 3) Parking(u, w, d, alley);
		else if (roll < 38) Vacant(u, w, d, alley);
		else if (roll < 47 && w >= 3 && d >= 3) AutoShop(u, w, d, alley, front);
		else if (roll < 62 && w >= 3 && d >= 3) WalkUp(u, w, d, alley, front);
		else Shop(u, w, d, alley, front);
	}

	// the one way out of a building at the back: onto the alley, or else a side door onto open ground beside it
	void BackOrSideDoor(int u, int w, int d, int alley)
	{
		if (alley >= 0 && Chance(70))
		{
			int bu = u + Rand(0, w - 1);
			LinkUV(bu, d - 1, bu, d, E_DOOR);
			return;
		}
		if (!Chance(45)) return;
		for (int s = 0; s < 2; s++)
		{
			int su = s == 0 ? u - 1 : u + w, iu = s == 0 ? u : u + w - 1;
			int v = Rand(min(1, d - 1), d - 1);
			int o = AtUV(su, v);
			if (IsOut(o) && o != roadR && AtUV(iu, v) >= 0) { LinkUV(iu, v, su, v, E_DOOR); return; }
		}
	}

	void Shop(int u, int w, int d, int alley, String front)
	{
		static const int SHOPS[] = { S_BODEGA, S_LAUNDROMAT, S_CHECKS, S_TAKEOUT, S_BARBER, S_BAR, S_PAWN, S_BOARDED, S_BODEGA, S_BOARDED };
		int t = SHOPS[Rand(0, SHOPS.Size() - 1)];
		int fd = d <= 2 ? d : (d >= 5 ? 3 : 2);
		int shop = MakeRoom(t);
		RectUV(shop, u, 0, u + w - 1, fd - 1);
		rFacT[shop] = t == S_BOARDED ? "CWPLANK" : front;
		int du = u + (w - 1) / 2 + (w % 2 == 0 ? Rand(0, 1) : 0);
		LinkUV(du, 0, du, -1, t == S_BOARDED && Chance(50) ? E_ARCH : E_DOOR);
		if (d > fd)
		{
			if (w >= 4 && Chance(60))
			{
				int a = Rand(2, w - 2);
				int b1 = MakeRoom(S_STORE), b2 = MakeRoom(Chance(50) ? S_OFFICE : S_STORE);
				RectUV(b1, u, fd, u + a - 1, d - 1); RectUV(b2, u + a, fd, u + w - 1, d - 1);
				LinkRooms(b1, shop, E_DOOR);
				LinkRooms(b2, Chance(50) ? shop : b1, E_DOOR);
				rFacT[b1] = rFacT[shop]; rFacT[b2] = rFacT[shop];
			}
			else
			{
				int b1 = MakeRoom(S_STORE);
				RectUV(b1, u, fd, u + w - 1, d - 1);
				LinkRooms(b1, shop, Chance(40) ? E_ARCH : E_DOOR);
				rFacT[b1] = rFacT[shop];
			}
		}
		BackOrSideDoor(u, w, d, alley);
	}

	// a walk-up: the stair hall to the flats upstairs (its front door on the street), the ground-floor flat off it
	void WalkUp(int u, int w, int d, int alley, String front)
	{
		bool east = Chance(50);
		int hu = east ? u + w - 1 : u;
		int f0 = east ? u : u + 1, f1 = east ? u + w - 2 : u + w - 1;
		int hall = MakeRoom(S_HALL); RectUV(hall, hu, 0, hu, d - 1);
		int ld = d >= 4 ? 2 : d - 1;
		int flat = MakeRoom(S_FLAT); RectUV(flat, f0, 0, f1, ld - 1);
		int bed = MakeRoom(S_FBED); RectUV(bed, f0, ld, f1, d - 1);
		LinkUV(hu, 0, hu, -1, E_DOOR);
		int hv = Rand(0, ld - 1);
		LinkUV(hu, hv, east ? hu - 1 : hu + 1, hv, E_DOOR);
		LinkRooms(flat, bed, E_DOOR);
		if (alley >= 0 && Chance(50)) LinkUV(hu, d - 1, hu, d, E_DOOR);
		rFacT[hall] = front; rFacT[flat] = front; rFacT[bed] = front;
		if (!walkupEntry) { walkupEntry = true; AddEntry(CenterUV(hu, d - 1), IntoAngle() + 180, "the walk-up stairs", EK_ROOF, hall); }
	}

	// an auto shop: one big bay behind a roll-up door, an office in a back corner of a wide one
	void AutoShop(int u, int w, int d, int alley, String front)
	{
		int bay = MakeRoom(S_AUTO);
		RectUV(bay, u, 0, u + w - 1, d - 1);
		rFacT[bay] = Chance(50) ? "SHAWN02" : front;
		if (w >= 4 && d >= 3)
		{
			int off = MakeRoom(S_OFFICE); rName[off] = "the shop office";
			bool left = Chance(50);
			RectUV(off, left ? u : u + w - 2, d - 2, left ? u + 1 : u + w - 1, d - 1);
			LinkRooms(off, bay, E_DOOR);
			rFacT[off] = rFacT[bay];
		}
		int gu = u + Rand(0, w - 1);
		LinkUV(gu, 0, gu, -1, E_WIDE);             // the roll-up door, up
		BackOrSideDoor(u, w, d, alley);
	}

	void Parking(int u, int w, int d, int alley)
	{
		int pk = MakeRoom(S_PARKING);
		RectUV(pk, u, 0, u + w - 1, d - 1);
		LinkAll(pk, walkR, E_FENCE);
		int gu = u + Rand(0, w - 1);
		LinkUV(gu, 0, gu, -1, E_WIDE);
		if (alley >= 0) LinkAll(pk, alley, E_WIDE);
	}

	void Vacant(int u, int w, int d, int alley)
	{
		int lot = MakeRoom(S_VACANT);
		RectUV(lot, u, 0, u + w - 1, d - 1);
		LinkAll(lot, walkR, E_FENCE);
		int gu = u + Rand(0, w - 1);
		LinkUV(gu, 0, gu, -1, E_WIDE);             // where the fence is down
		if (alley >= 0) { LinkAll(lot, alley, E_FENCE); int bu = u + Rand(0, w - 1); LinkUV(bu, d - 1, bu, d, E_WIDE); }
	}

	void Plaza(int u, int w, int d, int alley)
	{
		plazaDone = true;
		int sq = MakeRoom(S_PLAZA);
		RectUV(sq, u, 0, u + w - 1, d - 1);
		LinkAll(sq, walkR, E_WIDE);
		if (alley >= 0) LinkAll(sq, alley, E_WIDE);
	}

	void Alleyway(int u, int d, int alley)
	{
		int aw = MakeRoom(S_ALLEY); rName[aw] = "an alleyway";
		RectUV(aw, u, 0, u, d - 1);
		LinkUV(u, 0, u, -1, E_WIDE);
		if (alley >= 0) LinkAll(aw, alley, E_WIDE);
	}

	// ---------------------------------------------------------------- the variant's landmark (5 wide)
	void Landmark(int u, int d, int alley)
	{
		if (variant == V_TOWER) TowerBase(u, d, alley);
		else ChopLot(u, d, alley);
	}

	// The base of a tower: a fenced courtyard on the street, the lobby behind it, the lifts and the stairs.
	void TowerBase(int u, int d, int alley)
	{
		int court = MakeRoom(S_COURT); RectUV(court, u, 0, u + 4, 1);
		LinkAll(court, walkR, E_FENCE);
		LinkUV(u + 2, 0, u + 2, -1, E_WIDE);                          // the gate
		int stair = MakeRoom(S_TSTAIR); RectUV(stair, u, 2, u, 4);
		int lobby = MakeRoom(S_LOBBY); RectUV(lobby, u + 1, 2, u + 4, 3);
		int lifts = MakeRoom(S_LIFTS); RectUV(lifts, u + 1, 4, u + 3, 4);
		int sup = MakeRoom(S_SUPER); RectUV(sup, u + 4, 4, u + 4, 4);
		LinkUV(u + 2, 1, u + 2, 2, E_DOOR);                           // the front door
		LinkRooms(lobby, stair, E_DOOR);
		LinkAll(lifts, lobby, E_WIDE);
		LinkRooms(sup, lobby, E_DOOR);
		if (alley >= 0 && d == 5) LinkUV(u, 4, u, 5, E_DOOR);         // the fire door from the stairs
		if (d > 5) ShutUV(u, 5, u + 4, d - 1, "ADBRICK");             // the rest of the tower's footprint
		for (int r = stair; r <= sup; r++) rFacT[r] = "ADBRICK";
		AddEntry(CenterUV(u, 3), IntoAngle(), "the tower stairs", EK_ROOF, stair);
	}

	// A chop shop: a chain-link car lot on the street, the garage behind it, an office on the corner.
	void ChopLot(int u, int d, int alley)
	{
		int lot = MakeRoom(S_LOT); RectUV(lot, u, 0, u + 3, 1);
		LinkAll(lot, walkR, E_FENCE);
		LinkUV(u + 1, 0, u + 1, -1, E_WIDE); LinkUV(u + 2, 0, u + 2, -1, E_WIDE);   // the gate
		int gar = MakeRoom(S_GARAGE); RectUV(gar, u, 2, u + 3, d - 1);
		LinkUV(u + 1, 1, u + 1, 2, E_WIDE); LinkUV(u + 2, 1, u + 2, 2, E_WIDE);     // the roll-up doors
		int off = MakeRoom(S_OFFICE); RectUV(off, u + 4, 0, u + 4, d - 1);
		LinkUV(u + 4, 0, u + 4, -1, E_DOOR);
		LinkRooms(off, gar, E_DOOR);
		if (alley >= 0) LinkUV(u, d - 1, u, d, E_DOOR);
		rFacT[gar] = "SHAWN02"; rFacT[off] = "SHAWN02";
	}

	// ---------------------------------------------------------------- behind the alley
	void RearParcels(int v0, int v1, int alley)
	{
		int u = 0;
		while (u < bW)
		{
			int left = bW - u;
			int w = min(Rand(2, 4), left);
			if (left - w == 1) w = w < 4 ? w + 1 : w - 1;
			w = max(1, min(w, left));
			int roll = Rand(0, 99);
			String front = FRONTS[Rand(0, FRONTS.Size() - 1)];
			if (roll < 30 && w >= 2)
			{
				int y = MakeRoom(S_YARD); RectUV(y, u, v0, u + w - 1, v1);
				LinkAll(y, alley, E_FENCE);
				int gu = u + Rand(0, w - 1);
				LinkUV(gu, v0, gu, v0 - 1, E_WIDE);
			}
			else if (roll < 50 && w >= 2)
			{
				int g = MakeRoom(S_AUTO); rName[g] = "a lock-up garage";
				RectUV(g, u, v0, u + w - 1, v1);
				int gu = u + Rand(0, w - 1);
				LinkUV(gu, v0, gu, v0 - 1, E_WIDE);
				rFacT[g] = front;
			}
			else ShutUV(u, v0, u + w - 1, v1, front);
			u += w;
		}
	}

	// the crew's back room behind one of the shops
	void Hangout()
	{
		Array<int> pool;
		for (int r = 0; r < rtype.Size(); r++) if (IsType(r, S_STORE) && CellCount(r)) pool.Push(r);
		if (!pool.Size()) return;
		int r = pool[Rand(0, pool.Size() - 1)];
		int tmp = MakeRoom(S_HANGOUT);
		rtype[r] = S_HANGOUT; rflags[r] = rflags[tmp]; rLight[r] = rLight[tmp]; rName[r] = rName[tmp];
		rFloorT[r] = rFloorT[tmp]; rWallT[r] = rWallT[tmp];
		rtype.Pop(); rflags.Pop(); rF.Pop(); rC.Pop(); rLight.Pop();
		rFloorT.Pop(); rCeilT.Pop(); rWallT.Pop(); rFacT.Pop(); rName.Pop();
	}

	// ---------------------------------------------------------------- objectives, light, dressing
	override int ObjScore(int r, int k)
	{
		if (IsOut(r) || IsType(r, S_UNDER)) return 0;
		if (k == OBJ_STEAL && (IsType(r, S_HANGOUT) || IsType(r, S_OFFICE) || IsType(r, S_CHECKS) || IsType(r, S_SUPER) || IsType(r, S_PAWN))) return 160;
		if (k == OBJ_DESTROY && (IsType(r, S_GARAGE) || IsType(r, S_HANGOUT) || IsType(r, S_AUTO))) return 160;
		if (k == OBJ_TURN && (IsType(r, S_BARBER) || IsType(r, S_SUPER) || IsType(r, S_BAR))) return 140;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case S_BODEGA: case S_LAUNDROMAT: case S_CHECKS: case S_TAKEOUT: case S_BARBER: case S_PAWN: case S_LOBBY: case S_LIFTS: return 0;
		case S_GARAGE: case S_AUTO: case S_STORE: case S_HANGOUT: case S_TSTAIR: case S_HALL: case S_UNDER: return 2;
		case S_OFFICE: case S_SUPER: case S_BAR: case S_FLAT: case S_FBED: return 1;
		}
		return 3;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case S_ALLEY:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				int d0 = Rand(0, 3);
				Class<Actor> what = null;
				if (roll < 25) what = "CW_FDumpster";
				else if (roll < 40) what = "CW_FPallet";
				else if (roll < 52) what = "CW_FScrap";
				if (what) for (int t = 0; t < 4; t++) if (PutWall(what, ci[k], cj[k], (d0 + t) % 4, Rand(-40, 40))) break;
			}
			break;
		case S_WALK:
			// street furniture against the building fronts: bins, benches, planters, junk, a scaffold now and then
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				Class<Actor> what = null;
				if (roll < 14) what = "CW_FBin";
				else if (roll < 22) what = "CW_FPew";
				else if (roll < 28) what = "CW_FPlanter";
				else if (roll < 34) what = "CW_FPallet";
				else if (roll < 40) what = "CW_FCrates";
				else if (roll < 45) what = "CW_FScrap";
				else if (roll < 48) what = "CW_FScaffold";
				else if (roll < 53) what = "CW_FDumpster";
				if (!what) continue;
				int d0 = Rand(0, 3);
				for (int t = 0; t < 4; t++) if (PutWall(what, ci[k], cj[k], (d0 + t) % 4, Rand(-30, 30))) break;
			}
			break;
		case S_ROAD:
			// a wreck now and then, and barriers where someone blocked the road
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				Vector2 c = CellCenter(ci[k], cj[k]);
				if (roll < 4) Car(c + (Rand(-20, 20), Rand(-20, 20)), Rand(0, 359), "ModernCarDirtyGreen");
				else if (roll < 9) Put("CW_FBarrier", c + (Rand(-30, 30), Rand(-30, 30)), Rand(0, 1) * 90 + Rand(-15, 15));
				else if (roll < 13) Put("CW_FScrap", c + (Rand(-30, 30), Rand(-30, 30)), Rand(0, 359));
			}
			break;
		case S_PROM:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 20) PutWall("CW_FPew", ci[k], cj[k], 3, Rand(-30, 30));
				else if (roll < 32) PutWall("CW_FBin", ci[k], cj[k], 3, Rand(-40, 40));
			}
			break;
		case S_PLAZA: case S_COURT:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 22) PutInCell("CW_FPew", ci[k], cj[k], 90 * Rand(0, 1));
				else if (roll < 36) PutInCell("CW_FPlanter", ci[k], cj[k]);
				else if (roll < 46) PutInCell("CW_FBin", ci[k], cj[k]);
				else if (roll < 52 && rtype[r] == S_PLAZA) PutInCell("CW_FStall", ci[k], cj[k], 90 * Rand(0, 3));
			}
			break;
		case S_PLAY:
			PutInRoom("CW_FScaffold", r, 0);          // what's left of the climbing frame
			for (int k = 0; k < ci.Size(); k++) if (Chance(35)) PutInCell(Chance(50) ? "CW_FPew" : "CW_FScrap", ci[k], cj[k], 90 * Rand(0, 1));
			break;
		case S_LOT:
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) Car(CellCenter(ci[k], cj[k]), 90 * Rand(0, 3), Chance(50) ? "ModernCarDirtyGreen" : "");
			LineWalls("CW_FScrap", r, 160, 3);
			break;
		case S_PARKING:
			for (int k = 0; k < ci.Size(); k++) if (Chance(55)) Car(CellCenter(ci[k], cj[k]), Chance(50) ? 90 : 270);
			if (ci.Size()) PoleLight(CellCenter(ci[0], cj[0]), 300);
			break;
		case S_VACANT: case S_YARD:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 25) PutInCell("CW_FScrap", ci[k], cj[k], 90 * Rand(0, 3));
				else if (roll < 38) PutInCell("CW_FPallet", ci[k], cj[k], 90 * Rand(0, 3));
				else if (roll < 46 && rtype[r] == S_VACANT) Car(CellCenter(ci[k], cj[k]), Rand(0, 359), "ModernCarDirtyGreen");
				else if (roll < 54) PutInCell("CW_FBin", ci[k], cj[k]);
			}
			break;
		case S_UNDER:
			for (int k = 0; k < ci.Size(); k++)
			{
				if (cj[k] == mainRow && ci[k] % 4 == 1) PutInCell("CW_FBarrier", ci[k], cj[k], 0);   // the el's footings
				else if (Chance(30)) PutInCell("CW_FStall", ci[k], cj[k], 90 * Rand(0, 3));
			}
			break;
		case S_LOBBY:
			LineWalls("CW_FPlanter", r, 160, 2); LineWalls("CW_FBin", r, 160, 1); PutInRoom("CW_FReception", r);
			break;
		case S_LIFTS:
			LineWalls("CW_FBin", r, 200, 1);
			break;
		case S_SUPER: case S_OFFICE:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FFileCabinet", r, 60, 3); if (Chance(50)) LineWalls("CW_FWallTV", r, 120, 1);
			break;
		case S_BODEGA:
			LineWalls("CW_FShelving", r, 80, 6); PutInRoom("CW_FCounter", r, 90); LineWalls("CW_FVending", r, 120, 1);
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutInCell("CW_FShelving", ci[k], cj[k], 90 * Rand(0, 1));
			break;
		case S_LAUNDROMAT:
			LineWalls("CW_FCounter", r, 70, 8); PutInRoom("CW_FPew", r, 0);
			break;
		case S_CHECKS: case S_PAWN:
			LineWalls("CW_FCounter", r, 110, 3); LineWalls("CW_FShelving", r, 90, 3); LineWalls("CW_FFileCabinet", r, 60, 2);
			break;
		case S_TAKEOUT:
			LineWalls("CW_FCounter", r, 110, 2);
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) { PutInCell("CW_FRoundTable", ci[k], cj[k]); PutInCell("CW_FStool", ci[k], cj[k]); }
			break;
		case S_BAR:
			LineWalls("CW_FBarCounter", r, 120, 2); LineWalls("CW_FStool", r, 60, 5);
			for (int k = 0; k < ci.Size(); k++) if (Chance(55)) PutInCell("CW_FRoundTable", ci[k], cj[k]);
			break;
		case S_BARBER:
			LineWalls("CW_FVanity", r, 80, 4); LineWalls("CW_FChair", r, 80, 4); PutInRoom("CW_FPew", r, 0);
			break;
		case S_BOARDED:
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutInCell(Chance(50) ? "CW_FScrap" : "CW_FCrates", ci[k], cj[k], 90 * Rand(0, 3));
			break;
		case S_STORE:
			LineWalls("CW_FShelving", r, 90, 4);
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell(Chance(50) ? "CW_FCrates" : "CW_FPallet", ci[k], cj[k]);
			break;
		case S_HANGOUT:
			LineWalls("CW_FSofa", r, 140, 2); PutInRoom("CW_FRoundTable", r); LineWalls("CW_FWallTV", r, 160, 1); LineWalls("CW_FCrates", r, 120, 2);
			break;
		case S_HALL:
			LineWalls("CW_FBin", r, 200, 1);
			break;
		case S_FLAT:
			LineWalls("CW_FSofa", r, 140, 1); PutInRoom("CW_FCoffeeTable", r); LineWalls("CW_FWallTV", r, 200, 1);
			LineWalls("CW_FCounter", r, 110, 2); if (Chance(60)) PutInRoom("CW_FRoundTable", r);
			break;
		case S_FBED:
			LineWalls("CW_FBed", r, 220, 1); LineWalls("CW_FCredenza", r, 150, 1); if (ci.Size() >= 3) LineWalls("CW_FBed", r, 220, 1);
			break;
		case S_GARAGE: case S_AUTO:
			for (int k = 0; k < ci.Size(); k++) if (Chance(35)) Car(CellCenter(ci[k], cj[k]), 90 * Rand(0, 3), Chance(40) ? "ModernCarDirtyGreen" : "");
			LineWalls("CW_FWorkbench", r, 140, 3); LineWalls("CW_FLocker", r, 160, 2); LineWalls("CW_FScrap", r, 200, 2);
			break;
		}
	}

	override void Outdoors()
	{
		// street lamps on the kerbs, every other sidewalk cell along a road
		for (int j = 0; j < ROW_WALL; j++)
			for (int i = 0; i < NX; i++)
			{
				if (At(i, j) != walkR || (i + j) % 2) continue;
				for (int d = 0; d < 4; d++)
				{
					int o = At(i + DX[d], j + DY[d]);
					if (o != roadR && (o < 0 || o != underR)) continue;
					PoleLight(CellCenter(i, j) + (DX[d], DY[d]) * 46, 320);
					break;
				}
			}
		// fill light down the middle of the roads, so there are no black gaps between the lamps
		for (int j = 0; j < ROW_WALL; j++)
			for (int i = 0; i < NX; i++)
				if (At(i, j) == roadR && (i % 3 == 0) && (j % 3 == 0)) NBC_LightSource.Make((CellCenter(i, j), 160), 200, 180, 150, 280);
		// parked cars along both kerbs of the main road, and down one side of each side street
		if (underR < 0)
			for (int i = 0; i < NX; i += 2)
			{
				if (OnSideStreet(i)) continue;
				if (Chance(55)) Car((colX[i] + 64 + Rand(-20, 20), rowY[mainRow] + 44), 0);
				if (Chance(55)) Car((colX[i] + 64 + Rand(-20, 20), rowY[mainRow + 1] + rowh[mainRow + 1] - 44), 180);
			}
		for (int k = 0; k < sideCol.Size(); k++)
			for (int j = 0; j < ROW_WALL; j += 2)
				if (At(sideCol[k], j) == roadR && abs(j - mainRow) > 2 && Chance(50)) Car((colX[sideCol[k]] + 44, rowY[j] + 64), Chance(50) ? 90 : 270);
		// lights over the alleys and the canal walk, floodlights on the Wall
		for (int j = 0; j < ROW_WALL; j++)
			for (int i = 0; i < NX; i++)
			{
				int r = At(i, j);
				if (r < 0 || (i + j) % 3) continue;
				if (IsType(r, S_ALLEY) || IsType(r, S_YARD)) NBC_LightSource.Make((CellCenter(i, j), 96), 255, 170, 90, 220);
				else if (r == promR && i % 2 == 0) PoleLight(CellCenter(i, j) + (0, -46), 300);
				else if (IsType(r, S_PLAZA) || IsType(r, S_COURT) || IsType(r, S_VACANT)) PoleLight(CellCenter(i, j), 300);
			}
		for (int i = 1; i < NX; i += 3) NBC_LightSource.Make((colX[i] + 64, rowY[ROW_WALL] - 24, 200), 220, 230, 255, 260);
		if (underR >= 0)
			for (int i = 1; i < NX; i += 2) NBC_LightSource.Make((colX[i] + 64, rowY[mainRow] + 136, 150), 255, 190, 120, 200);
	}
	bool OnSideStreet(int i)
	{
		for (int k = 0; k < sideCol.Size(); k++) if (i >= sideCol[k] - 1 && i <= sideCol[k] + 2) return true;
		return false;
	}
}
