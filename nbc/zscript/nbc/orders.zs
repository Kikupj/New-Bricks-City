// Squad orders, the Ghost Recon way (PLAN.md §2.1 orders, M6). Owner request: "the Ghost Recon 1 squad command system".
//
// The squad splits into two fireteams, ALPHA and BRAVO (set per officer on the deploy screen). Commands go to
// the team you've selected (Q cycles ALL / ALPHA / BRAVO):
//   orders    FOLLOW (regroup on you), HOLD (stay put), MOVE (to the spot you're aiming at),
//             ADVANCE (walk the team's waypoint path from the command map)
//   ROE       RECON (weapons tight: they only return fire; they move slowly), ASSAULT (engage at will),
//             SUPPRESS (long bursts at anything, keep firing where a target was last seen, targets flinch)
//   go codes  a waypoint can carry a go code (X-RAY, YANKEE, ZULU): the team waits there until you call it
// The command map (M, NBC_CommandMap) plots waypoints and sets everything above; it runs in real time.
//
// The orders live in NBC_RunData (raid state; AGENTS.md); the officers read them in NBC_Ally.A_AllyThink.
// This handler takes the "nbc_cmd.<op>" netevents, owns the navigation graph the officers route over
// (CW_NavGraph, zscript/cw/nav.zs), keeps the squad's radio log and the contacts for the threat indicator.

class NBC_Orders : EventHandler
{
	enum ETeam { TEAM_ALPHA, TEAM_BRAVO, TEAMS }
	enum ECmdTeam { CT_ALL, CT_ALPHA, CT_BRAVO }
	enum EOrder { ORD_FOLLOW, ORD_HOLD, ORD_MOVE, ORD_ADVANCE }
	enum EROE { ROE_RECON, ROE_ASSAULT, ROE_SUPPRESS, ROE_COUNT }
	enum EGo { GO_NONE, GO_XRAY, GO_YANKEE, GO_ZULU, GO_COUNT }
	const MAX_WAYPOINTS = 8;        // per team
	enum ECmd
	{
		CMD_CYCLE_TEAM = 1, CMD_FOLLOW, CMD_HOLD, CMD_MOVE, CMD_ROE, CMD_ADVANCE, CMD_GO,
		CMD_MOVE_AT, CMD_WP_ADD, CMD_WP_DEL, CMD_WP_CLEAR, CMD_WP_GO, CMD_SET_TEAM, CMD_SELECT, CMD_WP_MOVE
	}
	static const String TEAM_NAME[] = { "ALPHA", "BRAVO" };
	static const String ROE_NAME[] = { "RECON", "ASSAULT", "SUPPRESS" };
	static const String ORDER_NAME[] = { "FOLLOW", "HOLD", "MOVE", "ADVANCE" };
	static const String GO_NAME[] = { "-", "X-RAY", "YANKEE", "ZULU" };
	static const int TEAM_COLOR[] = { 0x4FC3D9, 0xF2A93B };    // alpha teal, bravo amber (HUD, map, markers)

	transient CW_NavGraph graph;
	transient bool navBuilt;
	// the squad radio log (newest last)
	Array<String> logText;
	Array<int> logTics, logColor;
	// what the squad can see of the gang right now, for the threat indicator (hot: it's after one of you)
	Array<Actor> contacts;
	Array<bool> contactHot;

	static clearscope NBC_Orders Get() { return NBC_Orders(EventHandler.Find("NBC_Orders")); }

	static void Reset(NBC_RunData rd)
	{
		rd.cmdTeam = CT_ALL;
		rd.teamOrder.Clear(); rd.teamROE.Clear(); rd.teamSerial.Clear();
		rd.teamGX.Clear(); rd.teamGY.Clear(); rd.teamGZ.Clear();
		for (int t = 0; t < TEAMS; t++)
		{
			rd.teamOrder.Push(ORD_FOLLOW); rd.teamROE.Push(ROE_ASSAULT); rd.teamSerial.Push(0);
			rd.teamGX.Push(0); rd.teamGY.Push(0); rd.teamGZ.Push(0);
		}
		rd.wpTeam.Clear(); rd.wpGo.Clear(); rd.wpX.Clear(); rd.wpY.Clear(); rd.wpZ.Clear();
		rd.goCalled.Clear();
		for (int g = 0; g < GO_COUNT; g++) rd.goCalled.Push(false);
	}

	// ------------------------------------------------------------ waypoints (kept in one list, tagged by team)

	static clearscope int WaypointCount(NBC_RunData rd, int team)
	{
		int n = 0;
		for (int i = 0; i < rd.wpTeam.Size(); i++) if (rd.wpTeam[i] == team) n++;
		return n;
	}
	// the k-th waypoint of a team, as an index into the list (-1: none)
	static clearscope int WaypointIndex(NBC_RunData rd, int team, int k)
	{
		for (int i = 0; i < rd.wpTeam.Size(); i++)
			if (rd.wpTeam[i] == team && k-- == 0) return i;
		return -1;
	}
	// how many members a team has on this raid (the slots in it)
	static clearscope int TeamSize(NBC_RunData rd, int team)
	{
		int n = 0;
		for (int s = 0; s < rd.raidOff.Size(); s++) if (rd.TeamOfSlot(s) == team) n++;
		return n;
	}
	// which teams a command reaches: -1 = the selected one(s)
	static clearscope bool Reaches(NBC_RunData rd, int arg, int team)
	{
		if (arg >= 0) return arg == team;
		return rd.cmdTeam == CT_ALL || rd.cmdTeam - 1 == team;
	}
	static clearscope String Addressee(NBC_RunData rd, int arg)
	{
		if (arg >= 0) return NBC_Orders.TEAM_NAME[clamp(arg, 0, TEAMS - 1)];
		return rd.cmdTeam == CT_ALL ? "ALL TEAMS" : NBC_Orders.TEAM_NAME[rd.cmdTeam - 1];
	}

	// ------------------------------------------------------------ the navigation graph

	CW_NavGraph Nav()
	{
		if (!navBuilt)
		{
			navBuilt = true;
			graph = new("CW_NavGraph");
			graph.offmapX = 1e9;        // Obsidian maps sit anywhere
			graph.linkRange = 512;      // nearby links only: big maps, thousands of nodes
			int t0 = MSTime();
			graph.Build();
			if (developer) Console.Printf("nbc nav: %d nodes in %d ms", graph.Count(), MSTime() - t0);
		}
		return graph;
	}

	// ------------------------------------------------------------ the radio log

	void Log(String text, int cr = Font.CR_WHITE)
	{
		// the same line twice in a row within two seconds is one call
		int n = logText.Size();
		if (n && logText[n - 1] == text && logTics[n - 1] > 35 * 4) return;
		logText.Push(text); logTics.Push(35 * 6); logColor.Push(cr);
		while (logText.Size() > 6) { logText.Delete(0); logTics.Delete(0); logColor.Delete(0); }
	}

	static void Say(String text, int cr = Font.CR_WHITE)
	{
		let o = Get();
		if (o) o.Log(text, cr);
	}

	// ------------------------------------------------------------ every tic

	override void WorldTick()
	{
		for (int i = logTics.Size() - 1; i >= 0; i--)
			if (--logTics[i] <= 0) { logText.Delete(i); logTics.Delete(i); logColor.Delete(i); }

		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		let rd = NBC_RunData.Find();
		if (!rm || !rm.IsRaidMap(rd) || !rm.raidSetUp) return;
		// the graph is built once the raid is set up (a second or so on a big map, before anyone needs it)
		if (!navBuilt && rm.squad.Size()) Nav();
		if (level.maptime % 5) return;

		// contacts: gang members an officer has in sight, and any that are after you or the squad
		contacts.Clear(); contactHot.Clear();
		let p = players[consoleplayer].mo;
		for (int i = 0; i < rm.crew.Size(); i++)
		{
			Actor m = rm.crew[i];
			if (!m || m.health <= 0) continue;
			bool hot = m.target && (m.target.player || m.target is "NBC_Ally") && m.CheckSight(m.target);
			bool seen = hot || (p && m.Distance2D(p) < 1600 && p.CheckSight(m));
			for (int s = 0; s < rm.squad.Size() && !seen; s++)
			{
				let a = NBC_Ally(rm.squad[s]);
				if (a && a.enemy == m) seen = true;
			}
			if (seen) { contacts.Push(m); contactHot.Push(hot); }
		}
		if (rm.leader && rm.leader.health > 0 && p && p.CheckSight(rm.leader))
		{
			contacts.Push(rm.leader); contactHot.Push(rm.leader.target != null);
		}
	}

	// ------------------------------------------------------------ commands

	override void NetworkProcess(ConsoleEvent e)
	{
		if (!(e.Name.Left(8) ~== "nbc_cmd.")) return;
		// "nbc_cmd.<op>" a b c (SendNetworkEvent carries three numbers; the op rides in the name)
		Command(e.Name.Mid(8).ToInt(), e.Args[0], e.Args[1], e.Args[2]);
	}

	void Command(int cmd, int a, int b, int c)
	{
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		let rd = NBC_RunData.Find();
		let p = players[consoleplayer].mo;
		if (!rm || !rd || !p || !rm.IsRaidMap(rd)) return;
		if (!rd.raidOff.Size()) { Log("No squad with you on this raid.", Font.CR_DARKGRAY); return; }
		String who = Addressee(rd, a);
		switch (cmd)
		{
		case CMD_CYCLE_TEAM:
			rd.cmdTeam = (rd.cmdTeam + 1) % 3;
			Log(String.Format("Talking to %s.", Addressee(rd, -1)), Font.CR_GRAY);
			return;
		case CMD_SELECT:
			rd.cmdTeam = clamp(a, 0, 2);
			return;
		case CMD_FOLLOW:
			SetOrder(rd, a, ORD_FOLLOW);
			Log(String.Format("%s: On you.", who), Font.CR_GREEN);
			Ack(rm, rd, a);
			return;
		case CMD_HOLD:
			SetOrder(rd, a, ORD_HOLD);
			Log(String.Format("%s: Holding here.", who), Font.CR_GREEN);
			Ack(rm, rd, a);
			return;
		case CMD_MOVE:
		case CMD_MOVE_AT:
		{
			Vector3 at;
			if (cmd == CMD_MOVE)
			{
				// the spot you're aiming at, pulled back off the wall
				FLineTraceData t;
				p.LineTrace(p.angle, 4096, p.pitch, TRF_THRUACTORS, p.player.viewheight, 0, 0, t);
				Vector2 back = Actor.AngleToVector(p.angle, 24);
				at.xy = t.HitLocation.xy - back;
				if (t.HitType == TRACE_HitNone) at.xy = p.pos.xy + Actor.AngleToVector(p.angle, 1024);
			}
			else at.xy = (b, c);
			at.z = level.PointInSector(at.xy).floorplane.ZAtPoint(at.xy);
			for (int t = 0; t < TEAMS; t++)
			{
				if (!Reaches(rd, a, t)) continue;
				rd.teamGX[t] = at.x; rd.teamGY[t] = at.y; rd.teamGZ[t] = at.z;
			}
			SetOrder(rd, a, ORD_MOVE);
			int col = (a >= 0 ? a : (rd.cmdTeam == CT_BRAVO ? 1 : 0));
			let mk = NBC_OrderMarker(Actor.Spawn("NBC_OrderMarker", at));
			if (mk) mk.col = NBC_Orders.TEAM_COLOR[clamp(col, 0, 1)];
			Log(String.Format("%s: Moving.", who), Font.CR_GREEN);
			Ack(rm, rd, a);
			return;
		}
		case CMD_ROE:
			for (int t = 0; t < TEAMS; t++)
			{
				if (!Reaches(rd, a, t)) continue;
				rd.teamROE[t] = b >= 0 ? clamp(b, 0, ROE_COUNT - 1) : (rd.teamROE[t] + 1) % ROE_COUNT;
			}
			{
				int shown = rd.teamROE[a >= 0 ? a : (rd.cmdTeam == CT_BRAVO ? 1 : 0)];
				static const String roeLine[] = { "Recon. Weapons tight, returning fire only.", "Assault. Weapons free.", "Suppress. Putting rounds on anything that moves." };
				Log(String.Format("%s: %s", who, roeLine[shown]), Font.CR_GOLD);
			}
			return;
		case CMD_ADVANCE:
		{
			bool any = false;
			for (int t = 0; t < TEAMS; t++)
			{
				if (!Reaches(rd, a, t)) continue;
				if (WaypointCount(rd, t)) { rd.teamOrder[t] = ORD_ADVANCE; rd.teamSerial[t]++; any = true; }
			}
			if (any) { Log(String.Format("%s: Advancing on the plan.", who), Font.CR_GREEN); Ack(rm, rd, a); }
			else Log(String.Format("%s: No path plotted. Use the command map (M).", who), Font.CR_DARKGRAY);
			return;
		}
		case CMD_GO:
		{
			int g = clamp(b, GO_XRAY, GO_ZULU);
			rd.goCalled[g] = true;
			Log(String.Format("GO CODE %s!", NBC_Orders.GO_NAME[g]), Font.CR_GOLD);
			Ack(rm, rd, -1);
			return;
		}
		case CMD_WP_ADD:
			if (a < 0 || a >= TEAMS || WaypointCount(rd, a) >= MAX_WAYPOINTS) return;
			rd.wpTeam.Push(a); rd.wpGo.Push(GO_NONE);
			rd.wpX.Push(b); rd.wpY.Push(c);
			rd.wpZ.Push(level.PointInSector((b, c)).floorplane.ZAtPoint((b, c)));
			return;
		case CMD_WP_MOVE:
			if (a < 0 || a >= rd.wpTeam.Size()) return;
			rd.wpX[a] = b; rd.wpY[a] = c;
			rd.wpZ[a] = level.PointInSector((b, c)).floorplane.ZAtPoint((b, c));
			return;
		case CMD_WP_DEL:
			if (a < 0 || a >= rd.wpTeam.Size()) return;
			rd.wpTeam.Delete(a); rd.wpGo.Delete(a); rd.wpX.Delete(a); rd.wpY.Delete(a); rd.wpZ.Delete(a);
			return;
		case CMD_WP_CLEAR:
			for (int i = rd.wpTeam.Size() - 1; i >= 0; i--)
			{
				if (rd.wpTeam[i] != a) continue;
				rd.wpTeam.Delete(i); rd.wpGo.Delete(i); rd.wpX.Delete(i); rd.wpY.Delete(i); rd.wpZ.Delete(i);
			}
			if (a >= 0 && a < TEAMS && rd.teamOrder[a] == ORD_ADVANCE) { rd.teamOrder[a] = ORD_HOLD; rd.teamSerial[a]++; }
			return;
		case CMD_WP_GO:
			if (a < 0 || a >= rd.wpGo.Size()) return;
			rd.wpGo[a] = clamp(b, GO_NONE, GO_ZULU);
			if (b > GO_NONE) rd.goCalled[b] = false;     // a fresh hold point waits for a fresh call
			return;
		case CMD_SET_TEAM:
			if (a < 0 || a >= rd.raidOffTeam.Size()) return;
			rd.raidOffTeam[a] = clamp(b, 0, TEAMS - 1);
			return;
		}
	}

	static void SetOrder(NBC_RunData rd, int arg, int order)
	{
		for (int t = 0; t < TEAMS; t++)
		{
			if (!Reaches(rd, arg, t)) continue;
			rd.teamOrder[t] = order;
			rd.teamSerial[t]++;
		}
	}

	// one officer on the team answers
	static void Ack(NBC_RunManager rm, NBC_RunData rd, int arg)
	{
		for (int s = 0; s < rm.squad.Size(); s++)
		{
			let a = NBC_Ally(rm.squad[s]);
			if (!a || a.health <= 0 || !Reaches(rd, arg, rd.TeamOfSlot(a.slot))) continue;
			a.A_StartSound(a.SeeSound, CHAN_VOICE, CHANF_DEFAULT, 0.7);
			return;
		}
	}
}

// Where a MOVE order points: a ring of light on the floor for a few seconds, in the team's colour.
class NBC_OrderMarker : Actor
{
	int col;
	Default { +NOINTERACTION; +NOBLOCKMAP; RenderStyle "None"; }

	override void Tick()
	{
		Super.Tick();
		if (GetAge() > 35 * 4) { Destroy(); return; }
		if (GetAge() % 3) return;
		double r = 28 + 6 * sin(GetAge() * 12.0);
		for (int i = 0; i < 12; i++)
		{
			double an = i * 30 + GetAge() * 4;
			A_SpawnParticle(col, SPF_FULLBRIGHT, 8, 5, 0, cos(an) * r, sin(an) * r, 2, 0, 0, 0.3);
		}
	}
	States { Spawn: TNT1 A -1; Stop; }
}

// What an officer chases when the order is a place, not a person: moved along the route, a node at a time.
class NBC_SteerPoint : Actor
{
	Default
	{
		+SHOOTABLE; +NODAMAGE; +NOBLOCKMAP; +NOGRAVITY; +NOSECTOR; +NOTARGET; +DONTSPLASH;
		Radius 4; Height 4;
	}
	States { Spawn: TNT1 A -1; Stop; }
}
