// =============================================================================
// Corpo Wars — the city layer: the daily tick (design: city-layer-design.md "Daily tick")
//   1 income and upkeep -> treasuries      2 agendas            3 operations: prep, deadlines, launches
//   4 minor-player turf and dormancy      5 property market    6 collapse, carve-up, patron, win / loss
//   7 news
// Tuning numbers live in CW_Tune so they can be balanced in one place (soak test: netevent cw_simdays N).
// =============================================================================

class CW_Tune
{
	const OPEX = 0.55;           // running cost as a share of a property's base yield
	const SEC_COST = 0.035;      // $k/day per guard x tech level
	const ADMIN = 1.0;           // $k/day overhead per subsidiary
	const INTEREST = 0.004;      // Meridian interest per day on corp debt
	const CASH_FLOOR = 30;       // $k a corp tries to keep in hand
	const CREDIT_PCT = 30;       // Meridian credit line: % of property value
	const PROP_VALUE = 12;       // property value = base yield x this ($k)
	const GRACE_DAYS = 3;        // days over the credit limit before Meridian seizes a property
	const OP_RETAINER = 5;       // $k a client pays freelancers on top of the step fees
	const OPS_MIN = 6;
	const OPS_MAX = 10;
	const FREELANCE_ODDJOB = 14;
	const INCIDENT_COST = 16;    // $k a corp pays after every successful hit on one of its sites (plus 1/8 of the site's value) // % chance per day that freelancers finish an open odd job
}

extend class CW_City
{
	int pendingBonus;            // $ owed to the player (operation success bonuses), collected by the ledger
	Array<String> pendingLines;  // ... and the lines explaining it

	// ================================================================ the day tick
	void AdvanceDay()
	{
		if (outcome) return;
		todayNews.Clear();
		day++;
		Economy();
		UpdateAgendas();
		ProgressOps();
		LaunchOps();
		MinorUpkeep();
		Market();
		CollapseCheck();
		PatronCheck();
		WinLossCheck();
		if (todayNews.Size() == 0) QuietDay();
		BuildOffers();
	}

	// what the decisive strike is after ("the Helix prototype")
	clearscope String StrikeItem(CWC_Op op)
	{
		for (int i = 0; i < op.steps.Size(); i++) if (op.steps[i].role == R_CONTRACT && op.steps[i].what.Length()) return op.steps[i].what;
		return "the " .. StealNoun(op.tProp);
	}

	// Nothing happened: the wire still carries hints (fog of war: debts, agendas, turf).
	void QuietDay()
	{
		switch (Random[CWSim](0, 3))
		{
		case 0:
		{
			int worst = -1; double wr = 0.3;
			for (int c = 0; c < NCORP; c++) if (corps[c].alive && CreditLimit(c) > 0 && corps[c].debt / double(CreditLimit(c)) > wr) { wr = corps[c].debt / double(CreditLimit(c)); worst = c; }
			if (worst >= 0) { AddNews(String.Format("Meridian analysts are watching %s's credit line.", corps[worst].short)); return; }
			break;
		}
		case 1:
		{
			int i = Random[CWSim](0, max(0, agendas.Size() - 1));
			if (i < agendas.Size() && IsCorp(agendas[i].owner) && IsCorp(agendas[i].target))
			{ AddNews(String.Format("Insiders say %s has its eye on %s.", corps[agendas[i].owner].short, corps[agendas[i].target].short)); return; }
			break;
		}
		case 2:
		{
			int m = Random[CWSim](0, minors.Size() - 1);
			if (!minors[m].dormant)
			{
				int bd = 0;
				for (int d = 1; d < NDIST; d++) if (minors[m].turf[d] > minors[m].turf[bd]) bd = d;
				AddNews(String.Format("%s is out in force in %s.", minors[m].short, distName[bd]));
				return;
			}
			break;
		}
		}
		AddNews("A quiet day on the wire.");
	}

	// bootstrap the first day: the four existing jobs become the city's opening operations
	void StartCampaign()
	{
		CalibrateOverhead();
		SeedOpeningOps();
		for (int i = 0; i < 2; i++) TryLaunch();
		AddNews("Day 1. Six corps, one lender, one city. Your desk is open for business.");
		BuildOffers();
	}

	// ================================================================ 1: economy
	// A corp's daily margin from its properties: yields (with executive bonuses) minus running costs,
	// security and power. Fixed overhead (HQ, lawyers, lobbying) is set per corp at the start of a campaign
	// (CalibrateOverhead), so a property is worth owning, losing one hurts, and buying one pays back in ~6 weeks.
	double CorpMargin(int c)
	{
		let o = corps[c];
		double yield = 0, cost = 0;
		for (int p = 0; p < props.Size(); p++)
		{
			if (PropCorp(p) != c) continue;
			let pr = props[p];
			yield += PropYield(p);
			double sec = PropForce(p) * PropTech(p) * CW_Tune.SEC_COST;
			if (day < pr.troubleUntil) { sec *= 1.5; yield -= TypeYield(pr.type) * 0.1; }
			double pw = TypePower(pr.type);
			if (o.code == "COR") pw *= 0.5;
			if (o.code == "LAT" && pr.type == PT_DC) pw *= HelionOnline() ? 0.9 : 1.3;
			cost += TypeYield(pr.type) * CW_Tune.OPEX + sec + pw;
		}
		int ceo = CeoOf(c);
		if (ceo >= 0) yield *= 1.0 + execs[ceo].bonus / 100.0;
		return yield - cost - SubCount(c) * CW_Tune.ADMIN;
	}

	void CalibrateOverhead()
	{
		for (int c = 0; c < corps.Size(); c++)
		{
			// richer corps start a little in the black, the poorest roughly break even
			double target = corps[c].wealth * 1.5 - 3.0;
			corps[c].overhead = max(0, int(round(CorpMargin(c) - target)));
		}
	}

	void Economy()
	{
		for (int c = 0; c < corps.Size(); c++)
		{
			let o = corps[c];
			if (!o.alive) continue;
			int net = int(round(CorpMargin(c) - o.overhead - o.debt * CW_Tune.INTEREST));
			o.treasury += net;
			if (o.treasury < 0) { o.debt += -o.treasury; o.treasury = 0; }
			else if (o.debt > 0 && o.treasury > CW_Tune.CASH_FLOOR * 2)
			{
				int pay = min(o.debt, (o.treasury - CW_Tune.CASH_FLOOR * 2) / 2);
				o.debt -= pay; o.treasury -= pay;
			}
			// a CEO lost to a rival: the board installs an acting chief after ~10 days
			if (CeoOf(c) < 0 && day % 10 == 0) PromoteCeo(c);
			// replacements for executives lost to rivals (~10 days)
			for (int s = 0; s < subs.Size(); s++)
			{
				let sb = subs[s];
				if (sb.corp == c && sb.head < 0 && day >= VacantUntil(s)) PromoteDeputy(s);
			}
		}
		// lease renewals
		for (int p = 0; p < props.Size(); p++)
		{
			let pr = props[p];
			if (pr.leaseEnd <= 0 || day != pr.leaseEnd || pr.seized) continue;
			int c = PropCorp(p);
			if (c < 0) continue;
			int fee = PropValue(p) * 15 / 100;
			// renewals go on credit if need be; only a corp with no cash and no credit loses the lease
			if (corps[c].treasury + max(0, CreditLimit(c) - corps[c].debt) - fee >= CW_Tune.CASH_FLOOR) { Spend(c, fee); pr.leaseEnd = day + Random[CWSim](40, 90); }
			else if (!Listed(p, false))
			{
				ListProperty(p, c, 2);
				AddNews(String.Format("%s can't renew the lease on %s. It goes to auction on day %d.", corps[c].short, PropName(p), day + 2));
			}
		}
	}

	bool HelionOnline()
	{
		int h = FindSub("HEL");
		return h >= 0 && subs[h].corp == FindCorp("LAT");
	}
	clearscope int CeoOf(int c)
	{
		for (int e = 0; e < execs.Size(); e++) if (execs[e].ceo && execs[e].corp == c && !execs[e].gone) return e;
		return -1;
	}
	// a vacancy lasts ~10 days after the head was poached (stored on the exec who left)
	int VacantUntil(int s)
	{
		int u = 0;
		for (int e = 0; e < execs.Size(); e++) if (execs[e].sub == -2 - s) u = max(u, execs[e].movedDay + 10);
		return u;
	}
	void PromoteCeo(int c)
	{
		let o = new("CWC_Exec");
		o.name = "(acting CEO)";
		o.role = "acting CEO of " .. corps[c].short;
		o.corp = c; o.sub = -1; o.minor = -1; o.bonus = 2; o.ceo = true; o.prop = -1; o.locKnown = true; o.movedDay = day;
		execs.Push(o);
	}
	void PromoteDeputy(int s)
	{
		// an unnamed, weaker replacement: a 4% bonus head with no name to poach
		let o = new("CWC_Exec");
		o.name = "(acting head)";
		o.role = "acting head of " .. subs[s].name;
		o.corp = subs[s].corp; o.sub = s; o.minor = -1; o.bonus = 4; o.gone = false;
		o.prop = -1;
		for (int p = 0; p < props.Size(); p++) if (props[p].sub == s) { o.prop = p; o.district = props[p].district; break; }
		o.locKnown = true;
		o.movedDay = day;
		execs.Push(o);
		subs[s].head = execs.Size() - 1;
	}

	// ================================================================ 2: agendas
	void UpdateAgendas()
	{
		// drop agendas that no longer make sense (target collapsed / dormant)
		for (int i = agendas.Size() - 1; i >= 0; i--)
		{
			let a = agendas[i];
			bool dead = (IsCorp(a.owner) && !corps[a.owner].alive) || (IsMinor(a.owner) && false);
			if (IsCorp(a.target) && !corps[a.target].alive) dead = true;
			if (a.focusSub >= 0 && IsCorp(a.owner) && a.kind == AG_PROTECT && subs[a.focusSub].corp != a.owner) dead = true;
			if (dead) agendas.Delete(i);
		}
		for (int f = 0; f < NCORP + NMINOR; f++)
		{
			int fac = f < NCORP ? f : MINOR_BASE + f - NCORP;
			if (IsCorp(fac) && !corps[fac].alive) continue;
			if ((day + f * 3) % 7) continue;          // each faction re-thinks about once a week
			int want = IsCorp(fac) ? 2 + (corps[fac].aggression >= 4 ? 1 : 0) : 2;
			int have = CountAgendas(fac);
			// every few weeks one old goal gives way to a new one
			if (have >= want && Random[CWSim](0, 99) < 30)
			{
				int oldest = OldestAgenda(fac);
				if (oldest >= 0 && day - agendas[oldest].since > 12) { agendas.Delete(oldest); have--; }
			}
			if (have < want) NewAgenda(fac);
		}
	}
	clearscope int CountAgendas(int f) { int n = 0; for (int i = 0; i < agendas.Size(); i++) if (agendas[i].owner == f) n++; return n; }
	int OldestAgenda(int f)
	{
		int best = -1;
		for (int i = 0; i < agendas.Size(); i++) if (agendas[i].owner == f && (best < 0 || agendas[i].since < agendas[best].since)) best = i;
		return best;
	}

	void NewAgenda(int f)
	{
		let a = new("CWC_Agenda");
		a.owner = f; a.target = -1; a.focusSub = -1; a.district = -1; a.since = day;
		if (IsMinor(f))
		{
			let m = minors[f - MINOR_BASE];
			// push into the district where they're strongest, or hit the corp that hurts them most
			if (Random[CWSim](0, 1))
			{
				int bd = 0;
				for (int d = 1; d < NDIST; d++) if (m.turf[d] > m.turf[bd]) bd = d;
				a.kind = AG_TURF; a.district = bd;
				a.text = String.Format("Hold %s", distName[bd]);
			}
			else
			{
				int worst = WorstCorpFor(f);
				if (worst < 0) return;
				a.kind = AG_HURT; a.target = worst;
				a.text = String.Format("Make %s pay", corps[worst].short);
			}
			agendas.Push(a);
			return;
		}
		let o = corps[f];
		Array<int> kinds, w;
		kinds.Push(AG_HURT); w.Push(30 + o.aggression * 8);
		kinds.Push(AG_TECH); w.Push(o.special == "STRIKEBREAK" || o.tech >= 5 ? 30 : 12);
		kinds.Push(AG_SUPPRESS); w.Push(20);
		kinds.Push(AG_HIRE); w.Push(o.wRec * 8);
		kinds.Push(AG_EXPOSE); w.Push(o.special == "EXPOSE" ? 35 : 4);
		kinds.Push(AG_PROTECT); w.Push(o.aggression <= 2 ? 25 : 8);
		int k = kinds[PickWeighted(w)];
		a.kind = k;
		switch (k)
		{
		case AG_HURT:
		{
			int t = FinishingTarget(f);
			bool finish = t >= 0;
			if (t < 0) t = WorstCorpFor(f);
			if (t < 0) return;
			a.target = t;
			a.text = finish ? String.Format("Finish off %s", corps[t].short) : String.Format("Hurt %s", corps[t].short);
			break;
		}
		case AG_TECH:
		{
			int t = RichestTech(f);
			if (t < 0) return;
			a.target = t;
			a.text = String.Format("Get %s's tech", corps[t].short);
			break;
		}
		case AG_SUPPRESS:
		{
			int m = MinorInMyWay(f);
			if (m < 0) return;
			a.target = MINOR_BASE + m;
			a.text = String.Format("Push %s back", minors[m].short);
			break;
		}
		case AG_HIRE: a.text = "Out-hire everyone"; break;
		case AG_EXPOSE: a.text = "Expose a rival's shell"; break;
		case AG_PROTECT:
		{
			int best = -1, bv = -1;
			for (int s = 0; s < subs.Size(); s++) if (subs[s].corp == f && SubValue(s) > bv) { bv = SubValue(s); best = s; }
			a.focusSub = best;
			a.text = best >= 0 ? String.Format("Protect %s", subs[best].name) : "Dig in";
			break;
		}
		}
		agendas.Push(a);
		if (Random[CWSim](0, 99) < 35 && IsCorp(a.target))
			AddNews(String.Format("Analysts say %s is circling %s.", o.short, corps[a.target].short));
	}

	int WorstCorpFor(int f)
	{
		int best = -1, bv = 999;
		for (int c = 0; c < NCORP; c++)
		{
			if (c == f || !corps[c].alive) continue;
			int v = GetRel(f, c) + Random[CWSim](-8, 8);
			if (v < bv) { bv = v; best = c; }
		}
		return best;
	}
	// a hostile rival close to foreclosure: "finish them"
	int FinishingTarget(int f)
	{
		for (int c = 0; c < NCORP; c++)
			if (c != f && corps[c].alive && GetRel(f, c) < 0 && corps[c].debt > CreditLimit(c) * 7 / 10) return c;
		return -1;
	}
	int RichestTech(int f)
	{
		int best = -1, bv = -1;
		for (int c = 0; c < NCORP; c++)
		{
			if (c == f || !corps[c].alive || GetRel(f, c) >= 75) continue;
			int v = corps[c].tech * 10 - GetRel(f, c) / 5 + Random[CWSim](0, 10);
			if (c == FindCorp("COR") && corps[f].special == "STRIKEBREAK") v += 30;   // Lattice wants Corvane's power tech
			if (v > bv) { bv = v; best = c; }
		}
		return best;
	}
	// the minor player with the most turf where this corp owns property
	int MinorInMyWay(int f)
	{
		int best = -1, bv = 0;
		for (int m = 0; m < minors.Size(); m++)
		{
			if (minors[m].dormant) continue;
			int v = 0;
			for (int p = 0; p < props.Size(); p++) if (PropCorp(p) == f) v += minors[m].turf[props[p].district];
			v -= GetRel(f, MINOR_BASE + m);
			if (v > bv) { bv = v; best = m; }
		}
		return best;
	}

	int PickWeighted(Array<int> w)
	{
		int tot = 0;
		for (int i = 0; i < w.Size(); i++) tot += max(0, w[i]);
		if (tot <= 0) return 0;
		int r = Random[CWSim](0, tot - 1);
		for (int i = 0; i < w.Size(); i++) { r -= max(0, w[i]); if (r < 0) return i; }
		return w.Size() - 1;
	}

	// ================================================================ 3: operations
	clearscope int ActiveOps() { int n = 0; for (int i = 0; i < ops.Size(); i++) if (ops[i].state == 0) n++; return n; }
	clearscope CWC_Op FindOp(int id) { for (int i = 0; i < ops.Size(); i++) if (ops[i].id == id) return ops[i]; return null; }

	void LaunchOps()
	{
		int cap = CW_Tune.OPS_MIN + (day * 7 / 3) % (CW_Tune.OPS_MAX - CW_Tune.OPS_MIN + 1);
		int launched = 0;
		for (int tries = 0; tries < 6 && launched < 2 && ActiveOps() < cap; tries++)
			if (TryLaunch()) launched++;
		// old, finished operations are forgotten after a while
		for (int i = ops.Size() - 1; i >= 0; i--) if (ops[i].state && day - ops[i].deadline > 6) ops.Delete(i);
	}

	bool TryLaunch()
	{
		// who moves: weighted by aggression and means
		Array<int> fs, w;
		for (int c = 0; c < NCORP; c++)
		{
			if (!corps[c].alive) continue;
			int room = corps[c].treasury + max(0, CreditLimit(c) - corps[c].debt);
			if (room < 25) continue;
			fs.Push(c); w.Push(corps[c].aggression * 10 + (corps[c].treasury > 150 ? 8 : 0));
		}
		for (int m = 0; m < minors.Size(); m++)
		{
			if (minors[m].dormant || minors[m].funds < 10) continue;
			fs.Push(MINOR_BASE + m); w.Push(minors[m].aggression * 5);
		}
		if (!fs.Size()) return false;
		int f = fs[PickWeighted(w)];
		// pick one of its agendas (PROTECT agendas launch counter-operations, not attacks)
		Array<int> ag, aw;
		for (int i = 0; i < agendas.Size(); i++)
			if (agendas[i].owner == f && agendas[i].kind != AG_PROTECT) { ag.Push(i); aw.Push(10); }
		let a = ag.Size() ? agendas[ag[PickWeighted(aw)]] : null;
		return BuildOp(f, a) != null;
	}

	// Score every target the faction could hit and build an operation against one of the best.
	CWC_Op BuildOp(int f, CWC_Agenda a, int forceProp = -1, int forceGoal = -1, int forceHold = -1)
	{
		int aggr = IsCorp(f) ? corps[f].aggression : minors[f - MINOR_BASE].aggression;
		int tProp = forceProp, tHold = forceHold;
		if (tProp < 0 && tHold < 0)
		{
			Array<int> cand, score;
			bool suppress = a && a.kind == AG_SUPPRESS && IsMinor(a.target);
			if (suppress)
			{
				for (int h = 0; h < holds.Size(); h++)
				{
					let hd = holds[h];
					if (MINOR_BASE + hd.minor != a.target || !HoldActive(h)) continue;
					cand.Push(-2 - h); score.Push(minors[hd.minor].turf[hd.district] + 20 + Random[CWSim](0, 20));
				}
			}
			else
			{
				for (int p = 0; p < props.Size(); p++)
				{
					int s = TargetScore(f, a, p);
					if (s > 0) { cand.Push(p); score.Push(s * (6 + aggr) / 8); }
				}
			}
			if (!cand.Size()) return null;
			// weighted random among the top five
			Array<int> top, tw;
			for (int n = 0; n < 5; n++)
			{
				int bi = -1;
				for (int i = 0; i < cand.Size(); i++) if (score[i] > -1 && (bi < 0 || score[i] > score[bi])) bi = i;
				if (bi < 0) break;
				top.Push(cand[bi]); tw.Push(score[bi]);
				score[bi] = -1;
			}
			int pick = top[PickWeighted(tw)];
			if (pick <= -2) tHold = -2 - pick; else tProp = pick;
		}

		let op = new("CWC_Op");
		op.id = nextOpId++;
		op.client = f;
		op.tProp = tProp; op.tStronghold = tHold; op.tExec = -1; op.counterOf = -1;
		op.startDay = day;
		op.deadline = day + Random[CWSim](5, 10);
		op.agendaKind = a ? a.kind : -1;
		if (tHold >= 0)
		{
			let hd = holds[tHold];
			op.tFaction = MINOR_BASE + hd.minor;
			op.tDistrict = hd.district;
			op.goal = G_SUPPRESS;
			op.tExec = LeaderAt(hd.minor, hd.district);
		}
		else
		{
			op.tFaction = PropCorp(tProp);
			op.tDistrict = props[tProp].district;
			op.goal = forceGoal >= 0 ? forceGoal : PickGoal(f, a, tProp);
			if (op.goal == G_RECRUIT) op.tExec = ExecAt(tProp);
		}
		op.launcher = IsCorp(f) ? PickLauncher(f, op) : -1;
		op.clientKnown = op.launcher < 0 || !subs[op.launcher].shell || subs[op.launcher].shellKnown;
		op.title = OpTitle(op);
		BuildSteps(op);
		// the client pays up front: step fees plus the freelancers' retainer
		int cost = CW_Tune.OP_RETAINER;
		for (int i = 0; i < op.steps.Size(); i++) cost += op.steps[i].pay / 1000;
		if (IsCorp(f)) Spend(f, cost);
		else minors[f - MINOR_BASE].funds -= cost / 2;
		ops.Push(op);
		if (Random[CWSim](0, 99) < 25) AddNews(RumourLine(op));
		// the target may catch wind of it and answer
		MaybeCounter(op);
		return op;
	}

	int TargetScore(int f, CWC_Agenda a, int p)
	{
		let pr = props[p];
		if (pr.seized || pr.sub < 0) return 0;
		int owner = PropCorp(p);
		if (owner < 0 || owner == f || !corps[owner].alive) return 0;
		if (IsCorp(f) && GetRel(f, owner) >= 75) return 0;          // allies don't hit each other
		int fit = 0;
		if (IsMinor(f))
		{
			let m = minors[f - MINOR_BASE];
			if (m.turf[pr.district] < 15) return 0;                // only on their own turf
			fit += m.turf[pr.district] / 2;
			if (a && a.kind == AG_TURF && a.district == pr.district) fit += 25;
			// each group has its favourite kind of target
			if (m.special == "STRIKE" && (pr.type == PT_FAB || pr.type == PT_WH || pr.type == PT_DOCK)) fit += 20;
			if (m.special == "EXTORT" && (pr.type == PT_WH || pr.type == PT_DOCK || pr.type == PT_CLN || pr.type == PT_SAL)) fit += 20;
			if (m.special == "LEAK" && (pr.type == PT_DC || subs[pr.sub].shell)) fit += 20;
			if (m.special == "PROTEST" && pr.district == FindDist("OQ")) fit += 15;
		}
		if (a)
		{
			if (a.target == owner) fit += 40;
			if (a.focusSub >= 0 && pr.sub == a.focusSub) fit += 25;
			if (a.kind == AG_TECH && (pr.type == PT_RND || pr.type == PT_LAB || pr.type == PT_PLT || pr.type == PT_DC || pr.type == PT_FAB)) fit += 25;
			if (a.kind == AG_HIRE && ExecAt(p) >= 0) fit += 35;
			if (a.kind == AG_EXPOSE && subs[pr.sub].shell && !subs[pr.sub].shellKnown) fit += 35;
		}
		int hostility = -GetRel(f, owner) / 2;
		int weakness = (16 - PropForce(p)) * 2 + (4 - PropTech(p)) * 4;
		if (corps[owner].debt > CreditLimit(owner) * 7 / 10) weakness += 15;
		if (day < pr.refitUntil) weakness += 10;
		int value = TypeYield(pr.type) * 2;
		int opportunity = (day < pr.damagedUntil || day < pr.strikeUntil || day < pr.scandalUntil) ? 8 : 0;
		if (patron >= 0 && f == patron && GetRel(f, owner) < 0) fit += 15;   // your patron goes after its enemies
		int s = fit + hostility + weakness + value + opportunity + Random[CWSim](0, 12);
		// don't pile several operations onto one site
		for (int i = 0; i < ops.Size(); i++) if (ops[i].state == 0 && ops[i].tProp == p) s -= 40;
		return max(0, s);
	}

	int PickGoal(int f, CWC_Agenda a, int p)
	{
		let pr = props[p];
		if (IsMinor(f))
		{
			let m = minors[f - MINOR_BASE];
			Array<int> g, w;
			if (m.special == "STRIKE") { g.Push(G_STRIKE); w.Push(60); g.Push(G_LEAK); w.Push(20); }
			if (m.special == "EXTORT") { g.Push(G_EXTORT); w.Push(40); g.Push(G_RAID); w.Push(30); g.Push(G_STEAL); w.Push(30); }
			if (m.special == "LEAK")   { g.Push(G_LEAK); w.Push(60); g.Push(G_STEAL); w.Push(30); }
			if (m.special == "PROTEST"){ g.Push(G_PROTEST); w.Push(70); g.Push(G_LEAK); w.Push(15); }
			if (!g.Size()) return G_RAID;
			return g[PickWeighted(w)];
		}
		let o = corps[f];
		int ws = o.wSteal * 10, wb = o.wSab * 10, wr = o.wRec * 10;
		int owner = PropCorp(p);
		if (owner >= 0 && corps[owner].debt > CreditLimit(owner) * 7 / 10 && wb > 0) wb += 25;   // finish them
		if (ExecAt(p) >= 0) wr += 15; else wr /= 3;
		if (a)
		{
			if (a.kind == AG_TECH) { ws += 20; wr += 10; }
			if (a.kind == AG_HIRE) wr += 30;
			if (a.kind == AG_EXPOSE) ws += 30;
		}
		Array<int> w;
		w.Push(ws); w.Push(wb); w.Push(wr);
		int k = PickWeighted(w);
		return k == 0 ? G_STEAL : (k == 1 ? G_SABOTAGE : G_RECRUIT);
	}

	clearscope int ExecAt(int p)
	{
		for (int e = 0; e < execs.Size(); e++)
		{
			let x = execs[e];
			if (!x.gone && x.minor < 0 && x.prop == p && x.name.Left(1) != "(") return e;
		}
		return -1;
	}
	clearscope int LeaderAt(int m, int d)
	{
		for (int e = 0; e < execs.Size(); e++) if (!execs[e].gone && execs[e].minor == m && execs[e].district == d) return e;
		return -1;
	}
	clearscope bool HoldActive(int h)
	{
		let hd = holds[h];
		return !minors[hd.minor].dormant && minors[hd.minor].turf[hd.district] >= 30;
	}

	// the subsidiary that fronts the operation: a shell for dirty work, else one in the target's line of business
	int PickLauncher(int f, CWC_Op op)
	{
		Array<int> mine;
		for (int s = 0; s < subs.Size(); s++) if (subs[s].corp == f) mine.Push(s);
		if (!mine.Size()) return -1;
		bool dirty = op.goal == G_SABOTAGE || corps[f].ethics <= 2 || op.goal == G_SUPPRESS;
		if (dirty && Random[CWSim](0, 99) < 55)
		{
			Array<int> shells;
			for (int i = 0; i < mine.Size(); i++) if (subs[mine[i]].shell) shells.Push(mine[i]);
			if (shells.Size()) return shells[Random[CWSim](0, shells.Size() - 1)];
		}
		if (op.tProp >= 0)
		{
			int tt = props[op.tProp].type;
			for (int i = 0; i < mine.Size(); i++)
				for (int p = 0; p < props.Size(); p++)
					if (props[p].sub == mine[i] && props[p].type == tt && Random[CWSim](0, 1)) return mine[i];
		}
		return mine[Random[CWSim](0, mine.Size() - 1)];
	}

	clearscope String GoalPhrase(CWC_Op op)
	{
		String who = op.tExec >= 0 ? execs[op.tExec].name : "";
		switch (op.goal)
		{
		case G_STEAL:    return op.agendaKind == AG_EXPOSE ? "dig up the records" : "steal the " .. StealNoun(op.tProp);
		case G_SABOTAGE: return "sabotage the site";
		case G_RECRUIT:  return who.Length() ? "poach " .. who : "poach a lead engineer";
		case G_STRIKE:   return "walk out";
		case G_RAID:     return "raid the site";
		case G_LEAK:     return "leak the files";
		case G_PROTEST:  return "blockade the site";
		case G_EXTORT:   return "shake them down";
		case G_SUPPRESS: return who.Length() ? "take down " .. who : "break their hold";
		case G_COUNTER:  return "find the leak, harden the site";
		}
		return "?";
	}
	clearscope String StealNoun(int p)
	{
		if (p < 0) return "files";
		switch (props[p].type)
		{
		case PT_LAB: return PropCorp(p) >= 0 && corps[PropCorp(p)].code == "COR" ? "power-cell prototype" : "specimen case";
		case PT_RND: case PT_BNK: return "prototype";
		case PT_DC: return "training data";
		case PT_FAB: return "line designs";
		case PT_PLT: case PT_SUB: return "grid schematics";
		case PT_CLN: return "trial data";
		case PT_STU: return "raw footage";
		case PT_WH: case PT_DOCK: case PT_PARK: return "manifests";
		case PT_FARM: return "strain samples";
		case PT_TRN: return "doctrine files";
		case PT_SAL: return "package";
		case PT_HQ: return "board minutes";
		}
		return "books";
	}
	clearscope String TargetLabel(CWC_Op op)
	{
		if (op.tStronghold >= 0) { let hd = holds[op.tStronghold]; return String.Format("%s (%s, %s)", hd.name, minors[hd.minor].short, distCode[hd.district]); }
		return PropName(op.tProp);
	}
	String OpTitle(CWC_Op op)
	{
		String by = op.launcher >= 0 ? subs[op.launcher].name : FactionShort(op.client);
		String vs = op.tStronghold >= 0 ? minors[holds[op.tStronghold].minor].short : (props[op.tProp].sub >= 0 ? subs[props[op.tProp].sub].name : "?");
		return String.Format("%s vs %s: %s", by, vs, GoalPhrase(op));
	}
	String RumourLine(CWC_Op op)
	{
		switch (Random[CWSim](0, 2))
		{
		case 0: return String.Format("Street talk: someone's asking questions about %s.", TargetLabel(op));
		case 1: return String.Format("Freelancers are being hired in %s. Nobody says by whom.", distName[op.tDistrict]);
		}
		return String.Format("Security contractors report probing around %s.", TargetLabel(op));
	}

	// ---- steps: one decisive contract + 1-3 odd jobs at neutral sites (contract-hierarchy.md)
	void BuildSteps(CWC_Op op)
	{
		int wealth = IsCorp(op.client) ? corps[op.client].wealth : 2;
		let c = new("CWC_Step");
		c.role = R_CONTRACT; c.decisive = true;
		c.prop = op.tProp; c.stronghold = op.tStronghold; c.district = op.tDistrict; c.site = -1;
		c.seed = op.tProp >= 0 ? props[op.tProp].seed : holds[op.tStronghold].seed;
		c.pay = ContractPay(op);
		op.steps.Push(c);
		int odd = 1 + Random[CWSim](0, IsCorp(op.client) ? 1 : 0) + (IsCorp(op.client) && corps[op.client].wealth >= 5 ? 1 : 0);
		Array<int> roles;
		roles.Push(R_INTEL); roles.Push(R_ACCESS); roles.Push(R_WEAKEN); roles.Push(R_LEVERAGE); roles.Push(R_PROGRESS);
		for (int n = 0; n < odd && roles.Size(); n++)
		{
			int ri = n == 0 && Random[CWSim](0, 99) < 60 ? 0 : Random[CWSim](0, roles.Size() - 1);
			int role = roles[ri];
			roles.Delete(ri);
			if (role == R_LEVERAGE && op.goal != G_RECRUIT && op.goal != G_STEAL && op.goal != G_SABOTAGE) role = R_PROGRESS;
			op.steps.Push(MakeOddStep(op, role, wealth));
		}
	}

	CWC_Step MakeOddStep(CWC_Op op, int role, int wealth)
	{
		let s = new("CWC_Step");
		s.role = role; s.prop = -1; s.stronghold = -1;
		s.district = Random[CWSim](0, 99) < 70 ? op.tDistrict : Random[CWSim](0, NDIST - 1);
		s.site = PickSite(op, role, s.district);
		s.seed = Random[CWSim](1, 0x7ffffff);
		s.pay = (600 + wealth * 180 + Random[CWSim](0, 4) * 100) * (IsMinor(op.client) ? 7 : 10) / 10;
		String ex = op.tExec >= 0 ? execs[op.tExec].name : "";
		switch (role)
		{
		case R_INTEL:
			s.mode = 1;
			if (ex.Length()) s.what = ex .. "'s schedule";
			else { static const String iw[] = { "the site's shift roster", "the floor plans", "the security rota", "the delivery schedule" }; s.what = iw[Random[CWSim](0, 3)]; }
			break;
		case R_ACCESS:
			{ static const String aw[] = { "a maintenance keycard", "a guard's pass", "the service-door codes" }; s.what = aw[Random[CWSim](0, 2)]; s.mode = 0; }
			break;
		case R_WEAKEN:
			s.mode = 3; s.what = "the security contractor's dispatch terminal";
			break;
		case R_LEVERAGE:
			if (ex.Length() && Random[CWSim](0, 1)) { s.mode = 0; s.what = ex .. "'s gambling ledger"; }
			else { static const String lw[] = { "the compromising photos", "the payroll file", "the whistleblower's notes" }; s.mode = 0; s.what = lw[Random[CWSim](0, 2)]; }
			break;
		default:
			{ static const String pw[] = { "the planted evidence", "a tracker", "the package" }; s.mode = 2; s.what = pw[Random[CWSim](0, 2)]; }
			break;
		}
		return s;
	}

	// neutral sites that suit the client's line of business (neutral-sites-and-odd-jobs.md)
	int PickSite(CWC_Op op, int role, int d)
	{
		Array<int> s;
		String dc = distCode[d];
		if (op.launcher >= 0)
		{
			String n = subs[op.launcher].code;
			if (n == "NGR" || n == "HFR" || n == "HMA") { s.Push(NS_CONSTRUCTION); s.Push(NS_UNDERPASS); s.Push(NS_PARKING); }
			if (n == "CAN" || n == "NST" || n == "TWB") { s.Push(NS_HOTEL); s.Push(NS_RESTAURANT); s.Push(NS_LUXURY); }
			if (n == "KES" || n == "OCL") { s.Push(NS_HOSPITAL); s.Push(NS_TENEMENT); }
			if (n == "SOD" || n == "GHL" || n == "SNN") { s.Push(NS_MALL); s.Push(NS_BAR); s.Push(NS_MARKET); }
			if (n == "AEG" || n == "GHS") { s.Push(NS_PARKING); s.Push(NS_BAR); s.Push(NS_CHOPSHOP); s.Push(NS_ROOFTOPS); }
			if (n == "VOL" || n == "CDS" || n == "HEL") { s.Push(NS_CONSTRUCTION); s.Push(NS_TUNNELS); }
		}
		else if (IsMinor(op.client))
		{
			String m = minors[op.client - MINOR_BASE].code;
			if (m == "RUS") { s.Push(NS_BAR); s.Push(NS_CHOPSHOP); s.Push(NS_GAMBLING); s.Push(NS_PAWN); }
			if (m == "L9") { s.Push(NS_UNIONHALL); s.Push(NS_BAR); s.Push(NS_TRANSIT); }
			if (m == "NUL") { s.Push(NS_UNIVERSITY); s.Push(NS_ARCHIVE); s.Push(NS_RESTAURANT); }
			if (m == "TEN") { s.Push(NS_TENEMENT); s.Push(NS_MARKET); s.Push(NS_APARTMENTS); }
		}
		// district flavour
		if (dc == "MR") { s.Push(NS_HOTEL); s.Push(NS_LUXURY); s.Push(NS_RESTAURANT); s.Push(NS_MALL); }
		if (dc == "EG") { s.Push(NS_UNIVERSITY); s.Push(NS_APARTMENTS); s.Push(NS_RESTAURANT); }
		if (dc == "IS") { s.Push(NS_BAR); s.Push(NS_UNDERPASS); s.Push(NS_TENEMENT); s.Push(NS_UNIONHALL); }
		if (dc == "OQ") { s.Push(NS_TENEMENT); s.Push(NS_MARKET); s.Push(NS_GAMBLING); s.Push(NS_BAR); s.Push(NS_PAWN); }
		if (dc == "HL") { s.Push(NS_CONSTRUCTION); s.Push(NS_TRANSIT); s.Push(NS_TUNNELS); }
		if (role == R_INTEL && op.tExec >= 0) { s.Push(NS_HOTEL); s.Push(NS_LUXURY); s.Push(NS_RESTAURANT); }
		return s[Random[CWSim](0, s.Size() - 1)];
	}

	int ContractPay(CWC_Op op)
	{
		int base;
		int risk = 1;
		if (op.tProp >= 0)
		{
			base = 2200 + TypeYield(props[op.tProp].type) * 450;
			risk = RiskOf(PropForce(op.tProp), PropTech(op.tProp));
		}
		else base = 2600;
		double m = IsCorp(op.client) ? 0.75 + corps[op.client].wealth * 0.08 : 0.55;
		m *= 0.85 + risk * 0.15;
		if (op.goal == G_RECRUIT) m *= 1.1;
		if (op.goal == G_STRIKE || op.goal == G_PROTEST || op.goal == G_EXTORT) m *= 0.8;
		return int(base * m / 100) * 100;
	}

	// ---- prep effects that apply to the strike (steps done by you or by freelancers)
	clearscope bool StepDone(CWC_Op op, int role)
	{
		for (int i = 0; i < op.steps.Size(); i++) if (op.steps[i].role == role && op.steps[i].done) return true;
		return false;
	}

	// ---- counter-operations: the target learns of an operation and answers it
	void MaybeCounter(CWC_Op op)
	{
		if (op.goal == G_COUNTER || !IsCorp(op.tFaction) || !corps[op.tFaction].alive) return;
		int t = op.tFaction;
		int chance = corps[t].tech * 4;
		for (int i = 0; i < agendas.Size(); i++) if (agendas[i].owner == t && agendas[i].kind == AG_PROTECT) chance += 15;
		if (corps[t].treasury < 25 || Random[CWSim](0, 99) >= chance) return;
		let co = new("CWC_Op");
		co.id = nextOpId++;
		co.client = t;
		co.goal = G_COUNTER;
		co.counterOf = op.id;
		co.tFaction = op.client; co.tProp = op.tProp; co.tStronghold = -1; co.tExec = -1; co.tDistrict = op.tDistrict;
		co.startDay = day;
		co.deadline = min(op.deadline - 1, day + Random[CWSim](3, 6));
		if (co.deadline <= day) co.deadline = day + 2;
		// defensive work runs through the security subsidiary if there is one
		co.launcher = op.tProp >= 0 ? props[op.tProp].sub : -1;
		for (int s = 0; s < subs.Size(); s++) if (subs[s].corp == t && (subs[s].code == "CSE" || subs[s].code == "AEG")) co.launcher = s;
		co.clientKnown = true;
		co.title = String.Format("%s: protect %s", co.launcher >= 0 ? subs[co.launcher].name : corps[t].short, TargetLabel(op));
		let s1 = MakeOddStep(co, R_INTEL, corps[t].wealth);
		s1.decisive = true; s1.mode = 4; s1.what = "the go-between who hired the crew";
		co.steps.Push(s1);
		if (Random[CWSim](0, 1))
		{
			let s2 = MakeOddStep(co, R_PROGRESS, corps[t].wealth);
			s2.what = "a tracker on their courier";
			co.steps.Push(s2);
		}
		Spend(t, CW_Tune.OP_RETAINER / 2 + 2);
		ops.Push(co);
	}

	// ---- daily progress: freelancers work the open steps; deadlines resolve
	void ProgressOps()
	{
		for (int i = 0; i < ops.Size(); i++)
		{
			let op = ops[i];
			if (op.state) continue;
			// client or target gone: the operation is withdrawn
			if ((IsCorp(op.client) && !corps[op.client].alive) || (op.goal != G_COUNTER && op.tProp >= 0 && (PropCorp(op.tProp) < 0 || PropCorp(op.tProp) == op.client))
				|| (op.tStronghold >= 0 && !HoldActive(op.tStronghold) && op.goal == G_SUPPRESS))
			{
				op.state = 3;
				continue;
			}
			int wealth = IsCorp(op.client) ? corps[op.client].wealth : 2;
			for (int k = 0; k < op.steps.Size(); k++)
			{
				let st = op.steps[k];
				if (st.done || st.decisive || st.taken) continue;
				if (Random[CWSim](0, 99) < CW_Tune.FREELANCE_ODDJOB) { st.done = 2; op.progress = min(90, op.progress + (st.role == R_PROGRESS ? 25 : 12)); }
			}
			op.progress = min(90, op.progress + 3 + wealth);
			if (day < op.deadline) continue;
			// deadline: did freelancers pull off the decisive step?
			int sec = op.tProp >= 0 ? PropForce(op.tProp) / 2 + PropTech(op.tProp) * 2 : 6;
			int chance = clamp(20 + op.progress / 2 + (wealth * 3 - sec) * 2, 5, 85);
			if (op.goal == G_COUNTER) chance = clamp(35 + op.progress / 2, 10, 80);
			if (Random[CWSim](0, 99) < chance) OpSucceeded(op, false);
			else OpFailed(op);
		}
	}

	void OpFailed(CWC_Op op)
	{
		op.state = 2;
		if (op.tProp >= 0)
		{
			let pr = props[op.tProp];
			pr.alertUntil = max(pr.alertUntil, day + 3);
			pr.hardenUntil = day + 7; pr.hardenForce = max(pr.hardenForce, 2);
			if (op.goal != G_COUNTER)
			{
				switch (Random[CWSim](0, 2))
				{
				case 0: AddNews(String.Format("Intruders repelled at %s.", PropName(op.tProp))); break;
				case 1: AddNews(String.Format("A hired crew came up empty at %s.", PropName(op.tProp))); break;
				default: AddNews(String.Format("%s security reports a break-in attempt at %s. Nothing taken.", PropCorp(op.tProp) >= 0 ? corps[PropCorp(op.tProp)].short : "Site", PropName(op.tProp))); break;
				}
			}
		}
		else if (op.tStronghold >= 0) AddNews(String.Format("%s saw off a crew at %s.", minors[holds[op.tStronghold].minor].short, holds[op.tStronghold].name));
		AgendaResult(op, false);
	}

	// ---- what a successful operation does (city-layer-design.md "Mission consequences")
	void OpSucceeded(CWC_Op op, bool byYou, bool leverage = false)
	{
		op.state = 1;
		op.progress = 100;
		int c = op.client;
		String cl = op.clientKnown ? FactionShort(c) : "An unknown client";
		String who = byYou ? "A crew" : "Freelancers";
		int p = op.tProp;
		if (leverage && op.goal == G_SABOTAGE) op.goal = G_LEAK;   // dirt instead of damage: a scandal
		switch (op.goal)
		{
		case G_STEAL:
		{
			let pr = props[p];
			pr.stolenUntil = day + 10;
			if (op.launcher >= 0) { subs[op.launcher].boostUntil = day + 10; subs[op.launcher].boostPct = 15; }
			bool expose = op.agendaKind == AG_EXPOSE || (IsCorp(c) && corps[c].special == "EXPOSE");
			if (expose)
			{
				pr.scandalUntil = day + 7;
				if (subs[pr.sub].shell && !subs[pr.sub].shellKnown)
				{
					subs[pr.sub].shellKnown = true;
					AddNews(String.Format("EXPOSED: %s is a %s shell.", subs[pr.sub].name, corps[subs[pr.sub].corp].short));
				}
				else AddNews(String.Format("Leaked records embarrass %s. %s's income takes a hit.", corps[PropCorp(p)].short, subs[pr.sub].name));
				MaybeScandalSale(p);
			}
			else AddNews(String.Format("%s lifted %s from %s.", who, StrikeItem(op), PropName(p)));
			break;
		}
		case G_SABOTAGE:
			Damage(p, 6);
			AddNews(String.Format("Sabotage at %s: operations crippled.", PropName(p)));
			break;
		case G_RECRUIT:
			if (op.tExec >= 0 && !execs[op.tExec].gone) Poach(op.tExec, c, op.launcher);
			else
			{
				props[p].stolenUntil = day + 5;
				if (op.launcher >= 0) { subs[op.launcher].boostUntil = day + 10; subs[op.launcher].boostPct = 8; }
				AddNews(String.Format("A senior engineer walks out of %s.", PropName(p)));
			}
			break;
		case G_STRIKE:
			props[p].strikeUntil = day + 5;
			AddNews(String.Format("WALKOUT: %s shuts %s.", FactionShort(c), PropName(p)));
			break;
		case G_RAID:
			Damage(p, 4);
			if (IsMinor(c)) minors[c - MINOR_BASE].funds += 8;
			AddNews(String.Format("%s raid on %s. Stock gone, damage everywhere.", FactionShort(c), PropName(p)));
			break;
		case G_LEAK:
		{
			let pr = props[p];
			pr.scandalUntil = day + 7;
			if (subs[pr.sub].shell && !subs[pr.sub].shellKnown)
			{
				subs[pr.sub].shellKnown = true;
				AddNews(String.Format("LEAK: %s is a %s shell. Files from %s are all over the net.", subs[pr.sub].name, corps[subs[pr.sub].corp].short, PropName(p)));
			}
			else AddNews(String.Format("LEAK: internal files from %s hit the net.", PropName(p)));
			MaybeScandalSale(p);
			break;
		}
		case G_PROTEST:
			props[p].troubleUntil = day + 5;
			AddNews(String.Format("Blockade at %s: protesters won't move.", PropName(p)));
			break;
		case G_EXTORT:
		{
			int owner = PropCorp(p);
			if (owner >= 0) Spend(owner, 12);
			if (IsMinor(c)) minors[c - MINOR_BASE].funds += 12;
			props[p].troubleUntil = day + 3;
			AddNews(String.Format("%s pays protection at %s.", owner >= 0 ? corps[owner].short : "?", PropName(p)));
			break;
		}
		case G_SUPPRESS:
		{
			let hd = holds[op.tStronghold];
			let m = minors[hd.minor];
			m.turf[hd.district] = max(0, m.turf[hd.district] - 25);
			m.funds = max(0, m.funds - 15);
			if (op.tExec >= 0 && !execs[op.tExec].gone)
			{
				m.leaderOutUntil = day + 10;
				AddNews(String.Format("%s of %s is out of the picture.", execs[op.tExec].name, m.short));
			}
			AddNews(String.Format("%s broken at %s. %s loses ground in %s.", m.short, hd.name, m.short, distName[hd.district]));
			break;
		}
		case G_COUNTER:
		{
			let orig = FindOp(op.counterOf);
			if (orig && orig.state == 0)
			{
				orig.progress = max(0, orig.progress - 30);
				orig.clientKnown = true;
				AddRel(op.client, orig.client, -10);
				if (orig.tProp >= 0) { props[orig.tProp].hardenUntil = day + 10; props[orig.tProp].hardenForce = 3; }
				AddNews(String.Format("%s traces a hired crew back to %s.", corps[op.client].short, FactionShort(orig.client)));
			}
			break;
		}
		}
		// relations: the target resents a known client; minor players gain or lose turf
		int t = op.tFaction;
		// every hit costs the target: incident response, lawyers, insurance, a security review
		if (IsCorp(t) && p >= 0 && op.goal != G_COUNTER) Spend(t, CW_Tune.INCIDENT_COST + PropValue(p) / 8);
		if (op.goal != G_COUNTER)
		{
			if (op.clientKnown || Random[CWSim](0, 99) < 35) AddRel(t, c, IsMinor(c) || IsMinor(t) ? -6 : -10);
			for (int k = 0; k < NCORP; k++) if (IsCorp(t) && k != t && k != c && corps[k].alive && GetRel(k, t) >= 50) AddRel(k, c, -3);
			if (IsMinor(c) && p >= 0) { let m = minors[c - MINOR_BASE]; int gain = day < m.leaderOutUntil ? 5 : 10; m.turf[props[p].district] = min(100, m.turf[props[p].district] + gain); }
			if (IsCorp(t)) { corps[t].alertUntil = max(corps[t].alertUntil, day + 1); if (corps[t].security >= 5 && p >= 0) { props[p].hardenUntil = day + 10; props[p].hardenForce = 3; } }
		}
		AgendaResult(op, true);
		// everyone who worked the operation shares in the success
		if (op.playerSteps > 0 && !byYou)
		{
			int bonus = 400 * op.playerSteps;
			pendingBonus += bonus;
			pendingLines.Push(String.Format("%s succeeded\t\cd+%s", op.title, CW_Handler.Money(bonus)));
			AddRep(c, 3);
		}
	}

	void Damage(int p, int days)
	{
		let pr = props[p];
		pr.damagedUntil = day + days;
		int owner = PropCorp(p);
		if (owner >= 0) Spend(owner, PropValue(p) / 6);   // repairs
	}

	void Poach(int e, int toCorp, int toSub)
	{
		let x = execs[e];
		int fromSub = x.sub, fromCorp = x.corp;
		String was = x.ceo ? "CEO of " .. corps[fromCorp].short : x.role;
		if (fromSub >= 0 && subs[fromSub].head == e) subs[fromSub].head = -1;
		if (x.ceo) x.gone = true;   // a CEO walking out is replaced by the board; the corp bonus pauses
		x.ceo = false;
		x.movedDay = day;
		x.sub = fromSub >= 0 ? -2 - fromSub : -1;   // remembers the vacancy (see VacantUntil)
		x.prop = -1;
		if (IsCorp(toCorp))
		{
			x.corp = toCorp;
			x.role = "defected from " .. (fromSub >= 0 ? subs[fromSub].name : corps[max(0, fromCorp)].short);
			if (toSub >= 0) { subs[toSub].boostUntil = day + 30; subs[toSub].boostPct = max(subs[toSub].boostPct, x.bonus); }
		}
		else x.gone = true;
		AddNews(String.Format("%s (%s) has left for %s.", x.name, was, IsCorp(toCorp) ? corps[toCorp].short : "parts unknown"));
	}

	void AgendaResult(CWC_Op op, bool ok)
	{
		for (int i = 0; i < agendas.Size(); i++)
		{
			let a = agendas[i];
			if (a.owner != op.client || a.kind != op.agendaKind) continue;
			if (!ok) return;
			// three wins on one agenda: it's done, and the faction is the stronger for it
			a.since -= 4;
			if (day - a.since >= 16 && Random[CWSim](0, 1))
			{
				if (IsCorp(op.client))
				{
					for (int s = 0; s < subs.Size(); s++) if (subs[s].corp == op.client) { subs[s].boostUntil = max(subs[s].boostUntil, day + 10); subs[s].boostPct = max(subs[s].boostPct, 5); }
					AddNews(String.Format("%s's strategy is paying off: \"%s\".", corps[op.client].short, a.text));
				}
				agendas.Delete(i);
			}
			return;
		}
	}

	void Spend(int c, int k)
	{
		if (!IsCorp(c)) return;
		let o = corps[c];
		o.treasury -= k;
		if (o.treasury < 0) { o.debt += -o.treasury; o.treasury = 0; }
	}

	// ---- the opening board: the four prototype jobs as operations (contract-hierarchy.md "Existing contracts")
	void SeedOpeningOps()
	{
		SeedOp("CAS", "BAS", "HLX", PT_LAB, G_STEAL, "the Helix prototype", R_INTEL, R_ACCESS, R_WEAKEN);
		SeedOp("ORI", "KES", "CSE", PT_OFF, G_STEAL, "the black ledger", R_INTEL, R_LEVERAGE, R_ACCESS);
		SeedOp("LAT", "NST", "HLX", PT_LAB, G_RECRUIT, "", R_INTEL, R_LEVERAGE, -1);
		SeedOp("CAS", "AEG", "HFR", PT_HQ, G_STEAL, "the audit drive", R_INTEL, R_PROGRESS, -1);
	}
	void SeedOp(String client, String launcher, String tSub, int tType, int goal, String item, int r1, int r2, int r3)
	{
		int c = FindCorp(client), ts = FindSub(tSub);
		int p = -1;
		for (int i = 0; i < props.Size(); i++) if (props[i].sub == ts && props[i].type == tType) { p = i; if (goal != G_RECRUIT || ExecAt(i) >= 0) break; }
		if (c < 0 || p < 0) return;
		let op = new("CWC_Op");
		op.id = nextOpId++;
		op.client = c; op.goal = goal; op.tProp = p; op.tStronghold = -1; op.counterOf = -1;
		op.tFaction = PropCorp(p); op.tDistrict = props[p].district;
		op.tExec = goal == G_RECRUIT ? ExecAt(p) : -1;
		op.startDay = day; op.deadline = day + 7 + Random[CWSim](0, 2);
		op.launcher = FindSub(launcher);
		op.clientKnown = op.launcher < 0 || !subs[op.launcher].shell;
		op.agendaKind = -1;
		op.title = OpTitle(op);
		let st = new("CWC_Step");
		st.role = R_CONTRACT; st.decisive = true; st.prop = p; st.stronghold = -1; st.site = -1; st.district = op.tDistrict;
		st.seed = props[p].seed; st.pay = ContractPay(op); st.what = item;
		op.steps.Push(st);
		if (item.Length()) op.title = String.Format("%s vs %s: steal %s", subs[op.launcher].name, subs[ts].name, item);
		int w = corps[c].wealth;
		if (r1 >= 0) op.steps.Push(MakeOddStep(op, r1, w));
		if (r2 >= 0) op.steps.Push(MakeOddStep(op, r2, w));
		if (r3 >= 0) op.steps.Push(MakeOddStep(op, r3, w));
		ops.Push(op);
	}

	// ================================================================ 4: minor players
	void MinorUpkeep()
	{
		for (int m = 0; m < minors.Size(); m++)
		{
			let o = minors[m];
			int tot = 0;
			for (int d = 0; d < NDIST; d++) tot += o.turf[d];
			if (o.dormant)
			{
				if (day >= o.dormantUntil)
				{
					// the city never fully cleans itself up
					o.dormant = false;
					int bd = 0;
					for (int d = 1; d < NDIST; d++) if (o.startTurf[d] > o.startTurf[bd]) bd = d;
					o.turf[bd] = 25;
					o.funds = max(o.funds, 30);
					AddNews(String.Format("%s is back on the streets of %s.", o.short, distName[bd]));
				}
				continue;
			}
			if (tot <= 0)
			{
				o.dormant = true;
				o.dormantUntil = day + 10;
				for (int i = 0; i < ops.Size(); i++) if (ops[i].state == 0 && (ops[i].client == MINOR_BASE + m)) ops[i].state = 3;
				AddNews(String.Format("%s has gone quiet. For now.", o.name));
				continue;
			}
			o.funds = min(250, o.funds + 1 + tot / 40);
			// turf drifts back toward where they started when nobody is pushing
			if (day % 5 == 0) for (int d = 0; d < NDIST; d++) if (o.turf[d] < o.startTurf[d] && o.turf[d] > 0) o.turf[d] = min(o.startTurf[d], o.turf[d] + 3);
		}
	}

	// ================================================================ 5: property market (factions-draft.md)
	clearscope bool Listed(int idx, bool wholeSub)
	{
		for (int i = 0; i < listings.Size(); i++) if (listings[i].idx == idx && listings[i].wholeSub == wholeSub) return true;
		return false;
	}
	bool CorpHasListing(int c)
	{
		for (int i = 0; i < listings.Size(); i++) if (listings[i].seller == c) return true;
		return false;
	}
	void ListProperty(int p, int seller, int reason, int delay = 2, int pct = 60)
	{
		let l = new("CWC_Listing");
		l.wholeSub = false; l.idx = p; l.seller = seller; l.reason = reason; l.day = day + delay;
		l.minPrice = PropValue(p) * pct / 100;
		listings.Push(l);
	}
	void ListSub(int s, int seller, int reason, int delay, int pct)
	{
		let l = new("CWC_Listing");
		l.wholeSub = true; l.idx = s; l.seller = seller; l.reason = reason; l.day = day + delay;
		l.minPrice = SubValue(s) * pct / 100;
		listings.Push(l);
	}
	static clearscope String ReasonName(int r)
	{
		switch (r) { case 0: return "foreclosure"; case 1: return "distress sale"; case 2: return "lease expiry"; case 3: return "scandal sale"; case 4: return "carve-up"; case 5: return "receivership"; }
		return "sale";
	}

	void Market()
	{
		// ---- triggers
		for (int c = 0; c < corps.Size(); c++)
		{
			let o = corps[c];
			if (!o.alive) continue;
			int lim = CreditLimit(c);
			if (o.debt > lim)
			{
				o.overDays++;
				if (o.overDays >= CW_Tune.GRACE_DAYS)
				{
					o.overDays = 0;
					int p = WeakestProperty(c);
					if (p >= 0)
					{
						let pr = props[p];
						pr.seized = true;
						ListProperty(p, -1, 0, 2, 50);
						AddNews(String.Format("FORECLOSURE: Meridian seizes %s from %s. EarthGov guards it until the auction on day %d.", PropName(p), o.short, day + 2));
						// the property is held by Meridian until sold: it no longer earns for the corp
						pr.leaseEnd = 0;
						SeizedFrom(p, c);
					}
				}
			}
			else o.overDays = 0;
			if (CorpHasListing(c)) continue;
			// an empty brand is dead weight: the parent sells it off
			for (int s = 0; s < subs.Size(); s++)
			{
				if (subs[s].corp != c || SubProps(s) > 0 || Listed(s, true) || SubCount(c) <= 1) continue;
				ListSub(s, c, 1, 2, 50);
				AddNews(String.Format("%s puts the empty %s brand up for sale.", o.short, subs[s].name));
				break;
			}
			if (CorpHasListing(c)) continue;
			// distress: deep in debt with no cash
			if (o.debt > lim * 85 / 100 && o.treasury < CW_Tune.CASH_FLOOR)
			{
				if (SubCount(c) >= 3 && Random[CWSim](0, 99) < (o.debt > lim * 95 / 100 ? 70 : 35))
				{
					int s = WeakestSub(c);
					if (s >= 0)
					{
						ListSub(s, c, 1, 3, 70);
						AddNews(String.Format("DISTRESS SALE: %s puts %s up for sale, auction on day %d.", o.short, subs[s].name, day + 3));
						continue;
					}
				}
				int p = WeakestProperty(c);
				if (p >= 0 && !Listed(p, false))
				{
					ListProperty(p, c, 1, 2, 70);
					AddNews(String.Format("%s lists %s for a quick sale.", o.short, PropName(p)));
				}
			}
		}
		// ---- auctions due today
		for (int i = listings.Size() - 1; i >= 0; i--)
		{
			if (listings[i].day > day) continue;
			let l = listings[i];
			listings.Delete(i);
			RunAuction(l);
		}
	}

	// a seized property is split off the corp: Meridian holds it through a hidden holding sub (-1)
	void SeizedFrom(int p, int c)
	{
		props[p].sub = -1 - 1000 - c;   // remembers the old owner for the log; PropCorp() reads it as Meridian
		// executives working there move to another site of their subsidiary (or nowhere)
		for (int e = 0; e < execs.Size(); e++) if (execs[e].prop == p) execs[e].prop = -1;
	}

	int WeakestProperty(int c)
	{
		int best = -1, bv = 1 << 30;
		for (int p = 0; p < props.Size(); p++)
		{
			if (PropCorp(p) != c || props[p].seized || Listed(p, false)) continue;
			int v = PropValue(p) + (props[p].type == PT_HQ ? 500 : 0);
			if (v < bv) { bv = v; best = p; }
		}
		return best;
	}
	int WeakestSub(int c)
	{
		int best = -1, bv = 1 << 30;
		for (int s = 0; s < subs.Size(); s++)
		{
			if (subs[s].corp != c || Listed(s, true)) continue;
			int v = SubValue(s) + (HasHQ(s) ? 400 : 0);
			if (v < bv) { bv = v; best = s; }
		}
		return best;
	}
	bool HasHQ(int s) { for (int p = 0; p < props.Size(); p++) if (props[p].sub == s && props[p].type == PT_HQ) return true; return false; }

	void MaybeScandalSale(int p)
	{
		int c = PropCorp(p);
		if (c < 0 || props[p].type == PT_HQ || Listed(p, false)) return;
		if (corps[c].debt > CreditLimit(c) / 2 && Random[CWSim](0, 99) < 35)
		{
			ListProperty(p, c, 3, 3, 55);
			AddNews(String.Format("SCANDAL SALE: %s dumps %s after the story broke.", corps[c].short, PropName(p)));
		}
	}

	void RunAuction(CWC_Listing l)
	{
		int value = l.wholeSub ? SubValue(l.idx) : PropValue(l.idx);
		String what = l.wholeSub ? subs[l.idx].name : PropName(l.idx);
		// sealed bids: value x want x appetite, capped by what each corp can raise
		Array<int> bidder, bid;
		for (int c = 0; c < corps.Size(); c++)
		{
			let o = corps[c];
			if (!o.alive || c == l.seller) continue;
			int capacity = o.treasury - CW_Tune.CASH_FLOOR + max(0, CreditLimit(c) - o.debt) / 2;
			if (capacity < l.minPrice) continue;
			double want = 1.0 + (o.aggression - 3) * 0.1;
			int type = l.wholeSub ? -1 : props[l.idx].type;
			int dist = l.wholeSub ? -1 : props[l.idx].district;
			for (int p = 0; p < props.Size(); p++)
			{
				if (PropCorp(p) != c) continue;
				if (type >= 0 && props[p].type == type) want += 0.12;
				if (dist >= 0 && props[p].district == dist) want += 0.04;
			}
			want = min(want, 1.6);
			if (l.seller >= 0 && GetRel(c, l.seller) <= -50) want += 0.2;   // grabbing it hurts a rival
			if (l.wholeSub) want += 0.25;                                     // subsidiaries win the war
			int b = int(value * want * FRandom[CWSim](0.8, 1.1));
			b = min(b, capacity);
			if (b < l.minPrice) continue;
			bidder.Push(c); bid.Push(b);
		}
		// corps don't bid against an Allied corp: the lower of two allies stands aside
		for (int i = 0; i < bidder.Size(); i++)
			for (int j = 0; j < bidder.Size(); j++)
				if (i != j && bid[i] > 0 && bid[j] > 0 && GetRel(bidder[i], bidder[j]) >= 75 && bid[j] >= bid[i]) bid[i] = 0;
		int win = -1, second = l.minPrice;
		for (int i = 0; i < bidder.Size(); i++)
		{
			if (bid[i] <= 0) continue;
			if (win < 0 || bid[i] > bid[win]) { if (win >= 0) second = max(second, bid[win]); win = i; }
			else second = max(second, bid[i]);
		}
		if (win < 0)
		{
			// no buyer: Meridian receivership, re-auctioned in a few days at a lower reserve
			if (l.wholeSub) subs[l.idx].corp = -1;
			else if (!props[l.idx].seized) { SeizedFrom(l.idx, l.seller); props[l.idx].seized = true; }
			if (l.seller >= 0 && l.reason != 4) { l.seller = -1; }
			l.reason = 5;
			l.day = day + 3;
			l.minPrice = max(10, l.minPrice * 80 / 100);
			listings.Push(l);
			marketLog.Push(String.Format("%d\t%s: no bids. Meridian receivership.", day, what));
			return;
		}
		int buyer = bidder[win];
		int price = clamp(second + 5, l.minPrice, bid[win]);
		Spend(buyer, price);
		if (l.reason == 2) { }   // lease expiry: the lease simply ended, the landlord re-lets it (no proceeds)
		else if (l.seller >= 0 && corps[l.seller].alive)
		{
			// the seller's creditors are paid first
			let s = corps[l.seller];
			int toDebt = min(s.debt, price);
			s.debt -= toDebt;
			s.treasury += price - toDebt;
		}
		else if (l.reason == 0 && !l.wholeSub)
		{
			// a foreclosure pays down the old owner's debt
			int old = -1 - 1000 - props[l.idx].sub;
			if (IsCorp(old) && corps[old].alive) corps[old].debt = max(0, corps[old].debt - price * 80 / 100);   // Meridian keeps its fees
		}
		if (l.wholeSub) TransferSub(l.idx, buyer);
		else TransferProp(l.idx, buyer);
		String line = String.Format("SOLD (%s): %s to %s for %dk.", ReasonName(l.reason), what, corps[buyer].short, price);
		AddNews(line);
		marketLog.Push(String.Format("%d\t%s", day, line));
		while (marketLog.Size() > 60) marketLog.Delete(0);
	}

	void TransferProp(int p, int buyer)
	{
		let pr = props[p];
		// the buyer files it under the subsidiary that fits best
		int best = -1, bs = -1;
		for (int s = 0; s < subs.Size(); s++)
		{
			if (subs[s].corp != buyer) continue;
			int sc = 1;
			for (int q = 0; q < props.Size(); q++) if (props[q].sub == s && props[q].type == pr.type) sc += 10;
			sc += 3 - min(3, SubProps(s));
			if (sc > bs) { bs = sc; best = s; }
		}
		if (best < 0) return;
		pr.sub = best;
		pr.seized = false;
		pr.refitUntil = day + 5;
		pr.alertUntil = 0;
		pr.leaseEnd = pr.type == PT_HQ ? 0 : day + Random[CWSim](40, 90);
	}

	void TransferSub(int s, int buyer)
	{
		let sb = subs[s];
		int old = sb.corp;
		sb.corp = buyer;
		// a shell's new parent is public knowledge only if the old one was
		for (int p = 0; p < props.Size(); p++) if (props[p].sub == s) { props[p].refitUntil = day + 5; props[p].seized = false; }
		if (sb.head >= 0) execs[sb.head].corp = buyer;
		for (int i = 0; i < ops.Size(); i++) if (ops[i].state == 0 && ops[i].launcher == s && ops[i].client != buyer) ops[i].state = 3;
		if (old >= 0) AddRel(buyer, old, -8);
	}

	// ================================================================ 6: collapse, patron, win / loss
	void CollapseCheck()
	{
		for (int c = 0; c < corps.Size(); c++)
		{
			let o = corps[c];
			if (!o.alive) continue;
			// insolvent: the debt is far past the credit line (more than the properties would fetch at a fire sale)
			bool insolvent = o.debt > CreditLimit(c) * 13 / 10 + 10 && o.treasury < CW_Tune.CASH_FLOOR;
			if (SubCount(c) > 0 && !insolvent) continue;
			o.alive = false;
			o.diedDay = day;
			AddNews(String.Format("COLLAPSE: %s is finished. Meridian takes the pieces to auction.", o.name));
			// the carve-up: every subsidiary is auctioned as a unit, one a day, fire-sale reserve
			int n = 0;
			for (int s = 0; s < subs.Size(); s++)
			{
				if (subs[s].corp != c) continue;
				subs[s].corp = -1;
				ListSub(s, -1, 4, 1 + n, 40);
				n++;
			}
			for (int i = listings.Size() - 1; i >= 0; i--) if (listings[i].seller == c) { listings[i].seller = -1; }
			for (int i = 0; i < ops.Size(); i++) if (ops[i].state == 0 && (ops[i].client == c || ops[i].tFaction == c)) ops[i].state = 3;
			for (int e = 0; e < execs.Size(); e++) if (execs[e].ceo && execs[e].corp == c) execs[e].gone = true;
			// relations reshuffle among the survivors
			for (int a = 0; a < NCORP; a++)
				for (int b = a + 1; b < NCORP; b++)
					if (corps[a].alive && corps[b].alive && Random[CWSim](0, 1)) AddRel(a, b, Random[CWSim](-10, 10));
			if (patron == c) Lose(String.Format("Your patron, %s, has collapsed. Nobody protects its brokers now.", o.name));
			if (offer == c) offer = -1;
		}
	}

	void PatronCheck()
	{
		if (offer >= 0 && (GetRep(offer) < 75 || !corps[offer].alive)) offer = -1;
		if (patron >= 0 || offer >= 0 || day < declinedUntil) return;
		for (int c = 0; c < NCORP; c++)
		{
			if (!corps[c].alive || betrayed[c] || GetRep(c) < 75) continue;
			offer = c;
			AddNews(String.Format("%s's board wants you on their side. Patronage offered (LEDGER).", corps[c].short));
			return;
		}
	}

	void WinLossCheck()
	{
		if (outcome) return;
		int alive = AliveCorps();
		for (int c = 0; c < NCORP; c++)
		{
			if (!corps[c].alive) continue;
			bool dominant = SubCount(c) >= WIN_SUBS || alive == 1;
			if (!dominant) continue;
			if (c == patron) Win(String.Format("%s controls the city%s, and you put it there.", corps[c].name, alive == 1 ? " alone" : String.Format(" (%d of %d subsidiaries)", SubCount(c), subs.Size())));
			else Lose(String.Format("%s controls the city%s. You backed %s.", corps[c].name, alive == 1 ? " alone" : String.Format(" (%d of %d subsidiaries)", SubCount(c), subs.Size()), patron >= 0 ? "the wrong side" : "nobody"));
			return;
		}
	}
	void Win(String why) { if (outcome) return; outcome = 1; outcomeText = why; AddNews("CAMPAIGN WON: " .. why); }
	void Lose(String why) { if (outcome) return; outcome = 2; outcomeText = why; AddNews("CAMPAIGN LOST: " .. why); }

	// ================================================================ player actions
	void Pledge(bool accept)
	{
		if (offer < 0 || patron >= 0) return;
		if (accept)
		{
			patron = offer;
			AddNews(String.Format("You pledged to %s. Its operations pay more; its enemies are yours.", corps[patron].short));
		}
		else declinedUntil = day + 7;
		offer = -1;
		BuildOffers();
	}

	void Betray(int c)
	{
		if (patron != c) return;
		rep[c] = min(rep[c], -60);
		for (int k = 0; k < NCORP; k++) if (k != c && GetRel(c, k) >= 50) AddRep(k, -15);
		betrayed[c] = true;
		patron = -1;
		AddNews(String.Format("BETRAYAL: %s learned whose job you took. The pledge is over.", corps[c].short));
	}
}
