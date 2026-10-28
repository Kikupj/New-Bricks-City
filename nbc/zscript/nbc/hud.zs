// Reload-aware magazine readout layered over the stock Doom HUD.
class NBC_StatusBar : DoomStatusBar
{
	HUDFont nbcAmmoFont;
	HUDFont nbcSmallFont;

	override void Init()
	{
		Super.Init();
		Font fnt = "HUDFONT_DOOM";
		nbcAmmoFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), Mono_CellLeft, 1, 1);
		nbcSmallFont = HUDFont.Create(NewSmallFont);
	}

	void DrawNBCWeaponAmmo()
	{
		if (!CPlayer || !CPlayer.ReadyWeapon || !nbcSmallFont) return;
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(CPlayer.ReadyWeapon);
		if (!weapon) return;

		Inventory magazineItem = weapon.Ammo1;
		Inventory reserveItem = weapon.Ammo2;
		int magazine = magazineItem ? magazineItem.Amount : 0;
		int capacity = magazineItem ? magazineItem.MaxAmount : 0;
		int reserve = reserveItem ? reserveItem.Amount : 0;
		int color = magazine == 0 || magazine * 4 <= capacity ? Font.CR_RED :
			(magazine * 2 <= capacity ? Font.CR_YELLOW : Font.CR_UNTRANSLATED);
		String ammoText = FormatNumber(magazine, 0) .. " / " .. FormatNumber(reserve, 0);
		// bottom right, above the stock ammo counter
		DrawString(nbcSmallFont, "MAG " .. ammoText, (-4, -58), DI_TEXT_ALIGN_RIGHT, color, scale: (0.5, 0.5));
		if (magazine == 0)
			DrawString(nbcSmallFont, "RELOAD", (-4, -66), DI_TEXT_ALIGN_RIGHT, Font.CR_RED, scale: (0.5, 0.5));
	}

	void DrawNBCDebris()
	{
		if (!CPlayer || !CPlayer.mo || !nbcSmallFont) return;
		NBC_Player pawn = NBC_Player(CPlayer.mo);
		if (!pawn) return;
		int selected = pawn.NBC_GetSelectedDebris();
		String icon = "BRKPA0";
		String label = "BRICK";
		switch (selected)
		{
		case NBC_DEBRIS_HALF_BRICK: icon = "HBRKA0"; label = "HALF"; break;
		case NBC_DEBRIS_CONCRETE: icon = "CNCKA0"; label = "CONCRETE"; break;
		case NBC_DEBRIS_BOTTLE: icon = "MOLPA0"; label = "BOTTLE"; break;
		}
		DrawImage(icon, (-4, -40), DI_ITEM_RIGHT_BOTTOM, scale: (0.6, 0.6));
		String count = FormatNumber(pawn.NBC_GetDebrisCount(selected), 0) .. " / " .. FormatNumber(pawn.NBC_GetDebrisCarryLimit(), 0);
		DrawString(nbcSmallFont, label .. " " .. count, (-20, -48), DI_TEXT_ALIGN_RIGHT, Font.CR_TAN, scale: (0.5, 0.5));
	}

	// Case and raid readout, top left (PLAN M2 vertical slice).
	void DrawNBCCase()
	{
		let rd = NBC_RunData.Find();
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (!rd || !rm || !nbcSmallFont || (!rd.caseActive && !rd.raidActive)) return;
		int y = 3;
		if (rm.IsRaidMap(rd))
		{
			let g = rm.GangAt(rd.raidGang);
			String title = rm.TurfTitle(rd.raidDistrict);
			DrawString(nbcSmallFont, title .. (g ? "  -  " .. g.name : ""), (3, y), DI_TEXT_ALIGN_LEFT, g ? g.TextColor() : Font.CR_WHITE, scale: (0.4, 0.4));
			y += 7;
			// the hour (clock.zs) and the day's event, if it's this raid's
			String when = NBC_Clock.WindowLine(rd.raidWindow);
			if (rd.raidEvent > NBC_Clock.EV_NONE && rd.raidEvent < NBC_Clock.EV_COUNT) when = when .. "  -  " .. NBC_Clock.EV_NAME[rd.raidEvent];
			DrawString(nbcSmallFont, when, (3, y), DI_TEXT_ALIGN_LEFT, rd.raidEvent ? Font.CR_GOLD : Font.CR_GRAY, scale: (0.4, 0.4));
			y += 7;
			String lead;
			int lc = Font.CR_RED;
			if (rd.leaderDown) { lead = "Leader down: get to the exit"; lc = Font.CR_GREEN; }
			else if (rm.leader && rm.leader.health > 0 && CPlayer && CPlayer.mo)
			{
				Vector2 d = rm.leader.pos.xy - CPlayer.mo.pos.xy;
				static const String dirs[] = { "E", "NE", "N", "NW", "W", "SW", "S", "SE" };
				int o = int(floor((VectorAngle(d.x, d.y) + 22.5) / 45.0)) & 7;
				lead = String.Format("Leader: %s, %d m %s", g ? g.leaderTitle : "?", int(d.Length() / 32), dirs[o]);
			}
			else lead = "Leader: unknown";
			DrawString(nbcSmallFont, lead, (3, y), DI_TEXT_ALIGN_LEFT, lc, scale: (0.4, 0.4));
			y += 7;
			// shot down: the ambush round the wreck
			if (rd.raidMode == NBC_Motor.MODE_CRASH)
			{
				String cs = rd.crashClear ? "CRASH SITE: the way out is clear - get to the exit" :
					String.Format("CRASH SITE: hold out (wave %d of %d)", rd.crashWave, NBC_Motor.CRASH_WAVES);
				DrawString(nbcSmallFont, cs, (3, y), DI_TEXT_ALIGN_LEFT, rd.crashClear ? Font.CR_GREEN : Font.CR_ORANGE, scale: (0.4, 0.4));
				y += 7;
			}
			int left = 0;
			for (int i = 0; i < rm.crew.Size(); i++) if (rm.crew[i] && rm.crew[i].health > 0) left++;
			DrawString(nbcSmallFont, String.Format("Crew left %d", left), (3, y), DI_TEXT_ALIGN_LEFT, Font.CR_LIGHTBLUE, scale: (0.4, 0.4));
			y += 8;
			// the squad strip: a portrait, a health bar, the name (Hamburger Hill's squad panel)
			let dept = NBC_Department.Find();
			for (int i = 0; i < rm.squad.Size(); i++)
			{
				let a = NBC_Ally(rm.squad[i]);
				if (!a) continue;
				let o = dept ? dept.OfficerById(a.officerId) : null;
				double x = 3 + i * 26;
				bool down = a.health <= 0;
				if (o) DrawImage(o.Portrait(), (x, y), DI_ITEM_LEFT_TOP, down ? 0.35 : 1.0, scale: (0.21, 0.21));   // 96-px portraits
				Fill(Color(255, 10, 14, 20), x, y + 21, 20, 2);
				double frac = clamp(a.health / double(max(1, a.maxHp)), 0, 1);
				Fill(frac > 0.6 ? Color(255, 88, 176, 74) : (frac > 0.3 ? Color(255, 242, 169, 59) : Color(255, 200, 53, 43)), x, y + 21, 20 * frac, 2);
				DrawString(nbcSmallFont, down ? "DOWN" : (o ? o.surname : a.GetTag()), (x, y + 24), DI_TEXT_ALIGN_LEFT, down ? Font.CR_RED : Font.CR_GRAY, scale: (0.26, 0.26));
				// the fireteam letter in the corner
				int team = rd.TeamOfSlot(a.slot);
				Fill(team == NBC_Orders.TEAM_ALPHA ? Color(255, 79, 195, 217) : Color(255, 242, 169, 59), x + 14, y, 6, 6);
				DrawString(nbcSmallFont, team == NBC_Orders.TEAM_ALPHA ? "A" : "B", (x + 15, y), DI_TEXT_ALIGN_LEFT, Font.CR_BLACK, scale: (0.24, 0.24));
			}
			if (rm.squad.Size()) y += 30;
			// each fireteam's order and rules of engagement; ">" marks who your keys talk to
			if (rm.squad.Size() && rd.teamOrder.Size() == NBC_Orders.TEAMS)
				for (int t = 0; t < NBC_Orders.TEAMS; t++)
				{
					if (!NBC_Orders.TeamSize(rd, t)) continue;
					bool talking = rd.cmdTeam == NBC_Orders.CT_ALL || rd.cmdTeam - 1 == t;
					String line = String.Format("%s%s  %s  %s", talking ? "> " : "  ", NBC_Orders.TEAM_NAME[t],
						NBC_Orders.ORDER_NAME[rd.teamOrder[t]], NBC_Orders.ROE_NAME[rd.teamROE[t]]);
					if (rd.teamOrder[t] == NBC_Orders.ORD_ADVANCE) line = line .. String.Format("  (%d wp)", NBC_Orders.WaypointCount(rd, t));
					DrawString(nbcSmallFont, line, (3, y), DI_TEXT_ALIGN_LEFT, t == NBC_Orders.TEAM_ALPHA ? Font.CR_CYAN : Font.CR_GOLD, scale: (0.34, 0.34));
					y += 6;
				}
			y += 2;
		}
		if (rd.caseActive)
			DrawString(nbcSmallFont, String.Format("Day %d/%d   Strikes %d/%d   $%d", rd.day, NBC_RunData.MAX_DAYS,
				rd.strikes, NBC_RunData.MAX_STRIKES, rd.cash), (3, y), DI_TEXT_ALIGN_LEFT, Font.CR_GRAY, scale: (0.4, 0.4));
		// at the precinct: today's event
		if (rd.caseActive && !rd.raidActive && rd.evKind > NBC_Clock.EV_NONE && rd.evKind < NBC_Clock.EV_COUNT)
			DrawString(nbcSmallFont, String.Format("TODAY: %s in %s, %s", NBC_Clock.EV_NAME[rd.evKind], rm.TurfTitle(rd.evDistrict),
				NBC_Clock.WindowLine(rd.evWindow)), (3, y + 7), DI_TEXT_ALIGN_LEFT, rd.evKind == NBC_Clock.EV_PINNED ? Font.CR_RED : Font.CR_GOLD, scale: (0.4, 0.4));
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		if (state != HUD_StatusBar && state != HUD_Fullscreen) return;
		// our readouts use fullscreen HUD space in both modes: negative coordinates count from the bottom right
		BeginHUD();
		DrawNBCWeaponAmmo();
		DrawNBCDebris();
		DrawNBCCase();
		DrawThreatRing();
		DrawSquadLog();
	}

	// Ghost Recon's threat indicator: a ring at the bottom of the screen, a mark for every gang member the squad
	// can see, in the direction it is from where you're looking (up = ahead). Red: it's after you or an officer.
	void DrawThreatRing()
	{
		let ord = NBC_Orders.Get();
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		let rd = NBC_RunData.Find();
		if (!ord || !rm || !rm.IsRaidMap(rd) || !CPlayer || !CPlayer.mo) return;
		Actor me = CPlayer.mo;
		Vector2 c = (0, -62);
		double r = 13;
		for (int i = 0; i < 16; i++)
		{
			double an = i * 22.5;
			Fill(Color(150, 120, 140, 160), c.x + sin(an) * r - 0.5, c.y - cos(an) * r - 0.5, 1, 1, DI_SCREEN_CENTER_BOTTOM);
		}
		Fill(Color(200, 220, 220, 220), c.x - 0.5, c.y - r - 2, 1, 2, DI_SCREEN_CENTER_BOTTOM);   // ahead
		for (int i = 0; i < ord.contacts.Size(); i++)
		{
			Actor m = ord.contacts[i];
			if (!m) continue;
			double rel = Actor.DeltaAngle(me.angle, me.AngleTo(m));
			double dist = me.Distance2D(m);
			double sz = dist < 384 ? 3 : (dist < 1024 ? 2 : 1.5);
			Color col = ord.contactHot[i] ? Color(255, 230, 60, 50) : Color(255, 240, 200, 70);
			Fill(col, c.x - sin(rel) * r - sz / 2, c.y - cos(rel) * r - sz / 2, sz, sz, DI_SCREEN_CENTER_BOTTOM);
		}
	}

	// the squad's radio log, bottom left, fading out
	void DrawSquadLog()
	{
		let ord = NBC_Orders.Get();
		if (!ord || !nbcSmallFont) return;
		int n = ord.logText.Size();
		for (int i = 0; i < n; i++)
		{
			double alpha = min(1.0, ord.logTics[i] / 35.0);
			DrawString(nbcSmallFont, ord.logText[i], (3, -78 - (n - 1 - i) * 7), DI_TEXT_ALIGN_LEFT, ord.logColor[i], alpha, scale: (0.36, 0.36));
		}
	}
}
