// The vertical-slice loop (PLAN.md M2, M2b): hub -> raid board -> one of the gang's kit floors -> the hub.
//
// The raid board picks a turf; the raid runs on one of the holding gang's kit floors (gangs.txt "mansion"),
// generated from the case RNG by NBC_KitRunner. The manager fills the kit's spawn spots with the raiding
// gang (count from the gang's tier, budget and alert). The leader stands nearest the exit with escorts; two
// officers come in with the player. Taking the exit resolves the raid: leader down = gang toppled, otherwise
// a retreat. Lethal damage = OFFICER DOWN. (Maps without a kit, like the frozen Obsidian NBC_CT maps, still
// work: their monster layer becomes the spawn spots.)

// A spawn spot (ZScript 4.10 has no arrays of vectors).
class NBC_Spot
{
	Vector3 pos;
	static NBC_Spot Make(Vector3 at) { let s = new("NBC_Spot"); s.pos = at; return s; }
}

class NBC_RunManager : EventHandler
{
	const HUB_MAP = "NBC_HUB";
	const SAFE_RADIUS = 768.0;          // no gang member starts this close to the player
	const REINFORCE_AT = 0.6;           // fraction of the starting crew down before the stairs fill up
	const OFFICER_DOWN_TICS = 70;

	Array<NBC_GangDef> gangs;
	Array<String> districtMaps, districtTitles;

	// raid bookkeeping (this map only)
	bool raidSetUp, reinforced, exitFound;
	int startCount, officerDownTics;
	Vector3 exitPos;
	Actor leader;
	Array<Actor> crew, squad;
	Array<NBC_Spot> spareSpots;

	// messages
	String announceText;
	int announceTics;
	Array<String> card;
	int cardTics;

	// the raid board (NBC_RaidBoard.Used bumps this; the UI opens the menu)
	int boardRequests;
	ui int boardSeen;

	override void WorldLoaded(WorldEvent e)
	{
		NBC_Gangs.LoadGangs(gangs);
		NBC_Gangs.LoadDistricts(districtMaps, districtTitles);
		if (e.IsSaveGame) return;

		let rd = NBC_RunData.Get();
		if (IsHub())
		{
			if (rd.reportPending)
			{
				card.Copy(rd.report);
				cardTics = 35 * 14;
				rd.reportPending = false;
			}
			else Announce("CHECKPOINT 9. Use the raid board to pick a district.", 35 * 6);
			return;
		}

	}

	override void WorldUnloaded(WorldEvent e)
	{
		if (e.IsSaveGame) return;
		let rd = NBC_RunData.Find();
		if (!IsRaidMap(rd)) return;
		ResolveRaid(rd);
	}

	override void WorldTick()
	{
		if (announceTics > 0) announceTics--;
		if (cardTics > 0) cardTics--;

		let rd = NBC_RunData.Find();
		if (!IsRaidMap(rd)) return;
		if (!raidSetUp)
		{
			// wait two tics: the kit puts the player at the insertion on the first, and spawners resolve
			if (level.maptime >= 2) SetupRaid(rd);
			return;
		}
		RaidTick(rd);
	}

	// ------------------------------------------------------------ helpers

	clearscope bool IsHub() const
	{
		return level.MapName ~== HUB_MAP;
	}

	// the map the current raid runs on
	clearscope bool IsRaidMap(NBC_RunData rd) const
	{
		return rd && rd.raidActive && rd.raidMap != "" && rd.raidMap ~== level.MapName;
	}

	clearscope String TurfTitle(int d) const
	{
		return d >= 0 && d < districtTitles.Size() ? districtTitles[d] : "the block";
	}

	// Pick one of the gang's kit floors ("tower:gang floor") with the case RNG and set the raid up to run on it.
	static void PickMansion(NBC_GangDef g, NBC_RunData rd)
	{
		int kit = NBC_KitGen.KIT_TOWER, v = 0;
		if (g && g.mansion.Size())
		{
			String pick = g.mansion[rd.Rand(0, g.mansion.Size() - 1)];
			int colon = pick.IndexOf(":");
			String kitName = colon >= 0 ? pick.Left(colon) : pick;
			String varName = colon >= 0 ? pick.Mid(colon + 1) : "";
			int k = NBC_KitGen.KitByName(kitName);
			let probe = k ? NBC_KitGen.Make(k) : null;
			if (probe)
			{
				kit = k;
				v = -1;
				for (int i = 0; i < probe.VariantCount() && v < 0; i++)
				{
					probe.variant = i;
					if (probe.VariantName() ~== varName) v = i;
				}
				if (v < 0)
				{
					Console.Printf("\cggangs.txt: %s has no kit variant \"%s\"; using %s.", g.id, pick, probe.VariantName());
					v = 0;
				}
			}
			else Console.Printf("\cggangs.txt: %s mansion \"%s\" isn't a kit (tower, street, basement or roof).", g.id, pick);
		}
		rd.raidMap = NBC_KitGen.MapOfKit(kit);
		rd.raidVariant = v;
		rd.raidKitSeed = rd.Rand(1, 0x7ffffff);
		rd.raidEntry = 0;
	}

	clearscope NBC_GangDef GangAt(int i) const
	{
		return i >= 0 && i < gangs.Size() ? gangs[i] : null;
	}

	static int NewSeed()
	{
		int s = CVar.GetCVar("nbc_seed").GetInt();
		if (s != 0) return s;
		return MSTime() * 69069 + gametic * 40503 + 12345;
	}

	void Announce(String text, int tics = 35 * 5)
	{
		announceText = text;
		announceTics = tics;
	}

	// ------------------------------------------------------------ raid setup

	void SetupRaid(NBC_RunData rd)
	{
		raidSetUp = true;
		let p = players[consoleplayer].mo;
		let g = GangAt(rd.raidGang);
		if (!p || !g) return;

		// 1. any placed monsters out (their spots kept for maps without a kit); a kit gives its own spots
		Array<NBC_Spot> spots;
		Array<Actor> remove;
		let it = ThinkerIterator.Create("Actor");
		Actor mo;
		while ((mo = Actor(it.Next())))
		{
			if (mo is "RandomSpawner") { remove.Push(mo); continue; }
			if (mo.bIsMonster && !mo.player && !(mo is "NBC_Ally"))
			{
				spots.Push(NBC_Spot.Make(mo.pos));
				remove.Push(mo);
			}
		}
		for (int i = 0; i < remove.Size(); i++) if (remove[i]) remove[i].Destroy();
		let kr = NBC_KitRunner(EventHandler.Find("NBC_KitRunner"));
		NBC_KitGen kit = kr ? kr.kit : null;
		if (kit)
		{
			spots.Clear();
			for (int i = 0; i < kit.spotX.Size(); i++)
			{
				Vector2 kp = (kit.spotX[i], kit.spotY[i]);
				spots.Push(NBC_Spot.Make((kp, kit.FloorAt(kp))));
			}
		}

		// 2. the exit: the kit's, else an exit switch or line
		exitFound = false;
		if (kit) { exitPos = (kit.exitPos, kit.FloorAt(kit.exitPos)); exitFound = true; }
		for (int i = 0; i < level.Lines.Size() && !exitFound; i++)
		{
			int sp = level.Lines[i].special;
			if (sp == 243 || sp == 244 || sp == 74)
			{
				Line l = level.Lines[i];
				Vector2 mid = (l.v1.p + l.v2.p) / 2;
				exitPos = (mid, 0);
				exitFound = true;
				if (sp == 243) break;
			}
		}

		// 3. far spots only, shuffled with the case RNG
		Array<NBC_Spot> cand;
		for (int i = 0; i < spots.Size(); i++)
			if ((spots[i].pos.xy - p.pos.xy).Length() > SAFE_RADIUS) cand.Push(spots[i]);
		for (int i = cand.Size() - 1; i > 0; i--)
		{
			int j = rd.Rand(0, i);
			NBC_Spot t = cand[i]; cand[i] = cand[j]; cand[j] = t;
		}
		if (!exitFound)
		{
			double far = 0;
			for (int i = 0; i < cand.Size(); i++)
			{
				double d = (cand[i].pos.xy - p.pos.xy).Length();
				if (d > far) { far = d; exitPos = cand[i].pos; }
			}
		}

		// 4. the leader, nearest the exit, with escorts
		int leaderSpot = -1;
		double best = 1e12;
		for (int i = 0; i < cand.Size(); i++)
		{
			double d = (cand[i].pos.xy - exitPos.xy).Length();
			if (d < best) { best = d; leaderSpot = i; }
		}
		if (leaderSpot >= 0)
		{
			Vector3 lp = cand[leaderSpot].pos;
			cand.Delete(leaderSpot);
			leader = SpawnMember(g.leader, lp, g, rd, g.leaderHealth);
			if (leader)
			{
				leader.GiveInventoryType("NBC_LeaderToken");
				leader.SetTag(g.leaderTitle);
				leader.Scale *= 1.12;
				for (int k = 0; k < g.escorts; k++)
				{
					Vector2 off = Actor.AngleToVector(k * 360.0 / max(1, g.escorts), 72);
					Vector3 ep = (lp.xy + off, lp.z);
					let esc = SpawnMember(PickRoster(g, rd, 2), ep, g, rd, g.health);
					if (esc) crew.Push(esc);
				}
			}
		}

		// 5. the crew: the game sets the count, not Obsidian
		static const int baseCount[] = { 22, 18, 16 };
		int alert = rd.gangAlert.Size() > rd.raidGang ? rd.gangAlert[rd.raidGang] : 0;
		int want = int(baseCount[clamp(g.tier, 1, 3) - 1] * g.budget * (1.0 + 0.15 * alert));
		want = min(want, cand.Size());
		int placed = 0, k = 0;
		while (placed < want && k < cand.Size())
		{
			int r = rd.Rand(0, 99);
			int tier = r < 60 - alert * 5 ? 1 : (r < 90 ? 2 : 3);
			let a = SpawnMember(PickRoster(g, rd, tier), cand[k].pos, g, rd, g.health);
			k++;
			if (a) { crew.Push(a); placed++; }
		}
		for (; k < cand.Size(); k++) spareSpots.Push(cand[k]);
		startCount = crew.Size();

		// 6. the squad comes in behind the player
		for (int s = 0; s < rd.squadNames.Size(); s++)
		{
			if (rd.squadHealth[s] <= 0) continue;
			let a = NBC_Ally(Actor.Spawn("NBC_Ally", p.pos, NO_REPLACE));
			if (!a) continue;
			a.slot = s;
			a.health = rd.squadHealth[s];
			a.SetTag(rd.squadNames[s]);
			a.CatchUp(p);
			squad.Push(a);
		}

		if (developer) Console.Printf("nbc raid: %s (%s), %s. %d spawn spots; the game placed %d crew + %s, %d officers. Exit %s.",
			level.MapName, kit ? kit.VariantName() : "no kit", g.name, spots.Size(), startCount, leader ? "leader" : "no leader",
			squad.Size(), exitFound ? "found" : "not found (far spot)");
		String title = TurfTitle(rd.raidDistrict);
		if (kit) title = String.Format("%s, %s", title, kit.VariantName());
		Announce(String.Format("%s. %s hold this block (%d on the floor).\nTake down %s, then get to the exit sign.",
			title, g.name, startCount + (leader ? 1 : 0), g.leaderTitle), 35 * 7);
	}

	String PickRoster(NBC_GangDef g, NBC_RunData rd, int tier)
	{
		Array<String> list;
		if (tier >= 3 && g.roster3.Size()) list.Copy(g.roster3);
		else if (tier >= 2 && g.roster2.Size()) list.Copy(g.roster2);
		else if (g.roster1.Size()) list.Copy(g.roster1);
		else if (g.roster2.Size()) list.Copy(g.roster2);
		if (!list.Size()) return "";
		return list[rd.Rand(0, list.Size() - 1)];
	}

	Actor SpawnMember(String className, Vector3 at, NBC_GangDef g, NBC_RunData rd, double healthMul)
	{
		if (className == "") return null;
		class<Actor> cls = NBC_Gangs.Resolve(className, rd);
		if (!cls) return null;
		Actor a = Actor.Spawn(cls, at, NO_REPLACE);
		if (!a) return null;
		if (!a.TestMobjLocation())
		{
			a.Destroy();
			return null;
		}
		a.angle = rd.Rand(0, 7) * 45;
		a.health = max(1, int(a.SpawnHealth() * healthMul));
		a.PainChance = int(a.PainChance * g.painChance);
		if (g.damageTypes.Size())
		{
			let prof = NBC_GangProfile(a.GiveInventoryType("NBC_GangProfile"));
			if (prof)
			{
				prof.types.Copy(g.damageTypes);
				prof.factors.Copy(g.damageFactors);
			}
		}
		return a;
	}

	// ------------------------------------------------------------ during the raid

	void RaidTick(NBC_RunData rd)
	{
		let p = players[consoleplayer].mo;
		if (!p) return;

		if (rd.officerDown)
		{
			if (officerDownTics == 0)
			{
				officerDownTics = OFFICER_DOWN_TICS;
				p.A_StartSound("*death", CHAN_VOICE);
			}
			p.player.cheats |= CF_TOTALLYFROZEN | CF_GODMODE;
			if (--officerDownTics == 1)
				level.ChangeLevel(HUB_MAP, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETINVENTORY | CHANGELEVEL_RESETHEALTH);
			return;
		}

		if (level.maptime % 35 != 0) return;

		// gang members notice the officers too (the pack's enemies only look for players)
		for (int i = crew.Size() - 1; i >= 0; i--)
		{
			Actor m = crew[i];
			if (!m || m.health <= 0) { crew.Delete(i); continue; }
			if (!m.target || !m.target.player || random(0, 99) >= 30) continue;
			double toPlayer = m.Distance3D(m.target);
			for (int s = 0; s < squad.Size(); s++)
			{
				let a = squad[s];
				if (a && a.health > 0 && m.Distance3D(a) < toPlayer * 0.8 && m.CheckSight(a))
				{
					m.target = a;
					break;
				}
			}
		}

		// reinforcements once the crew is mostly down: out of the player's sight, away from them
		if (!reinforced && startCount > 0 && rd.raidKills >= startCount * REINFORCE_AT)
		{
			reinforced = true;
			let g = GangAt(rd.raidGang);
			int sent = 0;
			for (int i = 0; i < spareSpots.Size() && sent < 6; i++)
			{
				if ((spareSpots[i].pos.xy - p.pos.xy).Length() < SAFE_RADIUS) continue;
				let a = SpawnMember(PickRoster(g, rd, 2), spareSpots[i].pos, g, rd, g.health);
				if (!a) continue;
				if (a.CheckSight(p)) { a.Destroy(); continue; }
				a.target = p;
				a.SetStateLabel("See");
				crew.Push(a);
				sent++;
			}
			if (sent) Announce("Radio: more of them coming down the stairwells.", 35 * 4);
		}
	}

	override void WorldThingDied(WorldEvent e)
	{
		let rd = NBC_RunData.Find();
		if (!rd || !rd.raidActive || !raidSetUp) return;
		Actor t = e.Thing;
		let g = GangAt(rd.raidGang);
		if (t is "NBC_Ally")
		{
			let a = NBC_Ally(t);
			if (a.slot < rd.squadHealth.Size()) rd.squadHealth[a.slot] = 0;
			Announce(String.Format("%s is down!", a.GetTag()), 35 * 3);
			return;
		}
		if (!t.bIsMonster) return;
		rd.raidKills++;
		rd.cash += 10 * (g ? g.tier : 1);
		if (t.FindInventory("NBC_LeaderToken") && !rd.leaderDown)
		{
			rd.leaderDown = true;
			rd.raidBounty = 300 * (g ? g.tier : 1);
			Announce(String.Format("%s is down. Get to the exit to take the block.", g ? g.leaderTitle : "The leader"), 35 * 6);
		}
	}

	override void WorldThingDamaged(WorldEvent e)
	{
		// shot by an officer: often turn on them
		if (e.DamageSource is "NBC_Ally" && e.Thing && e.Thing.bIsMonster && !(e.Thing is "NBC_Ally")
			&& e.Thing.health > 0 && random(0, 99) < 60)
			e.Thing.target = e.DamageSource;
	}

	// ------------------------------------------------------------ results

	void ResolveRaid(NBC_RunData rd)
	{
		let g = GangAt(rd.raidGang);
		String gname = g ? g.name : "The gang";
		String title = TurfTitle(rd.raidDistrict);

		for (int s = 0; s < squad.Size(); s++)
		{
			let a = NBC_Ally(squad[s]);
			if (a && a.slot < rd.squadHealth.Size()) rd.squadHealth[a.slot] = max(0, a.health);
		}

		rd.report.Clear();
		int gi = rd.raidGang;
		if (rd.officerDown)
		{
			rd.strikes++;
			rd.cash /= 2;
			if (gi >= 0 && gi < rd.gangAlert.Size()) rd.gangAlert[gi] = min(3, rd.gangAlert[gi] + 1);
			rd.report.Push("OFFICER DOWN");
			rd.report.Push(String.Format("You were pulled out of %s. Strike %d of %d.", title, rd.strikes, NBC_RunData.MAX_STRIKES));
			rd.report.Push("Half the seized cash went missing in the confusion.");
		}
		else if (rd.leaderDown && gi >= 0 && gi < rd.gangToppled.Size())
		{
			rd.gangToppled[gi] = true;
			rd.cash += rd.raidBounty;
			rd.report.Push(String.Format("%s TOPPLED", g ? g.shortName.MakeUpper() : "GANG"));
			rd.report.Push(String.Format("%s is in custody or in the morgue. Bounty: $%d.", g ? g.leaderTitle : "The leader", rd.raidBounty));
		}
		else
		{
			if (gi >= 0 && gi < rd.gangAlert.Size()) rd.gangAlert[gi] = min(3, rd.gangAlert[gi] + 1);
			rd.report.Push("RETREAT");
			rd.report.Push(String.Format("You pulled out of %s. %s are on alert.", title, gname));
		}
		rd.report.Push(String.Format("Gang members down: %d.   Seized cash: $%d.", rd.raidKills, rd.cash));
		String sq = "Squad:";
		for (int s = 0; s < rd.squadNames.Size(); s++)
			sq = sq .. String.Format("  %s %s", rd.squadNames[s], rd.squadHealth[s] > 0 ? String.Format("(%d)", rd.squadHealth[s]) : "(hospital)");
		rd.report.Push(sq);

		rd.raidActive = false;
		rd.EndDay(gi);
		switch (rd.caseResult)
		{
		case NBC_CASE_WON: rd.report.Push("CASE CLOSED. Every gang in the Bricks is down."); break;
		case NBC_CASE_STRUCK_OUT: rd.report.Push("Three strikes. Internal Affairs takes your badge. The case is over."); break;
		case NBC_CASE_DEMOLITION: rd.report.Push("Day 30. The demolition crews roll in. The case is over."); break;
		default: rd.report.Push(String.Format("Day %d of %d begins.", rd.day, NBC_RunData.MAX_DAYS)); break;
		}
		rd.reportPending = true;
	}

	// ------------------------------------------------------------ the board and debug commands

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "nbc_debug_case") { DebugCase(); return; }
		if (!(e.Name ~== "nbc_board")) return;
		let rd = NBC_RunData.Get();
		int choice = e.Args[0];
		if (choice == -1)
		{
			rd.NewCase(NewSeed(), gangs.Size(), districtMaps.Size());
			Announce(String.Format("New case opened (seed %d). %d gangs, %d districts, %d days.",
				rd.seed, gangs.Size(), districtMaps.Size(), NBC_RunData.MAX_DAYS), 35 * 5);
			return;
		}
		if (!rd.caseActive) return;
		if (choice == -2)
		{
			rd.EndDay(-1);
			Announce(rd.caseActive ? String.Format("You close the day. Day %d.", rd.day) : "The case is over.", 35 * 4);
			return;
		}
		if (choice < 0 || choice >= districtMaps.Size()) return;
		int gi = choice < rd.districtGang.Size() ? rd.districtGang[choice] : -1;
		if (gi >= 0 && gi < rd.gangToppled.Size() && rd.gangToppled[gi]) return;
		rd.BeginRaid(choice);
		PickMansion(GangAt(gi), rd);
		level.ChangeLevel(rd.raidMap, 0, CHANGELEVEL_NOINTERMISSION);
	}

	void DebugCase()
	{
		let rd = NBC_RunData.Find();
		if (!rd) { Console.Printf("nbc: no case data"); return; }
		Console.Printf("nbc case: active %d result %d seed %d rng steps %d day %d strikes %d cash %d",
			rd.caseActive, rd.caseResult, rd.seed, rd.rngSteps, rd.day, rd.strikes, rd.cash);
		for (int d = 0; d < districtMaps.Size(); d++)
		{
			int gi = d < rd.districtGang.Size() ? rd.districtGang[d] : -1;
			let g = GangAt(gi);
			Console.Printf("  %s  %s  %s  alert %d%s", districtMaps[d], districtTitles[d], g ? g.name : "-",
				gi >= 0 && gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0,
				gi >= 0 && gi < rd.gangToppled.Size() && rd.gangToppled[gi] ? "  TOPPLED" : "");
		}
		if (rd.raidActive)
			Console.Printf("  raid: turf %d gang %d on %s variant %d (kit seed %d), crew %d/%d kills %d leader %s", rd.raidDistrict,
				rd.raidGang, rd.raidMap, rd.raidVariant, rd.raidKitSeed, crew.Size(), startCount, rd.raidKills, rd.leaderDown ? "down" : "at large");
	}

	override void UiTick()
	{
		if (boardRequests != boardSeen)
		{
			boardSeen = boardRequests;
			Menu.SetMenu("NBC_RaidBoardMenu");
		}
	}

	// ------------------------------------------------------------ overlay: announcements, officer down, the card

	override void RenderOverlay(RenderEvent e)
	{
		let rd = NBC_RunData.Find();
		int vw = 960, vh = 600;
		if (rd && rd.officerDown && rd.raidActive)
		{
			double t = 1.0 - officerDownTics / double(OFFICER_DOWN_TICS);
			Screen.Dim(0x600000, clamp(0.35 + t * 0.6, 0, 0.95), 0, 0, Screen.GetWidth(), Screen.GetHeight());
			String s = "OFFICER DOWN";
			Screen.DrawText(BigFont, Font.CR_RED, (vw - BigFont.StringWidth(s)) / 2, vh / 2 - 12, s,
				DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);
			return;
		}

		if (announceTics > 0 && announceText != "")
		{
			double alpha = min(1.0, announceTics / 35.0);
			Array<String> lines;
			announceText.Split(lines, "\n");
			for (int i = 0; i < lines.Size(); i++)
				Screen.DrawText(NewSmallFont, Font.CR_GOLD, (vw - NewSmallFont.StringWidth(lines[i])) / 2, 220 + i * 16, lines[i],
					DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true, DTA_Alpha, alpha);
		}

		if (cardTics > 0 && card.Size())
		{
			double alpha = min(1.0, cardTics / 35.0);
			int h = 34 + card.Size() * 16;
			int top = 150;
			Screen.Dim(0, 0.7 * alpha, Screen.GetWidth() / 8, int(Screen.GetHeight() * top / double(vh)),
				Screen.GetWidth() * 3 / 4, int(Screen.GetHeight() * h / double(vh)));
			Screen.DrawText(BigFont, Font.CR_GOLD, (vw - BigFont.StringWidth(card[0])) / 2, top + 8, card[0],
				DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true, DTA_Alpha, alpha);
			for (int i = 1; i < card.Size(); i++)
				Screen.DrawText(NewSmallFont, Font.CR_WHITE, (vw - NewSmallFont.StringWidth(card[i])) / 2, top + 16 + i * 16, card[i],
					DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true, DTA_Alpha, alpha);
		}
	}
}
