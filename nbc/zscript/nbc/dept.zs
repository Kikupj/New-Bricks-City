// The department (PLAN.md §2.1, §2.7, §6.5): the officers on the roster, the memorial wall, the Evidence Locker
// of seized weapons and supplies, everyone's kit, and the last raid's after-action report.
//
// NBC_Department is a STAT_STATIC thinker (saved with the game). The roster and the memorial also go to the
// archived nbc_roster / nbc_memorial CVars (written from the UI, NBC_RunManager.UiTick) so a new game starts
// with the officers who survived the last one. The Evidence Locker belongs to the case: a new case resets it
// to the department's own issue (PLAN.md §2.3).
//
// The menus only read this; every change is a netevent ("nbc_dept", op, a, b) checked in play scope
// (NBC_RunManager.NetworkProcess -> NBC_Department.Apply).

// ---------------------------------------------------------------- the catalog
class NBC_Cat
{
	enum EItem
	{
		IT_COLT, IT_DUAL92, IT_PUMP, IT_UZI, IT_AK, IT_MACHETE, IT_KNIFE,
		IT_LIGHT, IT_SHELL, IT_RIFLE, IT_MOLOTOV, IT_MEDKIT, IT_VEST, IT_COUNT
	}
	enum EKind { K_SIDEARM, K_PRIMARY, K_MELEE, K_AMMO, K_POUCH, K_VEST }
	enum EClass { C_PATROL, C_BREACHER, C_MARKSMAN, C_MEDIC, C_COUNT }
	enum EPerk
	{
		P_STEADY, P_TOUGH, P_KEVLAR, P_HOLLOW, P_TRIGGER, P_SPEED, P_REFLEX, P_MEDIC, P_PACK, P_WATCH, P_COUNT
	}
	const MAX_RANK = 3;
	// the officers' faces: graphics/portraits/NBCPF000-143 (tools/art/import_npc_art.py); one is Det. Vance's
	const FACES = 144;
	const VANCE_FACE = 10;
	const SQUAD_SLOTS = 4;
	const PLAYER_POUCHES = 4;

	static const String ITEM_NAME[] = { "Colt .45", "Dual 92s", "Pump Shotgun", "Micro-Uzi", "AK-47", "Machete", "Combat Knife",
		"Light Rounds", "Shotgun Shells", "Rifle Rounds", "Molotov", "Medkit", "Kevlar Vest" };
	static const String ITEM_CLASS[] = { "NBC_Colt45", "NBC_Dual92", "NBC_PumpShotgun", "NBC_MicroUzi", "NBC_AK47", "Machete", "CombatKnife",
		"NBC_LightAmmo", "Shell", "NBC_RifleAmmo", "MolotovAmmo", "NBC_Medkit", "GreenArmor" };
	static const int ITEM_KIND[] = { K_SIDEARM, K_SIDEARM, K_PRIMARY, K_PRIMARY, K_PRIMARY, K_MELEE, K_MELEE,
		K_AMMO, K_AMMO, K_AMMO, K_POUCH, K_POUCH, K_VEST };
	static const String ITEM_ICON[] = { "COLTP0", "B92GA0", "XSOTA0", "MUZPA0", "AK4IA0", "MHTEA0", "KNFPA0",
		"CLIPA0", "SHELA0", "ROCKA0", "MOLPA0", "MEDIA0", "ARM1A0" };
	// what one comes in for at the counter (ammo: per 10 rounds); 0 = not on the requisition list
	static const int ITEM_SELL[] = { 40, 70, 90, 100, 150, 20, 15, 2, 4, 5, 10, 15, 30 };
	static const int ITEM_BUY[] = { 0, 0, 0, 0, 0, 0, 0, 6, 10, 12, 30, 40, 90 };
	static const int ITEM_UNIT[] = { 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 1, 1, 1 };
	static const int ITEM_AMMO[] = { IT_LIGHT, IT_LIGHT, IT_SHELL, IT_LIGHT, IT_RIFLE, -1, -1, -1, -1, -1, -1, -1, -1 };
	static const String ITEM_DESC[] = {
		"Department issue .45. Eight rounds, light ammo.",
		"A pair of 9mm pistols. Fast and loud, light ammo.",
		"Pump-action 12 gauge. Shells. Clears a doorway.",
		"Seized machine pistol. Light ammo, sprays bursts.",
		"Seized assault rifle. Rifle ammo, hits hard at range.",
		"A long blade off a Rust Saint. Quiet.",
		"A fighting knife. Quick.",
		"9mm and .45 for pistols and SMGs.",
		"12 gauge buckshot.",
		"7.62 for the AK.",
		"A bottle of fuel and a rag. Fire won't touch officers.",
		"Patches 40 health. Officers use theirs below a third.",
		"Soaks up a share of every hit. One per officer." };

	static const String CLASS_NAME[] = { "Patrol", "Breacher", "Marksman", "Paramedic" };
	static const String CLASS_ROLE[] = {
		"All-rounder. Bursts from an SMG, sticks close.",
		"Front of the stack. Shotgun, heavy armor, draws fire.",
		"Long sightlines. Single shots that hit hard.",
		"Keeps you standing: patches you up under half health." };
	static const int CLASS_HP[] = { 80, 130, 60, 70 };
	static const int CLASS_AIM[] = { 60, 52, 72, 55 };
	static const int CLASS_PRICE[] = { 150, 200, 250, 250 };
	static const String CLASS_ISSUE[] = { "Service SMG", "Service Shotgun", "Service Rifle", "Light SMG" };
	static const String CLASS_SPRITE[] = { "EW1A", "ER5A", "ER6A", "EW2A" };

	static const String RANK_NAME[] = { "Officer", "Corporal", "Sergeant", "Lieutenant" };
	static const String RANK_SHORT[] = { "Ofc.", "Cpl.", "Sgt.", "Lt." };
	static const int RANK_XP[] = { 0, 60, 160, 320 };

	static const String PERK_NAME[] = { "Steady Hands", "Tough as Nails", "Kevlar Faith", "Hollow Points", "Trigger Discipline",
		"Speed Loader", "Hair Trigger", "Field Dressing", "Packrat", "Long Watch" };
	static const String PERK_DESC[] = { "+10 aim.", "+20 max health.", "Takes 15% less damage.", "+20% damage.",
		"One more round per burst, one more pellet per shell.", "Reloads 40% faster.", "Reacts 40% faster.",
		"Medkits heal double; patches you up twice as often.", "+1 pouch slot.", "Spots enemies 30% further away." };
	// two perks to choose from per class and promotion (Corporal, Sergeant, Lieutenant)
	static const int PERK_TREE[] = {
		P_STEADY, P_TOUGH,   P_TRIGGER, P_REFLEX,  P_HOLLOW, P_PACK,      // patrol
		P_TOUGH, P_REFLEX,   P_KEVLAR, P_HOLLOW,   P_TRIGGER, P_PACK,     // breacher
		P_STEADY, P_WATCH,   P_HOLLOW, P_SPEED,    P_REFLEX, P_PACK,      // marksman
		P_MEDIC, P_TOUGH,    P_KEVLAR, P_SPEED,    P_STEADY, P_PACK };    // paramedic

	static const String SURNAMES[] = { "Okafor", "Brandt", "Castillo", "Nguyen", "Doyle", "Harlan", "Mbeki", "Sorensen", "Reyes",
		"Kowal", "Petrov", "Haddad", "Romero", "Tanaka", "Walsh", "O'Neill", "Delgado", "Fischer", "Mendez", "Brooks", "Abara",
		"Lindqvist", "Moreau", "Santos", "Kim", "Patel", "Duarte", "Novak", "Grady", "Whitlock", "Osei", "Rusk", "Varga", "Chen",
		"Ibarra", "Kincaid", "Lowry", "Mercado", "Quinlan", "Rojas", "Sato", "Toure", "Ulrich", "Vega", "Wade", "Yusuf",
		"Zielinski", "Barros", "Dunn", "Esposito", "Farrow", "Galvez", "Holt", "Iverson", "Jansen", "Kaplan", "Mwangi", "Pruitt" };

	clearscope static String ItemName(int i) { return i >= 0 && i < IT_COUNT ? NBC_Cat.ITEM_NAME[i] : "Empty"; }
	clearscope static int Kind(int i) { return i >= 0 && i < IT_COUNT ? NBC_Cat.ITEM_KIND[i] : -1; }
	clearscope static bool IsWeapon(int i) { int k = Kind(i); return k == K_SIDEARM || k == K_PRIMARY || k == K_MELEE; }
	clearscope static bool IsFirearm(int i) { int k = Kind(i); return k == K_SIDEARM || k == K_PRIMARY; }
	clearscope static int AmmoOf(int i) { return i >= 0 && i < IT_COUNT ? NBC_Cat.ITEM_AMMO[i] : -1; }
	clearscope static int ItemOfClass(class<Actor> cls)
	{
		for (int i = 0; i < IT_COUNT; i++)
		{
			if (cls && cls.GetClassName() == Name(NBC_Cat.ITEM_CLASS[i])) return i;
		}
		return -1;
	}
	// the seized weapons each class can carry as its primary (PLAN.md §6.5)
	clearscope static bool ClassTakes(int cls, int item)
	{
		switch (cls)
		{
		case C_PATROL: return item == IT_UZI || item == IT_AK;
		case C_BREACHER: return item == IT_PUMP;
		case C_MARKSMAN: return item == IT_AK;
		case C_MEDIC: return item == IT_UZI || item == IT_COLT || item == IT_DUAL92;
		}
		return false;
	}
	clearscope static int PerkChoice(int cls, int newRank, int choice)
	{
		int k = clamp(cls, 0, C_COUNT - 1) * 6 + (clamp(newRank, 1, MAX_RANK) - 1) * 2 + clamp(choice, 0, 1);
		return NBC_Cat.PERK_TREE[k];
	}
	clearscope static String Face(int f) { return String.Format("NBCPF%03d", clamp(f, 0, FACES - 1)); }
	clearscope static String Money(int v)
	{
		String s = String.Format("%d", abs(v));
		String o = "";
		int n = s.Length();
		for (int i = 0; i < n; i++)
		{
			if (i > 0 && (n - i) % 3 == 0) o = o .. ",";
			o = o .. s.Mid(i, 1);
		}
		return (v < 0 ? "-$" : "$") .. o;
	}
}

// ---------------------------------------------------------------- an officer
class NBC_Officer
{
	enum EState { ST_ACTIVE, ST_HOSPITAL, ST_KIA }
	int id, cls, rank, xp, raids, kills, health, hospital, face, baseAim, tough, state;
	int team;                   // fireteam on raids: NBC_Orders.TEAM_ALPHA / TEAM_BRAVO (the deploy screen sets it)
	String initial, surname;
	Array<int> perks;           // one per promotion, in order
	int kitPrimary;             // a locker item, or -1 for the class's issue weapon
	Array<int> kitPouch;        // locker items (-1 empty), one per pouch slot
	bool kitVest;
	// the memorial
	int diedDay, diedCase;
	String diedWhere;

	clearscope String FullName() const { return initial .. ". " .. surname; }
	clearscope String RankedName() const { return NBC_Cat.RANK_SHORT[clamp(rank, 0, 3)] .. " " .. surname; }
	clearscope String RankName() const { return NBC_Cat.RANK_NAME[clamp(rank, 0, 3)]; }
	clearscope String ClassName() const { return NBC_Cat.CLASS_NAME[clamp(cls, 0, 3)]; }
	clearscope bool HasPerk(int p) const { return perks.Find(p) != perks.Size(); }
	clearscope int MaxHealth() const
	{
		int hp = NBC_Cat.CLASS_HP[clamp(cls, 0, 3)] + tough;
		hp = hp * (100 + rank * 15) / 100;
		if (HasPerk(NBC_Cat.P_TOUGH)) hp += 20;
		return max(20, hp);
	}
	clearscope int Aim() const { return min(99, baseAim + rank * 6 + (HasPerk(NBC_Cat.P_STEADY) ? 10 : 0)); }
	clearscope int PouchSlots() const { return min(3, 1 + rank) + (HasPerk(NBC_Cat.P_PACK) ? 1 : 0); }
	clearscope int NextXP() const { return rank < NBC_Cat.MAX_RANK ? NBC_Cat.RANK_XP[rank + 1] : 0; }
	clearscope bool CanPromote() const { return state != ST_KIA && rank < NBC_Cat.MAX_RANK && xp >= NBC_Cat.RANK_XP[rank + 1]; }
	clearscope bool Available() const { return state == ST_ACTIVE; }
	clearscope String Portrait() const { return NBC_Cat.Face(face); }
	clearscope String PrimaryName() const
	{
		return kitPrimary >= 0 ? NBC_Cat.ItemName(kitPrimary) : NBC_Cat.CLASS_ISSUE[clamp(cls, 0, 3)];
	}

	void FitPouches()
	{
		while (kitPouch.Size() < 4) kitPouch.Push(-1);
	}

	// one line for the nbc_roster CVar
	clearscope String Serialize() const
	{
		String p = "";
		for (int i = 0; i < perks.Size(); i++) p = p .. (i ? "." : "") .. perks[i];
		return String.Format("%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%s", id, initial, surname, cls, rank, xp, raids, kills, face, baseAim, tough, p);
	}
	static NBC_Officer Deserialize(String line)
	{
		Array<String> f;
		line.Split(f, ",");
		if (f.Size() < 11) return null;
		let o = new("NBC_Officer");
		o.id = f[0].ToInt(); o.initial = f[1]; o.surname = f[2]; o.cls = clamp(f[3].ToInt(), 0, 3);
		o.rank = clamp(f[4].ToInt(), 0, 3); o.xp = f[5].ToInt(); o.raids = f[6].ToInt(); o.kills = f[7].ToInt();
		o.face = f[8].ToInt(); o.baseAim = f[9].ToInt(); o.tough = f[10].ToInt();
		if (f.Size() > 11 && f[11].Length())
		{
			Array<String> ps;
			f[11].Split(ps, ".");
			for (int i = 0; i < ps.Size(); i++) o.perks.Push(ps[i].ToInt());
		}
		o.kitPrimary = -1;
		o.FitPouches();
		o.health = o.MaxHealth();
		return o;
	}
}

// ---------------------------------------------------------------- the after-action report
class NBC_Report
{
	enum EOutcome { OUT_TAKEN, OUT_RETREAT, OUT_DOWN, OUT_CRASH }
	int outcome;
	String title, place, gang, grade, dayLine;
	int kills, playerKills, crewTotal, healthLost, timeSecs, cashRaid, bounty, sold, balance;
	bool leaderDown;
	// the officers who went in
	Array<int> offId, offKills, offState, offFace, offRank, offXP;
	Array<String> offName;
	Array<bool> offPromote;
	// what the raid brought back to the locker (net), item and count
	Array<int> lootItem, lootCount;
	// what happened to the motorcade, and how the squad went in (NBC_Motor.MODE_*)
	Array<String> notes;
	int mode;
	// the hour it went in at (NBC_Clock.W_*) and the day's event, if it was this raid's (NBC_Clock.EV_*)
	int window, eventKind;

	enum EOffState { OS_FIT, OS_WOUNDED, OS_CRITICAL, OS_KIA }
}

// ---------------------------------------------------------------- the department
class NBC_Department : Thinker
{
	Array<NBC_Officer> roster, fallen;
	int nextId;
	Array<int> locker;                  // count per NBC_Cat item (rounds for ammo)
	// your own kit
	int pPrimary, pSidearm, pMelee;
	Array<int> pPouch;
	bool pVest;
	// who goes on the next raid (officer ids, in slot order)
	Array<int> squad;
	// the last raid
	NBC_Report report;
	bool reportPending;
	int reportSerial;
	int rosterVersion;
	// the motor pool (garage.zs): vehicles, the motorcade's insertion; your own face (any of the portraits)
	Array<NBC_Vehicle> garage;
	int nextVehicle, insertion;
	int playerFace;                  // bumped on every roster change (the UI writes the CVars)
	bool loaded;

	static NBC_Department Get()
	{
		let it = ThinkerIterator.Create("NBC_Department", STAT_STATIC);
		let d = NBC_Department(it.Next());
		if (!d)
		{
			d = new("NBC_Department");
			d.ChangeStatNum(STAT_STATIC);
			d.Setup();
		}
		return d;
	}
	static clearscope NBC_Department Find()
	{
		let it = ThinkerIterator.Create("NBC_Department", STAT_STATIC);
		return NBC_Department(it.Next());
	}

	void Setup()
	{
		nextId = 1;
		pPrimary = -1; pSidearm = NBC_Cat.IT_COLT; pMelee = -1;
		pPouch.Clear();
		for (int i = 0; i < NBC_Cat.PLAYER_POUCHES; i++) pPouch.Push(-1);
		locker.Clear();
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++) locker.Push(0);
		// the officers who survived your last game (nbc_roster), else the department's first four
		LoadRoster(CVar.GetCVar("nbc_roster").GetString(), CVar.GetCVar("nbc_memorial").GetString());
		playerFace = CVar.GetCVar("nbc_avatar").GetInt();
		if (playerFace < 0 || playerFace >= NBC_Cat.FACES) playerFace = NBC_Cat.VANCE_FACE;
		ResetGarage(null);
		if (!roster.Size())
		{
			Recruit(NBC_Cat.C_PATROL, null, true);
			Recruit(NBC_Cat.C_PATROL, null, true);
			Recruit(NBC_Cat.C_BREACHER, null, true);
			Recruit(NBC_Cat.C_MEDIC, null, true);
		}
		ResetLocker();
		AutoSquad();
	}

	// a new case: the locker goes back to the department's own issue
	void ResetLocker()
	{
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++) locker[i] = 0;
		locker[NBC_Cat.IT_COLT] = 2;
		locker[NBC_Cat.IT_PUMP] = 1;
		locker[NBC_Cat.IT_UZI] = 1;
		locker[NBC_Cat.IT_LIGHT] = 240;
		locker[NBC_Cat.IT_SHELL] = 40;
		locker[NBC_Cat.IT_RIFLE] = 30;
		locker[NBC_Cat.IT_MOLOTOV] = 3;
		locker[NBC_Cat.IT_MEDKIT] = 3;
		locker[NBC_Cat.IT_VEST] = 1;
		// kits are emptied back first, so nothing is counted twice
		for (int i = 0; i < roster.Size(); i++)
		{
			let o = roster[i];
			o.kitPrimary = -1; o.kitVest = false;
			o.FitPouches();
			for (int k = 0; k < o.kitPouch.Size(); k++) o.kitPouch[k] = -1;
		}
		pPrimary = -1; pSidearm = -1; pMelee = -1; pVest = false;
		for (int i = 0; i < pPouch.Size(); i++) pPouch[i] = -1;
		// your own issue, drawn from the locker like everyone else's: the Colt, a medkit and a bottle
		SwapPlayer(pSidearm, NBC_Cat.IT_COLT, NBC_Cat.K_SIDEARM);
		SetPouch(0, 0, NBC_Cat.IT_MEDKIT);
		SetPouch(0, 1, NBC_Cat.IT_MOLOTOV);
	}

	// a new case: a fresh Bricks, the locker back to issue, everyone out of the hospital
	void NewCase()
	{
		for (int i = 0; i < roster.Size(); i++)
		{
			let o = roster[i];
			o.state = NBC_Officer.ST_ACTIVE;
			o.hospital = 0;
			o.health = o.MaxHealth();
		}
		ResetLocker();
		ResetGarage(NBC_RunData.Find());
		AutoSquad();
		reportPending = false;
		rosterVersion++;
	}

	// ------------------------------------------------------------ the motor pool
	// a new case: the department's own panel van (you and four) and an unmarked sedan (you and one)
	void ResetGarage(NBC_RunData rd)
	{
		garage.Clear();
		nextVehicle = 1;
		insertion = NBC_Motor.INS_STREET;
		AddVehicle(NBC_Motor.V_VAN, rd).rolling = true;
		AddVehicle(NBC_Motor.V_SEDAN, rd);
	}

	NBC_Vehicle AddVehicle(int type, NBC_RunData rd)
	{
		let v = new("NBC_Vehicle");
		v.id = nextVehicle++;
		v.type = clamp(type, 0, NBC_Motor.V_COUNT - 1);
		v.cond = 100;
		v.plate = String.Format("%c%c-%d%d", 65 + Roll(rd, 0, 25), 65 + Roll(rd, 0, 25), Roll(rd, 1, 9), Roll(rd, 0, 9));
		garage.Push(v);
		return v;
	}

	clearscope NBC_Vehicle VehicleById(int id) const
	{
		for (int i = 0; i < garage.Size(); i++) if (garage[i].id == id) return garage[i];
		return null;
	}

	// a vehicle counts for this insertion: ready, and flies for the roofs or drives for the street; a sedan only
	// takes you alone or with one officer (owner request), and then it rides alone
	clearscope bool Fits(NBC_Vehicle v, int ins) const
	{
		if (!v || !v.Ready() || NBC_Motor.Flies(v.type) != (ins == NBC_Motor.INS_ROOFTOP)) return false;
		return !NBC_Motor.SoloOnly(v.type) || SeatsNeeded() <= NBC_Motor.TYPE_SEATS[v.type];
	}
	// seats in the motorcade as picked (you included)
	clearscope int Seats(int ins) const
	{
		int n = 0;
		for (int i = 0; i < garage.Size(); i++) if (garage[i].rolling && Fits(garage[i], ins)) n += garage[i].Seats();
		return n;
	}
	clearscope int SeatsNeeded() const { return squad.Size() + 1; }
	clearscope bool HasHeli() const
	{
		for (int i = 0; i < garage.Size(); i++) if (garage[i].type == NBC_Motor.V_HELI && garage[i].Ready()) return true;
		return false;
	}
	// the helicopter going in (rooftop insertions take one)
	clearscope NBC_Vehicle RollingHeli() const
	{
		for (int i = 0; i < garage.Size(); i++) if (garage[i].rolling && Fits(garage[i], NBC_Motor.INS_ROOFTOP)) return garage[i];
		return null;
	}

	// pick enough of the right vehicles: the roomiest first; a rooftop insertion takes the best helicopter
	void AutoMotorcade()
	{
		for (int i = 0; i < garage.Size(); i++) garage[i].rolling = false;
		if (insertion == NBC_Motor.INS_ROOFTOP)
		{
			NBC_Vehicle best = null;
			for (int i = 0; i < garage.Size(); i++)
				if (Fits(garage[i], insertion) && (!best || garage[i].cond > best.cond)) best = garage[i];
			if (best) best.rolling = true;
			return;
		}
		// you alone or with one partner: the sedan, if there's one (low profile)
		NBC_Vehicle car = null;
		for (int i = 0; i < garage.Size(); i++)
			if (NBC_Motor.SoloOnly(garage[i].type) && Fits(garage[i], insertion) && (!car || garage[i].cond > car.cond)) car = garage[i];
		if (car) { car.rolling = true; return; }
		for (int pass = 0; pass < NBC_Motor.MAX_VEHICLES && Seats(insertion) < SeatsNeeded(); pass++)
		{
			NBC_Vehicle best = null;
			for (int i = 0; i < garage.Size(); i++)
			{
				let v = garage[i];
				if (v.rolling || !Fits(v, insertion) || NBC_Motor.SoloOnly(v.type)) continue;
				if (!best || v.Seats() > best.Seats() || (v.Seats() == best.Seats() && v.cond > best.cond)) best = v;
			}
			if (!best) break;
			best.rolling = true;
		}
	}

	clearscope String PlayerPortrait() const { return NBC_Cat.Face(playerFace); }

	bool Take(int item, int n = 1)
	{
		if (item < 0 || item >= NBC_Cat.IT_COUNT || locker[item] < n) return false;
		locker[item] -= n;
		return true;
	}
	void Give(int item, int n = 1)
	{
		if (item >= 0 && item < NBC_Cat.IT_COUNT && n > 0) locker[item] += n;
	}

	clearscope NBC_Officer OfficerById(int id) const
	{
		for (int i = 0; i < roster.Size(); i++) if (roster[i].id == id) return roster[i];
		return null;
	}
	clearscope int CountClass(int cls) const
	{
		int n = 0;
		for (int i = 0; i < roster.Size(); i++) if (roster[i].cls == cls) n++;
		return n;
	}
	clearscope bool InSquad(int id) const { return squad.Find(id) != squad.Size(); }

	NBC_Officer Recruit(int cls, NBC_RunData rd, bool free = false)
	{
		cls = clamp(cls, 0, NBC_Cat.C_COUNT - 1);
		if (!free)
		{
			if (!rd || rd.cash < NBC_Cat.CLASS_PRICE[cls]) return null;
			rd.cash -= NBC_Cat.CLASS_PRICE[cls];
		}
		let o = new("NBC_Officer");
		o.id = nextId++;
		o.cls = cls;
		// stats come from the case RNG when there's a case (AGENTS.md), else the start-of-game roll
		o.surname = PickSurname(rd);
		o.initial = String.Format("%c", 65 + Roll(rd, 0, 25));
		o.face = PickFace(rd);
		o.baseAim = NBC_Cat.CLASS_AIM[cls] + Roll(rd, -8, 8);
		o.tough = Roll(rd, -10, 10);
		o.kitPrimary = -1;
		o.FitPouches();
		o.health = o.MaxHealth();
		roster.Push(o);
		rosterVersion++;
		return o;
	}
	int Roll(NBC_RunData rd, int lo, int hi)
	{
		return rd && rd.caseActive ? rd.Rand(lo, hi) : random(lo, hi);
	}
	// a face nobody on the roster has (and never Vance's)
	int PickFace(NBC_RunData rd)
	{
		for (int t = 0; t < 30; t++)
		{
			int f = Roll(rd, 0, NBC_Cat.FACES - 1);
			if (f == NBC_Cat.VANCE_FACE || f == playerFace) continue;
			bool used = false;
			for (int i = 0; i < roster.Size() && !used; i++) if (roster[i].face == f) used = true;
			if (!used) return f;
		}
		return (Roll(rd, 0, NBC_Cat.FACES - 2) + NBC_Cat.VANCE_FACE + 1) % NBC_Cat.FACES;
	}
	String PickSurname(NBC_RunData rd)
	{
		for (int t = 0; t < 20; t++)
		{
			String s = NBC_Cat.SURNAMES[Roll(rd, 0, NBC_Cat.SURNAMES.Size() - 1)];
			bool used = false;
			for (int i = 0; i < roster.Size() && !used; i++) if (roster[i].surname == s) used = true;
			if (!used) return s;
		}
		return NBC_Cat.SURNAMES[Roll(rd, 0, NBC_Cat.SURNAMES.Size() - 1)];
	}

	// AUTO: the healthiest available officers, a mix of classes first
	void AutoSquad()
	{
		squad.Clear();
		for (int pass = 0; pass < 2 && squad.Size() < NBC_Cat.SQUAD_SLOTS; pass++)
		{
			Array<bool> classTaken;
			for (int c = 0; c < NBC_Cat.C_COUNT; c++) classTaken.Push(false);
			for (int n = 0; n < roster.Size() && squad.Size() < NBC_Cat.SQUAD_SLOTS; n++)
			{
				// the best remaining officer by health, rank, xp
				NBC_Officer best = null;
				for (int i = 0; i < roster.Size(); i++)
				{
					let o = roster[i];
					if (!o.Available() || InSquad(o.id)) continue;
					if (pass == 0 && classTaken[o.cls]) continue;
					if (!best || o.health * 4 + o.rank * 40 + o.xp / 10 > best.health * 4 + best.rank * 40 + best.xp / 10) best = o;
				}
				if (!best) break;
				classTaken[best.cls] = true;
				squad.Push(best.id);
				best.team = squad.Size() <= 2 ? NBC_Orders.TEAM_ALPHA : NBC_Orders.TEAM_BRAVO;
			}
		}
	}

	// ------------------------------------------------------------ changes from the menus
	enum EOp
	{
		OP_SQUAD_TOGGLE = 1, OP_SQUAD_AUTO, OP_PRIMARY, OP_POUCH, OP_VEST, OP_SIDEARM, OP_MELEE,
		OP_PROMOTE, OP_RECRUIT, OP_SELL, OP_BUY, OP_DISMISS, OP_REPORT_SEEN, OP_AUTO_KIT, OP_TEAM,
		OP_AVATAR, OP_BUY_VEHICLE, OP_REPAIR, OP_SELL_VEHICLE, OP_ROLL, OP_INSERTION, OP_AUTO_MOTORCADE,
		OP_WINDOW
	}

	// a: officer id (0 = you) for kit ops; b/c: the value
	void Apply(int op, int a, int b, int c, NBC_RunData rd)
	{
		switch (op)
		{
		case OP_SQUAD_TOGGLE:
		{
			let o = OfficerById(a);
			if (!o) return;
			int at = squad.Find(a);
			if (at != squad.Size()) squad.Delete(at);
			else if (o.Available() && squad.Size() < NBC_Cat.SQUAD_SLOTS)
			{
				squad.Push(a);
				o.team = squad.Size() <= 2 ? NBC_Orders.TEAM_ALPHA : NBC_Orders.TEAM_BRAVO;
			}
			return;
		}
		case OP_SQUAD_AUTO: AutoSquad(); return;
		case OP_PRIMARY: SetPrimary(a, b); return;
		case OP_POUCH: SetPouch(a, b, c); return;
		case OP_VEST: SetVest(a, b != 0); return;
		case OP_SIDEARM: if (b < 0 || b != pPrimary) SwapPlayer(pSidearm, b, NBC_Cat.K_SIDEARM); return;
		case OP_MELEE: SwapPlayer(pMelee, b, NBC_Cat.K_MELEE); return;
		case OP_PROMOTE:
		{
			let o = OfficerById(a);
			if (!o || !o.CanPromote()) return;
			o.rank++;
			o.perks.Push(NBC_Cat.PerkChoice(o.cls, o.rank, b));
			o.health = min(o.MaxHealth(), o.health + 15 * o.MaxHealth() / 100);
			o.FitPouches();
			rosterVersion++;
			return;
		}
		case OP_RECRUIT:
			if (roster.Size() < 16) Recruit(a, rd);
			return;
		case OP_SELL:
		{
			if (b < 0 || b >= NBC_Cat.IT_COUNT || !rd) return;
			int unit = NBC_Cat.ITEM_UNIT[b];
			if (locker[b] < unit) return;
			locker[b] -= unit;
			rd.cash += NBC_Cat.ITEM_SELL[b];
			return;
		}
		case OP_BUY:
		{
			if (b < 0 || b >= NBC_Cat.IT_COUNT || !rd || NBC_Cat.ITEM_BUY[b] <= 0 || rd.cash < NBC_Cat.ITEM_BUY[b]) return;
			rd.cash -= NBC_Cat.ITEM_BUY[b];
			locker[b] += NBC_Cat.ITEM_UNIT[b];
			return;
		}
		case OP_DISMISS:
		{
			let o = OfficerById(a);
			if (!o || roster.Size() <= 1) return;
			StripKit(o);
			int at = squad.Find(a);
			if (at != squad.Size()) squad.Delete(at);
			roster.Delete(roster.Find(o));
			rosterVersion++;
			return;
		}
		case OP_REPORT_SEEN: reportPending = false; return;
		case OP_AUTO_KIT: AutoKit(); return;
		case OP_AVATAR:
			if (b >= 0 && b < NBC_Cat.FACES) { playerFace = b; rosterVersion++; }
			return;
		case OP_BUY_VEHICLE:
		{
			if (!rd || b < 0 || b >= NBC_Motor.V_COUNT || garage.Size() >= NBC_Motor.MAX_VEHICLES) return;
			int price = NBC_Motor.TYPE_PRICE[b];
			if (rd.cash < price) return;
			rd.cash -= price;
			AddVehicle(b, rd);
			return;
		}
		case OP_REPAIR:
		{
			let v = VehicleById(a);
			if (!v || !rd) return;
			int cost = NBC_Motor.RepairCost(v.type, v.cond);
			if (cost <= 0 || rd.cash < cost) return;
			rd.cash -= cost;
			v.cond = 100;
			return;
		}
		case OP_SELL_VEHICLE:
		{
			let v = VehicleById(a);
			if (!v || !rd || garage.Size() <= 1) return;
			rd.cash += NBC_Motor.SellValue(v.type, v.cond);
			garage.Delete(garage.Find(v));
			return;
		}
		case OP_ROLL:
		{
			let v = VehicleById(a);
			if (!v || (!v.rolling && !Fits(v, insertion))) return;
			v.rolling = !v.rolling;
			// the sedan rides alone: picking it sends the rest back to the garage, and the other way round
			if (v.rolling)
				for (int i = 0; i < garage.Size(); i++)
					if (garage[i] != v && (NBC_Motor.SoloOnly(v.type) || NBC_Motor.SoloOnly(garage[i].type))) garage[i].rolling = false;
			return;
		}
		case OP_INSERTION:
			if (b == NBC_Motor.INS_ROOFTOP && !HasHeli()) return;
			insertion = clamp(b, NBC_Motor.INS_STREET, NBC_Motor.INS_ROOFTOP);
			AutoMotorcade();
			return;
		case OP_AUTO_MOTORCADE: AutoMotorcade(); return;
		case OP_WINDOW: if (rd) rd.planWindow = clamp(b, 0, NBC_Clock.W_COUNT - 1); return;
		case OP_TEAM:
		{
			let o = OfficerById(a);
			if (o) o.team = o.team == NBC_Orders.TEAM_ALPHA ? NBC_Orders.TEAM_BRAVO : NBC_Orders.TEAM_ALPHA;
			return;
		}
		}
	}

	void SetPrimary(int who, int item)
	{
		if (who == 0)
		{
			if (item >= 0 && NBC_Cat.Kind(item) != NBC_Cat.K_PRIMARY && NBC_Cat.Kind(item) != NBC_Cat.K_SIDEARM) return;
			if (item >= 0 && item == pSidearm) return;     // one gun can't fill two slots
			SwapPlayer(pPrimary, item, -1);
			return;
		}
		let o = OfficerById(who);
		if (!o || (item >= 0 && !NBC_Cat.ClassTakes(o.cls, item))) return;
		if (item >= 0 && !Take(item)) return;
		Give(o.kitPrimary);
		o.kitPrimary = item;
	}

	// your slots hold one item each: the old one goes back, the new one comes out
	void SwapPlayer(out int slot, int item, int kind)
	{
		if (item >= 0 && kind >= 0 && NBC_Cat.Kind(item) != kind) return;
		if (item >= 0 && !Take(item)) return;
		Give(slot);
		slot = item;
	}

	void SetPouch(int who, int slot, int item)
	{
		if (item >= 0 && NBC_Cat.Kind(item) != NBC_Cat.K_POUCH) return;
		if (who == 0)
		{
			if (slot < 0 || slot >= pPouch.Size()) return;
			if (item >= 0 && !Take(item)) return;
			Give(pPouch[slot]);
			pPouch[slot] = item;
			return;
		}
		let o = OfficerById(who);
		if (!o) return;
		o.FitPouches();
		if (slot < 0 || slot >= o.PouchSlots()) return;
		if (item >= 0 && !Take(item)) return;
		Give(o.kitPouch[slot]);
		o.kitPouch[slot] = item;
	}

	void SetVest(int who, bool on)
	{
		bool had = who == 0 ? pVest : false;
		NBC_Officer o = null;
		if (who != 0) { o = OfficerById(who); if (!o) return; had = o.kitVest; }
		if (on == had) return;
		if (on && !Take(NBC_Cat.IT_VEST)) return;
		if (!on) Give(NBC_Cat.IT_VEST);
		if (o) o.kitVest = on; else pVest = on;
	}

	void StripKit(NBC_Officer o)
	{
		Give(o.kitPrimary); o.kitPrimary = -1;
		for (int k = 0; k < o.kitPouch.Size(); k++) { Give(o.kitPouch[k]); o.kitPouch[k] = -1; }
		if (o.kitVest) { Give(NBC_Cat.IT_VEST); o.kitVest = false; }
	}

	// AUTO kit: best seized primary each officer's class can take, a medkit or Molotov per free pouch, vests
	// to the front of the stack
	void AutoKit()
	{
		static const int prefer[] = { NBC_Cat.IT_AK, NBC_Cat.IT_PUMP, NBC_Cat.IT_UZI, NBC_Cat.IT_DUAL92, NBC_Cat.IT_COLT };
		for (int s = 0; s < squad.Size(); s++)
		{
			let o = OfficerById(squad[s]);
			if (!o) continue;
			if (o.kitPrimary < 0)
				for (int k = 0; k < prefer.Size(); k++)
					if (NBC_Cat.ClassTakes(o.cls, prefer[k]) && locker[prefer[k]] > 0) { SetPrimary(o.id, prefer[k]); break; }
			o.FitPouches();
			for (int k = 0; k < o.PouchSlots(); k++)
			{
				if (o.kitPouch[k] >= 0) continue;
				int want = (k % 2 == 0 || o.cls == NBC_Cat.C_MEDIC) ? NBC_Cat.IT_MEDKIT : NBC_Cat.IT_MOLOTOV;
				if (locker[want] <= 0) want = want == NBC_Cat.IT_MEDKIT ? NBC_Cat.IT_MOLOTOV : NBC_Cat.IT_MEDKIT;
				SetPouch(o.id, k, want);
			}
			if (!o.kitVest && (o.cls == NBC_Cat.C_BREACHER || o.cls == NBC_Cat.C_PATROL)) SetVest(o.id, true);
		}
	}

	// ------------------------------------------------------------ the roster in CVars
	clearscope String SaveRoster() const
	{
		String s = "";
		for (int i = 0; i < roster.Size(); i++) s = s .. (i ? ";" : "") .. roster[i].Serialize();
		return s;
	}
	clearscope String SaveMemorial() const
	{
		String s = "";
		for (int i = 0; i < fallen.Size(); i++)
		{
			let o = fallen[i];
			s = s .. (i ? ";" : "") .. String.Format("%s,%s,%d,%d,%d,%d,%d,%s", o.initial, o.surname, o.cls, o.rank, o.raids, o.diedDay,
				o.face, o.diedWhere.Filter());
		}
		return s;
	}
	void LoadRoster(String rs, String ms)
	{
		Array<String> lines;
		rs.Split(lines, ";", TOK_SKIPEMPTY);
		for (int i = 0; i < lines.Size(); i++)
		{
			let o = NBC_Officer.Deserialize(lines[i]);
			if (!o) continue;
			roster.Push(o);
			nextId = max(nextId, o.id + 1);
		}
		lines.Clear();
		ms.Split(lines, ";", TOK_SKIPEMPTY);
		for (int i = 0; i < lines.Size(); i++)
		{
			Array<String> f;
			lines[i].Split(f, ",");
			if (f.Size() < 7) continue;
			let o = new("NBC_Officer");
			o.initial = f[0]; o.surname = f[1]; o.cls = f[2].ToInt(); o.rank = f[3].ToInt(); o.raids = f[4].ToInt();
			o.diedDay = f[5].ToInt(); o.face = f[6].ToInt(); o.diedWhere = f.Size() > 7 ? f[7] : "";
			o.state = NBC_Officer.ST_KIA;
			fallen.Push(o);
		}
	}

	// After a raid: what the player carried out goes back in the locker. Kit weapons stay checked out to you,
	// used pouches empty; everything else (ammo, extra guns, bottles and medkits you found) is loot.
	// loot gets the net per item (negative: spent).
	void CheckIn(Array<int> back, Array<int> issued, out Array<int> loot)
	{
		loot.Clear();
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
		{
			int got = i < back.Size() ? back[i] : 0;
			int sent = i < issued.Size() ? issued[i] : 0;
			int k = NBC_Cat.Kind(i);
			int keep = 0;
			if (NBC_Cat.IsWeapon(i))
			{
				keep = (pPrimary == i ? 1 : 0) + (pSidearm == i ? 1 : 0) + (pMelee == i ? 1 : 0);
				Give(i, max(0, got - keep));
				loot.Push(max(0, got - keep));
				continue;
			}
			if (k == NBC_Cat.K_POUCH)
			{
				// pouches you came back without empty out
				int gone = sent - got;
				for (int s = pPouch.Size() - 1; s >= 0 && gone > 0; s--)
					if (pPouch[s] == i) { pPouch[s] = -1; gone--; }
				Give(i, max(0, got - sent));
				loot.Push(got - sent);
				continue;
			}
			if (k == NBC_Cat.K_VEST) { loot.Push(0); continue; }     // the vest stays on you
			Give(i, got);
			loot.Push(got - sent);
		}
	}

	// killed in the line of duty: the kit they carried is gone with them
	void KillOfficer(NBC_Officer o, int day, String where)
	{
		o.state = NBC_Officer.ST_KIA;
		o.diedDay = day;
		o.diedWhere = where;
		o.kitPrimary = -1;
		o.kitVest = false;
		for (int k = 0; k < o.kitPouch.Size(); k++) o.kitPouch[k] = -1;
		int at = squad.Find(o.id);
		if (at != squad.Size()) squad.Delete(at);
		at = roster.Find(o);
		if (at != roster.Size()) roster.Delete(at);
		fallen.Push(o);
		rosterVersion++;
	}

	// officers in the hospital can't stay in the squad
	void PruneSquad()
	{
		for (int i = squad.Size() - 1; i >= 0; i--)
		{
			let o = OfficerById(squad[i]);
			if (!o || !o.Available()) squad.Delete(i);
		}
	}

	void PostReport(NBC_Report rep)
	{
		report = rep;
		reportPending = true;
		reportSerial++;
	}

	// a day passes: the hospital empties out; officers heal up
	void NewDay()
	{
		for (int i = 0; i < roster.Size(); i++)
		{
			let o = roster[i];
			if (o.state == NBC_Officer.ST_HOSPITAL && --o.hospital <= 0)
			{
				o.hospital = 0;
				o.state = NBC_Officer.ST_ACTIVE;
				o.health = o.MaxHealth();
			}
			else if (o.state == NBC_Officer.ST_ACTIVE) o.health = min(o.MaxHealth(), o.health + o.MaxHealth() / 2);
		}
		PruneSquad();
	}
}

// A medkit you carry (Use from the inventory bar); the same item the officers carry in their pouches.
class NBC_Medkit : HealthPickup
{
	Default
	{
		Health 40;
		Inventory.MaxAmount 6;
		Inventory.InterHubAmount 6;
		Inventory.Icon "MEDIA0";
		Inventory.PickupMessage "Picked up a medkit.";
		Tag "Medkit";
		HealthPickup.Autouse 0;
	}
	States { Spawn: MEDI A -1; Stop; }
}
