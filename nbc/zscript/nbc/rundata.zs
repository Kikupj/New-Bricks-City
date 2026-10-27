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
	const SQUAD_SIZE = 2;

	bool caseActive;
	int caseResult;
	int seed, rngState, rngSteps;
	int day, strikes, cash, casesClosed;

	// per gang (index into NBC_RunManager.gangs) and per district (index into the district pool)
	Array<bool> gangToppled;
	Array<int> gangAlert;
	Array<int> districtGang;

	// the current raid
	bool raidActive, leaderDown, officerDown;
	int raidDistrict, raidGang, raidKills, raidBounty;
	Array<int> squadHealth;
	Array<String> squadNames;

	// the card shown back at the hub
	Array<String> report;
	bool reportPending;

	static NBC_RunData Get()
	{
		let it = ThinkerIterator.Create("NBC_RunData", STAT_STATIC);
		let rd = NBC_RunData(it.Next());
		if (!rd)
		{
			rd = new("NBC_RunData");
			rd.ChangeStatNum(STAT_STATIC);
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
		seed = newSeed;
		rngState = newSeed;
		rngSteps = 0;
		day = 1;
		strikes = 0;
		cash = 0;
		raidActive = false;
		reportPending = false;
		report.Clear();

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

		squadNames.Clear(); squadHealth.Clear();
		static const String first[] = { "Reyes", "Okafor", "Brandt", "Castillo", "Nguyen", "Doyle", "Harlan", "Mbeki", "Sorensen", "Vance" };
		static const String rank[] = { "Ofc.", "Ofc.", "Cpl." };
		Array<int> used;
		for (int s = 0; s < SQUAD_SIZE; s++)
		{
			int k = Rand(0, 9);
			while (used.Find(k) != used.Size()) k = (k + 1) % 10;
			used.Push(k);
			squadNames.Push(rank[Rand(0, 2)] .. " " .. first[k]);
			squadHealth.Push(100);
		}
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
	}

	// One day passes: officers recover, alert decays for gangs you left alone, the case may end.
	void EndDay(int hitGang)
	{
		day++;
		for (int i = 0; i < gangAlert.Size(); i++)
			if (i != hitGang && gangAlert[i] > 0) gangAlert[i]--;
		for (int s = 0; s < squadHealth.Size(); s++)
			squadHealth[s] = squadHealth[s] <= 0 ? 100 : min(100, squadHealth[s] + 50);

		if (GangsLeft() == 0) caseResult = NBC_CASE_WON;
		else if (strikes >= MAX_STRIKES) caseResult = NBC_CASE_STRUCK_OUT;
		else if (day > MAX_DAYS) caseResult = NBC_CASE_DEMOLITION;
		if (caseResult != NBC_CASE_RUNNING)
		{
			caseActive = false;
			if (caseResult == NBC_CASE_WON) casesClosed++;
		}
	}
}
