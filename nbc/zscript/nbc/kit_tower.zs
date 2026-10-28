// The tower floor (PLAN.md §4.4, §6.7, M2c): one storey of a brick housing tower in the Bricks.
//
// Template NBC_KT (tools/make_kit_maps.py): 14 columns (a stair core of 192 at each end, 12 flat bays of 176)
// by 5 rows (south windows 176, south inner 128, corridor 96, north inner 128, north windows 176).
// Real scale against the 56-unit people (PLAN.md §4.4): bays 4.8 m, ceilings 88 (2.8 m), 104 in the penthouse,
// doors 68 x 48. Flats are two bays or more, so no room is a cupboard.
//
//   row 4  N window rooms: living rooms, bedrooms (windows onto the city)    trash chute | laundry
//   row 3  N inner rooms: hall, kitchen, bathroom                             lift lobby  (cols 6-7)
//   row 2  the corridor, a scissor stair at each end (cols 0 and 13, rows 1-3)
//   row 1  S inner rooms
//   row 0  S window rooms
//
// The gallery variant turns the south side into an open-air deck: row 0 is the drop (a railing and the
// city beyond), row 1 the walkway, and the flats run three rows deep behind it.
//
// Variants: an occupied floor, a gallery floor, a gang floor (knocked-through flats, barricades, stash,
// cook, count and lookout flats), a burned-out floor (half of it gutted by fire), and a penthouse floor.
class NBC_KitTower : NBC_KitGen
{
	enum EVar { V_OCCUPIED, V_GALLERY, V_GANG, V_GUTTED, V_PENTHOUSE, V_COUNT }
	enum ERoom
	{
		T_CORR, T_STAIR, T_LOBBY, T_CHUTE, T_LAUNDRY, T_METER, T_HALL, T_LIVING, T_KITCHEN, T_BED, T_BATH,
		T_GALLERY, T_DROP, T_SQUAT, T_STASH, T_COOK, T_COUNTING, T_LOOKOUT, T_TRAP, T_BURNT, T_DOORMAN, T_STUDY
	}
	const COL_W = 0;
	const COL_E = 13;
	const LIFT = 6;             // the lift lobby takes columns LIFT and LIFT + 1 on the north side

	int corrW, corrE;           // the corridor, in two halves (so half a floor can burn)
	// the flats, in the order they were built: their rooms are the range [flatFirst, flatEnd)
	Array<int> flatFirst, flatEnd, flatLiving, flatC0, flatC1;
	Array<bool> flatSouth;
	int burnLo, burnHi;         // the gutted floor's burned columns

	override void Setup()
	{
		colw.Push(192);
		for (int i = 0; i < 12; i++) colw.Push(176);
		colw.Push(192);
		static const int RW[] = { 176, 128, 96, 128, 176 };
		for (int j = 0; j < RW.Size(); j++) rowh.Push(RW[j]);
		Grid(colw.Size(), rowh.Size());
		doorTex = "ADDOOR3"; jambTex = "ADGREY2"; edgeTex = "ADBRICK";
	}
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "occupied floor", "gallery floor", "gang floor", "burned-out floor", "penthouse floor" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 8, 7, 2, 3, 4 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	// the gallery deck and the drop beside it are open to the city
	override bool EdgeOpen(int r) { return IsOut(r); }
	// the gallery's rail: 1.1 m
	override double FenceH(int a, int b) { return 36; }
	// window rooms look out over the city; boarded up where the flat is burned, empty or a squat
	override String EdgeWall(int r)
	{
		switch (rtype[r])
		{
		case T_BURNT: case T_SQUAT: case T_STASH: case T_COOK: return "CWPLANK";
		case T_LIVING: case T_BED: case T_STUDY: case T_LOOKOUT: case T_TRAP: case T_COUNTING: case T_KITCHEN:
			return Has(r, RF_DARK) ? "CWPLANK" : "CWWINDO";
		}
		return rWallT[r];
	}

	int MakeRoom(int t)
	{
		bool lux = variant == V_PENTHOUSE;
		bool rough = variant == V_GANG || variant == V_GUTTED;
		String wall = lux ? "ADMARBL" : (rough ? "CWWALLD" : "CWWALL1");
		String carpet = lux ? "ADFMARB" : (rough ? "CWCONCF" : "CWCARP1");
		int flatC = lux ? 104 : 88;         // flat ceilings: 2.8 m, 3.3 m in the penthouse
		switch (t)
		{
		case T_CORR:     return Room(t, RF_PATROL | (rough ? RF_RUBBLE : 0), 0, 88, rough ? 104 : 136, lux ? "CWCARP2" : "CWCONCF", "CWCEILT", lux ? "ADGREYW" : (rough ? "CWWALLD" : "ADGREYW"), "the corridor");
		case T_STAIR:    return Room(t, RF_NOGUARD, 0, 96, 120, "CWSTAIF", "ADFLUOR", "ADGREY2", "the stairwell");
		case T_LOBBY:    return Room(t, RF_CIV, 0, lux ? 100 : 88, 152, lux ? "ADFMARB" : "CWTILEF", "CWCEILL", "CWELEVD", "the lift lobby");
		case T_CHUTE:    return Room(t, RF_RUBBLE, 0, flatC, 96, "CWCONCF", "ADFLUOR", "CWWALLD", "the trash chute");
		case T_LAUNDRY:  return Room(t, RF_CIV, 0, flatC, 144, "CWTILEF", "CWCEILT", "CWTILEW", "the laundry room");
		case T_METER:    return Room(t, RF_TECH, 0, flatC, 104, "CWCONCF", "ADFLUOR", "CWWALLD", "the meter room");
		case T_HALL:     return Room(t, 0, 0, flatC, 120, carpet, "CWCEILT", wall, "a hallway");
		case T_LIVING:   return Room(t, RF_CIV | RF_PEOPLE, 0, flatC, 136, carpet, "CWCEILT", wall, "a living room");
		case T_KITCHEN:  return Room(t, RF_CIV, 0, flatC, 152, "CWTILEF", "CWCEILT", "CWWALL2", "a kitchen");
		case T_BED:      return Room(t, RF_VALUE, 0, flatC, 112, carpet, "CWCEILT", wall, "a bedroom");
		case T_BATH:     return Room(t, 0, 0, flatC, 144, "CWTILEF", "CWCEILT", "CWTILEW", "a bathroom");
		case T_GALLERY:  return Room(t, RF_OUT | RF_PATROL | RF_CIV | RF_RUBBLE, 0, 0, 112, "CWCONCF", "F_SKY1", "ADBRICK", "the gallery");
		case T_DROP:     return Room(t, RF_OUT | RF_WATER | RF_NOGUARD, -768, 0, 112, "ADFCITY", "F_SKY1", "ADBRICK", "the drop");
		case T_SQUAT:    return Room(t, RF_DARK | RF_RUBBLE | RF_PATROL, 0, flatC, 80, "CWCONCF", "ADFLUOR", "CWWALLD", "a squat");
		case T_STASH:    return Room(t, RF_VALUE | RF_PATROL, 0, flatC, 96, "CWCONCF", "ADFLUOR", "CWWALLD", "the stash flat");
		case T_COOK:     return Room(t, RF_TECH | RF_PATROL | RF_RUBBLE, 0, flatC, 112, "CWTILEF", "ADFLUOR", "CWWALLD", "the cook flat");
		case T_COUNTING: return Room(t, RF_VALUE | RF_PEOPLE, 0, flatC, 128, "CWCARP1", "CWCEILT", "CWWALL1", "the counting room");
		case T_LOOKOUT:  return Room(t, RF_PEOPLE | RF_PATROL, 0, flatC, 96, "CWCONCF", "ADFLUOR", "CWWALLD", "the lookout");
		case T_TRAP:     return Room(t, RF_PEOPLE | RF_PATROL | RF_RUBBLE, 0, flatC, 104, "CWCARP1", "CWCEILT", "CWWALLD", "the trap house");
		case T_BURNT:    return Room(t, RF_DARK | RF_RUBBLE | RF_PATROL, 0, flatC, 64, "CWCONCF", "ADFLUOR", "CWWALLD", "a burned-out flat");
		case T_DOORMAN:  return Room(t, RF_PEOPLE | RF_PATROL, 0, 100, 168, "ADFMARB", "CWCEILT", "ADMARBL", "the doorman's desk");
		case T_STUDY:    return Room(t, RF_VALUE | RF_PEOPLE, 0, flatC, 136, "CWCARP2", "CWCEILT", "ADMARBL", "the study");
		}
		return Room(t, 0, 0, flatC, 128, carpet, "CWCEILT", wall, "a room");
	}

	// Turn a room into another type in place (its cells and links stay).
	void Recast(int r, int t)
	{
		int tmp = MakeRoom(t);
		rtype[r] = t; rflags[r] = rflags[tmp]; rF[r] = rF[tmp]; rC[r] = rC[tmp]; rLight[r] = rLight[tmp];
		rFloorT[r] = rFloorT[tmp]; rCeilT[r] = rCeilT[tmp]; rWallT[r] = rWallT[tmp]; rName[r] = rName[tmp];
		// drop the template room again (it has no cells)
		rtype.Pop(); rflags.Pop(); rF.Pop(); rC.Pop(); rLight.Pop();
		rFloorT.Pop(); rCeilT.Pop(); rWallT.Pop(); rFacT.Pop(); rName.Pop();
	}

	// ---------------------------------------------------------------- layout
	override void Layout()
	{
		if (variant == V_GALLERY) { GalleryLayout(); return; }
		// the corridor, in two halves joined in the middle
		corrW = MakeRoom(T_CORR); Rect(corrW, 1, 2, LIFT, 2);
		corrE = MakeRoom(T_CORR); Rect(corrE, LIFT + 1, 2, NX - 2, 2);
		LinkAll(corrW, corrE, E_WIDE);
		Stairs(1, 3, 2, 2);
		// the lift lobby off the north side, the trash chute and the laundry (or meter room) behind it
		int lobby = MakeRoom(variant == V_PENTHOUSE ? T_DOORMAN : T_LOBBY);
		if (variant == V_PENTHOUSE) rName[lobby] = "the private lobby";
		Rect(lobby, LIFT, 3, LIFT + 1, 3);
		LinkAll(lobby, corrW, E_WIDE); LinkAll(lobby, corrE, E_WIDE);
		AddEntry(CellCenter(LIFT, 3) + (64, 24), 270, "the lift", EK_SERVICE, lobby);
		int chute = MakeRoom(T_CHUTE); Claim(chute, LIFT, 4); Link(LIFT, 4, LIFT, 3, E_DOOR);
		int util = MakeRoom(variant == V_OCCUPIED ? T_LAUNDRY : T_METER); Claim(util, LIFT + 1, 4); Link(LIFT + 1, 4, LIFT + 1, 3, E_DOOR);
		// the flats
		FillSide(true, 1, NX - 2, 0, 1);
		FillSide(false, 1, LIFT - 1, 4, 3);
		FillSide(false, LIFT + 2, NX - 2, 4, 3);
		switch (variant)
		{
		case V_OCCUPIED: Occupied(); break;
		case V_GANG: GangFloor(); break;
		case V_GUTTED: Gutted(); break;
		case V_PENTHOUSE: break;
		}
	}

	// Scissor stairs in both end columns over rows [j0, j1], entered on row jc; a door from each onto the
	// corridor on row doorRow (-1: the caller links them itself).
	void Stairs(int j0, int j1, int jc, int doorRow)
	{
		int sw = MakeRoom(T_STAIR); rName[sw] = "the west stairs"; Rect(sw, COL_W, j0, COL_W, j1);
		int se = MakeRoom(T_STAIR); rName[se] = "the east stairs"; Rect(se, COL_E, j0, COL_E, j1);
		if (doorRow >= 0)
		{
			Link(COL_W, doorRow, COL_W + 1, doorRow, E_DOOR);
			Link(COL_E, doorRow, COL_E - 1, doorRow, E_DOOR);
		}
		AddEntry(CellCenter(COL_W, jc), 0, "the west stairs", EK_FRONT, sw);
		AddEntry(CellCenter(COL_E, jc), 180, "the east stairs", EK_BACK, se);
		AddEntry(CellCenter(COL_E, j1), 270, "the roof stairs", EK_ROOF, se);
		// the end cells beside the stair cores are solid brick
		for (int j = 0; j < NY; j++)
		{
			if (At(COL_W, j) < 0) cellFac[j * NX + COL_W] = "ADBRICK";
			if (At(COL_E, j) < 0) cellFac[j * NX + COL_E] = "ADBRICK";
		}
	}

	// how many bays a flat takes
	int FlatWidth()
	{
		switch (variant)
		{
		case V_PENTHOUSE: return Rand(4, 6);
		case V_GANG: case V_GUTTED: return Rand(2, 3);
		}
		int roll = Rand(0, 99);
		return roll < 45 ? 2 : (roll < 85 ? 3 : 4);
	}

	// Flats across columns c0..c1, window rooms on row `outer`, inner rooms (with the front doors) on `inner`.
	void FillSide(bool south, int c0, int c1, int outer, int inner)
	{
		int c = c0;
		while (c <= c1)
		{
			int left = c1 - c + 1;
			int w = min(FlatWidth(), left);
			if (left - w == 1) w = w < 4 ? w + 1 : w - 1;   // no one-bay leftovers next to a big flat
			w = clamp(w, 1, left);
			Flat(c, c + w - 1, outer, inner, south);
			c += w;
		}
	}

	// One flat. Inner row: bathroom, hall (the front door), kitchen; window row: bedrooms either side of the
	// living room. Small flats drop rooms: a one-bay studio is a kitchenette and one room.
	void Flat(int c0, int c1, int outer, int inner, bool south)
	{
		int w = c1 - c0 + 1;
		bool flip = Chance(50);
		int first = rtype.Size();
		int living;
		if (w == 1)
		{
			int kitch = MakeRoom(T_KITCHEN); rName[kitch] = "a kitchenette"; Claim(kitch, c0, inner);
			living = MakeRoom(T_LIVING); rName[living] = "a studio"; Claim(living, c0, outer);
			Link(c0, inner, c0, outer, E_ARCH);
			FrontDoor(c0, inner);
		}
		else if (w == 2)
		{
			int a = flip ? c1 : c0, b = flip ? c0 : c1;
			int hall = MakeRoom(T_HALL); Claim(hall, a, inner);
			int bath = MakeRoom(T_BATH); Claim(bath, b, inner);
			living = MakeRoom(T_LIVING); Claim(living, a, outer);
			int bed = MakeRoom(T_BED); Claim(bed, b, outer);
			Link(a, inner, a, outer, E_ARCH);
			Link(a, inner, b, inner, E_DOOR);
			Link(a, outer, b, outer, E_DOOR);
			FrontDoor(a, inner);
		}
		else
		{
			// bath | hall ... | kitchen  over  bed | living ... | bed
			int e0 = flip ? c1 : c0, e1 = flip ? c0 : c1;     // the two end columns
			int m0 = min(c0 + 1, c1 - 1), m1 = max(c0 + 1, c1 - 1);
			int bath = MakeRoom(T_BATH); Claim(bath, e0, inner);
			int hall = MakeRoom(T_HALL); Rect(hall, m0, inner, m1, inner);
			int kitch = MakeRoom(T_KITCHEN); Claim(kitch, e1, inner);
			int bed0 = MakeRoom(T_BED); Claim(bed0, e0, outer);
			living = MakeRoom(T_LIVING); Rect(living, m0, outer, m1, outer);
			int bed1 = MakeRoom(T_BED); Claim(bed1, e1, outer);
			LinkRooms(hall, bath, E_DOOR);
			LinkRooms(hall, kitch, w >= 4 ? E_WIDE : E_ARCH);
			LinkRooms(hall, living, E_ARCH);
			LinkRooms(living, bed0, E_DOOR);
			LinkRooms(living, bed1, E_DOOR);
			if (variant == V_PENTHOUSE) { rName[bed0] = "the master bedroom"; if (w >= 5) { Recast(bed1, T_STUDY); } }
			FrontDoor(flip ? m1 : m0, inner);
		}
		flatFirst.Push(first); flatEnd.Push(rtype.Size()); flatLiving.Push(living);
		flatC0.Push(c0); flatC1.Push(c1); flatSouth.Push(south);
	}

	// the flat's front door onto the corridor (or the gallery)
	void FrontDoor(int c, int inner)
	{
		int to = variant == V_GALLERY ? 1 : 2;
		Link(c, inner, c, to, E_DOOR);
	}

	bool FlatHas(int f, int r) { return r >= flatFirst[f] && r < flatEnd[f]; }
	void RecastFlat(int f, int t, String name = "")
	{
		for (int r = flatFirst[f]; r < flatEnd[f]; r++)
		{
			Recast(r, t);
			if (name.Length()) rName[r] = name;
		}
	}

	// ---------------------------------------------------------------- variants
	// lived in: one flat in six stands empty, one is a squat
	void Occupied()
	{
		for (int f = 0; f < flatFirst.Size(); f++)
		{
			int roll = Rand(0, 99);
			if (roll < 16)
			{
				for (int r = flatFirst[f]; r < flatEnd[f]; r++) { rflags[r] = (rflags[r] & ~(RF_CIV | RF_PEOPLE)) | RF_DARK; rName[r] = "an empty flat"; rLight[r] = 80; }
			}
			else if (roll < 24) RecastFlat(f, T_SQUAT);
		}
	}

	// held by the gang: the flats that matter, walls knocked through, front doors kicked in
	void GangFloor()
	{
		Array<int> order;
		for (int f = 0; f < flatFirst.Size(); f++) order.Push(f);
		for (int k = order.Size() - 1; k > 0; k--) { int q = Rand(0, k); int t = order[k]; order[k] = order[q]; order[q] = t; }
		static const int ROLES[] = { T_STASH, T_COOK, T_COUNTING, T_TRAP, T_TRAP, T_LOOKOUT };
		for (int k = 0; k < order.Size(); k++)
		{
			int f = order[k];
			if (k < ROLES.Size()) RecastFlat(f, ROLES[k]);
			else if (Chance(50)) RecastFlat(f, T_SQUAT);
		}
		// knocked through: holes between neighbouring flats on the same side
		for (int f = 0; f + 1 < flatFirst.Size(); f++)
		{
			if (flatSouth[f] != flatSouth[f + 1] || flatC1[f] + 1 != flatC0[f + 1] || !Chance(55)) continue;
			int row = flatSouth[f] ? 0 : 4;
			Link(flatC1[f], row, flatC0[f + 1], row, E_ARCH);
		}
		// kicked-in front doors become open doorways
		for (int k = 0; k < lI.Size(); k++)
		{
			if (lKind[k] != E_DOOR || lVert[k]) continue;
			int ra = At(lI[k], lJ[k]), rb = At(lI[k], lJ[k] + 1);
			if ((ra == corrW || ra == corrE || rb == corrW || rb == corrE) && Chance(40)) lKind[k] = E_ARCH;
		}
	}

	// half the floor burned out: dark, open, full of rubble, its walls partly gone
	void Gutted()
	{
		bool west = Chance(50);
		burnLo = west ? 1 : LIFT + 2;
		burnHi = west ? LIFT - 1 : NX - 2;
		Recast(west ? corrW : corrE, T_BURNT);
		rName[west ? corrW : corrE] = "the burned corridor";
		for (int f = 0; f < flatFirst.Size(); f++)
		{
			if (flatC1[f] < burnLo || flatC0[f] > burnHi) continue;
			RecastFlat(f, T_BURNT);
		}
		// the fire took walls down: neighbouring burned rooms open into each other
		for (int j = 0; j < NY; j++)
			for (int i = burnLo; i < burnHi; i++)
			{
				int a = At(i, j), b = At(i + 1, j);
				if (a >= 0 && b >= 0 && a != b && IsType(a, T_BURNT) && IsType(b, T_BURNT) && Chance(45)) Link(i, j, i + 1, j, E_WIDE);
			}
		for (int i = burnLo; i <= burnHi; i++)
			for (int j = 0; j + 1 < NY; j++)
			{
				int a = At(i, j), b = At(i, j + 1);
				if (a >= 0 && b >= 0 && a != b && IsType(a, T_BURNT) && IsType(b, T_BURNT) && Chance(35)) Link(i, j, i, j + 1, E_WIDE);
			}
		// the other half is lived in, mostly
		for (int f = 0; f < flatFirst.Size(); f++)
			if ((flatC1[f] < burnLo || flatC0[f] > burnHi) && Chance(25)) RecastFlat(f, T_SQUAT);
	}

	// The gallery floor: an open-air deck along the south face, the flats three rows deep behind it.
	void GalleryLayout()
	{
		int drop = MakeRoom(T_DROP); Rect(drop, 0, 0, NX - 1, 0);
		int deck = MakeRoom(T_GALLERY); Rect(deck, 0, 1, NX - 1, 1);
		LinkAll(drop, deck, E_FENCE);
		Stairs(2, 4, 2, -1);
		// the stair doors open onto the deck
		Link(COL_W, 2, COL_W, 1, E_DOOR); Link(COL_E, 2, COL_E, 1, E_DOOR);
		int lobby = MakeRoom(T_LOBBY); Rect(lobby, LIFT, 2, LIFT + 1, 2);
		LinkAll(lobby, deck, E_WIDE);
		AddEntry(CellCenter(LIFT, 2) + (64, 24), 270, "the lift", EK_SERVICE, lobby);
		int chute = MakeRoom(T_CHUTE); Claim(chute, LIFT, 3); Link(LIFT, 3, LIFT, 2, E_DOOR);
		int laundry = MakeRoom(T_LAUNDRY); Claim(laundry, LIFT + 1, 3); Link(LIFT + 1, 3, LIFT + 1, 2, E_DOOR);
		int store = MakeRoom(T_METER); rName[store] = "the storeroom"; Rect(store, LIFT, 4, LIFT + 1, 4); LinkRooms(store, chute, E_DOOR);
		GalleryFlats(1, LIFT - 1);
		GalleryFlats(LIFT + 2, NX - 2);
		for (int f = 0; f < flatFirst.Size(); f++) if (Chance(15)) RecastFlat(f, T_SQUAT);
	}

	// deck-access flats: kitchen and bathroom by the front door, the living room, bedrooms at the back
	void GalleryFlats(int c0, int c1)
	{
		int c = c0;
		while (c <= c1)
		{
			int left = c1 - c + 1;
			int w = min(Rand(2, 3), left);
			if (left - w == 1) w = w < 3 ? w + 1 : w - 1;
			w = clamp(w, 1, left);
			int x1 = c + w - 1;
			int first = rtype.Size();
			bool flip = Chance(50);
			int d = flip ? x1 : c;
			int kitch = MakeRoom(T_KITCHEN); Rect(kitch, c, 2, x1, 2);
			int living = MakeRoom(T_LIVING); Rect(living, c, 3, x1, 3);
			LinkRooms(kitch, living, w >= 3 ? E_WIDE : E_ARCH);
			if (w == 1) { Link(c, 3, c, 4, E_DOOR); int bed = MakeRoom(T_BED); Claim(bed, c, 4); }
			else
			{
				int bath = MakeRoom(T_BATH); Claim(bath, flip ? c : x1, 4);
				int bed = MakeRoom(T_BED); Rect(bed, flip ? c + 1 : c, 4, flip ? x1 : x1 - 1, 4);
				LinkRooms(bed, living, E_DOOR);
				LinkRooms(bath, living, E_DOOR);
			}
			Link(d, 2, d, 1, E_DOOR);
			flatFirst.Push(first); flatEnd.Push(rtype.Size()); flatLiving.Push(living);
			flatC0.Push(c); flatC1.Push(x1); flatSouth.Push(true);
			c += w;
		}
	}

	// ---------------------------------------------------------------- objectives, light, dressing
	override int ObjScore(int r, int k)
	{
		if (k == OBJ_STEAL && IsType(r, T_STASH)) return 200;
		if (k == OBJ_DESTROY && IsType(r, T_COOK)) return 200;
		if (k == OBJ_TURN && (IsType(r, T_COUNTING) || IsType(r, T_TRAP))) return 150;
		if (IsType(r, T_STAIR) || IsType(r, T_LOBBY) || IsType(r, T_CORR)) return 0;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case T_CORR: case T_STAIR: case T_CHUTE: case T_METER: case T_COOK: case T_STASH: return 2;
		case T_LIVING: case T_BED: case T_STUDY: case T_TRAP: case T_COUNTING: return 1;
		case T_LOBBY: case T_DOORMAN: return 3;
		}
		return 0;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		bool dark = Has(r, RF_DARK);
		switch (rtype[r])
		{
		case T_CORR:
			if (variant == V_GANG)
			{
				// barricades: sandbags and crates across part of the corridor, a gap left to get by
				for (int k = 0; k < ci.Size(); k++)
					if (Chance(22)) PutWall(Chance(60) ? "CW_FSandbags" : "CW_FCrates", ci[k], cj[k], Chance(50) ? 2 : 3, Rand(-30, 30));
			}
			else for (int k = 0; k < ci.Size(); k++) if (Chance(12)) PutWall("CW_FBin", ci[k], cj[k], Chance(50) ? 2 : 3, Rand(-50, 50));
			break;
		case T_LOBBY:
			LineWalls("CW_FBin", r, 160, 1);
			break;
		case T_DOORMAN:
			PutInRoom("CW_FReception", r, 270); LineWalls("CW_FPlanter", r, 140, 2);
			break;
		case T_CHUTE:
			LineWalls("CW_FBin", r, 60, 3); if (Chance(60)) PutInRoom("CW_FScrap", r);
			break;
		case T_LAUNDRY:
			LineWalls("CW_FCounter", r, 100, 3); PutInRoom("CW_FBin", r);
			break;
		case T_METER:
			LineWalls("CW_FPipes", r, 120, 2); PutInRoom("CW_FGenerator", r);
			break;
		case T_LIVING:
			if (dark) { if (Chance(40)) PutInRoom("CW_FScrap", r); break; }
			LineWalls("CW_FSofa", r, 130, 1); PutInRoom("CW_FCoffeeTable", r); LineWalls("CW_FWallTV", r, 200, 1);
			if (Chance(50)) PutInRoom("CW_FArmchair", r);
			if (ci.Size() >= 2 && Chance(60)) PutInRoom("CW_FRoundTable", r);
			break;
		case T_KITCHEN:
			if (dark) break;
			LineWalls("CW_FCounter", r, 110, ci.Size() + 1); if (ci.Size() >= 2 && Chance(50)) PutInRoom("CW_FRoundTable", r);
			break;
		case T_BED:
			if (dark) { if (Chance(50)) PutInRoom("CW_FBed", r); break; }
			LineWalls("CW_FBed", r, 220, 1); LineWalls("CW_FCredenza", r, 150, 1);
			break;
		case T_BATH:
			if (!dark) LineWalls("CW_FVanity", r, 120, 1);
			break;
		case T_STUDY:
			PutInRoom("CW_FDeskExec", r); LineWalls("CW_FBookshelf", r, 70, 4); PutInRoom("CW_FArmchair", r);
			break;
		case T_GALLERY:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 12) PutWall("CW_FBin", ci[k], cj[k], 2, Rand(-40, 40));
				else if (roll < 20) PutWall("CW_FPew", ci[k], cj[k], 2, Rand(-30, 30));
				else if (roll < 26) PutWall("CW_FPlanter", ci[k], cj[k], 2, Rand(-40, 40));
			}
			break;
		case T_SQUAT:
			if (Chance(60)) PutInRoom("CW_FBed", r);
			if (Chance(50)) PutInRoom("CW_FScrap", r);
			if (Chance(40)) PutInRoom("CW_FCrates", r);
			break;
		case T_STASH:
			LineWalls("CW_FShelving", r, 80, 3);
			for (int k = 0; k < ci.Size(); k++) if (Chance(70)) PutInCell("CW_FCrates", ci[k], cj[k]);
			break;
		case T_COOK:
			for (int k = 0; k < ci.Size(); k++) if (Chance(70)) PutInCell("CW_FLabBench", ci[k], cj[k], 90 * Rand(0, 1));
			LineWalls("CW_FTank", r, 140, 2); if (Chance(60)) PutInRoom("CW_FCrates", r);
			break;
		case T_COUNTING:
			PutInRoom("CW_FRoundTable", r); PutInRoom("CW_FChairGuest", r); LineWalls("CW_FFileCabinet", r, 70, 2); LineWalls("CW_FCredenza", r, 160, 1);
			break;
		case T_TRAP:
			LineWalls("CW_FSofa", r, 140, 2); LineWalls("CW_FWallTV", r, 220, 1);
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutInCell(Chance(50) ? "CW_FRoundTable" : "CW_FCrates", ci[k], cj[k]);
			break;
		case T_LOOKOUT:
			PutInRoom("CW_FArmchair", r); if (Chance(60)) PutInRoom("CW_FCrates", r);
			break;
		case T_BURNT:
			for (int k = 0; k < ci.Size(); k++) if (Chance(30)) PutInCell("CW_FScrap", ci[k], cj[k], 90 * Rand(0, 3));
			break;
		}
	}

	override void Outdoors()
	{
		// the gallery's wall lamps
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (!IsType(r, T_GALLERY)) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			for (int k = 0; k < ci.Size(); k += 2)
				NBC_LightSource.Make((CellCenter(ci[k], cj[k]) + (0, 48), 72), 255, 200, 140, 140);
		}
	}
}
