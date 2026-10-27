// =============================================================================
// Corpo Wars — noise system + stealth HUD
// =============================================================================
class CW_Handler : EventHandler
{
	int worstAwareness;
	double worstSuspicion;
	int stepTimer[MAXPLAYERS];
	int fireTimer[MAXPLAYERS];
	int prevWorst;
	String prompt;          // "[USE] ..." hint for the console player
	bool nearExtraction;
	double abortProgress;         // holding USE at an exit (0..1)
	bool wayOn; Vector2 wayPos; String wayLabel;   // extraction waypoint (primary objective done)
	int lastDoorWarp;           // maptime of the last stairwell fire-door teleport
	bool inHub;
	int terminalRequests, gearRequests, kitRequests;
	int mapRequests, mapFocus, mapFocusReq;      // HUD city map: open requests, and a debug "focus this lot" code (district * 100000 + lot id + 1)
	ui int mapSeen, focusUsed;
	int hackRequests, hackDoor, hackNodes;
	ui int hackSeen;
	// flashlight beam per player (from "Flashlight" by Alando1 et al.; see CREDITS.txt)
	SpotLight beam[MAXPLAYERS];
	ui int gearSeen, kitSeen;
	// radar snapshot (play writes, ui reads)
	Array<double> radarX, radarY;
	Array<int> radarKind;       // 0 guard unaware, 1 suspicious, 2 alert, 10+k objective k, 20 extraction
	bool radarOn;
	// blackout
	int blackoutTics;
	Array<int> savedLight;
	ui int terminalSeen;
	ui Array<String> rowText;
	ui Array<int> rowCol;

	override void WorldLoaded(WorldEvent e)
	{
		inHub = (level.MapName ~== "HUB01");
		if (inHub)
		{
			let vk0 = CW_CityLink.Get();
			if (vk0) { vk0.visit = false; vk0.siteBld = ""; vk0.siteTok = 0; }       // back from a city-map visit
			// older saves can be stuck below the cheapest contract: the board advances the difference
			let l0 = CW_Ledger.Of(players[consoleplayer].mo);
			if (l0 && !l0.missionActive)
			{
				// a new campaign (or a pre-city save): the city starts on day 1
				l0.EnsureCity();
				l0.completedMask = 0;
				l0.FixSelection();
				int adv = l0.EnsureSolvent();
				if (adv) Console.Printf("\ckMeridian advanced %s to keep the desk running (repaid from future payouts).", Money(adv));
			}
		}
		// multi-floor building: coming back to a floor you already visited (hub) keeps it as you left it
		if (e.IsReopen && floorGen)
		{
			floorArrivePending = true;
			return;
		}
		if (e.IsReopen && garageGen)
		{
			garageArrivePending = true;
			return;
		}
		// site-pack building (sitepool.zs): a floor visited before comes back as it was left (hub cluster snapshot)
		if (e.IsReopen && CW_SitePool.IsSiteMap(level.MapName))
		{
			if (!navGraph) { navGraph = new("CW_NavGraph"); SiteNav(); }
			return;
		}
		navGraph = new("CW_NavGraph");
		if (level.MapName ~== "G01")
		{
			// procedural site: carve it, then build the nav graph once the walls have finished opening
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			int seed = (l && l.missionActive && l.missionSeed) ? l.missionSeed : CVar.FindCVar("cw_procseed").GetInt();
			if (seed == 0) seed = Random(1, 0x7ffffff);
			procGen = new("CW_ProcGen");
			procGen.Generate(seed);
			navBuildAt = 12;
		}
		else if (level.MapName ~== "G05")
		{
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			int seed = (l && l.missionActive && l.missionSeed) ? l.missionSeed : CVar.FindCVar("cw_procseed").GetInt();
			if (seed == 0) seed = Random(1, 0x7ffffff);
			CW_Contract c = (l && l.missionActive) ? l.job : null;
			int floors = CW_Building.Floors(l);
			garageGen = new("CW_GarageGen");
			bool insertion = l && l.missionActive && l.garageRun && !l.PrimaryDone();
			garageGen.Generate(seed, insertion, l, c ? c.risk : 2, CW_Building.FloorNum(seed, floors, 0));
			if (insertion) garageInsertPending = true; else garageArrivePending = true;
			navBuildAt = 12;
		}
		else if (CW_SitePool.IsSiteMap(level.MapName))
		{
			// a building of the After Hours site pack: mission markers from CWSITES, the mission on top (sitemission.zs)
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			CW_Contract c = (l && l.missionActive) ? l.job : null;
			let clk = CW_CityLink.Get();
			siteMis = new("CW_SiteMission");
			if (siteMis.Init(l, c))
			{
				// the first floor of a visit is an insertion; a floor reached by the stairs is not
				String bn = CW_SitePool.BldOf(level.MapName);
				int tok = c ? l.visitSeed : 0;
				bool fresh = !(clk && clk.siteBld == bn && clk.siteTok == tok);
				if (clk) { clk.siteBld = bn; clk.siteTok = tok; }
				siteMis.Generate(l, fresh);
				siteInsertPending = fresh;
				if (fresh && clk && clk.visit && !c) VisitNote(clk, siteMis.bld.seed, siteMis.bld.variant);
			}
			SiteNav();
		}
		else if (CW_ObsSite.IsPoolMap(level.MapName))
		{
			// a site Obsidian built (the map pool): read its markers and run the mission on it
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			int seed = (l && l.missionActive && l.missionSeed) ? l.missionSeed : CVar.FindCVar("cw_procseed").GetInt();
			if (seed == 0) seed = Random(1, 0x7ffffff);
			CW_Contract c = (l && l.missionActive) ? l.job : null;
			obsSite = new("CW_ObsSite");
			if (c) obsSite.SetupSite(c.secForce, c.secTech, c.neutral, l.visitSeed, c.prepIntel ? l.entryPref : 0);
			int v = c ? c.kitVariant : CVar.FindCVar("cw_kitvariant").GetInt();
			if (v < 0) v = CW_Building.Mix(seed, 17) % obsSite.VariantCount();
			obsSite.Generate(seed, v);
			obsInsertPending = true;
			navBuildAt = 12;
		}
		else if (CW_KitGen.KitOfMap(level.MapName))
		{
			// a site kit (street block, residential floor, industrial lot, underground, civic hall, tech interior)
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			int seed = (l && l.missionActive && l.missionSeed) ? l.missionSeed : CVar.FindCVar("cw_procseed").GetInt();
			// a building entered from the city district (C01) brings its own fixed seed
			let clk = CW_CityLink.Get();
			int cityVar = -2;
			if (clk && clk.kitSeed && !(l && l.missionActive)) { seed = clk.kitSeed; cityVar = clk.kitVar; clk.kitSeed = 0; }
			if (seed == 0) seed = Random(1, 0x7ffffff);
			CW_Contract c = (l && l.missionActive) ? l.job : null;
			kitGen = CW_KitGen.Make(CW_KitGen.KitOfMap(level.MapName));
			if (kitGen)
			{
				if (c) kitGen.SetupSite(c.secForce, c.secTech, c.neutral, l.visitSeed, c.prepIntel ? l.entryPref : 0);
				int v = c ? c.kitVariant : (cityVar > -2 ? cityVar : CVar.FindCVar("cw_kitvariant").GetInt());
				if (v < 0) v = CW_Building.Mix(seed, 17) % kitGen.VariantCount();
				kitGen.Generate(seed, v);
				kitInsertPending = true;
				if (clk && clk.visit && !(l && l.missionActive)) VisitNote(clk, seed, v);
			}
			navBuildAt = 12;
		}
		else if (CW_Building.IsFloorMap(level.MapName))
		{
			// procedural office floor: random floor role, random insertion among its entry points.
			// G03 / G04 are the other floors of a multi-floor building, reached by the stairs.
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			int floors = CW_Building.Floors(l);
			int seed = (l && l.missionActive && l.missionSeed) ? l.missionSeed : CVar.FindCVar("cw_procseed").GetInt();
			// a building entered from the HUD city map brings its own fixed seed, role and interior theme
			let vlk = CW_CityLink.Get();
			int role = CVar.FindCVar("cw_floorrole").GetInt();
			int visitTh = -2;
			bool visiting = false;
			if (vlk && vlk.g02Seed && !(l && l.missionActive))
			{
				seed = vlk.g02Seed; role = vlk.g02Role; visitTh = vlk.g02Theme; vlk.g02Seed = 0;
				floors = 1; visiting = true;
			}
			if (seed == 0) seed = floors > 1 ? 1 + level.totaltime / 1000000 : Random(1, 0x7ffffff);   // test runs without a seed: every floor of the building must agree (set cw_procseed to vary it)
			CW_Contract c = null;
			if (l && l.missionActive) c = l.job;
			floorGen = new("CW_FloorGen");
			floorGen.SetupBuilding(seed, floors, CW_Building.MapIndex(level.MapName), c);
			// the city sets the site: security, neutral-site rules, and this visit's entry
			if (c) floorGen.SetupSite(c.secForce, c.secTech, c.neutral, l.visitSeed, c.prepIntel ? l.entryPref : 0);
			int th = CVar.FindCVar("cw_theme").GetInt();
			if (th < 0 && c) th = c.theme;
			if (th < 0 && floors > 1) th = CW_Building.Mix(seed, 5) % CW_Themes.COUNT;   // one tenant: every floor matches
			if (visitTh > -2) th = visitTh;
			floorGen.Generate(seed, role, th);
			if (visiting) VisitNote(vlk, seed, th);
			if (floorGen.mapIdx == 0 && !(l && l.missionActive && l.garageRun)) floorInsertPending = true;
			else floorArrivePending = true;
			navBuildAt = 12;
		}
		else navGraph.Build();
	}

	// ---- HUD city map: visit a building (no mission). Seeds travel in CW_CityLink; the kit / G02 branch of WorldLoaded takes them.
	void GoToLot(CW_Ledger l, int d, int id)
	{
		if (!l || l.missionActive) { Console.MidPrint(NewSmallFont, "\cgFinish or abort the running mission first."); return; }
		let mp = CW_CityMap.Build();
		let lot = mp.FindLot(d, id);
		let lk = CW_CityLink.Get();
		if (!lot || !lot.enter || !lk) { Console.Printf("CW_MAP GO: no enterable lot %d/%d", d + 1, id); return; }
		lk.visit = true; lk.visitName = lot.name; lk.visitDist = d; lk.visitLot = id;
		lk.kitSeed = 0; lk.g02Seed = 0; lk.siteBld = ""; lk.siteTok = 0;
		String dest = lot.map;
		if (CW_SitePool.IsSiteMap(lot.map)) dest = CW_SitePool.LaunchMap(lot.map, 0, 2);      // site pack: walk in by the front
		else if (lot.kit > 0) { lk.kitSeed = lot.seed; lk.kitVar = lot.kvar; }
		else { lk.g02Seed = lot.seed; lk.g02Role = 0; lk.g02Theme = lot.theme; }
		l.job = null;   // CW_Building.Floors reads a lingering job
		Console.Printf("CW_MAP GO %s: D%d #%d (%s) map %s variant %d seed %d", lot.name, d + 1, id, lot.typeName, dest, lot.kvar, lot.seed);
		level.ChangeLevel(dest, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}

	void VisitNote(CW_CityLink lk, int seed, int variant)
	{
		Console.Printf("CW_VISIT %s: %s seed %d %s %d (D%d #%d)", lk.visitName, level.MapName, seed, level.MapName ~== "G02" ? "theme" : "variant", variant, lk.visitDist + 1, lk.visitLot);
		visitStart = gametic;
		Console.MidPrint(NewSmallFont, String.Format("Visiting %s\nM: city map   |   R in the map: return to office   |   HOME key", lk.visitName));
	}

	int navBuildAt;
	int visitStart;        // gametic the current city-map visit began (for the on-screen note)
	CW_ProcGen procGen;
	CW_FloorGen floorGen;
	bool floorInsertPending, floorArrivePending;
	CW_GarageGen garageGen;
	bool garageInsertPending, garageArrivePending;
	CW_KitGen kitGen;
	bool kitInsertPending;
	CW_ObsSite obsSite;
	bool obsInsertPending;
	CW_SiteMission siteMis;       // After Hours site pack map (sitemission.zs)
	bool siteInsertPending;
	// big generated maps: no off-map limit, link only nearby nodes (nav.zs)
	void SiteNav()
	{
		navGraph.offmapX = 1e9;
		navGraph.linkRange = 520;
		navBuildAt = 12;
	}

	CW_NavGraph navGraph;
	static CW_NavGraph Nav()
	{
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		return h ? h.navGraph : null;
	}

	override void PlayerEntered(PlayerEvent e)
	{
		let pm = players[e.PlayerNumber].mo;
		if (!pm) return;
		if (!pm.FindInventory("CW_Ledger")) pm.GiveInventory("CW_Ledger", 1);
		let l = CW_Ledger.Of(pm);
		if (l) l.InvInit();

		// The player class starts with Doom's stock pistol: swap it for our service pistol.
		let stock = pm.FindInventory("Pistol");
		if (stock)
		{
			pm.TakeInventory("Pistol", 1);
			pm.GiveInventory("CW_ServicePistol", 1);
			pm.GiveInventory("CW_PistolMag", CW_ServicePistol.MAG);
			pm.player.PendingWeapon = Weapon(pm.FindInventory("CW_ServicePistol"));
		}
		if (l && l.missionActive && !inHub)
		{
			if (l.HasIntel(CW_Services.INTEL_SURVEY)) pm.GiveInventory("Allmap", 1);
			// issue the personal kit
			l.IssuePersonal(pm);
			for (int i = 0; i < CW_Services.CREW_COUNT; i++)
				if (l.HasCrew(i)) Console.Printf("\cf%s\c- (%s) on comms. %s", CW_Services.CrewName(i), CW_Services.CrewRole(i), CW_Services.CrewDesc(i));
		}
	}

	// ---------------------------------------------------------------- crew abilities
	void UseBlackout(CW_Ledger l)
	{
		if (l.hackerUses <= 0) { Console.Printf("\cgNyx: \"I'm burned, no more tricks this op.\""); return; }
		if (blackoutTics > 0) return;
		l.hackerUses--;
		savedLight.Clear();
		for (int i = 0; i < level.Sectors.Size(); i++)
		{
			savedLight.Push(level.Sectors[i].lightlevel);
			level.Sectors[i].SetLightLevel(min(level.Sectors[i].lightlevel, 24));
		}
		let it = ThinkerIterator.Create("CW_CeilingLight");
		CW_CeilingLight cl;
		while (cl = CW_CeilingLight(it.Next())) cl.SetStateLabel("Off");
		// every mains light goes; battery-backed ones (monitors, exit signs, emergency lamps) stay
		let li = ThinkerIterator.Create("CW_LightSource", Thinker.STAT_DLIGHT);
		CW_LightSource ls;
		while (ls = CW_LightSource(li.Next()))
			if (!ls.ups && !ls.bDormant) { ls.Deactivate(null); ls.cutByBlackout = true; }
		let si = ThinkerIterator.Create("CW_WallSconce");
		CW_WallSconce sc;
		while (sc = CW_WallSconce(si.Next())) if (!sc.emergency) sc.SetStateLabel("Off");
		// Voltaic Holdings' grid contacts (Friendly or better) buy Nyx ten more seconds
		bool grid = l.city && l.city.ServicePct("blackout") && CW_City.Tier(l.city.EffRep(l.city.ServiceCorp("blackout"))) >= 1;
		blackoutTics = 35 * (grid ? 30 : 20);
		S_StartSound("switches/exitbutn", CHAN_AUTO, CHANF_UI);
		Console.MidPrint(NewSmallFont, grid ? "\chNyx:\c- Power's down. Voltaic's people bought us thirty seconds." : "\chNyx:\c- Power's down. Twenty seconds.");
	}

	void EndBlackout()
	{
		for (int i = 0; i < savedLight.Size() && i < level.Sectors.Size(); i++)
			level.Sectors[i].SetLightLevel(savedLight[i]);
		savedLight.Clear();
		let it = ThinkerIterator.Create("CW_CeilingLight");
		CW_CeilingLight cl;
		while (cl = CW_CeilingLight(it.Next())) if (!cl.unlit) cl.SetStateLabel("Spawn");
		let li = ThinkerIterator.Create("CW_LightSource", Thinker.STAT_DLIGHT);
		CW_LightSource ls;
		while (ls = CW_LightSource(li.Next()))
			if (ls.cutByBlackout) { ls.Activate(null); ls.cutByBlackout = false; }
		let si = ThinkerIterator.Create("CW_WallSconce");
		CW_WallSconce sc;
		while (sc = CW_WallSconce(si.Next())) if (sc.lamp && !sc.emergency) sc.SetStateLabel("Spawn");
		Console.MidPrint(NewSmallFont, "\chNyx:\c- Backup power's on. Hope you're somewhere dark.");
	}

	void ThrowGadget(CW_Ledger l, Actor pm, int which)
	{
		if (which == 1)
		{
			if (!l.ConsumeOne(2, CW_Items.IT_NOISEMAKER)) { Console.MidPrint(NewSmallFont, "\cgNo noisemaker in your kit."); return; }
			let t = pm.SpawnPlayerMissile("CW_ThrownNoisemaker");
			if (t) t.Vel.Z += 4;
		}
		else if (which == 2)
		{
			if (!l.ConsumeOne(2, CW_Items.IT_FLASHBANG)) { Console.MidPrint(NewSmallFont, "\cgNo flashbang in your kit."); return; }
			let t = pm.SpawnPlayerMissile("CW_ThrownFlashbang");
			if (t) t.Vel.Z += 4;
		}
	}

	void UseLure(CW_Ledger l, Actor pm)
	{
		if (l.voxUses <= 0) { Console.Printf("\ciVox: \"Out of toys.\""); return; }
		FLineTraceData t;
		pm.LineTrace(pm.angle, 2048, pm.pitch, TRF_THRUACTORS, pm.player.viewz - pm.pos.z, data: t);
		Vector3 at = t.HitLocation;
		l.voxUses--;
		let snd = Actor.Spawn("CW_LureSound", at);
		EmitNoise(null, at, 700, 0.6);
	}

	// ---------------------------------------------------------------- suppressor helpers
	static clearscope bool CanSuppress(Weapon w) { return w && w.FindState("ToggleSuppressor") != null; }
	static clearscope bool IsSuppressed(Weapon w)
	{
		let a = CW_SMG(w); if (a) return a.cwSuppressed;
		let b = CW_ServicePistol(w); if (b) return b.cwSuppressed;
		return false;
	}
	static void SetSuppressed(Weapon w, bool on)
	{
		let a = CW_SMG(w); if (a) a.cwSuppressed = on;
		let b = CW_ServicePistol(w); if (b) b.cwSuppressed = on;
	}

	void ToggleSuppressor(CW_Ledger l, Actor pm)
	{
		let w = pm.player.ReadyWeapon;
		if (!CanSuppress(w)) { Console.MidPrint(NewSmallFont, "\cgThis weapon can't take a suppressor."); return; }
		if (!(pm.player.WeaponState & WF_WEAPONREADY)) return;   // busy firing/reloading
		if (!IsSuppressed(w))
		{
			int have = l.CountIn(2, CW_Items.IT_SUPPRESSOR);
			if (have <= 0) { Console.MidPrint(NewSmallFont, "\cgNo suppressor in your kit."); return; }
			// Suppressors all in use: take one off another weapon.
			int used = 0;
			for (Inventory it = pm.Inv; it; it = it.Inv) { let ow = Weapon(it); if (ow && ow != w && IsSuppressed(ow)) used++; }
			if (used >= have)
				for (Inventory it = pm.Inv; it; it = it.Inv) { let ow = Weapon(it); if (ow && ow != w && IsSuppressed(ow)) { SetSuppressed(ow, false); break; } }
		}
		pm.player.SetPsprite(PSP_WEAPON, w.FindState("ToggleSuppressor"));
	}

	// ---------------------------------------------------------------- flashlight
	clearscope bool FlashOn(int p) { return p >= 0 && p < MAXPLAYERS && beam[p] != null; }

	void ToggleFlashlight(CW_Ledger l, int p)
	{
		let pm = players[p].mo;
		if (beam[p]) { beam[p].Destroy(); beam[p] = null; pm.A_StartSound("cw/flash/off", CHAN_ITEM); return; }
		if (l.CountIn(2, CW_Items.IT_FLASHLIGHT) <= 0) { Console.MidPrint(NewSmallFont, "\cgNo flashlight in your kit."); return; }
		let b = SpotLight(Actor.Spawn("SpotLight", (pm.pos.xy, pm.player.viewz - 10)));
		if (!b) return;
		b.args[0] = 255; b.args[1] = 244; b.args[2] = 220; b.args[3] = 512;
		b.SpotInnerAngle = 8; b.SpotOuterAngle = 24;
		b.bATTENUATE = true;
		beam[p] = b;
		pm.A_StartSound("cw/flash/on", CHAN_ITEM);
	}

	void UpdateFlashlights()
	{
		for (int p = 0; p < MAXPLAYERS; p++)
		{
			if (!beam[p]) continue;
			let pm = playeringame[p] ? players[p].mo : null;
			let l = pm ? CW_Ledger.Of(pm) : null;
			if (!pm || pm.health <= 0 || !l || l.CountIn(2, CW_Items.IT_FLASHLIGHT) <= 0)
			{
				beam[p].Destroy(); beam[p] = null;
				continue;
			}
			beam[p].SetOrigin((pm.pos.xy, pm.player.viewz - 10), true);
			beam[p].A_SetAngle(pm.angle, SPF_INTERPOLATE);
			beam[p].A_SetPitch(pm.pitch, SPF_INTERPOLATE);
		}
	}

	override void UiTick()
	{
		if (terminalRequests != terminalSeen)
		{
			terminalSeen = terminalRequests;
			let m = new("CW_TerminalMenu");
			m.Init(Menu.GetCurrentMenu());
			m.ActivateMenu();
		}
		if (mapRequests != mapSeen)
		{
			mapSeen = mapRequests;
			if (!(Menu.GetCurrentMenu() is "CW_CityMapMenu"))
			{
				let m = new("CW_CityMapMenu");
				m.Init(Menu.GetCurrentMenu());
				m.ActivateMenu();
			}
		}
		if (hackRequests != hackSeen)
		{
			hackSeen = hackRequests;
			let m = new("CW_HackMenu");
			m.Init(Menu.GetCurrentMenu());
			m.Setup(hackDoor, hackNodes);
			m.ActivateMenu();
		}
		if (gearRequests != gearSeen)
		{
			gearSeen = gearRequests;
			let m = new("CW_GearMenu");
			m.inField = false;
			m.Init(Menu.GetCurrentMenu());
			m.ActivateMenu();
		}
		if (kitRequests != kitSeen)
		{
			kitSeen = kitRequests;
			let m = new("CW_GearMenu");
			m.inField = true;
			m.Init(Menu.GetCurrentMenu());
			m.ActivateMenu();
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || !playeringame[e.Player]) return;
		let l = CW_Ledger.Of(players[e.Player].mo);
		if (!l) return;
		if (e.Name == "cw_select") { if (e.Args[0] >= 0 && e.Args[0] < l.OfferCount()) l.selected = e.Args[0]; }
		else if (e.Name == "cw_closeday" && !l.missionActive) l.CloseDay();
		else if (e.Name == "cw_openterminal" && inHub) terminalRequests++;
		else if (e.Name == "cw_citymap") mapRequests++;                                     // HUD city map (key M)
		else if (e.Name == "cw_mapdump") CW_CityMap.Build().Dump(e.Args[0] != 0);                          // debug: per-district counts and sample lots
		else if (e.Name == "cw_mapfocus" && CVar.FindCVar("sv_cheats").GetBool()) { mapFocus = e.Args[0] * 100000 + e.Args[1] + 1; mapFocusReq++; mapRequests++; }   // debug: open the map on district (1-5) lot id
		else if (e.Name == "cw_mapgo") GoToLot(l, e.Args[0] - 1, e.Args[1]);                // GO THERE (district 1-5, lot id)
		else if (e.Name == "cw_testodd" && !l.missionActive && CVar.FindCVar("sv_cheats").GetBool())
		{
			// debug (sv_cheats): deploy the first odd job (arg 0) or strike (arg 1) on the board
			for (int i = 0; i < l.OfferCount(); i++) if (l.Offer(i).decisive == (e.Args[0] != 0) && l.Offer(i).role == (e.Args[0] ? R_CONTRACT : l.Offer(i).role) && !l.Offer(i).refused.Length()) { l.selected = i; l.BeginMission(); break; }
		}
		else if (e.Name == "cw_testkit" && !l.missionActive && l.city && CVar.FindCVar("sv_cheats").GetBool())
		{
			// debug (sv_cheats): deploy the first job on site kit K0<arg> (closing days until one turns up)
			String want = CW_KitGen.MapOfKit(e.Args[0]);
			for (int day = 0; day < 20; day++)
			{
				for (int i = 0; i < l.OfferCount(); i++)
				{
					let o = l.Offer(i);
					String pp = CW_ObsSite.PoolOfKit(e.Args[0]);
					bool onKit = o.map ~== want || (pp.Length() && CW_ObsSite.IsPoolMap(o.map) && o.map.Left(3) ~== pp)
						|| (CW_SitePool.IsSiteMap(o.map) && CW_SitePool.KitOfCode(CW_SitePool.CodeOfMap(o.map)) == e.Args[0]
							&& (e.Args[1] <= 0 || e.Args[0] != 7 || CW_SitePool.CodeOfMap(o.map) == CW_SitePool.OfficeCode(e.Args[1] - 1)));
					if (onKit && !o.refused.Length()) { Console.Printf("CW_TESTKIT %s v%d: %s", o.map, o.kitVariant, o.target); l.selected = i; l.BeginMission(); return; }
				}
				l.CloseDay();
			}
			Console.Printf("CW_TESTKIT no job on %s", want);
		}
		else if (e.Name == "cw_sitelist")
		{
			// debug: the pools the loaded site pack holds (index, code, variants, mission markers)
			int np = CW_SitePool.PoolTotal();
			for (int i = 0; i < np; i++)
			{
				String cd = CW_SitePool.CodeAt(i);
				Console.Printf("CW_SITES %d %s x%d markers %d  %s", i + 1, cd, CW_SitePool.PoolCount(cd), CW_SitePool.PoolMarked(cd), CW_SitePool.PoolTitle(cd));
			}
			Console.Printf("CW_SITES %d pools, cw_newsites %d", np, CW_SitePool.Enabled());
		}
		else if (e.Name == "cw_sitego" && CVar.FindCVar("sv_cheats").GetBool()) CW_SiteMission.GoSite(l, e.Args[0], e.Args[1], e.Args[2] != 0);   // debug: pool (1-based, cw_sitelist), variant, 1 = on a borrowed job
		else if (e.Name == "cw_objdump" && CVar.FindCVar("sv_cheats").GetBool())
		{
			// debug (sv_cheats): where the mission objectives of this floor stand
			static const String cn[] = { "CW_Prototype", "CW_Server", "CW_Scientist", "CW_Extraction" };
			for (int k = 0; k < 4; k++)
			{
				let it = ThinkerIterator.Create(cn[k]);
				Actor a;
				while (a = Actor(it.Next())) Console.Printf("OBJ %s %d %d %d", cn[k], int(a.pos.x), int(a.pos.y), int(a.pos.z));
			}
		}
		else if (e.Name == "cw_sitestairs" && CVar.FindCVar("sv_cheats").GetBool() && players[e.Player].mo)
		{
			// debug (sv_cheats): take the Nth stairs / lift of this floor (a Teleport_NewMap line) as if walked into
			int n = 0;
			for (int i = 0; i < level.lines.Size(); i++)
			{
				Line ln = level.lines[i];
				if (ln.special != 74) continue;
				if (n++ != e.Args[0]) continue;
				Console.Printf("CW_SITESTAIRS line %d -> levelnum %d spot %d", i, ln.args[0], ln.args[1]);
				level.ExecuteSpecial(74, players[e.Player].mo, ln, 0, ln.args[0], ln.args[1], ln.args[2]);
				return;
			}
			Console.Printf("CW_SITESTAIRS: this floor has %d stairs lines", n);
		}
		else if (e.Name == "cw_dbgkit") CW_DebugKits.Go(l, e.Args[0], e.Args[1] != 0);   // debug hub: kit tester (arg 0 row, arg 1 with a job)
		else if (e.Name == "cw_dbgreturn") CW_DebugKits.GoHome(l);                        // debug hub: back to HUB01
		else if (e.Name == "cw_guarddump" && CVar.FindCVar("sv_cheats").GetBool())
		{
			// debug: where every guard is and what it's doing
			let it = ThinkerIterator.Create("CW_Guard");
			CW_Guard g;
			while (g = CW_Guard(it.Next())) Console.Printf("GUARD %s %d %d hp %d", g.GetClassName(), int(g.pos.x), int(g.pos.y), g.health);
		}
		else if (e.Name == "cw_testrep" && l.city && CVar.FindCVar("sv_cheats").GetBool()) { l.city.AddRep(e.Args[0], e.Args[1]); l.city.BuildOffers(); }   // debug: netevent cw_testrep <faction> <delta>
		else if (e.Name == "cw_testfinish" && l.missionActive && l.job && CVar.FindCVar("sv_cheats").GetBool())
		{
			// debug (sv_cheats): finish the running job; arg 1 = primary done and extracted, 0 = aborted
			if (e.Args[0]) l.objDone |= l.job.primaryMask;
			l.FinishMission(e.Args[0] != 0);
		}   // console / debug: open the terminal anywhere in the office
		else if (e.Name == "cw_pledge" && !l.missionActive && l.city) l.city.Pledge(e.Args[0] != 0);
		else if (e.Name == "cw_entry") l.entryPref = clamp(e.Args[0], 0, 5);
		else if (e.Name == "cw_cityintel" && !l.missionActive && l.city) BuyCityIntel(l, e.Args[0]);
		else if (e.Name == "cw_simdays" && l.city) SimDays(l, max(1, e.Args[0]));
		else if (e.Name == "cw_citydump") { if (l.city) l.city.Dump(); Console.Printf("CW_SMOKE_DUMP"); }
		else if (e.Name == "cw_dismiss") { l.debriefNew = false; l.FixSelection(); }
		else if (e.Name == "cw_deploy") { l.selected = e.Args[0]; l.BeginMission(); }
		else if (e.Name == "cw_intel") l.ToggleIntel(e.Args[0]);
		else if (e.Name == "cw_crew") l.ToggleCrew(e.Args[0]);
		else if (e.Name == "cw_buy") l.BuyItem(e.Args[0]);
		else if (e.Name == "cw_flashlight" && players[e.Player].mo.health > 0) ToggleFlashlight(l, e.Player);
		else if (e.Name == "cw_suppressor" && players[e.Player].mo.health > 0) ToggleSuppressor(l, players[e.Player].mo);
		else if (e.Name == "cw_move") l.MoveItem(e.Args[0], e.Args[1], e.Args[2], players[e.Player].mo);
		else if (e.Name == "cw_medkit" && l.missionActive && players[e.Player].mo.health > 0)
		{
			let pm = players[e.Player].mo;
			if (pm.health >= pm.GetMaxHealth()) return;
			if (!l.ConsumeOne(2, CW_Items.IT_MEDKIT)) { Console.MidPrint(NewSmallFont, "\cgNo medkit in your kit."); return; }
			pm.GiveBody(40);
			pm.A_StartSound("misc/health_pkup", CHAN_ITEM);
		}
		else if (e.Name == "cw_hackdone" && floorGen)
		{
			for (int k = 0; k < floorGen.secDoors.Size(); k++)
			{
				let dr = floorGen.secDoors[k];
				if (dr && dr.doorIdx == e.Args[0]) dr.HackResult(e.Args[1], players[e.Player].mo);
			}
		}
		else if (e.Name == "cw_breach" && l.missionActive && players[e.Player].mo.health > 0) PlantBreach(l, players[e.Player].mo);
		else if (e.Name == "cw_gadget" && l.missionActive && players[e.Player].mo.health > 0)
			ThrowGadget(l, players[e.Player].mo, e.Args[0]);
		else if (e.Name == "cw_ability" && l.missionActive && players[e.Player].mo.health > 0)
		{
			if (e.Args[0] == 1) UseBlackout(l);
			else if (e.Args[0] == 2) UseLure(l, players[e.Player].mo);
		}
	}

	// ---------------------------------------------------------------- city actions
	void BuyCityIntel(CW_Ledger l, int c)
	{
		int cost = l.city.CorpIntelCost();
		if (cost <= 0 || l.budget < cost || !CW_City.IsCorp(c) || !l.city.corps[c].alive) { Console.Printf("\cgNobody will sell you that intel right now."); return; }
		l.budget -= cost;
		Array<String> lines;
		l.city.BuyCorpIntel(c, lines);
		Console.Printf("\cfIntel on %s bought for %s. The books are open for a week.", l.city.corps[c].short, Money(cost));
		for (int i = 0; i < lines.Size(); i++) Console.Printf("%s", lines[i]);
	}

	// Debug soak: close N days in a row with no player jobs and print where the city ends up.
	void SimDays(CW_Ledger l, int n)
	{
		let city = l.city;
		int sales = 0, seized = 0;
		int helper = CVar.FindCVar("cw_simplayer").GetInt() - 1;   // test: a broker who wins one strike a day for this corp
		for (int d = 0; d < n && !city.outcome; d++)
		{
			if (CW_City.IsCorp(helper))
			{
				for (int i = 0; i < city.ops.Size(); i++)
				{
					let op = city.ops[i];
					if (op.state || op.client != helper || op.goal == G_COUNTER) continue;
					op.playerSteps++;
					city.OpSucceeded(op, true);
					break;
				}
			}
			city.AdvanceDay();
			for (int i = 0; i < city.todayNews.Size(); i++)
			{
				String t = city.todayNews[i];
				if (t.IndexOf("SOLD") >= 0) sales++;
				if (t.IndexOf("FORECLOSURE") >= 0) seized++;
				if (CVar.FindCVar("cw_simverbose").GetInt()) Console.Printf("d%d %s", city.day, t);
			}
			if (CVar.FindCVar("cw_simverbose").GetInt() >= 2)
				for (int i = 0; i < city.ops.Size(); i++)
				{
					let op = city.ops[i];
					if (op.startDay != city.day) continue;
					for (int k = 0; k < op.steps.Size(); k++)
					{
						let st = op.steps[k];
						String where = st.prop >= 0 ? "PROP " .. CW_City.TypeCode(city.props[st.prop].type) : (st.stronghold >= 0 ? "HOLD " .. city.holds[st.stronghold].name : "SITE " .. CW_City.SiteName(st.site));
						Console.Printf("CW_STEP %s %s", CW_City.RoleName(st.role), where);
					}
				}
			if (city.day % 10 == 0 || d == n - 1)
			{
				String line = String.Format("CW_SIM day %d ops %d |", city.day, city.ActiveOps());
				for (int c = 0; c < city.corps.Size(); c++)
				{
					let o = city.corps[c];
					line = line .. String.Format(" %s%s %ds/%dp %d/%d", o.alive ? "" : "x", o.code, city.SubCount(c), city.PropCount(c), o.treasury, o.debt);
				}
				Console.Printf("%s", line);
			}
		}
		Console.Printf("CW_SIM done: day %d, sales %d, foreclosures %d, outcome %d %s", city.day, sales, seized, city.outcome, city.outcomeText);
		city.BuildOffers();
		l.FixSelection();
	}

	// Open the hack minigame on this door (UI side picks it up in UiTick).
	void RequestHack(CW_Door dr)
	{
		hackDoor = dr.doorIdx;
		int tier = floorGen ? floorGen.mapIdx : 0;
		let l = CW_Ledger.Of(players[consoleplayer].mo);
		CW_Contract c = l ? l.job : null;
		// harder locks at higher tech levels (tech 1-2: 2 + tier, 3: 3 + tier, 4: 4 + tier)
		int tech = c ? c.secTech : 2;
		hackNodes = 2 + tier + (tech >= 3 ? 1 : 0) + (tech >= 4 ? 1 : 0);
		hackRequests++;
	}

	// [K]: stick a breaching charge on the maglocked door you're facing.
	void PlantBreach(CW_Ledger l, Actor pm)
	{
		if (!floorGen) return;
		CW_Door dr = null;
		for (int k = 0; k < floorGen.secDoors.Size(); k++)
		{
			let d = floorGen.secDoors[k];
			if (d && d.secured && !d.isOpen && d.Distance2D(pm) < 80) { dr = d; break; }
		}
		if (!dr) { Console.MidPrint(NewSmallFont, "\cgNo maglocked door here to breach."); return; }
		if (!l.ConsumeOne(2, CW_Items.IT_BREACH)) { Console.MidPrint(NewSmallFont, "\cgNo breaching charge in your kit."); return; }
		Vector2 face = pm.pos.xy - dr.pos.xy;
		face = face.Length() > 1 ? face / face.Length() : (1, 0);
		let ch = CW_BreachCharge(Actor.Spawn("CW_BreachCharge", (dr.pos.xy + face * 10, dr.floorz + 40)));
		if (ch) { ch.door = dr; ch.target = pm; }
		Console.MidPrint(NewSmallFont, "\cgCharge set. Get clear!");
	}

	override void WorldThingDied(WorldEvent e)
	{
		let l = CW_Ledger.Of(players[consoleplayer].mo);
		if (!l || !l.missionActive || !e.Thing) return;
		let c = l.job;

		// Who did it? Hitscan kills report the bullet puff (which has no owner),
		// so each NPC records whether the player ever damaged it instead.
		bool cleaner = l.HasCrew(CW_Services.CREW_CLEANER);

		let g = CW_Guard(e.Thing);
		if (g)
		{
			if (g.knockedOut) l.takedowns++;
			else
			{
				l.kills++;
				if (c && g.hitByPlayer) l.AddFine("Guard casualty", c.guardFine);
			}
			if (cleaner) g.cleanTics = 105;
			return;
		}
		let cv = CW_Civilian(e.Thing);
		if (cv)
		{
			if (!cv.knockedOut && cv.hitByPlayer)
			{
				l.civKills++;
				if (c && c.protectCivilians) l.AddFine("Civilian casualty", c.civFine);
			}
			if (cleaner) cv.cleanTics = 105;
			return;
		}
		let sc = CW_Scientist(e.Thing);
		if (sc)
		{
			if (sc.hitByPlayer)
			{
				l.civKills++;
				if (c && c.protectCivilians) l.AddFine("Recruit target killed", c.civFine);
			}
			l.FailObjective(OBJ_TURN, "target is dead");
		}
	}

	void UpdatePrompt()
	{
		prompt = "";
		nearExtraction = false;
		let pm = players[consoleplayer].mo;
		if (!pm || pm.health <= 0) return;

		FLineTraceData t;
		pm.LineTrace(pm.angle, 96, pm.pitch, 0, pm.player.viewz - pm.pos.z, data: t);
		if (t.HitType == TRACE_HitActor && t.HitActor)
		{
			let ia = CW_Interactable(t.HitActor);
			let g = CW_Guard(t.HitActor);
			if (ia && ia.health > 0)
			{
				String p = ia.GetPrompt(pm);
				if (p.Length()) prompt = "[USE] " .. p;
			}
			else if (g && g.health > 0 && g.awareness != CW_Guard.AW_ALERT && g.Distance2D(pm) <= 80
				&& abs(Actor.DeltaAngle(g.angle, g.AngleTo(pm))) >= 100)
				prompt = "[USE] Takedown";
			else if (t.HitActor is "CW_Civilian" && t.HitActor.health > 0)
				prompt = CW_Civilian(t.HitActor).CanTakedown(pm) ? "[USE] Knock out" : "Oriole staff - civilian";
			else if (t.HitActor is "CW_Server" && t.HitActor.health > 0)
				prompt = "Server - shoot to destroy (loud)";
		}

		// maglocked door in front of you
		let l0 = CW_Ledger.Of(pm);
		if (!prompt.Length() && floorGen)
			for (int k = 0; k < floorGen.secDoors.Size(); k++)
			{
				let dr = floorGen.secDoors[k];
				if (!dr || !dr.secured || dr.isOpen || !dr.AtLock()) continue;
				if (CW_SecurityPass.Has(pm)) prompt = "[USE] Swipe security pass";
				else if (blackoutTics > 0) prompt = "[USE] Maglock is dead - open the door";
				else if (dr.hackLock > 0) prompt = String.Format("Keypad locked out - %ds  ([K] breach)", dr.hackLock / 35 + 1);
				else if (dr.useTics >= CW_Door.HOLD_TICS && l0 && l0.CountIn(2, CW_Items.IT_BYPASS) > 0)
					prompt = String.Format("Bypassing... %d%%", (dr.useTics - CW_Door.HOLD_TICS) * 100 / CW_Door.BYPASS_TICS);
				else
				{
					String more = "";
					if (l0 && l0.CountIn(2, CW_Items.IT_BYPASS) > 0) more = more .. "   hold: bypass device";
					if (l0 && l0.CountIn(2, CW_Items.IT_BREACH) > 0) more = more .. "   [K] breach";
					prompt = "[USE] Hack the maglock" .. more;
				}
				break;
			}

		// vent hint: standing next to a crawl-height vent
		if (!prompt.Length() && procGen && pm.player.crouchfactor > 0.75)
			for (int v = 0; v < procGen.ventX.Size(); v++)
				if ((pm.pos.xy - (procGen.ventX[v], procGen.ventY[v])).Length() < 80) { prompt = "Air duct - crouch to enter"; break; }
		if (!prompt.Length() && floorGen && pm.player.crouchfactor > 0.75)
			for (int v = 0; v < floorGen.ventX.Size(); v++)
				if ((pm.pos.xy - (floorGen.ventX[v], floorGen.ventY[v])).Length() < 80) { prompt = "Air duct - crouch to enter"; break; }

		let it = ThinkerIterator.Create("CW_Extraction");
		Actor x;
		double bestD = 1e9;
		wayOn = false;
		if (!nearExtraction) abortProgress = 0;
		let l = CW_Ledger.Of(pm);
		bool going = l && l.missionActive && l.PrimaryDone();
		while (x = Actor(it.Next()))
		{
			double d = x.Distance2D(pm);
			if (d <= 72 && !CW_Extraction.UseIsForALine(pm)) nearExtraction = true;   // facing a door: USE is the door's, no exit prompt
			if (going && d < bestD) { bestD = d; wayPos = x.pos.xy; wayLabel = "EXTRACT"; wayOn = true; }
		}
		// upper floors of a building: point at the nearest stairwell, the exits are on the insertion floor
		if (going && !wayOn && floorGen && floorGen.mapIdx > 0)
			for (int t = 0; t < 2; t++)
			{
				let vd = floorGen.vestDoor[t];
				if (!vd) continue;
				double d = vd.Distance2D(pm);
				if (d < bestD) { bestD = d; wayPos = vd.pos.xy; wayOn = true; wayLabel = String.Format("EXTRACT  via stairs to floor %d", floorGen.floorNums[0]); }
			}
		// site-pack floors without an exit: point at the nearest stairs / lift
		if (going && !wayOn && siteMis)
			for (int t = 0; t < siteMis.stX.Size(); t++)
			{
				double d = ((siteMis.stX[t], siteMis.stY[t]) - pm.pos.xy).Length();
				if (d < bestD) { bestD = d; wayPos = (siteMis.stX[t], siteMis.stY[t]); wayOn = true; wayLabel = "EXTRACT  via the stairs"; }
			}
		if (abortProgress > 0 && abortProgress < 1) prompt = String.Format("Aborting mission... %d%%", int(abortProgress * 100));
	}

	// Guards within radius hear it. Blocked line of sight shrinks the radius.
	static void EmitNoise(Actor src, Vector3 at, double radius, double loud)
	{
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next()))
		{
			if (g.health <= 0 || g == src) continue;
			double r = radius;
			if (src && !g.CheckSight(src, SF_IGNOREVISIBILITY)) r *= 0.6;
			if (level.Vec3Diff(g.pos, at).Length() <= r) g.HearNoise(at, loud);
		}
	}

	static void RaiseAlarm(Actor caller, Vector3 at, double radius)
	{
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next()))
		{
			if (g.health <= 0 || g == caller) continue;
			if (level.Vec3Diff(g.pos, at).Length() > radius) continue;
			g.cautious = true;
			g.HearNoise(at, 0.6);
		}
	}

	override void WorldTick()
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i]) continue;
			let pm = players[i].mo;
			if (!pm || pm.health <= 0) continue;

			// --- Gunfire: the player pawn enters its Missile state each shot.
			if (fireTimer[i] > 0) fireTimer[i]--;
			State ms = pm.MissileState;
			if (ms && pm.InStateSequence(pm.CurState, ms) && fireTimer[i] == 0)
			{
				double r = 1400;
				let w = players[i].ReadyWeapon;
				double loud = 1.0;
				if (w is "CW_TranqGun" || w is "CW_Taser") r = 0;   // emit their own quiet noise
				else if (w && w.bMELEEWEAPON || w is "Fist") { r = 96; loud = 0.25; }   // a punch: a scuffle only the next guard over hears
				else if (IsSuppressed(w)) r = 0;
				else if (w is "Pistol") r = 1000;
				if (r > 0) EmitNoise(pm, pm.pos, r, loud);
				fireTimer[i] = 10;
			}

			// --- Footsteps
			if (++stepTimer[i] >= 10)
			{
				stepTimer[i] = 0;
				double spd = pm.vel.xy.Length();
				double r = 0;
				// thresholds for the grounded movement (CW_Player): running tops out ~12, walking ~6
				if (spd > 9) r = 360;
				else if (spd > 4.5) r = 160;
				if (players[i].crouchfactor < 0.75) r *= 0.4;
				if (r > 0 && pm.pos.z <= pm.floorz + 1) EmitNoise(pm, pm.pos, r, 0.3);
			}
		}

		UpdatePrompt();
		UpdateFlashlights();
		if (floorInsertPending && floorGen && players[consoleplayer].mo)
		{
			floorInsertPending = false;
			for (int i = 0; i < MAXPLAYERS; i++)
				if (playeringame[i] && players[i].mo) floorGen.Insert(players[i].mo);
		}
		if (garageGen && players[consoleplayer].mo && (garageInsertPending || garageArrivePending))
		{
			let pm = players[consoleplayer].mo;
			let l = CW_Ledger.Of(pm);
			if (garageInsertPending) garageGen.Insert(pm);
			else
			{
				garageGen.Arrive(pm);
				if (l) l.arriveTower = -1;
				lastDoorWarp = level.maptime;
				// the first time down with the job done: who's waiting depends on the heat you drew
				if (l && l.missionActive && l.PrimaryDone() && !l.scenarioRolled)
				{
					l.scenarioRolled = true;
					l.scenario = CW_GarageGen.PickScenario(l.Heat(), l.rerouted);
					garageGen.SpawnScenario(l.scenario);
					static const String MSG[] = { "\cdQuiet down here. Get to the van.", "\cgSecurity's sweeping the garage.", "\cgThey've set up a checkpoint at the lift.", "\crAmbush! They're waiting by the van." };
					pm.A_Print(String.Format("\cfPARKING GARAGE  -  B1\n%s", MSG[clamp(l.scenario, 0, 3)]), 4);
				}
			}
			garageInsertPending = garageArrivePending = false;
		}
		if (floorArrivePending && floorGen && players[consoleplayer].mo)
		{
			floorArrivePending = false;
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			int t = l ? l.arriveTower : 0;
			if (l) l.arriveTower = -1;
			lastDoorWarp = level.maptime;
			for (int i = 0; i < MAXPLAYERS; i++)
				if (playeringame[i] && players[i].mo) floorGen.Arrive(players[i].mo, t);
		}
		if (kitInsertPending && kitGen && players[consoleplayer].mo)
		{
			kitInsertPending = false;
			for (int i = 0; i < MAXPLAYERS; i++)
				if (playeringame[i] && players[i].mo) kitGen.Insert(players[i].mo);
		}
		if (siteInsertPending && siteMis && players[consoleplayer].mo)
		{
			siteInsertPending = false;
			for (int i = 0; i < MAXPLAYERS; i++)
				if (playeringame[i] && players[i].mo) siteMis.Insert(players[i].mo, true);
		}
		if (obsInsertPending && obsSite && players[consoleplayer].mo)
		{
			obsInsertPending = false;
			for (int i = 0; i < MAXPLAYERS; i++)
				if (playeringame[i] && players[i].mo) obsSite.Insert(players[i].mo);
		}
		if (navBuildAt > 0 && level.maptime >= navBuildAt) { navBuildAt = 0; navGraph.Build(); }
		if (floorGen && players[consoleplayer].mo) floorGen.Watch(players[consoleplayer].mo, CW_Ledger.Of(players[consoleplayer].mo));

		if (blackoutTics > 0 && --blackoutTics == 0) EndBlackout();

		// radar snapshot
		radarX.Clear(); radarY.Clear(); radarKind.Clear();
		radarOn = false;
		let lg = CW_Ledger.Of(players[consoleplayer].mo);
		if (lg && lg.missionActive && !inHub)
		{
			bool guards = lg.HasIntel(CW_Services.INTEL_PATROLS);
			bool objs = lg.HasIntel(CW_Services.INTEL_SURVEY);
			radarOn = guards || objs;
			if (guards)
			{
				let gi = ThinkerIterator.Create("CW_Guard");
				CW_Guard gg;
				while (gg = CW_Guard(gi.Next()))
				{
					if (gg.health <= 0) continue;
					radarX.Push(gg.pos.x); radarY.Push(gg.pos.y); radarKind.Push(gg.awareness);
				}
			}
			if (objs)
			{
				let oi = ThinkerIterator.Create("Actor");
				Actor o;
				while (o = Actor(oi.Next()))
				{
					int k = 0;
					if (o is "CW_Prototype") k = 10 + OBJ_STEAL;
					else if (o is "CW_Server" && o.health > 0) k = 10 + OBJ_DESTROY;
					else if (o is "CW_Scientist" && o.health > 0 && !CW_Scientist(o).turned) k = 10 + OBJ_TURN;
					else if (o is "CW_Extraction") k = 20;
					else if (o is "CW_SecurityPass" && !Inventory(o).Owner) k = 30;
					if (!k) continue;
					radarX.Push(o.pos.x); radarY.Push(o.pos.y); radarKind.Push(k);
				}
			}
		}

		// --- HUD summary: most alarmed living guard
		worstAwareness = 0;
		worstSuspicion = 0;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next()))
		{
			if (g.health <= 0) continue;
			if (g.awareness > worstAwareness) worstAwareness = g.awareness;
			worstSuspicion = max(worstSuspicion, g.suspicion);
		}
		// New alarm incident = a guard went into combat when none were.
		if (worstAwareness == CW_Guard.AW_ALERT && prevWorst != CW_Guard.AW_ALERT)
		{
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			if (l && l.missionActive) { l.alarms++; if (!l.firstAlarmTime) l.firstAlarmTime = level.totaltime; }
		}
		prevWorst = worstAwareness;
	}

	// ================================================================ HUD
	// Uses the engine's NewSmallFont (clean, mixed case) instead of the IWAD's
	// 8px bitmap font. Everything scales with screen height.

	ui double UiScale() { return max(1.0, Screen.GetHeight() / 540.0); }
	ui double LineH(double s) { return NewSmallFont.GetHeight() * s * 1.3; }
	ui double TextW(double s, String t) { return NewSmallFont.StringWidth(t) * s; }

	ui void Txt(double s, double x, double y, String t, int col)
	{
		Screen.DrawText(NewSmallFont, col, x, y, t, DTA_ScaleX, s, DTA_ScaleY, s);
	}

	ui void Panel(double x, double y, double w, double h, Color accent, double s)
	{
		Screen.Dim(Color(6, 9, 14), 0.80, int(x), int(y), int(w), int(h));
		Screen.Dim(accent, 1.0, int(x), int(y), int(max(2.0, 3 * s)), int(h));
	}

	static clearscope String Money(int v)
	{
		String n = String.Format("%d", abs(v));
		String o = "";
		int len = n.Length();
		for (int i = 0; i < len; i++)
		{
			if (i > 0 && (len - i) % 3 == 0) o = o .. ",";
			o = o .. n.Mid(i, 1);
		}
		return (v < 0 ? "-$" : "$") .. o;
	}

	// ---- row buffer: add rows, then DrawRows() sizes the panel to fit
	ui void ClearRows() { rowText.Clear(); rowCol.Clear(); }
	ui void Row(String t, int col = Font.CR_WHITE) { rowText.Push(t); rowCol.Push(col); }
	ui void Gap() { rowText.Push(""); rowCol.Push(-1); }
	ui void WrapRows(String t, int col, double wrapPx)   // wrapPx in font pixels
	{
		Array<String> paras;
		t.Split(paras, "\n");
		for (int p = 0; p < paras.Size(); p++)
		{
			BrokenLines bl = NewSmallFont.BreakLines(paras[p], int(wrapPx));
			for (int i = 0; i < bl.Count(); i++) Row(bl.StringAt(i), col);
		}
	}

	// sc scales the text (the mission panels use a smaller size); right = x is the panel's right edge,
	// bottomUp = y is its bottom edge.
	ui double DrawRows(double x, double y, double w, Color accent, double sc = 1.0, bool right = false, bool bottomUp = false)
	{
		double s = UiScale() * sc;
		double pad = 8 * s, lh = LineH(s);
		double h = pad * 2;
		for (int i = 0; i < rowText.Size(); i++)
		{
			h += rowCol[i] == -1 ? lh * 0.45 : lh;
			w = max(w, TextW(s, rowText[i]) + pad * 2 + 8 * s);
		}
		if (right) x -= w;
		if (bottomUp) y -= h;
		Panel(x, y, w, h, accent, s);
		double cy = y + pad;
		for (int i = 0; i < rowText.Size(); i++)
		{
			if (rowCol[i] == -1) { cy += lh * 0.45; continue; }
			Txt(s, x + pad + 4 * s, cy, rowText[i], rowCol[i]);
			cy += lh;
		}
		return y + h;
	}

	override void RenderOverlay(RenderEvent e)
	{
		let pm = players[consoleplayer].mo;
		if (!pm || automapactive) return;
		double s = UiScale();
		double margin = 12 * s;

		// ---------------- visibility meter (bottom-left, above the status bar)
		let st = EAI_StealthScript(pm.FindInventory("EAI_StealthScript"));
		double vis = st ? st.visibility : 1.0;

		String status; int col; Color scol;
		if (worstAwareness == CW_Guard.AW_ALERT)           { status = "ALERT";      col = Font.CR_RED;       scol = Color(230, 60, 50); }
		else if (worstAwareness == CW_Guard.AW_SUSPICIOUS) { status = "SUSPICIOUS"; col = Font.CR_ORANGE;    scol = Color(240, 150, 40); }
		else if (worstSuspicion > 1)                       { status = "NOTICED";    col = Font.CR_YELLOW;    scol = Color(230, 210, 70); }
		else if (vis < 0.15)                               { status = "HIDDEN";     col = Font.CR_LIGHTBLUE; scol = Color(70, 150, 255); }
		else                                               { status = "UNSEEN";     col = Font.CR_GREEN;     scol = Color(80, 200, 110); }

		double mw = 190 * s, mh = LineH(s) + 22 * s;
		double mx = margin, my = Screen.GetHeight() * 0.80 - mh;
		Panel(mx, my, mw, mh, scol, s);
		Txt(s, mx + 10 * s, my + 5 * s, "Visibility", Font.CR_GRAY);
		Txt(s, mx + mw - 8 * s - TextW(s, status), my + 5 * s, status, col);
		double bx = mx + 10 * s, by = my + 5 * s + LineH(s), bw = mw - 18 * s, bh = 7 * s;
		Screen.Dim(Color(40, 44, 52), 1.0, int(bx), int(by), int(bw), int(bh));
		Color vc = vis < 0.25 ? Color(70, 150, 255) : (vis < 0.6 ? Color(230, 200, 60) : Color(235, 80, 60));
		Screen.Dim(vc, 1.0, int(bx), int(by), int(bw * vis), int(bh));

		// ---------------- city-map visit note (top centre): how to get back
		let vlk = CW_CityLink.Get();
		if (vlk && vlk.visit && !inHub)
		{
			bool fresh = gametic - visitStart < 350;
			String v1 = String.Format("VISITING: %s", vlk.visitName);
			String v2 = "M: map  |  R in map: return  |  HOME";
			double vw2 = max(TextW(s, v1), TextW(s, v2)) + 24 * s, vh2 = LineH(s) * 2 + 12 * s;
			double vx2 = (Screen.GetWidth() - vw2) / 2, vy2 = 8 * s;
			Panel(vx2, vy2, vw2, vh2, fresh ? Color(240, 170, 40) : Color(70, 80, 96), s);
			Txt(s, vx2 + (vw2 - TextW(s, v1)) / 2, vy2 + 5 * s, v1, fresh ? Font.CR_GOLD : Font.CR_GRAY);
			Txt(s, vx2 + (vw2 - TextW(s, v2)) / 2, vy2 + 5 * s + LineH(s), v2, fresh ? Font.CR_WHITE : Font.CR_DARKGRAY);
		}

		// ---------------- radar (above the visibility meter)
		if (radarOn) DrawRadar(pm, mx, my - 8 * s, s);

		// ---------------- interaction prompt (center)
		if (prompt.Length())
		{
			String t = prompt;
			String key = "";
			if (t.Left(6) == "[USE] ") { key = "USE"; t = t.Mid(6); }
			double kw = key.Length() ? TextW(s, key) + 12 * s : 0;
			double pw = kw + TextW(s, t) + 24 * s, ph = LineH(s) + 10 * s;
			double px = (Screen.GetWidth() - pw) / 2, py = Screen.GetHeight() * 0.60;
			Panel(px, py, pw, ph, Color(240, 170, 40), s);
			double tx = px + 12 * s;
			if (key.Length())
			{
				Screen.Dim(Color(240, 170, 40), 1.0, int(tx - 3 * s), int(py + 4 * s), int(kw - 6 * s), int(ph - 8 * s));
				Txt(s, tx + 3 * s, py + 5 * s + 1, key, Font.CR_BLACK);
				tx += kw;
			}
			Txt(s, tx, py + 5 * s + 1, t, Font.CR_WHITE);
		}

		// ---------------- extraction waypoint (top centre)
		if (wayOn)
		{
			Vector2 dv = wayPos - pm.pos.xy;
			double rel = Actor.DeltaAngle(pm.angle, VectorAngle(dv.x, dv.y));   // + = to the left
			String t = String.Format("%s  %dm", wayLabel, int(dv.Length() / 32));
			double ww = TextW(s, t) + 44 * s, hh = LineH(s) + 10 * s;
			double wx = (Screen.GetWidth() - ww) / 2, wy = margin;
			Panel(wx, wy, ww, hh, Color(80, 200, 110), s);
			Txt(s, wx + 34 * s, wy + 5 * s + 1, t, Font.CR_GREEN);
			// arrow: up = straight ahead
			double cx = wx + 18 * s, cy = wy + hh / 2, r = hh * 0.36;
			double a = 90 + rel;   // screen: 90 = up
			Vector2 tip = (cx + cos(a) * r, cy - sin(a) * r);
			Vector2 tl = (cx + cos(a + 140) * r, cy - sin(a + 140) * r), tr = (cx + cos(a - 140) * r, cy - sin(a - 140) * r);
			Color gc = Color(255, 90, 220, 120);
			Screen.DrawThickLine(int(tip.x), int(tip.y), int(tl.x), int(tl.y), 2 * s, gc);
			Screen.DrawThickLine(int(tip.x), int(tip.y), int(tr.x), int(tr.y), 2 * s, gc);
			Screen.DrawThickLine(int(tip.x), int(tip.y), int(cx - cos(a) * r), int(cy + sin(a) * r), 2 * s, gc);
		}

		// ---------------- campaign panels (top-left)
		let l = CW_Ledger.Of(pm);
		if (!l) return;
		if (inHub) DrawHubPanel(l, margin);
		else if (l.missionActive) DrawMissionPanel(l, margin);
		else if (nearExtraction) { ClearRows(); Row("Press USE to return to the office", Font.CR_GRAY); DrawRows(margin, margin, 300 * s, Color(120, 120, 130)); }
	}

	// Heading-up radar, 1024 map units across the radius.
	ui void DrawRadar(Actor pm, double x, double bottom, double s)
	{
		double size = 150 * s, r = size / 2 - 6 * s;
		double y = bottom - size;
		Panel(x, y, size + 40 * s, size, Color(60, 220, 200), s);
		double cx = x + 20 * s + size / 2, cy = y + size / 2;
		// rings + you
		Screen.Dim(Color(40, 60, 70), 1.0, int(cx - r), int(cy), int(r * 2), max(1, int(s)));
		Screen.Dim(Color(40, 60, 70), 1.0, int(cx), int(cy - r), max(1, int(s)), int(r * 2));
		Screen.Dim(Color(255, 255, 255), 1.0, int(cx - 3 * s), int(cy - 3 * s), int(6 * s), int(6 * s));
		double range = 1024;
		double a = pm.angle;
		for (int i = 0; i < radarKind.Size(); i++)
		{
			double dx = radarX[i] - pm.pos.x, dy = radarY[i] - pm.pos.y;
			double fwd = dx * cos(a) + dy * sin(a);
			double rgt = dx * sin(a) - dy * cos(a);
			double px = rgt / range * r, py = -fwd / range * r;
			double len = sqrt(px * px + py * py);
			bool edge = len > r;
			if (edge) { px *= r / len; py *= r / len; }
			int k = radarKind[i];
			Color c;
			double d = 5 * s;
			if (k >= 30) c = Color(60, 220, 200);
			else if (k >= 20) c = Color(80, 220, 110);
			else if (k >= 10) { c = CW_Contract.KindColor(k - 10); d = 7 * s; }
			else c = k == 2 ? Color(240, 60, 50) : (k == 1 ? Color(245, 160, 40) : Color(235, 235, 235));
			if (edge) d *= 0.7;
			Screen.Dim(c, edge ? 0.6 : 1.0, int(cx + px - d / 2), int(cy + py - d / 2), int(d), int(d));
		}
		Txt(s, x + 8 * s, y + 4 * s, "RADAR", Font.CR_DARKGRAY);
	}

	ui void DrawHubPanel(CW_Ledger l, double margin)
	{
		ClearRows();
		let city = l.city;
		Row(city ? String.Format("THE BROKER'S DESK   DAY %d", city.day) : "THE BROKER'S DESK", Font.CR_GOLD);
		Row("Budget   " .. Money(l.budget), l.budget >= 0 ? Font.CR_GREEN : Font.CR_RED);
		if (l.debt) Row("Owed to Meridian   " .. Money(l.debt), Font.CR_ORANGE);
		if (city)
		{
			if (city.outcome) Row(city.outcome == 1 ? "CAMPAIGN WON" : "CAMPAIGN LOST", city.outcome == 1 ? Font.CR_GREEN : Font.CR_RED);
			else Row(String.Format("%d jobs on the board", city.offers.Size()), Font.CR_GRAY);
			if (city.patron >= 0) Row("Pledged to " .. city.corps[city.patron].short, CW_City.FactionFont(city.patron));
			else if (city.offer >= 0) Row(city.corps[city.offer].short .. " offers patronage (terminal: LEDGER)", Font.CR_ORANGE);
		}
		if (l.debriefNew) Row("New debrief at the terminal", Font.CR_ORANGE);
		String mk = l.MissingKits();
		if (mk.Length()) Row("Crew kit not loaded: " .. mk, Font.CR_RED);
		DrawRows(margin, margin, 0, Color(240, 170, 40));
	}

	ui void DrawMissionPanel(CW_Ledger l, double margin)
	{
		let c = l.job;
		if (!c) return;
		double s = UiScale();
		bool primaryDone = (l.objDone & c.primaryMask) != 0;
		ClearRows();
		Row(c.title, Font.CR_GOLD);
		for (int k = 1; k <= 3; k++)
		{
			if (c.pay[k] <= 0) continue;
			bool done = (l.objDone & (1 << k)) != 0;
			if (l.failedMask & (1 << k))
			{
				Row(String.Format("\cg[--]  %s  FAILED", c.ObjName(k)), Font.CR_RED);
				continue;
			}
			String tagc = k == OBJ_STEAL ? "\ch" : (k == OBJ_DESTROY ? "\ci" : "\ct");   // blue / orange / purple
			String fl = (floorGen && floorGen.floors > 1) ? String.Format("  \cuFL %d", floorGen.floorNums[CW_Building.ObjFloor(floorGen.bldSeed, floorGen.floors, c, k)]) : "";
			Row(String.Format("%s %s%s\c-  %s%s%s", done ? "\cd[x]" : "[ ]", tagc, CW_Contract.KindTag(k), c.ObjName(k), c.IsPrimary(k) ? "" : " \cu(bonus)", fl),
				done ? Font.CR_GREEN : (c.IsPrimary(k) ? Font.CR_WHITE : Font.CR_GRAY));
		}
		if (primaryDone) Row("Extract at any exit (follow the marker)", Font.CR_GREEN);
		else if (nearExtraction) Row("Hold USE here to abort", Font.CR_RED);
		if (l.alarms) Row(String.Format("Alarms raised: %d", l.alarms), Font.CR_RED);
		int heat = l.Heat();
		Row(String.Format("Heat %d%s", heat, (l.garageRun || l.rerouted) ? "   (van in the garage)" : ""), heat >= 70 ? Font.CR_RED : heat >= 45 ? Font.CR_ORANGE : heat >= 20 ? Font.CR_YELLOW : Font.CR_DARKGRAY);
		if (floorGen && l.passMask)
		{
			if (floorGen.floors > 1)
			{
				String ps = "";
				for (int m = 0; m < floorGen.floors; m++)
					if (l.passMask & (1 << m)) ps = ps .. (ps.Length() ? ", " : "") .. String.Format("%s (floor %d)", CW_Building.TierColour(m), floorGen.floorNums[m]);
				Row("Passes: " .. ps, CW_SecurityPass.Has(players[consoleplayer].mo) ? Font.CR_CYAN : Font.CR_DARKGRAY);
			}
			else Row("Security pass", Font.CR_CYAN);
		}
		if (l.fineTotal) Row(String.Format("Violations  -%s", Money(l.fineTotal)), Font.CR_RED);
		DrawRows(margin, margin, 0, primaryDone ? Color(80, 200, 110) : Color(240, 170, 40), 0.72);

		// kit and crew: a small panel on the right, above the status bar
		ClearRows();
		if (FlashOn(consoleplayer)) Row("[L] Flashlight ON  (you're easy to spot)", Font.CR_YELLOW);
		else if (l.CountIn(2, CW_Items.IT_FLASHLIGHT) > 0) Row("[L] Flashlight", Font.CR_DARKGRAY);
		let rw = players[consoleplayer].ReadyWeapon;
		if (CanSuppress(rw))
		{
			if (IsSuppressed(rw)) Row("[V] Weapon SUPPRESSED", Font.CR_PURPLE);
			else if (l.CountIn(2, CW_Items.IT_SUPPRESSOR) > 0) Row("[V] Fit suppressor", Font.CR_DARKGRAY);
		}
		int nm = l.CountIn(2, CW_Items.IT_NOISEMAKER), fb = l.CountIn(2, CW_Items.IT_FLASHBANG), mk = l.CountIn(2, CW_Items.IT_MEDKIT);
		if (nm || fb || mk)
		{
			if (nm) Row(String.Format("[G] Noisemaker  x%d", nm), Font.CR_GOLD);
			if (fb) Row(String.Format("[H] Flashbang  x%d", fb), Font.CR_GOLD);
			if (mk) Row(String.Format("[J] Medkit  x%d", mk), Font.CR_GREEN);
		}
		if (l.crewMask)
		{
			if (rowText.Size()) Gap();
			if (l.HasCrew(CW_Services.CREW_HACKER))
				Row(blackoutTics > 0 ? String.Format("Nyx  blackout %ds", blackoutTics / 35 + 1) : String.Format("Nyx  [B] blackout  x%d", l.hackerUses),
					l.hackerUses > 0 || blackoutTics > 0 ? Font.CR_CYAN : Font.CR_DARKGRAY);
			if (l.HasCrew(CW_Services.CREW_CLEANER)) Row("Marrow  cleaning up after you", Font.CR_GRAY);
			if (l.HasCrew(CW_Services.CREW_VOX))
				Row(String.Format("Vox  [N] noise lure  x%d", l.voxUses), l.voxUses > 0 ? Font.CR_ORANGE : Font.CR_DARKGRAY);
		}
		if (rowText.Size()) DrawRows(Screen.GetWidth() - margin, Screen.GetHeight() * 0.80, 0, Color(90, 100, 115), 0.72, true, true);
	}
}
