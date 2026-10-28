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

	// raid bookkeeping (this map only)
	bool raidSetUp, reinforced, exitFound;
	int startCount, officerDownTics, cashAtStart;
	Vector3 exitPos;
	Actor leader;
	Array<Actor> crew, squad;
	Array<NBC_Spot> spareSpots;

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
		if (e.IsSaveGame) return;

		let rd = NBC_RunData.Get();
		let dept = NBC_Department.Get();
		if (IsHub())
		{
			// the kit lives in the Evidence Locker between raids (it was checked in when the raid map unloaded)
			let p = players[consoleplayer].mo;
			if (p) StripKit(p);
			if (!dept.reportPending)
				Announce(rd.caseActive ? "CHECKPOINT 9. Plan the next raid at the raid board, or ask the captain." :
					"CHECKPOINT 9. Talk to the captain, or open a case at the raid board.", 35 * 6);
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
	// roughly how many are on the block (the raid's own count, before the dice)
	clearscope int CrewEstimate(NBC_RunData rd, int d) const
	{
		let g = DistrictGang(rd, d);
		if (!g) return 0;
		int gi = rd.districtGang[d];
		int alert = gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
		static const int baseCount[] = { 22, 18, 16 };
		return int(baseCount[clamp(g.tier, 1, 3) - 1] * g.budget * (1.0 + 0.15 * alert)) + 1 + g.escorts;
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

		// 6. your kit, then the squad in behind you
		IssueKit(p, dept, rd);
		for (int s = 0; s < rd.raidOff.Size(); s++)
		{
			let o = dept.OfficerById(rd.raidOff[s]);
			if (!o) continue;
			let a = NBC_Ally(Actor.Spawn("NBC_Ally", p.pos, NO_REPLACE));
			if (!a) continue;
			a.Equip(o, s);
			a.CatchUp(p);
			squad.Push(a);
		}

		if (developer) Console.Printf("nbc raid: %s (%s), %s. %d spawn spots; the game placed %d crew + %s, %d officers. Exit %s.",
			level.MapName, kit ? kit.VariantName() : TurfEnv(rd.raidDistrict), g.name, spots.Size(), startCount,
			leader ? "leader" : "no leader", squad.Size(), exitFound ? "found" : "not found (far spot)");
		String title = TurfTitle(rd.raidDistrict);
		if (kit) title = String.Format("%s, %s", title, kit.VariantName());
		Announce(String.Format("%s. %s hold this block (%d on the ground).\nTake down %s, then get to the exit.",
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
				level.ChangeLevel(HUB_MAP, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
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
			rd.raidBounty = 300 * (g ? g.tier : 1);
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
		else
		{
			rep.outcome = NBC_Report.OUT_RETREAT;
			rep.title = "RETREAT";
			if (gi >= 0 && gi < rd.gangAlert.Size()) rd.gangAlert[gi] = min(3, rd.gangAlert[gi] + 1);
		}
		rep.cashRaid = rd.cash - cashAtStart - rep.bounty;
		rep.balance = rd.cash;

		// 4. the grade: the block, the body count, the cost
		int score = (taken ? 40 : 0) + (rep.crewTotal > 0 ? 35 * min(rep.kills, rep.crewTotal) / rep.crewTotal : 0)
			+ (lost + critical == 0 && rd.raidOff.Size() > 0 ? 10 : 0) + 15
			- lost * 15 - critical * 5 - min(20, rep.healthLost / 10);
		if (rd.officerDown) score = min(score, 25);
		rep.grade = score >= 80 ? "A" : (score >= 65 ? "B" : (score >= 50 ? "C" : (score >= 35 ? "D" : "F")));

		rd.raidActive = false;
		rd.EndDay(gi);
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
		if (e.Name.Left(9) ~== "nbc_dept.")
		{
			// "nbc_dept.<op>" a b c (SendNetworkEvent carries three numbers; the op rides in the name)
			NBC_Department.Get().Apply(e.Name.Mid(9).ToInt(), e.Args[0], e.Args[1], e.Args[2], NBC_RunData.Get());
			return;
		}
		if (e.Name ~== "nbc_deploy") { Deploy(e.Args[0]); return; }
		if (e.Name ~== "nbc_terminal") { menuKind = MK_TERMINAL; menuTab = e.Args[0]; menuOfficer = 0; menuRequests++; return; }   // netevent nbc_terminal <tab 0-3>
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
			Announce(rd.caseActive ? String.Format("You close the day. The squad rests. Day %d.", rd.day) : "The case is over.", 35 * 4);
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
	void Deploy(int d)
	{
		let rd = NBC_RunData.Get();
		let dept = NBC_Department.Get();
		if (!rd.caseActive || rd.raidActive || !IsHub() || d < 0 || d >= districtMaps.Size()) return;
		if (!DistrictGang(rd, d) || DistrictTaken(rd, d)) return;
		if (!LevelInfo.MapExists(districtMaps[d]))
		{
			Console.Printf("\cgnbc: district map %s is missing (tools/Obsidian/make_bricks).", districtMaps[d]);
			return;
		}
		rd.readyDistrict = -1;
		rd.BeginRaid(d);
		rd.raidMap = districtMaps[d];
		dept.PruneSquad();
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
