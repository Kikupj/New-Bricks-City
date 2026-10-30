// Case and raid state (AGENTS.md: one STAT_STATIC thinker, saved with the game, kept across maps).
// All case and raid randomness comes from Rand() here, so a seed reproduces a case.

enum NBC_CaseResult
{
	NBC_CASE_RUNNING = 0,
	NBC_CASE_WON,          // the Crown taken (every gang toppled, in a case without a Crown)
	NBC_CASE_STRUCK_OUT,   // 3 strikes: Internal Affairs pulls you
	NBC_CASE_DEMOLITION,   // out of days
}

class NBC_RunData : Thinker
{
	const MAX_DAYS = 30;
	const MAX_STRIKES = 3;
	const CROWN_AFTER = 3;             // gangs toppled before the Crown opens
	// Backing (PLAN.md §2.5, §6.10): City Hall's and the street's faith in the department, 0-100
	const BACKING_START = 60;
	const BACKING_RESET = 40;          // after Backing hits zero (and a strike)
	const BACKING_HIGH = 75;
	const BACKING_LOW = 25;            // at or below: a day longer in the hospital
	const CASE_VERSION = 1;            // bumped when a case gains state; older saves are brought up to date on load

	bool caseActive;
	int caseResult, caseVersion;
	int seed, rngState, rngSteps;
	int day, strikes, cash, casesClosed;
	int backing;
	// the Crown's gang (gangs.txt, crown = 1) + 1; 0: no Crown this case
	int crownSlot;
	// the case so far, for the case summary when it ends
	int caseRaids, caseTaken, caseRetreats, caseDowns, caseLost, caseMerit, caseBackingLow;
	// the case summary waits at the precinct once the case ends (the UI opens it, like the after-action report)
	bool summaryPending;
	int summarySerial;
	// what moved Backing since the last report ("Retreat -5"), and whether it hit zero
	Array<String> backingLog;

	// per gang (index into NBC_RunManager.gangs) and per district (index into the district pool)
	Array<bool> gangToppled;
	Array<int> gangAlert;
	Array<int> districtGang;

	// the raid planned on the deploy screen (READY), waiting on the pilot; -1: none
	int readyDistrict;
	// the hour picked on the roll-out screen (NBC_Clock.W_*), and today's event (clock.zs): what, where, when;
	// missedUrgent: the last day ended with a pinned-down unit left there (a strike)
	int planWindow;
	int evKind, evDistrict, evWindow;
	bool missedUrgent;
	int evDistrictWas;                   // where yesterday's event was (for the missed-urgent line)

	// the current raid
	bool raidActive, leaderDown, officerDown;
	int raidDistrict, raidGang, raidKills, raidBounty;
	// the map the raid runs on (a district's Obsidian map); on a kit floor (M2b, test maps) also the variant,
	// layout seed and preferred entry (NBC_KitGen.EK_*)
	String raidMap;
	int raidVariant, raidKitSeed, raidEntry;
	// the officers who went in (NBC_Officer ids), their kills and their health at the end (0 = down)
	Array<int> raidOff, raidOffKills, raidOffHealth;
	int raidPlayerKills, raidHealthLost, raidTics;
	// your accuracy: rounds fired (NBC_ReloadWeapon.DepleteAmmo) and the shots that hit someone of the gang (one per
	// tic, so a shotgun's pellets count once); fists, blades, debris and fire don't count
	int raidShots, raidHits, raidLastHitTic;
	int raidBackingWas;
	// what the player was issued from the Evidence Locker (per NBC_Cat item), to tell loot from kit afterwards
	Array<int> raidIssued;
	// squad orders (Ghost Recon style, NBC_Orders): two fireteams, each with an order, rules of engagement, a goal
	// and a waypoint path; a go code holds a team at a waypoint until you call it
	Array<int> raidOffTeam;                 // per raid slot: NBC_Orders.TEAM_ALPHA / TEAM_BRAVO
	int cmdTeam;                            // who your commands go to: NBC_Orders.CT_ALL / CT_ALPHA / CT_BRAVO
	Array<int> teamOrder, teamROE, teamSerial;
	Array<double> teamGX, teamGY, teamGZ;
	Array<int> wpTeam, wpGo;
	Array<double> wpX, wpY, wpZ;
	Array<bool> goCalled;
	// how the squad went in (the motor pool, garage.zs): street, rooftop, or shot down on the way to the roofs;
	// the vehicles that rolled out; the crash site's ambush
	int raidMode;
	Array<int> raidVehicles;
	int crashWave, crashNext;
	bool crashClear;
	// the hour the raid went in at, and the day's event if it's in this district (NBC_Clock.EV_NONE otherwise)
	int raidWindow, raidEvent;

	static NBC_RunData Get()
	{
		let it = ThinkerIterator.Create("NBC_RunData", STAT_STATIC);
		let rd = NBC_RunData(it.Next());
		if (!rd)
		{
			rd = new("NBC_RunData");
			rd.ChangeStatNum(STAT_STATIC);
			rd.readyDistrict = -1;
			rd.evDistrict = -1;
			rd.planWindow = NBC_Clock.W_AFTERNOON;
		}
		return rd;
	}

	static clearscope NBC_RunData Find()
	{
		let it = ThinkerIterator.Create("NBC_RunData", STAT_STATIC);
		return NBC_RunData(it.Next());
	}

	// xorshift32 on the case seed; rngSteps counts draws for debugging
	int Rand(int lo, int hi)
	{
		if (hi <= lo) return lo;
		int x = rngState;
		if (x == 0) x = 0x2545F491;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		rngState = x;
		rngSteps++;
		int span = hi - lo + 1;
		int r = (x >>> 1) % span;
		return lo + r;
	}

	// gangCount and districtCount include the Crown's (crownGang, crownDistrict; -1 for none), which isn't dealt
	void NewCase(int newSeed, int gangCount, int districtCount, int crownGang = -1, int crownDistrict = -1)
	{
		caseActive = true;
		caseResult = NBC_CASE_RUNNING;
		caseVersion = CASE_VERSION;
		backing = BACKING_START;
		backingLog.Clear();
		crownSlot = crownGang >= 0 && crownGang < gangCount ? crownGang + 1 : 0;
		caseRaids = 0; caseTaken = 0; caseRetreats = 0; caseDowns = 0; caseLost = 0; caseMerit = 0;
		caseBackingLow = BACKING_START;
		summaryPending = false;
		readyDistrict = -1;
		seed = newSeed;
		rngState = newSeed;
		rngSteps = 0;
		day = 1;
		strikes = 0;
		cash = 0;
		raidActive = false;
		evKind = NBC_Clock.EV_NONE;
		evDistrict = -1;
		missedUrgent = false;

		gangToppled.Clear(); gangAlert.Clear();
		for (int i = 0; i < gangCount; i++) { gangToppled.Push(false); gangAlert.Push(0); }

		// shuffle the gangs, then deal them round the districts so every gang holds at least one; the Crown holds
		// its own tower
		Array<int> deck;
		for (int i = 0; i < gangCount; i++) if (i != crownGang) deck.Push(i);
		for (int i = deck.Size() - 1; i > 0; i--)
		{
			int j = Rand(0, i);
			int t = deck[i]; deck[i] = deck[j]; deck[j] = t;
		}
		districtGang.Clear();
		int k = 0;
		for (int d = 0; d < districtCount; d++)
		{
			if (d == crownDistrict) districtGang.Push(CrownGang());
			else districtGang.Push(deck.Size() > 0 ? deck[k++ % deck.Size()] : -1);
		}
	}

	// A case saved before Backing and the Crown: start them now (gangCount and the Crown as in NewCase).
	void Upgrade(int gangCount, int districtCount, int crownGang, int crownDistrict)
	{
		while (gangToppled.Size() < gangCount) gangToppled.Push(false);
		while (gangAlert.Size() < gangCount) gangAlert.Push(0);
		while (districtGang.Size() < districtCount) districtGang.Push(districtGang.Size() == crownDistrict ? crownGang : -1);
		if (caseVersion >= CASE_VERSION) return;
		caseVersion = CASE_VERSION;
		backing = BACKING_START;
		caseBackingLow = BACKING_START;
		crownSlot = crownGang >= 0 && crownGang < gangCount ? crownGang + 1 : 0;
	}

	clearscope int CrownGang() const { return crownSlot - 1; }
	clearscope bool IsCrown(int gi) const { return crownSlot > 0 && gi == crownSlot - 1; }

	// the gangs dealt to the districts (not the Crown)
	clearscope int RegularGangs() const
	{
		int n = 0;
		for (int i = 0; i < gangToppled.Size(); i++) if (!IsCrown(i)) n++;
		return n;
	}

	// The gangs still standing (not counting the Crown).
	clearscope int GangsLeft() const
	{
		int n = 0;
		for (int i = 0; i < gangToppled.Size(); i++) if (!gangToppled[i] && !IsCrown(i)) n++;
		return n;
	}

	clearscope int ToppledCount() const
	{
		int n = 0;
		for (int i = 0; i < gangToppled.Size(); i++) if (gangToppled[i] && !IsCrown(i)) n++;
		return n;
	}

	// how many more gangs have to fall before the Crown opens
	clearscope int CrownNeeds() const
	{
		return max(0, min(CROWN_AFTER, RegularGangs()) - ToppledCount());
	}
	clearscope bool CrownOpen() const { return crownSlot > 0 && CrownNeeds() == 0; }
	clearscope bool CrownTaken() const
	{
		int gi = CrownGang();
		return gi >= 0 && gi < gangToppled.Size() && gangToppled[gi];
	}

	// Backing goes up or down for a reason (shown on the next after-action report). At zero, Internal Affairs opens a
	// file: a strike, and Backing starts again at BACKING_RESET.
	void AddBacking(int n, String reason)
	{
		if (!caseActive || n == 0) return;
		backing = clamp(backing + n, 0, 100);
		caseBackingLow = min(caseBackingLow, backing);
		backingLog.Push(String.Format("%s %s%d", reason, n > 0 ? "+" : "", n));
		if (backing <= 0)
		{
			strikes++;
			backing = BACKING_RESET;
			backingLog.Push(String.Format("Backing hit zero. Internal Affairs opens a file: strike %d of %d", strikes, MAX_STRIKES));
		}
	}

	// the case ends: the Crown taken (or every gang, in a case without one), three strikes, or out of days
	void CheckCaseEnd()
	{
		if (!caseActive) return;
		if (crownSlot > 0 ? CrownTaken() : GangsLeft() == 0) caseResult = NBC_CASE_WON;
		else if (strikes >= MAX_STRIKES) caseResult = NBC_CASE_STRUCK_OUT;
		else if (day > MAX_DAYS) caseResult = NBC_CASE_DEMOLITION;
		if (caseResult == NBC_CASE_RUNNING) return;
		caseActive = false;
		readyDistrict = -1;
		if (caseResult == NBC_CASE_WON) casesClosed++;
		summaryPending = true;
		summarySerial++;
	}

	void BeginRaid(int district)
	{
		raidActive = true;
		raidDistrict = district;
		raidGang = district < districtGang.Size() ? districtGang[district] : -1;
		leaderDown = false;
		officerDown = false;
		raidKills = 0;
		raidBounty = 0;
		raidMap = "";
		raidVariant = 0;
		raidKitSeed = 0;
		raidEntry = 0;
		raidOff.Clear(); raidOffKills.Clear(); raidOffHealth.Clear();
		raidPlayerKills = 0;
		raidHealthLost = 0;
		raidTics = 0;
		raidShots = 0; raidHits = 0; raidLastHitTic = -1;
		raidBackingWas = backing;
		backingLog.Clear();
		raidIssued.Clear();
		raidOffTeam.Clear();
		NBC_Orders.Reset(self);
		raidMode = NBC_Motor.MODE_STREET;
		raidVehicles.Clear();
		crashWave = 0; crashNext = 0; crashClear = false;
		raidEvent = EventIn(district) ? evKind : NBC_Clock.EV_NONE;
		raidWindow = raidEvent != NBC_Clock.EV_NONE ? evWindow : planWindow;
	}

	// today's event, if it's in this district
	clearscope bool EventIn(int district) const
	{
		return evKind != NBC_Clock.EV_NONE && district >= 0 && district == evDistrict;
	}

	// the hour a raid on this district goes in at: the event's, or the one picked
	clearscope int WindowFor(int district) const
	{
		return EventIn(district) ? evWindow : clamp(planWindow, 0, NBC_Clock.W_COUNT - 1);
	}

	// Each morning, maybe something's going down somewhere (from day 2; only where a gang still stands)
	void RollEvent()
	{
		evKind = NBC_Clock.EV_NONE;
		evDistrict = -1;
		if (day < 2 || Rand(0, 99) >= NBC_Clock.EVENT_CHANCE) return;
		Array<int> open;
		for (int d = 0; d < districtGang.Size(); d++)
		{
			int gi = districtGang[d];
			if (gi >= 0 && gi < gangToppled.Size() && !gangToppled[gi] && !IsCrown(gi)) open.Push(d);
		}
		if (!open.Size()) return;
		int r = Rand(0, 99);
		evKind = r < 25 ? NBC_Clock.EV_WAR : (r < 45 ? NBC_Clock.EV_CROWD : (r < 70 ? NBC_Clock.EV_DEAL : (r < 85 ? NBC_Clock.EV_BLACKOUT : NBC_Clock.EV_PINNED)));
		evDistrict = open[Rand(0, open.Size() - 1)];
		evWindow = NBC_Clock.EventWindow(evKind, self);
	}

	clearscope int TeamOfSlot(int slot) const
	{
		return slot >= 0 && slot < raidOffTeam.Size() ? raidOffTeam[slot] : 0;
	}

	clearscope int RaidSlotOf(int officerId) const
	{
		for (int i = 0; i < raidOff.Size(); i++) if (raidOff[i] == officerId) return i;
		return -1;
	}

	// One day passes (the department heals its officers: NBC_Department.NewDay): alert decays for gangs you left alone, the case may end.
	// raided: the district raided today (-1: none); a pinned-down unit left where it was is a strike.
	void EndDay(int hitGang, int raided = -1)
	{
		missedUrgent = evKind == NBC_Clock.EV_PINNED && evDistrict >= 0 && raided != evDistrict;
		evDistrictWas = evDistrict;
		if (missedUrgent) strikes++;
		day++;
		readyDistrict = -1;
		for (int i = 0; i < gangAlert.Size(); i++)
			if (i != hitGang && gangAlert[i] > 0) gangAlert[i]--;

		CheckCaseEnd();
		RollEvent();
	}
}
