// The case loop (PLAN.md M2, M3, M6): precinct -> plan a raid -> a district's Obsidian map -> the precinct.
//
// The precinct terminal (nbc/zscript/nbc/ui/) opens a case, picks a district (each held by a gang) and fits out
// the raid: up to four officers off the roster, everyone's kit from the Evidence Locker. The raid runs on the
// district's map (districts.txt, built by Obsidian): the manager clears the map's own monsters, fills their
// spots with the holding gang (count from the gang's tier, budget and alert), stands the leader near the exit
// with escorts, kits the player out and brings the squad in behind them. Taking the exit resolves the raid:
// leader down = gang toppled, otherwise a retreat. Lethal damage = OFFICER DOWN. Afterwards everything the
// player carries goes back into the locker, the evidence team bags what the gang dropped (a taken block only),
// officers earn XP or go to the hospital or the memorial, and the after-action report waits at the precinct.
//
// Kit maps (NBC_K*, M2b) still work as raid maps: the kit gives the spawn spots and the exit.

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
	const REINFORCE_AT = 0.6;           // fraction of the starting crew down before reinforcements come
	const OFFICER_DOWN_TICS = 70;

	Array<NBC_GangDef> gangs;
	Array<String> districtMaps, districtTitles, districtEnvs;
	Array<String> roofMaps;             // the helicopter's rooftop map per district (nbc/rooftops.txt)

	// raid bookkeeping (this map only)
	bool raidSetUp, reinforced, exitFound;
	bool blockAwake, fireStrike;
	Vector3 parkedAt;                   // where the motorcade parked (nbc_debug_motorcade)        // crowded streets: the first shot wakes the block; fire in the crowd (a strike)
	int startCount, officerDownTics, cashAtStart;
	Vector3 exitPos;
	Actor leader;
	Array<Actor> crew, squad;
	Array<NBC_Spot> spareSpots, allSpots;

	// messages
	String announceText;
	int announceTics;

	// the precinct terminal: the hub usables ask for it (a tab), the UI opens it
	enum EMenuKind { MK_TERMINAL, MK_WHEELSUP }
	int menuRequests, menuTab, menuKind, menuOfficer;
	// someone at the HQ talking: a subtitle along the bottom (NBC_HQNpc)
	String speakName, speakText, speakHint, speakFace;
	int speakTics;
	ui int menuSeen, reportSeen, rosterSaved;

	override void WorldLoaded(WorldEvent e)
	{
		NBC_Gangs.LoadGangs(gangs);
		NBC_Gangs.LoadDistricts(districtMaps, districtTitles, districtEnvs);
		NBC_Gangs.LoadRooftops(districtMaps, roofMaps);
		if (e.IsSaveGame) return;

		let rd = NBC_RunData.Get();
		let dept = NBC_Department.Get();
		if (IsHub())
		{
			// the kit lives in the Evidence Locker between raids (it was checked in when the raid map unloaded)
			let p = players[consoleplayer].mo;
			if (p) StripKit(p);
			if (!dept.reportPending)
			{
				String radio = rd.caseActive && rd.evKind != NBC_Clock.EV_NONE ? String.Format("\nRADIO, %s: %s", NBC_Clock.EV_NAME[rd.evKind],
					NBC_Clock.EventLine(rd.evKind, TurfTitle(rd.evDistrict), rd.evWindow)) : "";
				Announce(rd.caseActive ? "CHECKPOINT 9. Plan the next raid at the raid board, or ask the captain." .. radio :
					"CHECKPOINT 9. Talk to the captain, or open a case at the raid board.", 35 * (radio != "" ? 10 : 6));
			}
			StaffHQ(dept);
		}
	}

	// The officers fit for duty stand around the HQ (NBC_HQSpot things, in order); the hospital keeps the rest.
	void StaffHQ(NBC_Department dept)
	{
		Array<Actor> spots;
		let it = ThinkerIterator.Create("NBC_HQSpot");
		Actor s;
		while ((s = Actor(it.Next()))) spots.Push(s);
		// the map's order, by editor position, so the same officer gets the same spot
		for (int i = 1; i < spots.Size(); i++)
			for (int j = i; j > 0 && spots[j - 1].SpawnPoint.x * 4096 + spots[j - 1].SpawnPoint.y > spots[j].SpawnPoint.x * 4096 + spots[j].SpawnPoint.y; j--)
			{
				Actor t = spots[j]; spots[j] = spots[j - 1]; spots[j - 1] = t;
			}
		int k = 0;
		for (int i = 0; i < dept.roster.Size() && k < spots.Size(); i++)
		{
			let o = dept.roster[i];
			if (!o.Available()) continue;
			let npc = NBC_HQOfficer(Actor.Spawn("NBC_HQOfficer", spots[k].pos, NO_REPLACE));
			if (!npc) continue;
			npc.angle = spots[k].angle;
			npc.Dress(o);
			k++;
		}
	}

	void Speak(String who, String text, String hint = "", String face = "")
	{
		speakName = who; speakText = text; speakHint = hint; speakFace = face;
		speakTics = 35 * 6;
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
		if (speakTics > 0) speakTics--;

		let rd = NBC_RunData.Find();
		if (!IsRaidMap(rd)) return;
		if (!raidSetUp)
		{
			// wait two tics: a kit puts the player at the insertion on the first, and spawners resolve
			if (level.maptime >= 2) SetupRaid(rd);
			return;
		}
		rd.raidTics++;
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

	clearscope String TurfEnv(int d) const
	{
		return d >= 0 && d < districtEnvs.Size() ? districtEnvs[d] : "streets";
	}

	clearscope NBC_GangDef GangAt(int i) const
	{
		return i >= 0 && i < gangs.Size() ? gangs[i] : null;
	}

	// the gang holding a district (null: nobody), and whether it's already down
	clearscope NBC_GangDef DistrictGang(NBC_RunData rd, int d) const
	{
		return rd && d >= 0 && d < rd.districtGang.Size() ? GangAt(rd.districtGang[d]) : null;
	}
	clearscope bool DistrictTaken(NBC_RunData rd, int d) const
	{
		int gi = rd && d >= 0 && d < rd.districtGang.Size() ? rd.districtGang[d] : -1;
		return gi >= 0 && gi < rd.gangToppled.Size() && rd.gangToppled[gi];
	}
	// roughly how many are on the block (the raid's own count, before the dice), at an hour (-1: the one it'd go in at)
	clearscope int CrewEstimate(NBC_RunData rd, int d, int w = -1) const
	{
		let g = DistrictGang(rd, d);
		if (!g) return 0;
		int gi = rd.districtGang[d];
		int alert = gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
		if (w < 0) w = rd.WindowFor(d);
		int ev = rd.EventIn(d) ? rd.evKind : NBC_Clock.EV_NONE;
		static const int baseCount[] = { 22, 18, 16 };
		return int(baseCount[clamp(g.tier, 1, 3) - 1] * g.budget * (1.0 + 0.15 * alert) * g.StrengthAt(w) * NBC_Clock.EV_STRENGTH[ev])
			+ 1 + g.escorts + NBC_Clock.EV_ESCORTS[ev];
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

	// ------------------------------------------------------------ the player's kit

	static const String MAGAZINES[] = { "NBC_ColtMagazine", "NBC_Dual92Magazine", "NBC_PumpMagazine", "NBC_UziMagazine", "NBC_AKMagazine" };

	// everything the catalog knows about out of the player's hands (fists, debris and the quick throw stay)
	static void StripKit(Actor p)
	{
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
		{
			class<Inventory> cls = NBC_Cat.ITEM_CLASS[i];
			if (cls && !(cls is "BasicArmorPickup")) p.TakeInventory(cls, 0x7fffffff);
		}
		for (int i = 0; i < NBC_RunManager.MAGAZINES.Size(); i++) p.TakeInventory(NBC_RunManager.MAGAZINES[i], 0x7fffffff);
		p.TakeInventory("MolotovCocktail", 1);
		p.TakeInventory("BasicArmor", 0x7fffffff);
		if (p.player && !p.player.ReadyWeapon)
		{
			let fists = Weapon(p.FindInventory("FistsOfFury"));
			if (!fists) fists = Weapon(p.GiveInventoryType("FistsOfFury"));
			let pp = PlayerPawn(p);
			if (fists && pp) { p.player.PendingWeapon = fists; pp.BringUpWeapon(); }
		}
	}

	// the kit the terminal fitted, out of the locker: weapons, ammo for them (up to a carry cap), pouches, vest
	void IssueKit(PlayerPawn p, NBC_Department dept, NBC_RunData rd)
	{
		StripKit(p);
		rd.raidIssued.Clear();
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++) rd.raidIssued.Push(0);
		static const int AMMO_CAP[] = { 200, 50, 150 };   // light, shells, rifle

		Array<int> slots;
		slots.Push(dept.pPrimary); slots.Push(dept.pSidearm); slots.Push(dept.pMelee);
		Weapon first = null;
		for (int k = 0; k < slots.Size(); k++)
		{
			int it = slots[k];
			if (it < 0) continue;
			class<Inventory> cls = NBC_Cat.ITEM_CLASS[it];
			let w = Weapon(p.GiveInventoryType(cls));
			rd.raidIssued[it]++;
			if (w && !first) first = w;
			int am = NBC_Cat.AmmoOf(it);
			if (am >= 0 && rd.raidIssued[am] == 0)
			{
				int n = min(dept.locker[am], AMMO_CAP[am - NBC_Cat.IT_LIGHT]);
				dept.Take(am, n);
				rd.raidIssued[am] = n;
				class<Inventory> acls = NBC_Cat.ITEM_CLASS[am];
				p.TakeInventory(acls, 0x7fffffff);
				if (n > 0) p.GiveInventory(acls, n);
			}
		}
		// the guns came with a few loose rounds of their own: none of those, the magazines load from the reserve
		for (int i = 0; i < NBC_RunManager.MAGAZINES.Size(); i++) p.TakeInventory(NBC_RunManager.MAGAZINES[i], 0x7fffffff);
		for (int i = NBC_Cat.IT_LIGHT; i <= NBC_Cat.IT_RIFLE; i++)
		{
			class<Inventory> acls = NBC_Cat.ITEM_CLASS[i];
			let have = p.FindInventory(acls);
			if (have) have.Amount = rd.raidIssued[i];
		}
		for (let inv = p.Inv; inv; inv = inv.Inv)
		{
			let w = NBC_ReloadWeapon(inv);
			if (!w || !w.AmmoType1 || !w.AmmoType2) continue;
			let mag = p.FindInventory(w.AmmoType1);
			if (!mag) mag = p.GiveInventoryType(w.AmmoType1);
			let res = p.FindInventory(w.AmmoType2);
			if (!mag || !res) continue;
			mag.MaxAmount = w.NBC_MagazineCapacity();
			int load = min(mag.MaxAmount - mag.Amount, res.Amount);
			mag.Amount += load;
			res.Amount -= load;
		}

		// pouches: one bottle or one medkit each
		int bottles = 0, kits = 0;
		for (int k = 0; k < dept.pPouch.Size(); k++)
		{
			if (dept.pPouch[k] == NBC_Cat.IT_MOLOTOV) bottles++;
			else if (dept.pPouch[k] == NBC_Cat.IT_MEDKIT) kits++;
		}
		rd.raidIssued[NBC_Cat.IT_MOLOTOV] = bottles;
		rd.raidIssued[NBC_Cat.IT_MEDKIT] = kits;
		if (bottles > 0)
		{
			p.GiveInventoryType("MolotovCocktail");
			let a = p.FindInventory("MolotovAmmo");
			if (a) a.Amount = bottles;
		}
		if (kits > 0) p.GiveInventory("NBC_Medkit", kits);
		if (dept.pVest) { p.GiveInventory("GreenArmor", 1); rd.raidIssued[NBC_Cat.IT_VEST] = 1; }

		if (first && p.player) { p.player.PendingWeapon = first; p.BringUpWeapon(); }
	}

	// what the player brings out, per catalog item (magazines count as rounds)
	static void CountKit(Actor p, out Array<int> back)
	{
		back.Clear();
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++) back.Push(0);
		if (!p) return;
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
		{
			int k = NBC_Cat.Kind(i);
			class<Inventory> cls = NBC_Cat.ITEM_CLASS[i];
			if (k == NBC_Cat.K_VEST || !cls) continue;
			back[i] = NBC_Cat.IsWeapon(i) ? (p.FindInventory(cls) ? 1 : 0) : p.CountInv(cls);
		}
		for (let inv = p.Inv; inv; inv = inv.Inv)
		{
			let w = NBC_ReloadWeapon(inv);
			if (!w || !w.AmmoType1 || !w.AmmoType2) continue;
			int am = NBC_Cat.ItemOfClass(w.AmmoType2);
			if (am >= 0) back[am] += p.CountInv(w.AmmoType1);
		}
		// magazines shared by two guns were counted twice: count each magazine type once
		Array<Name> seen;
		for (let inv = p.Inv; inv; inv = inv.Inv)
		{
			let w = NBC_ReloadWeapon(inv);
			if (!w || !w.AmmoType1 || !w.AmmoType2) continue;
			Name mn = w.AmmoType1.GetClassName();
			if (seen.Find(mn) != seen.Size())
			{
				int am = NBC_Cat.ItemOfClass(w.AmmoType2);
				if (am >= 0) back[am] -= p.CountInv(w.AmmoType1);
			}
			else seen.Push(mn);
		}
		let armor = p.FindInventory("BasicArmor");
		back[NBC_Cat.IT_VEST] = armor && armor.Amount > 0 ? 1 : 0;
	}

	// The evidence team bags what the gang dropped (items that fell from bodies, not what Obsidian placed).
	// Guns past three of a kind come back as their rounds.
	static void SweepDrops(out Array<int> found)
	{
		found.Clear();
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++) found.Push(0);
		let it = ThinkerIterator.Create("Inventory");
		Inventory item;
		while ((item = Inventory(it.Next())))
		{
			if (item.Owner || !item.bDropped) continue;
			if (item is "MolotovCocktail") { found[NBC_Cat.IT_MOLOTOV]++; continue; }
			if (item is "NBC_ShellAmmoBox") { found[NBC_Cat.IT_SHELL] += 20; continue; }
			for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
			{
				class<Inventory> cls = NBC_Cat.ITEM_CLASS[i];
				if (!cls || !(item is cls)) continue;
				found[i] += NBC_Cat.IsWeapon(i) ? 1 : max(1, item.Amount);
				break;
			}
		}
		// every thug carries a pistol: the evidence team keeps three of a kind, the rest are stripped for rounds
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
		{
			if (!NBC_Cat.IsWeapon(i) || found[i] <= 3) continue;
			int am = NBC_Cat.AmmoOf(i);
			if (am >= 0) found[am] += (found[i] - 3) * 8;
			found[i] = 3;
		}
	}

	// ------------------------------------------------------------ raid setup

	void SetupRaid(NBC_RunData rd)
	{
		raidSetUp = true;
		let p = players[consoleplayer].mo;
		let g = GangAt(rd.raidGang);
		if (!p || !g) return;
		let dept = NBC_Department.Get();
		cashAtStart = rd.cash;

		// 1. the map's own monsters out (their spots kept); a kit gives its own spots
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

		// the hour and the day's event (clock.zs)
		int w = clamp(rd.raidWindow, 0, NBC_Clock.W_COUNT - 1);
		int ev = clamp(rd.raidEvent, 0, NBC_Clock.EV_COUNT - 1);
		double hpMul = g.health * NBC_Clock.EV_HEALTH[ev];
		int offGuard = clamp(g.OffGuardAt(w) + NBC_Clock.EV_OFFGUARD[ev], 0, 90);
		blockAwake = false; fireStrike = false;

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
				int escorts = g.escorts + NBC_Clock.EV_ESCORTS[ev];
				for (int k = 0; k < escorts; k++)
				{
					Vector2 off = Actor.AngleToVector(k * 360.0 / max(1, escorts), 72 + 24 * (k / 4));
					Vector3 ep = (lp.xy + off, lp.z);
					let esc = SpawnMember(PickRoster(g, rd, 2), ep, g, rd, hpMul);
					if (esc) crew.Push(esc);
				}
			}
		}

		// 5. the crew: the game sets the count, not Obsidian
		static const int baseCount[] = { 22, 18, 16 };
		int alert = rd.gangAlert.Size() > rd.raidGang ? rd.gangAlert[rd.raidGang] : 0;
		int want = int(baseCount[clamp(g.tier, 1, 3) - 1] * g.budget * (1.0 + 0.15 * alert) * InsertionCrewFactor(rd)
			* g.StrengthAt(w) * NBC_Clock.EV_STRENGTH[ev]);
		want = min(want, cand.Size());
		int placed = 0, k = 0, asleep = 0;
		while (placed < want && k < cand.Size())
		{
			int r = rd.Rand(0, 99);
			int tier = r < 60 - alert * 5 ? 1 : (r < 90 ? 2 : 3);
			let a = SpawnMember(PickRoster(g, rd, tier), cand[k].pos, g, rd, hpMul);
			k++;
			if (!a) continue;
			crew.Push(a);
			placed++;
			if (rd.Rand(0, 99) < offGuard) { a.GiveInventoryType("NBC_OffGuard"); asleep++; }
		}
		for (; k < cand.Size(); k++) spareSpots.Push(cand[k]);
		allSpots.Copy(spots);
		startCount = crew.Size();

		// 6. your kit, then the squad in behind you
		IssueKit(p, dept, rd);
		for (int s = 0; s < rd.raidOff.Size(); s++)
		{
			let o = dept.OfficerById(rd.raidOff[s]);
			if (!o) continue;
			let a = NBC_Ally(Actor.Spawn("NBC_Ally", p.pos, NO_REPLACE));
			if (!a) continue;
			a.Equip(o, s);
			if (RolledOut(rd, NBC_Motor.V_TRUCK)) a.takeMul *= 0.85;     // they rode in armored
			a.range *= NBC_Clock.SIGHT[w];                                 // the dark
			a.spread *= NBC_Clock.SPREAD[w];
			a.CatchUp(p);
			squad.Push(a);
		}

		// 7. the hour: the sky and the light
		NBC_Clock.LightTheBlock(w, NBC_Clock.EV_DARK[ev]);

		// 8. how you got here: the motorcade parks behind you, or the helicopter came down
		int parked = rd.raidMode == NBC_Motor.MODE_STREET ? ParkMotorcade(p, rd) : 0;

		if (developer) Console.Printf("nbc raid: %s (%s), %s. %d spawn spots; the game placed %d crew + %s, %d officers, %d vehicles parked. %s, %d off guard. Exit %s.",
			level.MapName, kit ? kit.VariantName() : TurfEnv(rd.raidDistrict), g.name, spots.Size(), startCount,
			leader ? "leader" : "no leader", squad.Size(), parked, NBC_Clock.WindowLine(w), asleep, exitFound ? "found" : "not found (far spot)");
		String title = TurfTitle(rd.raidDistrict);
		if (kit) title = String.Format("%s, %s", title, kit.VariantName());
		if (rd.raidMode == NBC_Motor.MODE_CRASH) { CrashSite(p, rd, g); return; }
		String how = rd.raidMode == NBC_Motor.MODE_ROOF ? "Rook puts you down on the roofs. " : "";
		String when = NBC_Clock.WindowLine(w);
		if (ev != NBC_Clock.EV_NONE) when = String.Format("%s, %s", when, NBC_Clock.EV_NAME[ev]);
		if (ev == NBC_Clock.EV_CROWD) when = when .. ": no fire in the crowd";
		if (w == NBC_Clock.W_DUSK || w == NBC_Clock.W_NIGHT || ev == NBC_Clock.EV_BLACKOUT)
			when = when .. ". It's dark: F for your flashlight (they'll see it too)";
		Announce(String.Format("%s%s, %s. %s hold this block (%d on the ground).\nTake down %s, then get to the exit.",
			how, title, when, g.name, startCount + (leader ? 1 : 0), g.leaderTitle), 35 * 7);
	}

	// ------------------------------------------------------------ the motorcade (garage.zs)

	// after a raid: the motorcade takes its knocks; a shot-down helicopter is gone
	void Wear(NBC_RunData rd, NBC_Department dept, NBC_Report rep, bool taken)
	{
		for (int i = 0; i < rd.raidVehicles.Size(); i++)
		{
			let v = dept.VehicleById(rd.raidVehicles[i]);
			if (!v) continue;
			int was = v.cond;
			if (rd.raidMode == NBC_Motor.MODE_CRASH && NBC_Motor.Flies(v.type)) v.cond = 0;
			else if (v.type == NBC_Motor.V_TRUCK) continue;
			else if (NBC_Motor.Flies(v.type)) v.cond -= rd.Rand(2, 8);
			else v.cond -= rd.Rand(4, 14) + (taken ? 0 : 8);
			if (v.cond <= 0)
			{
				rep.notes.Push(rd.raidMode == NBC_Motor.MODE_CRASH && NBC_Motor.Flies(v.type) ?
					String.Format("The %s went down in the Bricks. It's gone.", v.Name()) : String.Format("The %s is a write-off.", v.Name()));
				dept.garage.Delete(dept.garage.Find(v));
				continue;
			}
			if (v.cond < NBC_Motor.SHOP_BELOW) { v.rolling = false; rep.notes.Push(String.Format("The %s needs the shop (%d%%).", v.Name(), v.cond)); }
			else if (was - v.cond >= 10) rep.notes.Push(String.Format("The %s took some rounds (%d%%).", v.Name(), v.cond));
		}
		// a raid used up a seat? pick again for the next one
		if (dept.Seats(dept.insertion) < dept.SeatsNeeded()) dept.AutoMotorcade();
	}

	clearscope bool RolledOut(NBC_RunData rd, int type) const
	{
		let dept = NBC_Department.Find();
		if (!dept) return false;
		for (int i = 0; i < rd.raidVehicles.Size(); i++)
		{
			let v = dept.VehicleById(rd.raidVehicles[i]);
			if (v && v.type == type) return true;
		}
		return false;
	}

	// fewer of them where they aren't looking: the roofs, or the unmarked sedan
	double InsertionCrewFactor(NBC_RunData rd)
	{
		if (rd.raidMode == NBC_Motor.MODE_ROOF) return 0.8;
		if (rd.raidMode != NBC_Motor.MODE_STREET || !rd.raidVehicles.Size()) return 1.0;
		let dept = NBC_Department.Find();
		for (int i = 0; i < rd.raidVehicles.Size(); i++)
		{
			let v = dept ? dept.VehicleById(rd.raidVehicles[i]) : null;
			if (v && v.type != NBC_Motor.V_SEDAN) return 1.0;
		}
		return 0.85;
	}

	// the vehicles that brought you, parked out on the street nearest the start (Obsidian's starts are often
	// indoors): the closest clear spot under the sky, away from the gang; the rest of the motorcade parks beside
	// the first
	int ParkMotorcade(Actor p, NBC_RunData rd)
	{
		let dept = NBC_Department.Find();
		if (!dept) return 0;
		int n = 0;
		Vector2 first = p.pos.xy;
		for (int i = 0; i < rd.raidVehicles.Size(); i++)
		{
			let v = dept.VehicleById(rd.raidVehicles[i]);
			if (!v) continue;
			class<Actor> cls = NBC_Motor.TYPE_ACTOR[v.type];
			if (!cls) continue;
			// the first one: rings out from the start; the others: rings out from the first
			Vector2 from = n ? first : p.pos.xy;
			double r0 = n ? 120 : 96, r1 = n ? 480 : 1600;
			bool parked = false;
			for (double r = r0; r <= r1 && !parked; r += 64)
			{
				for (double a = 0; a < 360 && !parked; a += 15)
				{
					Vector2 at = from + Actor.AngleToVector(p.angle + 180 + a, r);
					Sector sec = level.PointInSector(at);
					if (sec.GetTexture(Sector.ceiling) != skyflatnum) continue;
					bool near = false;
					for (int c = 0; c < crew.Size() && !near; c++) if (crew[c] && (crew[c].pos.xy - at).Length() < 448) near = true;
					if (near) continue;
					let car = Actor.Spawn(cls, (at, sec.floorplane.ZatPoint(at)), NO_REPLACE);
					if (!car) break;
					if (!car.TestMobjLocation()) { car.Destroy(); continue; }
					car.angle = p.angle + rd.Rand(-1, 1) * 10;
					parked = true;
					if (!n) { first = at; parkedAt = (at, car.pos.z); }
					n++;
				}
			}
		}
		return n;
	}

	// Shot down: the helicopter comes down somewhere out in the open, away from the exit and the leader; everyone's
	// hurt; the gang converges on the wreck in waves (CrashTick) until the way out is clear.
	void CrashSite(Actor p, NBC_RunData rd, NBC_GangDef g)
	{
		Array<NBC_Spot> ok;
		for (int i = 0; i < allSpots.Size(); i++)
		{
			Vector3 at = allSpots[i].pos;
			Sector sec = level.PointInSector(at.xy);
			if (sec.GetTexture(Sector.ceiling) != skyflatnum) continue;
			if (exitFound && (at.xy - exitPos.xy).Length() < 1200) continue;
			if (leader && (at.xy - leader.pos.xy).Length() < 1024) continue;
			bool crowded = false;
			for (int c = 0; c < crew.Size() && !crowded; c++) if (crew[c] && (crew[c].pos.xy - at.xy).Length() < 384) crowded = true;
			if (!crowded) ok.Push(allSpots[i]);
		}
		if (ok.Size())
		{
			Vector3 at = ok[rd.Rand(0, ok.Size() - 1)].pos;
			p.SetOrigin(at, false);
			p.angle = rd.Rand(0, 7) * 45;
		}
		// the wreck, burning, a little way off
		for (int t = 0; t < 8; t++)
		{
			Vector2 w = p.pos.xy + Actor.AngleToVector(p.angle + t * 45, 170);
			let wreck = Actor.Spawn(NBC_Motor.TYPE_ACTOR[NBC_Motor.V_HELI], (w, p.GetZAt(w.x, w.y, 0, GZF_ABSOLUTEPOS)), NO_REPLACE);
			if (!wreck) break;
			if (!wreck.TestMobjLocation()) { wreck.Destroy(); continue; }
			wreck.angle = p.angle + 70;
			wreck.A_SetTranslation("NBC_Burnt");
			Actor.Spawn("NBC_WreckFire", wreck.pos);
			break;
		}
		// everyone took the landing hard
		if (p.player) p.player.health = p.health = max(30, p.health - rd.Rand(15, 35));
		for (int s = 0; s < squad.Size(); s++)
		{
			let a = NBC_Ally(squad[s]);
			if (!a) continue;
			a.health = max(10, a.health - a.maxHp * rd.Rand(15, 40) / 100);
			a.CatchUp(p);
		}
		rd.crashWave = 0;
		rd.crashNext = level.maptime + 35 * 10;
		Announce(String.Format("MAYDAY! The bird's down in %s.\nThey'll come for the wreck. Hold out until the way to the exit is clear.",
			TurfTitle(rd.raidDistrict)), 35 * 8);
	}

	// the ambush round the wreck: waves out of sight, coming for you; after the last, the way out is clear
	void CrashTick(NBC_RunData rd, Actor p)
	{
		if (rd.crashClear) return;
		let g = GangAt(rd.raidGang);
		if (!g) return;
		if (rd.crashWave >= NBC_Motor.CRASH_WAVES)
		{
			if (level.maptime >= rd.crashNext)
			{
				rd.crashClear = true;
				Announce("Radio: a unit's holding the street to the exit. Move, now!", 35 * 6);
			}
			return;
		}
		if (level.maptime < rd.crashNext) return;
		int alert = rd.raidGang < rd.gangAlert.Size() ? rd.gangAlert[rd.raidGang] : 0;
		int n = min(10, 3 + 2 * g.tier + alert);
		int sent = 0;
		for (int t = 0; t < allSpots.Size() * 2 && sent < n; t++)
		{
			NBC_Spot sp = allSpots[rd.Rand(0, allSpots.Size() - 1)];
			double d = (sp.pos.xy - p.pos.xy).Length();
			if (d < 700 || d > 2400) continue;
			let a = SpawnMember(PickRoster(g, rd, rd.Rand(1, 2)), sp.pos, g, rd, g.health);
			if (!a) continue;
			if (a.CheckSight(p)) { a.Destroy(); continue; }
			a.target = p;
			a.SetStateLabel("See");
			crew.Push(a);
			sent++;
		}
		rd.crashWave++;
		rd.crashNext = level.maptime + 35 * (rd.crashWave >= NBC_Motor.CRASH_WAVES ? 30 : 25);
		Announce(String.Format("Wave %d of %d: %d of them closing on the wreck.", rd.crashWave, NBC_Motor.CRASH_WAVES, sent), 35 * 3);
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
				level.ChangeLevel(HUB_MAP, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
			return;
		}

		if (level.maptime % 35 != 0) return;
		if (rd.raidMode == NBC_Motor.MODE_CRASH) CrashTick(rd, p);

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
			if (sent) Announce("Radio: more of them coming in behind you.", 35 * 4);
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
			Announce(String.Format("%s is down!", a.GetTag()), 35 * 3);
			return;
		}
		if (!t.bIsMonster) return;
		rd.raidKills++;
		rd.cash += 10 * (g ? g.tier : 1);
		if (t.FindInventory("NBC_LeaderToken") && !rd.leaderDown)
		{
			rd.leaderDown = true;
			rd.raidBounty = 300 * (g ? g.tier : 1) * (rd.raidEvent == NBC_Clock.EV_DEAL ? 2 : 1);
			Announce(String.Format("%s is down. Get to the exit to take the block.", g ? g.leaderTitle : "The leader"), 35 * 6);
		}
	}

	override void WorldThingDamaged(WorldEvent e)
	{
		let rd = NBC_RunData.Find();
		if (!rd || !rd.raidActive || !raidSetUp || !e.Thing) return;
		Actor t = e.Thing;
		if (t.player) { rd.raidHealthLost += e.Damage; return; }
		if (!t.bIsMonster || t is "NBC_Ally") return;
		// crowded streets: the first shot sends the crowd running and wakes the block; fire in the crowd is a strike
		if (rd.raidEvent == NBC_Clock.EV_CROWD && e.DamageSource && (e.DamageSource.player || e.DamageSource is "NBC_Ally"))
		{
			if (!blockAwake) { blockAwake = true; Announce("Shots fired! The crowd scatters and the whole block knows you're here.", 35 * 4); }
			if (e.DamageType == 'Fire' && !fireStrike)
			{
				fireStrike = true;
				rd.strikes++;
				Announce(String.Format("Fire in a crowd. Internal Affairs will hear about this: strike %d of %d.", rd.strikes, NBC_RunData.MAX_STRIKES), 35 * 6);
			}
		}
		// who gets the kill (this event comes just before the death)
		if (t.health <= 0 && e.DamageSource)
		{
			if (e.DamageSource.player) rd.raidPlayerKills++;
			else if (e.DamageSource is "NBC_Ally")
			{
				int s = rd.RaidSlotOf(NBC_Ally(e.DamageSource).officerId);
				if (s >= 0) rd.raidOffKills[s]++;
			}
			return;
		}
		// shot by an officer: often turn on them
		if (e.DamageSource is "NBC_Ally" && t.health > 0 && random(0, 99) < 60) t.target = e.DamageSource;
	}

	// ------------------------------------------------------------ results

	void ResolveRaid(NBC_RunData rd)
	{
		let g = GangAt(rd.raidGang);
		let dept = NBC_Department.Get();
		String title = TurfTitle(rd.raidDistrict);
		int gi = rd.raidGang;
		bool taken = !rd.officerDown && rd.leaderDown && gi >= 0 && gi < rd.gangToppled.Size();

		let rep = new("NBC_Report");
		rep.place = title;
		rep.gang = g ? g.name : "";
		rep.kills = rd.raidKills;
		rep.playerKills = rd.raidPlayerKills;
		rep.crewTotal = startCount + (leader ? 1 : 0);
		rep.healthLost = rd.raidHealthLost;
		rep.timeSecs = rd.raidTics / 35;
		rep.leaderDown = rd.leaderDown;

		// a day has passed for the officers who stayed behind (before this raid's wounds are counted)
		dept.NewDay();

		// 1. the officers who went in
		for (int s = 0; s < squad.Size(); s++)
		{
			let a = NBC_Ally(squad[s]);
			if (!a) continue;
			int slot = rd.RaidSlotOf(a.officerId);
			if (slot < 0) continue;
			rd.raidOffHealth[slot] = max(0, a.health);
			let o = dept.OfficerById(a.officerId);
			if (o && a.health > 0) a.ReturnPouches(o);
		}
		int lost = 0, critical = 0;
		for (int s = 0; s < rd.raidOff.Size(); s++)
		{
			let o = dept.OfficerById(rd.raidOff[s]);
			if (!o) continue;
			int hp = rd.raidOffHealth[s];
			int kills = rd.raidOffKills[s];
			int st = NBC_Report.OS_FIT;
			o.raids++;
			o.kills += kills;
			o.xp += kills * 10 + (hp > 0 ? 20 : 0) + (rd.leaderDown ? 15 : 0);
			if (hp <= 0)
			{
				// pulled out alive? Better odds when the block is yours and the medics get in
				int chance = (taken ? 50 : (rd.officerDown ? 15 : 30)) + 10 * o.rank;
				if (rd.Rand(0, 99) < chance)
				{
					st = NBC_Report.OS_CRITICAL;
					o.state = NBC_Officer.ST_HOSPITAL;
					o.hospital = 4;
					o.health = max(1, o.MaxHealth() / 4);
					critical++;
				}
				else
				{
					st = NBC_Report.OS_KIA;
					lost++;
				}
			}
			else
			{
				o.health = min(hp, o.MaxHealth());
				if (hp * 100 < o.MaxHealth() * 40) { st = NBC_Report.OS_WOUNDED; o.state = NBC_Officer.ST_HOSPITAL; o.hospital = 2; }
				else if (hp * 100 < o.MaxHealth() * 70) { st = NBC_Report.OS_WOUNDED; o.state = NBC_Officer.ST_HOSPITAL; o.hospital = 1; }
			}
			rep.offId.Push(o.id);
			rep.offName.Push(o.RankedName());
			rep.offFace.Push(o.face);
			rep.offRank.Push(o.rank);
			rep.offKills.Push(kills);
			rep.offState.Push(st);
			rep.offXP.Push(o.xp);
			rep.offPromote.Push(st != NBC_Report.OS_KIA && o.CanPromote());
			if (st == NBC_Report.OS_KIA) dept.KillOfficer(o, rd.day, title);
		}
		dept.PruneSquad();
		dept.rosterVersion++;

		// 2. the player's kit back into the locker, plus what the evidence team bags on a taken block
		Array<int> back, found, loot;
		CountKit(players[consoleplayer].mo, back);
		dept.CheckIn(back, rd.raidIssued, loot);
		if (taken)
		{
			SweepDrops(found);
			for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
			{
				dept.Give(i, found[i]);
				loot[i] += found[i];
			}
		}
		for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
			if (loot[i] > 0) { rep.lootItem.Push(i); rep.lootCount.Push(loot[i]); }

		// 3. the block
		if (rd.officerDown)
		{
			rep.outcome = NBC_Report.OUT_DOWN;
			rep.title = "OFFICER DOWN";
			rd.strikes++;
			rd.cash = cashAtStart + (rd.cash - cashAtStart) / 2;
			if (gi >= 0 && gi < rd.gangAlert.Size()) rd.gangAlert[gi] = min(3, rd.gangAlert[gi] + 1);
		}
		else if (taken)
		{
			rep.outcome = NBC_Report.OUT_TAKEN;
			rep.title = String.Format("%s TOPPLED", g ? g.shortName.MakeUpper() : "GANG");
			rd.gangToppled[gi] = true;
			rd.cash += rd.raidBounty;
			rep.bounty = rd.raidBounty;
		}
		else if (rd.raidMode == NBC_Motor.MODE_CRASH)
		{
			// shot down and walked out: no strike for that
			rep.outcome = NBC_Report.OUT_CRASH;
			rep.title = "SHOT DOWN - SURVIVED";
			if (gi >= 0 && gi < rd.gangAlert.Size()) rd.gangAlert[gi] = min(3, rd.gangAlert[gi] + 1);
		}
		else
		{
			rep.outcome = NBC_Report.OUT_RETREAT;
			rep.title = "RETREAT";
			if (gi >= 0 && gi < rd.gangAlert.Size()) rd.gangAlert[gi] = min(3, rd.gangAlert[gi] + 1);
		}
		rep.mode = rd.raidMode;
		Wear(rd, dept, rep, taken);
		// the day's event: a pinned-down unit got out
		if (rd.raidEvent == NBC_Clock.EV_PINNED && !rd.officerDown)
		{
			rd.cash += NBC_Clock.PINNED_PAY;
			rep.bounty += NBC_Clock.PINNED_PAY;
			rep.notes.Push(String.Format("The pinned unit's out. City Hall pays $%d.", NBC_Clock.PINNED_PAY));
		}
		rep.cashRaid = rd.cash - cashAtStart - rep.bounty;
		rep.balance = rd.cash;

		// 4. the grade: the block, the body count, the cost
		int score = (taken ? 40 : 0) + (rep.crewTotal > 0 ? 35 * min(rep.kills, rep.crewTotal) / rep.crewTotal : 0)
			+ (lost + critical == 0 && rd.raidOff.Size() > 0 ? 10 : 0) + 15
			- lost * 15 - critical * 5 - min(20, rep.healthLost / 10);
		if (rd.officerDown) score = min(score, 25);
		rep.grade = score >= 80 ? "A" : (score >= 65 ? "B" : (score >= 50 ? "C" : (score >= 35 ? "D" : "F")));

		if (fireStrike) rep.notes.Push("Fire in a crowd: a strike from Internal Affairs.");
		rep.window = rd.raidWindow;
		rep.eventKind = rd.raidEvent;

		rd.raidActive = false;
		rd.EndDay(gi, rd.raidDistrict);
		if (rd.missedUrgent) rep.notes.Push(String.Format("The unit pinned down in %s waited all day: a strike from Internal Affairs.", TurfTitle(rd.evDistrictWas)));
		switch (rd.caseResult)
		{
		case NBC_CASE_WON: rep.dayLine = "CASE CLOSED. Every gang in the Bricks is down."; break;
		case NBC_CASE_STRUCK_OUT: rep.dayLine = "Three strikes. Internal Affairs takes your badge. The case is over."; break;
		case NBC_CASE_DEMOLITION: rep.dayLine = "Day 30. The demolition crews roll in. The case is over."; break;
		default: rep.dayLine = rd.officerDown ? String.Format("Strike %d of %d. Day %d of %d begins.", rd.strikes,
			NBC_RunData.MAX_STRIKES, rd.day, NBC_RunData.MAX_DAYS) : String.Format("Day %d of %d begins.", rd.day, NBC_RunData.MAX_DAYS); break;
		}
		dept.PostReport(rep);
	}

	// ------------------------------------------------------------ the terminal's netevents, and debug commands

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "nbc_debug_case") { DebugCase(); return; }
		if (e.Name ~== "nbc_debug_clear") { DebugClear(e.Args[0]); return; }
		if (e.Name ~== "nbc_debug_cash") { let rd = NBC_RunData.Get(); rd.cash += e.Args[0]; return; }   // testing
		if (e.Name ~== "nbc_debug_motorcade")   // testing: stand back from the parked motorcade, looking at it
		{
			let p = players[consoleplayer].mo;
			if (!p || parkedAt == (0, 0, 0)) return;
			Vector2 at = parkedAt.xy + Actor.AngleToVector(p.angle + 180, 220);
			p.SetOrigin((at, p.GetZAt(at.x, at.y, 0, GZF_ABSOLUTEPOS)), false);
			p.angle = p.AngleTo(Actor.Spawn("MapSpot", parkedAt));
			return;
		}
		if (e.Name ~== "nbc_debug_event")       // testing: netevent nbc_debug_event <kind 0-5> <district> <hour 0-3>
		{
			let rd = NBC_RunData.Get();
			rd.evKind = clamp(e.Args[0], 0, NBC_Clock.EV_COUNT - 1);
			rd.evDistrict = rd.evKind ? clamp(e.Args[1], 0, districtMaps.Size() - 1) : -1;
			rd.evWindow = clamp(e.Args[2], 0, NBC_Clock.W_COUNT - 1);
			return;
		}
		if (e.Name.Left(9) ~== "nbc_dept.")
		{
			// "nbc_dept.<op>" a b c (SendNetworkEvent carries three numbers; the op rides in the name)
			NBC_Department.Get().Apply(e.Name.Mid(9).ToInt(), e.Args[0], e.Args[1], e.Args[2], NBC_RunData.Get());
			return;
		}
		if (e.Name ~== "nbc_deploy") { Deploy(e.Args[0], e.Args[1]); return; }
		if (e.Name ~== "nbc_terminal") { menuKind = MK_TERMINAL; menuTab = e.Args[0]; menuOfficer = 0; menuRequests++; return; }   // netevent nbc_terminal <tab 0-4>
		if (e.Name ~== "nbc_ready") { Ready(e.Args[0]); return; }
		if (!(e.Name ~== "nbc_board")) return;
		let rd = NBC_RunData.Get();
		let dept = NBC_Department.Get();
		int choice = e.Args[0];
		if (choice == -1)
		{
			rd.NewCase(NewSeed(), gangs.Size(), districtMaps.Size());
			dept.NewCase();
			Announce(String.Format("New case opened (seed %d). %d gangs, %d districts, %d days.",
				rd.seed, gangs.Size(), districtMaps.Size(), NBC_RunData.MAX_DAYS), 35 * 5);
			return;
		}
		if (choice == -2 && rd.caseActive && !rd.raidActive)
		{
			rd.EndDay(-1);
			dept.NewDay();
			String missed = rd.missedUrgent ? String.Format("\nYou left the unit pinned down in %s. Internal Affairs: strike %d of %d.",
				TurfTitle(rd.evDistrictWas), rd.strikes, NBC_RunData.MAX_STRIKES) : "";
			Announce((rd.caseActive ? String.Format("You close the day. The squad rests. Day %d.", rd.day) : "The case is over.") .. missed, 35 * 6);
		}
	}

	// READY on the deploy screen: the raid's planned; the pilot starts it (NBC_Pilot -> NBC_WheelsUp -> Deploy)
	void Ready(int d)
	{
		let rd = NBC_RunData.Get();
		if (!rd.caseActive || rd.raidActive || !IsHub() || d < 0 || d >= districtMaps.Size()) return;
		if (!DistrictGang(rd, d) || DistrictTaken(rd, d)) return;
		rd.readyDistrict = d;
		Announce(String.Format("%s: the plan's set. Talk to Rook at the chopper when you're ready to go.", TurfTitle(d)), 35 * 6);
	}

	// WHEELS UP at the pilot (or netevent nbc_deploy <district> for testing): the squad as picked goes in with you
	// force (testing, netevent nbc_deploy <district> <force>): 1 = no shoot-down, 2 = shot down
	void Deploy(int d, int force = 0)
	{
		let rd = NBC_RunData.Get();
		let dept = NBC_Department.Get();
		if (!rd.caseActive || rd.raidActive || !IsHub() || d < 0 || d >= districtMaps.Size()) return;
		let g = DistrictGang(rd, d);
		if (!g || DistrictTaken(rd, d)) return;
		if (!LevelInfo.MapExists(districtMaps[d]))
		{
			Console.Printf("\cgnbc: district map %s is missing (tools/Obsidian/make_bricks).", districtMaps[d]);
			return;
		}
		// the motorcade: the vehicles have to seat everyone
		dept.PruneSquad();
		int ins = dept.insertion;
		if (ins == NBC_Motor.INS_ROOFTOP && !dept.RollingHeli()) ins = NBC_Motor.INS_STREET;
		if (dept.Seats(ins) < dept.SeatsNeeded())
		{
			Announce(String.Format("Not enough seats: %d going in, %d in the motorcade.", dept.SeatsNeeded(), dept.Seats(ins)), 35 * 4);
			return;
		}
		rd.readyDistrict = -1;
		rd.BeginRaid(d);
		rd.raidMap = districtMaps[d];
		for (int i = 0; i < dept.garage.Size(); i++)
			if (dept.garage[i].rolling && dept.Fits(dept.garage[i], ins)) rd.raidVehicles.Push(dept.garage[i].id);
		if (ins == NBC_Motor.INS_ROOFTOP)
		{
			// the way in over the roofs: the gang's guns might get the bird first
			int gi = rd.districtGang[d];
			int alert = gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
			int risk = NBC_Motor.ShootDownRisk(g.tier, alert, dept.RollingHeli().cond);
			bool down = force == 2 || (force != 1 && rd.Rand(0, 99) < risk);
			if (down) rd.raidMode = NBC_Motor.MODE_CRASH;
			else
			{
				rd.raidMode = NBC_Motor.MODE_ROOF;
				String roof = d < roofMaps.Size() ? roofMaps[d] : "";
				if (roof != "" && LevelInfo.MapExists(roof)) rd.raidMap = roof;
			}
		}
		for (int s = 0; s < dept.squad.Size(); s++)
		{
			rd.raidOff.Push(dept.squad[s]);
			rd.raidOffKills.Push(0);
			let o = dept.OfficerById(dept.squad[s]);
			rd.raidOffHealth.Push(o ? o.health : 0);
			rd.raidOffTeam.Push(o ? o.team : 0);
		}
		level.ChangeLevel(rd.raidMap, 0, CHANGELEVEL_NOINTERMISSION);
	}

	// testing: down the leader and the first N of the crew (all of them for 0), the kills shared between you and
	// the squad, as if they'd been shot
	void DebugClear(int n)
	{
		let rd = NBC_RunData.Find();
		if (!IsRaidMap(rd) || !raidSetUp) return;
		Array<Actor> who;
		who.Push(players[consoleplayer].mo);
		for (int i = 0; i < squad.Size(); i++) if (squad[i] && squad[i].health > 0) who.Push(squad[i]);
		Array<Actor> victims;
		if (leader && leader.health > 0) victims.Push(leader);
		for (int i = 0; i < crew.Size() && (n <= 0 || victims.Size() < n + 1); i++) if (crew[i] && crew[i].health > 0) victims.Push(crew[i]);
		for (int i = 0; i < victims.Size(); i++)
		{
			Actor src = who[i % who.Size()];
			victims[i].DamageMobj(src, src, victims[i].health + 1000, 'NBC_Light', DMG_FORCED | DMG_THRUSTLESS);
		}
		Console.Printf("nbc: downed %d (leader %s)", victims.Size(), rd.leaderDown ? "down" : "standing");
	}

	void DebugCase()
	{
		let rd = NBC_RunData.Find();
		if (!rd) { Console.Printf("nbc: no case data"); return; }
		Console.Printf("nbc case: active %d result %d seed %d rng steps %d day %d strikes %d cash %d",
			rd.caseActive, rd.caseResult, rd.seed, rd.rngSteps, rd.day, rd.strikes, rd.cash);
		Console.Printf("  today: event %d in district %d at %s; planned hour %s", rd.evKind, rd.evDistrict, NBC_Clock.WindowLine(rd.evWindow), NBC_Clock.WindowLine(rd.planWindow));
		if (IsRaidMap(rd))
		{
			int alive = 0, off = 0;
			for (int i = 0; i < crew.Size(); i++) if (crew[i] && crew[i].health > 0) { alive++; if (crew[i].FindInventory("NBC_OffGuard")) off++; }
			Console.Printf("  raid: %s, event %d, %d of the crew standing, %d off guard, block awake %d", NBC_Clock.WindowLine(rd.raidWindow), rd.raidEvent, alive, off, blockAwake);
		}
		for (int d = 0; d < districtMaps.Size(); d++)
		{
			int gi = d < rd.districtGang.Size() ? rd.districtGang[d] : -1;
			let g = GangAt(gi);
			Console.Printf("  %s  %s (%s)  %s  alert %d%s", districtMaps[d], districtTitles[d], TurfEnv(d), g ? g.name : "-",
				gi >= 0 && gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0, DistrictTaken(rd, d) ? "  TOPPLED" : "");
		}
		let dept = NBC_Department.Find();
		if (dept)
		{
			Console.Printf("  roster %d, fallen %d, squad %d", dept.roster.Size(), dept.fallen.Size(), dept.squad.Size());
			for (int i = 0; i < dept.roster.Size(); i++)
			{
				let o = dept.roster[i];
				Console.Printf("    #%d %s, %s %s, hp %d/%d xp %d kills %d raids %d%s%s", o.id, o.RankedName(), o.RankName(), o.ClassName(),
					o.health, o.MaxHealth(), o.xp, o.kills, o.raids, o.state == NBC_Officer.ST_HOSPITAL ? String.Format(" hospital %d", o.hospital) : "",
					dept.InSquad(o.id) ? " SQUAD" : "");
			}
			String lk = "  locker:";
			for (int i = 0; i < NBC_Cat.IT_COUNT; i++) if (dept.locker[i]) lk = lk .. String.Format(" %s %d,", NBC_Cat.ItemName(i), dept.locker[i]);
			Console.Printf("%s", lk);
		}
		if (rd.raidActive && rd.teamOrder.Size() == NBC_Orders.TEAMS)
		{
			for (int t = 0; t < NBC_Orders.TEAMS; t++)
				Console.Printf("  team %s: %s, %s, %d waypoints%s", NBC_Orders.TEAM_NAME[t], NBC_Orders.ORDER_NAME[rd.teamOrder[t]],
					NBC_Orders.ROE_NAME[rd.teamROE[t]], NBC_Orders.WaypointCount(rd, t), rd.cmdTeam == 0 || rd.cmdTeam - 1 == t ? " (selected)" : "");
			for (int i = 0; i < squad.Size(); i++)
			{
				let a = NBC_Ally(squad[i]);
				if (a) Console.Printf("    slot %d %s team %s at (%d, %d) hp %d step %d%s", a.slot, a.GetTag(), NBC_Orders.TEAM_NAME[rd.TeamOfSlot(a.slot)],
					int(a.pos.x), int(a.pos.y), a.health, a.wpStep, a.waitingGo ? " WAITING" : "");
			}
		}
		if (rd.raidActive)
			Console.Printf("  raid: turf %d gang %d on %s, crew %d/%d kills %d (you %d) leader %s", rd.raidDistrict,
				rd.raidGang, rd.raidMap, crew.Size(), startCount, rd.raidKills, rd.raidPlayerKills, rd.leaderDown ? "down" : "at large");
	}

	// ------------------------------------------------------------ the UI side: menus and the roster CVars

	override void UiTick()
	{
		let dept = NBC_Department.Find();
		if (dept && dept.rosterVersion != rosterSaved)
		{
			// the officers who survive outlast the save (AGENTS.md: permanent progress in CVars)
			rosterSaved = dept.rosterVersion;
			CVar.FindCVar("nbc_roster").SetString(dept.SaveRoster());
			CVar.FindCVar("nbc_memorial").SetString(dept.SaveMemorial());
			CVar.FindCVar("nbc_avatar").SetInt(dept.playerFace);
		}
		if (gamestate != GS_LEVEL || menuactive != Menu.Off) return;
		if (dept && dept.reportPending && dept.reportSerial != reportSeen && IsHub())
		{
			reportSeen = dept.reportSerial;
			Menu.SetMenu("NBC_ResultsMenu");
			return;
		}
		if (menuRequests != menuSeen)
		{
			menuSeen = menuRequests;
			if (menuKind == MK_WHEELSUP) Menu.SetMenu("NBC_WheelsUp");
			else NBC_Terminal.Open(menuTab, menuOfficer);
		}
	}

	// ------------------------------------------------------------ overlay: announcements, officer down

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

		// at the HQ: a raid waiting on the pilot
		if (rd && rd.readyDistrict >= 0 && IsHub())
		{
			String r = String.Format("RAID READY: %s.  Talk to Rook (the pilot) to go.", TurfTitle(rd.readyDistrict));
			Screen.DrawText(NewSmallFont, Font.CR_GOLD, (vw - NewSmallFont.StringWidth(r)) / 2, 24, r,
				DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);
		}

		// someone talking: name, line, a portrait if they have one, and what Use does next
		if (speakTics > 0 && speakText != "")
		{
			double alpha = min(1.0, speakTics / 20.0);
			int bw = 620, bx = (vw - bw) / 2, by = 404, bh = 84;
			double k = Screen.GetHeight() / double(vh);
			double ox = (Screen.GetWidth() - vw * k) / 2;
			Screen.Dim(0x05080C, 0.78 * alpha, int(ox + bx * k), int(by * k), int(bw * k), int(bh * k));
			Screen.Dim(0xF2A93B, 0.9 * alpha, int(ox + bx * k), int(by * k), int(bw * k), max(1, int(2 * k)));
			int tx = bx + 12;
			if (speakFace != "")
			{
				TextureID t = TexMan.CheckForTexture(speakFace, TexMan.Type_Any);
				if (t.IsValid())
					Screen.DrawTexture(t, false, bx + 10, by + 10, DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true,
						DTA_DestWidth, 64, DTA_DestHeight, 64, DTA_Alpha, alpha);
				tx = bx + 84;
			}
			Screen.DrawText(NewSmallFont, Font.CR_GOLD, tx, by + 10, speakName, DTA_VirtualWidth, vw, DTA_VirtualHeight, vh,
				DTA_KeepRatio, true, DTA_Alpha, alpha);
			// the line, wrapped to the box
			BrokenLines bl = NewSmallFont.BreakLines(speakText, bx + bw - 12 - tx);
			for (int i = 0; i < bl.Count() && i < 3; i++)
				Screen.DrawText(NewSmallFont, Font.CR_WHITE, tx, by + 28 + i * 14, bl.StringAt(i), DTA_VirtualWidth, vw, DTA_VirtualHeight, vh,
					DTA_KeepRatio, true, DTA_Alpha, alpha);
			if (speakHint != "")
				Screen.DrawText(NewSmallFont, Font.CR_DARKGRAY, bx + bw - 12 - NewSmallFont.StringWidth(speakHint), by + bh - 16, speakHint,
					DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true, DTA_Alpha, alpha);
		}
	}
}
