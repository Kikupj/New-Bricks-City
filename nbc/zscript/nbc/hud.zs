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
				if (o) DrawImage(o.Portrait(), (x, y), DI_ITEM_LEFT_TOP, down ? 0.35 : 1.0, scale: (0.42, 0.42));
				Fill(Color(255, 10, 14, 20), x, y + 21, 20, 2);
				double frac = clamp(a.health / double(max(1, a.maxHp)), 0, 1);
				Fill(frac > 0.6 ? Color(255, 88, 176, 74) : (frac > 0.3 ? Color(255, 242, 169, 59) : Color(255, 200, 53, 43)), x, y + 21, 20 * frac, 2);
				DrawString(nbcSmallFont, down ? "DOWN" : (o ? o.surname : a.GetTag()), (x, y + 24), DI_TEXT_ALIGN_LEFT, down ? Font.CR_RED : Font.CR_GRAY, scale: (0.26, 0.26));
			}
			if (rm.squad.Size()) y += 30;
		}
		if (rd.caseActive)
			DrawString(nbcSmallFont, String.Format("Day %d/%d   Strikes %d/%d   $%d", rd.day, NBC_RunData.MAX_DAYS,
				rd.strikes, NBC_RunData.MAX_STRIKES, rd.cash), (3, y), DI_TEXT_ALIGN_LEFT, Font.CR_GRAY, scale: (0.4, 0.4));
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
	}
}
