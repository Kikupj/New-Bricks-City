// Case and raid state (AGENTS.md: one STAT_STATIC thinker, saved with the game, kept across maps).
// All case and raid randomness comes from Rand() here, so a seed reproduces a case.

enum NBC_CaseResult
{
	NBC_CASE_RUNNING = 0,
	NBC_CASE_WON,          // every gang toppled
	NBC_CASE_STRUCK_OUT,   // 3 strikes: Internal Affairs pulls you
	NBC_CASE_DEMOLITION,   // out of days
}

class NBC_RunData : Thinker
{
	const MAX_DAYS = 30;
	const MAX_STRIKES = 3;

	bool caseActive;
	int caseResult;
	int seed, rngState, rngSteps;
	int day, strikes, cash, casesClosed;

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

	void NewCase(int newSeed, int gangCount, int districtCount)
	{
		caseActive = true;
		caseResult = NBC_CASE_RUNNING;
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

		// shuffle the gangs, then deal them round the districts so every gang holds at least one
		Array<int> deck;
		for (int i = 0; i < gangCount; i++) deck.Push(i);
		for (int i = deck.Size() - 1; i > 0; i--)
		{
			int j = Rand(0, i);
			int t = deck[i]; deck[i] = deck[j]; deck[j] = t;
		}
		districtGang.Clear();
		for (int d = 0; d < districtCount; d++)
			districtGang.Push(gangCount > 0 ? deck[d % gangCount] : -1);
	}

	// The gangs still standing; the case is won when none are.
	clearscope int GangsLeft() const
	{
		int n = 0;
		for (int i = 0; i < gangToppled.Size(); i++) if (!gangToppled[i]) n++;
		return n;
	}

	clearscope int ToppledCount() const
	{
		int n = 0;
		for (int i = 0; i < gangToppled.Size(); i++) if (gangToppled[i]) n++;
		return n;
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
			if (gi >= 0 && gi < gangToppled.Size() && !gangToppled[gi]) open.Push(d);
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

		if (GangsLeft() == 0) caseResult = NBC_CASE_WON;
		else if (strikes >= MAX_STRIKES) caseResult = NBC_CASE_STRUCK_OUT;
		else if (day > MAX_DAYS) caseResult = NBC_CASE_DEMOLITION;
		if (caseResult != NBC_CASE_RUNNING)
		{
			caseActive = false;
			if (caseResult == NBC_CASE_WON) casesClosed++;
		}
		RollEvent();
	}
}
