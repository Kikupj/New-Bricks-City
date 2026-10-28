// The HUD (polish pass, 2026-10-28): Doom's status bar and marine face are gone. One bar along the bottom in the
// precinct screens' colours (Hamburger Hill's bottom bar): your portrait (the face you picked), health and vest on
// the left; your pouches and the debris in the middle; the weapon, its magazine and the reserve on the right.
// Above it: the case and raid readout and the squad strip top left, the threat ring, the radio log.
class NBC_StatusBar : BaseStatusBar
{
	HUDFont nbcBigFont;
	HUDFont nbcSmallFont;

	const BAR_H = 26;

	override void Init()
	{
		Super.Init();
		SetSize(0, 320, 200);       // the bar sits over the view: no strip of the screen kept for it
		nbcBigFont = HUDFont.Create(BigFont);
		nbcSmallFont = HUDFont.Create(NewSmallFont);
	}

	static Color Hex(int c, int a = 255) { return Color(a, (c >> 16) & 255, (c >> 8) & 255, c & 255); }

	// text a given height in HUD units
	void Say(HUDFont f, Font fnt, String s, Vector2 pos, int flags, int cr, double height, double alpha = 1.0)
	{
		double k = height / max(1, fnt.GetHeight());
		DrawString(f, s, pos, flags, cr, alpha, scale: (k, k));
	}

	void DrawNBCBar()
	{
		if (!CPlayer || !CPlayer.mo) return;
		let mo = CPlayer.mo;
		int lb = DI_SCREEN_LEFT_BOTTOM, rb = DI_SCREEN_RIGHT_BOTTOM, cb = DI_SCREEN_CENTER_BOTTOM;

		// the bar
		Fill(Hex(0x080B10, 215), 0, -BAR_H, 4000, BAR_H, lb);
		Fill(Hex(0x8A5E1E, 255), 0, -BAR_H, 4000, 1, lb);
		Fill(Hex(0x8A5E1E, 255), -4000, -BAR_H, 4000, 1, rb);
		Fill(Hex(0x080B10, 215), -4000, -BAR_H, 4000, BAR_H, rb);

		// you: the portrait, red when you're hurt; health and the vest
		let dept = NBC_Department.Find();
		int hp = max(0, mo.health);
		TextureID face = TexMan.CheckForTexture(dept ? dept.PlayerPortrait() : "NBCPVANC", TexMan.Type_Any);
		Fill(Hex(0x3D5064), 2, -BAR_H + 2, 24, 24, lb);
		if (face.IsValid())
			DrawTexture(face, (3, -BAR_H + 3), lb | DI_ITEM_LEFT_TOP, 1.0, (22, 22), (1, 1), STYLE_Translucent,
				hp < 35 ? Color(255, 255, 120, 120) : Color(255, 255, 255, 255));
		int hc = hp < 35 ? Font.CR_RED : (hp < 70 ? Font.CR_GOLD : Font.CR_WHITE);
		Say(nbcBigFont, BigFont, String.Format("%d", hp), (30, -BAR_H + 3), lb | DI_TEXT_ALIGN_LEFT, hc, 13);
		Say(nbcSmallFont, NewSmallFont, "HEALTH", (30, -BAR_H + 17), lb | DI_TEXT_ALIGN_LEFT, Font.CR_GRAY, 4);
		double frac = clamp(hp / 100.0, 0, 1);
		Fill(Hex(0x1F2B38), 30, -4, 44, 2, lb);
		Fill(hp < 35 ? Hex(0xC8352B) : (hp < 70 ? Hex(0xF2A93B) : Hex(0x58B04A)), 30, -4, 44 * frac, 2, lb);
		let armor = mo.FindInventory("BasicArmor");
		int ap = armor ? armor.Amount : 0;
		if (ap > 0)
		{
			DrawImage("ARM1A0", (90, -5), lb | DI_ITEM_CENTER_BOTTOM, 1.0, (14, 12));
			Say(nbcBigFont, BigFont, String.Format("%d", ap), (100, -BAR_H + 7), lb | DI_TEXT_ALIGN_LEFT, Font.CR_LIGHTBLUE, 9);
			Say(nbcSmallFont, NewSmallFont, "VEST", (100, -BAR_H + 17), lb | DI_TEXT_ALIGN_LEFT, Font.CR_GRAY, 4);
		}

		// the pouches and the debris, in the middle
		let pawn = NBC_Player(mo);
		int kits = mo.CountInv("NBC_Medkit"), bottles = mo.CountInv("MolotovAmmo");
		double x = -88;
		if (kits > 0)
		{
			DrawImage("MEDIA0", (x, -4), cb | DI_ITEM_CENTER_BOTTOM, 1.0, (14, 14));
			Say(nbcBigFont, BigFont, String.Format("%d", kits), (x + 9, -BAR_H + 9), cb | DI_TEXT_ALIGN_LEFT, Font.CR_WHITE, 9);
		}
		x += 30;
		if (bottles > 0)
		{
			DrawImage("MOLPA0", (x, -4), cb | DI_ITEM_CENTER_BOTTOM, 1.0, (14, 16));
			Say(nbcBigFont, BigFont, String.Format("%d", bottles), (x + 9, -BAR_H + 9), cb | DI_TEXT_ALIGN_LEFT, Font.CR_ORANGE, 9);
		}
		// the grenades, with their keys
		static const String nades[] = { "NBC_Flashbang", "NBC_SmokeGrenade" };
		static const String nadeIcons[] = { "NFBGA0", "NSMGA0" };
		static const String nadeKeys[] = { "+nbc_flashbang", "+nbc_smoke" };
		for (int i = 0; i < 2; i++)
		{
			x += 30;
			int n = mo.CountInv(nades[i]);
			if (n <= 0) continue;
			DrawImage(nadeIcons[i], (x, -4), cb | DI_ITEM_CENTER_BOTTOM, 1.0, (10, 18));
			Say(nbcBigFont, BigFont, String.Format("%d", n), (x + 8, -BAR_H + 9), cb | DI_TEXT_ALIGN_LEFT, i == 0 ? Font.CR_WHITE : Font.CR_GRAY, 9);
			Say(nbcSmallFont, NewSmallFont, NBC_KeyName(nadeKeys[i]), (x + 8, -BAR_H + 19), cb | DI_TEXT_ALIGN_LEFT, Font.CR_DARKGRAY, 4);
		}
		if (pawn)
		{
			int sel = pawn.NBC_GetSelectedDebris();
			int n = pawn.NBC_GetDebrisCount(sel);
			static const String icons[] = { "BRKPA0", "HBRKA0", "CNCKA0", "MOLPA0" };
			static const String names[] = { "BRICK", "HALF BRICK", "CONCRETE", "BOTTLE" };
			x += 34;
			DrawImage(icons[clamp(sel, 0, 3)], (x, -6), cb | DI_ITEM_CENTER_BOTTOM, n > 0 ? 1.0 : 0.35, (16, 12));
			Say(nbcBigFont, BigFont, String.Format("%d/%d", pawn.NBC_GetTotalDebris(), pawn.NBC_GetDebrisCarryLimit()), (x + 10, -BAR_H + 9),
				cb | DI_TEXT_ALIGN_LEFT, n > 0 ? Font.CR_TAN : Font.CR_DARKGRAY, 9);
			Say(nbcSmallFont, NewSmallFont, names[clamp(sel, 0, 3)] .. " (G)", (x + 10, -BAR_H + 19), cb | DI_TEXT_ALIGN_LEFT, Font.CR_GRAY, 4);
		}

		// the keys you carry (mapmarks.zs: the doors they open wear their colour)
		x += 48;
		for (let it = mo.Inv; it; it = it.Inv)
		{
			if (!(it is "Key")) continue;
			String spr = it is "RedCard" ? "RKEYA0" : (it is "BlueCard" ? "BKEYA0" : (it is "YellowCard" ? "YKEYA0" : ""));
			if (spr != "") DrawImage(spr, (x, -5), cb | DI_ITEM_CENTER_BOTTOM, 1.0, (12, 16));
			else DrawInventoryIcon(it, (x, -BAR_H / 2), cb | DI_ITEM_CENTER, 1.0, (12, 16));
			x += 13;
		}

		// the weapon: its picture, the magazine and the reserve
		let w = CPlayer.ReadyWeapon;
		if (!w) return;
		DrawInventoryIcon(w, (-118, -BAR_H / 2), rb | DI_ITEM_CENTER, 1.0, (40, 20));
		int item = NBC_Cat.ItemOfClass(w.GetClass());
		String wname = item >= 0 ? NBC_Cat.ITEM_NAME[item] : w.GetTag();
		Say(nbcSmallFont, NewSmallFont, wname.MakeUpper(), (-4, -BAR_H + 2), rb | DI_TEXT_ALIGN_RIGHT, Font.CR_GRAY, 5);
		let rw = NBC_ReloadWeapon(w);
		if (rw && rw.Ammo1 && rw.Ammo2)
		{
			int mag = rw.Ammo1.Amount, cap = rw.Ammo1.MaxAmount, res = rw.Ammo2.Amount;
			int mc = mag == 0 || mag * 4 <= cap ? Font.CR_RED : (mag * 2 <= cap ? Font.CR_GOLD : Font.CR_WHITE);
			Say(nbcSmallFont, NewSmallFont, String.Format("/ %d", res), (-4, -BAR_H + 13), rb | DI_TEXT_ALIGN_RIGHT, Font.CR_GRAY, 8);
			Say(nbcBigFont, BigFont, String.Format("%d", mag), (-34, -BAR_H + 9), rb | DI_TEXT_ALIGN_RIGHT, mc, 14);
			if (mag == 0 && (level.maptime / 12) % 2)
				Say(nbcBigFont, BigFont, "RELOAD (R)", (0, -BAR_H - 12), cb | DI_TEXT_ALIGN_CENTER, Font.CR_RED, 8);
		}
		else if (w.Ammo1)
			Say(nbcBigFont, BigFont, String.Format("%d", w.Ammo1.Amount), (-34, -BAR_H + 9), rb | DI_TEXT_ALIGN_RIGHT, Font.CR_ORANGE, 14);
	}

	// Case and raid readout, top left (PLAN M2 vertical slice).
	// the readout's lines, gathered first so the panel behind them can be sized (owner playtest: the text floated)
	Array<String> rlText;
	Array<int> rlColor, rlY;
	Array<double> rlScale;

	void Line(String text, int cr, double scale, int y)
	{
		rlText.Push(text); rlColor.Push(cr); rlScale.Push(scale); rlY.Push(y);
	}

	// a slate panel with an amber rule along its top, like the precinct screens
	void HudPanel(double x, double y, double w, double h, int flags, double alpha = 1.0)
	{
		Fill(Hex(0x080B10, int(200 * alpha)), x, y, w, h, flags);
		Fill(Hex(0x8A5E1E, int(255 * alpha)), x, y, w, 1, flags);
	}

	void DrawNBCCase()
	{
		let rd = NBC_RunData.Find();
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (!rd || !rm || !nbcSmallFont || (!rd.caseActive && !rd.raidActive)) return;
		rlText.Clear(); rlColor.Clear(); rlScale.Clear(); rlY.Clear();
		int y = 4;
		int squadY = -1;
		let dept = NBC_Department.Find();
		if (rm.IsRaidMap(rd))
		{
			let g = rm.GangAt(rd.raidGang);
			Line(rm.TurfTitle(rd.raidDistrict) .. (g ? "  -  " .. g.name : ""), g ? g.TextColor() : Font.CR_WHITE, 0.4, y);
			y += 7;
			// the hour (clock.zs) and the day's event, if it's this raid's
			String when = NBC_Clock.WindowLine(rd.raidWindow);
			if (rd.raidEvent > NBC_Clock.EV_NONE && rd.raidEvent < NBC_Clock.EV_COUNT) when = when .. "  -  " .. NBC_Clock.EV_NAME[rd.raidEvent];
			Line(when, rd.raidEvent ? Font.CR_GOLD : Font.CR_GRAY, 0.4, y);
			y += 7;
			// the flashlight (F): on, or a reminder after dark
			let np = NBC_Player(CPlayer ? CPlayer.mo : null);
			bool dark = rd.raidWindow == NBC_Clock.W_DUSK || rd.raidWindow == NBC_Clock.W_NIGHT || rd.raidEvent == NBC_Clock.EV_BLACKOUT;
			if (np && np.nbcFlashlightOn) { Line("Flashlight ON", Font.CR_YELLOW, 0.4, y); y += 7; }
			else if (dark) { Line("Flashlight off (F)", Font.CR_DARKGRAY, 0.4, y); y += 7; }
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
			Line(lead, lc, 0.4, y);
			y += 7;
			// shot down: the ambush round the wreck
			if (rd.raidMode == NBC_Motor.MODE_CRASH)
			{
				Line(rd.crashClear ? "CRASH SITE: the way out is clear - get to the exit" :
					String.Format("CRASH SITE: hold out (wave %d of %d)", rd.crashWave, NBC_Motor.CRASH_WAVES), rd.crashClear ? Font.CR_GREEN : Font.CR_ORANGE, 0.4, y);
				y += 7;
			}
			int left = 0;
			for (int i = 0; i < rm.crew.Size(); i++) if (rm.crew[i] && rm.crew[i].health > 0) left++;
			Line(String.Format("Crew left %d", left), Font.CR_LIGHTBLUE, 0.4, y);
			y += 8;
			if (rm.squad.Size()) { squadY = y; y += 30; }
			// each fireteam's order and rules of engagement; ">" marks who your keys talk to
			if (rm.squad.Size() && rd.teamOrder.Size() == NBC_Orders.TEAMS)
				for (int t = 0; t < NBC_Orders.TEAMS; t++)
				{
					if (!NBC_Orders.TeamSize(rd, t)) continue;
					bool talking = rd.cmdTeam == NBC_Orders.CT_ALL || rd.cmdTeam - 1 == t;
					String line = String.Format("%s%s  %s  %s", talking ? "> " : "  ", NBC_Orders.TEAM_NAME[t],
						NBC_Orders.ORDER_NAME[rd.teamOrder[t]], NBC_Orders.ROE_NAME[rd.teamROE[t]]);
					if (rd.teamOrder[t] == NBC_Orders.ORD_ADVANCE) line = line .. String.Format("  (%d wp)", NBC_Orders.WaypointCount(rd, t));
					Line(line, t == NBC_Orders.TEAM_ALPHA ? Font.CR_CYAN : Font.CR_GOLD, 0.34, y);
					y += 6;
				}
			y += 2;
		}
		if (rd.caseActive)
		{
			Line(String.Format("Day %d/%d   Strikes %d/%d   $%d", rd.day, NBC_RunData.MAX_DAYS, rd.strikes, NBC_RunData.MAX_STRIKES, rd.cash), Font.CR_GRAY, 0.4, y);
			y += 7;
		}
		// at the precinct: today's event
		if (rd.caseActive && !rd.raidActive && rd.evKind > NBC_Clock.EV_NONE && rd.evKind < NBC_Clock.EV_COUNT)
		{
			Line(String.Format("TODAY: %s in %s, %s", NBC_Clock.EV_NAME[rd.evKind], rm.TurfTitle(rd.evDistrict), NBC_Clock.WindowLine(rd.evWindow)),
				rd.evKind == NBC_Clock.EV_PINNED ? Font.CR_RED : Font.CR_GOLD, 0.4, y);
			y += 7;
		}
		if (!rlText.Size()) return;

		// the panel, as wide as the longest line (or the squad strip)
		double w = squadY >= 0 ? rm.squad.Size() * 26 + 2 : 0;
		for (int i = 0; i < rlText.Size(); i++) w = max(w, NewSmallFont.StringWidth(rlText[i]) * rlScale[i]);
		HudPanel(0, 0, w + 8, y + 2, DI_SCREEN_LEFT_TOP);
		for (int i = 0; i < rlText.Size(); i++)
			DrawString(nbcSmallFont, rlText[i], (4, rlY[i]), DI_TEXT_ALIGN_LEFT, rlColor[i], scale: (rlScale[i], rlScale[i]));

		// the squad strip: a portrait, a health bar, the name (Hamburger Hill's squad panel)
		if (squadY >= 0)
			for (int i = 0; i < rm.squad.Size(); i++)
			{
				let a = NBC_Ally(rm.squad[i]);
				if (!a) continue;
				let o = dept ? dept.OfficerById(a.officerId) : null;
				double x = 4 + i * 26;
				int sy = squadY;
				bool down = a.health <= 0;
				Fill(Hex(0x3D5064), x - 1, sy - 1, 22, 22);
				if (o) DrawImage(o.Portrait(), (x, sy), DI_ITEM_LEFT_TOP, down ? 0.35 : 1.0, scale: (0.21, 0.21));   // 96-px portraits
				Fill(Color(255, 10, 14, 20), x, sy + 21, 20, 2);
				double frac = clamp(a.health / double(max(1, a.maxHp)), 0, 1);
				Fill(frac > 0.6 ? Color(255, 88, 176, 74) : (frac > 0.3 ? Color(255, 242, 169, 59) : Color(255, 200, 53, 43)), x, sy + 21, 20 * frac, 2);
				DrawString(nbcSmallFont, down ? "DOWN" : (o ? o.surname : a.GetTag()), (x, sy + 24), DI_TEXT_ALIGN_LEFT, down ? Font.CR_RED : Font.CR_GRAY, scale: (0.26, 0.26));
				// the fireteam letter in the corner
				int team = rd.TeamOfSlot(a.slot);
				Fill(team == NBC_Orders.TEAM_ALPHA ? Color(255, 79, 195, 217) : Color(255, 242, 169, 59), x + 14, sy, 6, 6);
				DrawString(nbcSmallFont, team == NBC_Orders.TEAM_ALPHA ? "A" : "B", (x + 15, sy), DI_TEXT_ALIGN_LEFT, Font.CR_BLACK, scale: (0.24, 0.24));
			}
	}

	// the first key bound to a command, upper case (empty if unbound)
	String NBC_KeyName(String cmd)
	{
		int k1, k2;
		[k1, k2] = Bindings.GetKeysForCommand(cmd);
		if (!k1 && !k2) return "";
		String n = Bindings.NameKeys(k1 ? k1 : k2, 0, false);
		return n.MakeUpper();
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		if (state != HUD_StatusBar && state != HUD_Fullscreen) return;
		// our readouts use fullscreen HUD space in both modes: negative coordinates count from the bottom right
		BeginHUD();
		DrawNBCBar();
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
		if (n)
		{
			double w = 0, alpha = 0;
			for (int i = 0; i < n; i++)
			{
				w = max(w, NewSmallFont.StringWidth(ord.logText[i]) * 0.36);
				alpha = max(alpha, min(1.0, ord.logTics[i] / 35.0));
			}
			HudPanel(0, -80 - (n - 1) * 7, w + 8, n * 7 + 3, DI_SCREEN_LEFT_BOTTOM, alpha);
		}
		for (int i = 0; i < n; i++)
		{
			double alpha = min(1.0, ord.logTics[i] / 35.0);
			DrawString(nbcSmallFont, ord.logText[i], (3, -78 - (n - 1 - i) * 7), DI_TEXT_ALIGN_LEFT, ord.logColor[i], alpha, scale: (0.36, 0.36));
		}
	}
}
