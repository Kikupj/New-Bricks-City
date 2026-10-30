// The front door (owner request, 2026-10-28: "add the menu splash screen and theme the main menu to match the
// game GUI"). The splash (art/new_brick_city_menu_screen.png -> graphics/NBCTITLE, tools/art/make_title_art.py)
// fills the screen, fitted to its height with a blurred copy at the sides; the buttons sit in a bar along the
// bottom in the precinct screens' look (nbcui.zs).
//
// The engine opens the main menu by name and only takes a ListMenu there (MENUDEF), so NBC_MainMenu is a
// ListMenu that hands its drawing and input to an NBC_UI screen (NBC_TitleScreen) it never opens. The same trick
// themes the engine's yes / no boxes (NBC_MessageBox, gameinfo MessageBoxClass). The help key opens How to Play
// (gameinfo HelpMenuClass).
//
//   NEW GAME     a skill (MAPINFO: Rookie, Patrol, Detective, Internal Affairs), then Checkpoint 9
//   LOAD / SAVE / OPTIONS   the engine's own screens (themed by gameinfo: colours, dim)
//   HOW TO PLAY  the keys as bound now, and the job in four panels
//   CREDITS      nbc/CREDITS.txt, scrolling
//   QUIT         the engine's quit box, with our quit lines (gameinfo QuitMessages)

class NBC_MainMenu : ListMenu
{
	NBC_TitleScreen scr;

	override void Init(Menu parent, ListMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		DontDim = true;
		DontBlur = true;
		scr = new("NBC_TitleScreen");
		scr.host = self;
		scr.registering = true;
	}

	override void Drawer() { if (scr) scr.Drawer(); }
	override void Ticker() { Super.Ticker(); if (scr) scr.ticks++; }
	override bool MenuEvent(int mkey, bool fromcontroller) { return scr ? scr.MenuEvent(mkey, fromcontroller) : Super.MenuEvent(mkey, fromcontroller); }
	override bool OnUIEvent(UIEvent ev) { return scr ? scr.OnUIEvent(ev) : Super.OnUIEvent(ev); }
	override bool MouseEvent(int type, int x, int y) { return true; }

	// back to the game (in a game only: on the title screen the menu stays up)
	void Resume()
	{
		Close();
		let m = GetCurrentMenu();
		MenuSound(m ? "menu/backup" : "menu/clear");
		if (!m) menuDelegate.MenuDismissed();
	}
}

// The splash with the buttons along the bottom. Drawn for NBC_MainMenu; never opened itself.
class NBC_TitleScreen : NBC_UI
{
	enum EId { ID_RESUME = 1, ID_NEW, ID_LOAD, ID_SAVE, ID_OPTIONS, ID_HELP, ID_CREDITS, ID_QUIT, ID_SKILL, ID_YES, ID_NO }
	enum EPopup { POP_NONE, POP_SKILL, POP_ABANDON }
	static const String SKILL_NAME[] = { "ROOKIE", "PATROL", "DETECTIVE", "INTERNAL AFFAIRS" };
	static const String SKILL_LINE[] = {
		"They hit half as hard, and every drop carries more rounds. Learn the Bricks.",
		"The job as it is.",
		"They hit harder and take more to put down.",
		"Every mistake goes on the record. Less ammo, harder hits, tougher crews." };

	NBC_MainMenu host;
	int popup;

	clearscope static bool InGame() { return gamestate == GS_LEVEL; }

	override void Activate(int id, int arg)
	{
		switch (id)
		{
		case ID_RESUME: if (host) host.Resume(); return;
		case ID_NEW:
			popup = InGame() ? POP_ABANDON : POP_SKILL;
			FocusLater(popup == POP_SKILL ? ID_SKILL : ID_NO, popup == POP_SKILL ? 1 : 0);
			return;
		case ID_YES: popup = POP_SKILL; FocusLater(ID_SKILL, 1); return;
		case ID_NO: popup = POP_NONE; return;
		case ID_SKILL:
			popup = POP_NONE;
			Menu.StartGameDirect(false, false, null, 0, clamp(arg, 0, 3));
			return;
		case ID_LOAD: Menu.SetMenu("LoadGameMenu"); return;
		case ID_SAVE: Menu.SetMenu("SaveGameMenu"); return;
		case ID_OPTIONS: Menu.SetMenu("OptionsMenu"); return;
		case ID_HELP: Menu.SetMenu("NBC_HowToPlay"); return;
		case ID_CREDITS: Menu.SetMenu("NBC_CreditsScreen"); return;
		case ID_QUIT: Menu.SetMenu("QuitMenu"); return;
		}
	}

	override bool Back()
	{
		if (popup != POP_NONE) { popup = POP_NONE; return true; }
		if (InGame() && host) host.Resume();
		return true;
	}

	// the splash: fitted to the screen's height, centred; a blurred, darkened copy fills the sides
	static void DrawSplash()
	{
		int sw = Screen.GetWidth(), sh = Screen.GetHeight();
		Screen.Clear(0, 0, sw, sh, Color(255, 0, 0, 0));
		TextureID blur = TexMan.CheckForTexture("NBCTITLB", TexMan.Type_Any);
		TextureID art = TexMan.CheckForTexture("NBCTITLE", TexMan.Type_Any);
		if (!art.IsValid()) return;
		Vector2 sz = TexMan.GetScaledSize(art);
		double k = min(sw / sz.x, sh / sz.y);
		double dw = sz.x * k, dh = sz.y * k, dx = (sw - dw) / 2, dy = (sh - dh) / 2;
		if (blur.IsValid() && dw < sw - 1)
		{
			double kb = max(sw / sz.x, sh / sz.y);
			Screen.DrawTexture(blur, false, (sw - sz.x * kb) / 2, (sh - sz.y * kb) / 2, DTA_DestWidthF, sz.x * kb, DTA_DestHeightF, sz.y * kb,
				DTA_LeftOffsetF, 0., DTA_TopOffsetF, 0.);
		}
		Screen.DrawTexture(art, false, dx, dy, DTA_DestWidthF, dw, DTA_DestHeightF, dh, DTA_LeftOffsetF, 0., DTA_TopOffsetF, 0.);
		// soften the seams into the blurred sides
		if (dw < sw - 1)
		{
			for (int i = 0; i < 12; i++)
			{
				double a = 0.5 * (1 - i / 12.0);
				int w = int(max(1, dw / 160));
				Screen.Dim(Color(255, 0, 0, 0), a, int(dx + i * w), 0, w, sh);
				Screen.Dim(Color(255, 0, 0, 0), a, int(dx + dw - (i + 1) * w), 0, w, sh);
			}
		}
	}

	override void DrawScreen()
	{
		DrawSplash();
		int sw = Screen.GetWidth(), sh = Screen.GetHeight();
		bool game = InGame();

		// the bar along the bottom, the whole width of the screen
		double top = 512;
		for (int i = 0; i < 10; i++) Screen.Dim(Color(255, 0, 0, 0), 0.06 * i, 0, PY(top - 40 + i * 4), sw, PY(top - 36 + i * 4) - PY(top - 40 + i * 4) + 1);
		Screen.Dim(RGB(C_PANEL_LO), 0.82, 0, PY(top), sw, sh - PY(top));
		Screen.Clear(0, PY(top), sw, PY(top) + max(1, int(2 * sc)), RGB(C_AMBER_DIM));

		// the buttons: RESUME and SAVE in a game only
		Array<int> ids;
		Array<String> labels;
		if (game) { ids.Push(ID_RESUME); labels.Push("RESUME"); }
		ids.Push(ID_NEW); labels.Push(game ? "NEW GAME" : "NEW GAME");
		if (game) { ids.Push(ID_SAVE); labels.Push("SAVE"); }
		ids.Push(ID_LOAD); labels.Push("LOAD");
		ids.Push(ID_OPTIONS); labels.Push("OPTIONS");
		ids.Push(ID_HELP); labels.Push("HOW TO PLAY");
		ids.Push(ID_CREDITS); labels.Push("CREDITS");
		ids.Push(ID_QUIT); labels.Push("QUIT");
		int n = ids.Size();
		double gap = 8, bw = min(150, (VW - 40 - gap * (n - 1)) / n), bh = 42;
		double bx = (VW - (bw * n + gap * (n - 1))) / 2, by = top + 18;
		registering = popup == POP_NONE;
		for (int i = 0; i < n; i++)
			Button(ids[i], 0, bx + i * (bw + gap), by, bw, bh, labels[i], true, n > 6 ? 13 : 15, ids[i] == ID_NEW || ids[i] == ID_RESUME ? C_AMBER : -1);
		Text(NewSmallFont, Font.CR_GRAY, 18, VH - 22, "ARROWS / MOUSE  select     ENTER / CLICK  use     F1  how to play", 10);
		Text(NewSmallFont, Font.CR_DARKGRAY, VW - 18, VH - 22, "New Bricks City  v1.0  -  for UZDoom", 10, 2);
		registering = true;

		if (popup == POP_ABANDON)
		{
			Fill(0, 0, VW, VH, 0, 0.6);
			double w = 520, h = 190, x = (VW - w) / 2, y = 170;
			Panel(x, y, w, h, "NEW GAME");
			Wrap(NewSmallFont, Font.CR_WHITE, x + 24, y + 48, w - 48, "Walk away from this game? Anything since your last save is lost. Your officers on the roster stay with the department.", 12, 4);
			Button(ID_YES, 0, x + w - 24 - 300, y + h - 56, 140, 36, "NEW GAME", true, 14, C_AMBER);
			Button(ID_NO, 0, x + w - 24 - 140, y + h - 56, 140, 36, "CANCEL", true, 14);
		}
		else if (popup == POP_SKILL)
		{
			Fill(0, 0, VW, VH, 0, 0.6);
			double w = 600, h = 352, x = (VW - w) / 2, y = 110;
			Panel(x, y, w, h, "HOW HARD DO THE BRICKS HIT BACK?");
			for (int i = 0; i < 4; i++)
			{
				double ry = y + 50 + i * 64;
				Button(ID_SKILL, i, x + 24, ry, 210, 48, SKILL_NAME[i], true, i == 3 ? 13 : 16, i == 1 ? C_AMBER : -1);
				Wrap(NewSmallFont, IsFocus(ID_SKILL, i) ? Font.CR_GOLD : Font.CR_GRAY, x + 252, ry + 8, w - 276, SKILL_LINE[i], 11, 3);
			}
			Text(NewSmallFont, Font.CR_DARKGRAY, x + 24, y + h - 38, "A new game starts at Checkpoint 9. Open a case at the raid board.", 11);
			Button(ID_NO, 0, x + w - 24 - 130, y + h - 46, 130, 32, "CANCEL", true, 13);
		}
	}
}

// The engine's yes / no and notice boxes (quit, overwrite a save, load a game) in the precinct panel.
class NBC_MessageBox : MessageBoxMenu
{
	NBC_BoxPainter scr;
	String text;

	override void Init(Menu parent, String message, int messagemode, bool playsound, Name cmd, voidptr native_handler)
	{
		Super.Init(parent, message, messagemode, playsound, cmd, native_handler);
		text = Stringtable.Localize(message);
		// the engine adds "(press y to quit)" and the like: the buttons say it
		int cut = text.IndexOf("\n\n(");
		if (cut < 0) cut = text.IndexOf("\n(");
		if (cut > 0) text = text.Left(cut);
		scr = new("NBC_BoxPainter");
		scr.box = self;
		scr.registering = true;
	}

	override void Drawer() { if (scr) scr.Drawer(); }
	override void Ticker() { Super.Ticker(); if (scr) scr.ticks++; }

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mMessageMode == 0 && (mkey == MKEY_Left || mkey == MKEY_Right))
		{
			MenuSound("menu/cursor");
			messageSelection = messageSelection == 0 ? 1 : 0;
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		if (!scr) return false;
		scr.Layout();
		int i = scr.RegionAt(scr.VX(x), scr.VY(y));
		if (mMessageMode == 1)
		{
			if (type == MOUSE_Release && i >= 0) return MenuEvent(MKEY_Enter, true);
			return true;
		}
		if (i >= 0) messageSelection = scr.rarg[i];
		if (type == MOUSE_Release && i >= 0) return MenuEvent(MKEY_Enter, true);
		return true;
	}
}

class NBC_BoxPainter : NBC_UI
{
	NBC_MessageBox box;

	override void DrawScreen()
	{
		if (!box) return;
		Fill(0, 0, VW, VH, 0, 0.35);
		double w = 540, x = (VW - w) / 2;
		// measure the text first: the panel fits it
		Array<String> words;
		double lines = 1, lw = 0;
		box.text.Split(words, " ");
		for (int i = 0; i < words.Size(); i++)
		{
			double ww = TextWidth(NewSmallFont, words[i] .. " ", 13);
			if (lw + ww > w - 56 || words[i].IndexOf("\n") >= 0) { lines++; lw = ww; }
			else lw += ww;
		}
		double h = 110 + lines * 17, y = (VH - h) / 2;
		Panel(x, y, w, h, box.mMessageMode == 0 ? "CONFIRM" : "NOTICE");
		Wrap(NewSmallFont, Font.CR_WHITE, x + 28, y + 46, w - 56, box.text, 13, 4);
		if (box.mMessageMode == 0)
		{
			focusSet = true;
			focusId = 1;
			focusArg = box.messageSelection == 1 ? 1 : 0;
			Button(1, 0, x + w - 28 - 300, y + h - 54, 140, 36, "YES", true, 15, C_AMBER);
			Button(1, 1, x + w - 28 - 140, y + h - 54, 140, 36, "NO", true, 15);
		}
		else
		{
			focusSet = true; focusId = 1; focusArg = 0;
			Button(1, 0, x + w - 28 - 140, y + h - 54, 140, 36, "OK", true, 15, C_AMBER);
		}
	}
}

// How to play: the keys as they're bound right now, and the job. F1 (gameinfo HelpMenuClass) or the main menu.
class NBC_HowToPlay : NBC_UI
{
	override bool KeepsRunning() { return false; }

	static String Keys(String cmd)
	{
		int k1, k2;
		[k1, k2] = Bindings.GetKeysForCommand(cmd);
		if (!k1 && !k2) return "unbound";
		String s = Bindings.NameKeys(k1 ? k1 : k2, 0, false);
		return s.MakeUpper();
	}

	override void Activate(int id, int arg) { if (id == 1) Leave(); }

	override void DrawScreen()
	{
		if (InGameBackdrop()) Fill(0, 0, VW, VH, C_BG, 0.86);
		else { NBC_TitleScreen.DrawSplash(); Fill(0, 0, VW, VH, C_BG, 0.82); }
		TopBar("HOW TO PLAY", "THE KEYS AS THEY'RE BOUND NOW  -  CHANGE THEM IN OPTIONS, CUSTOMIZE CONTROLS");

		// the keys
		Panel(16, 70, 420, 470, "KEYS");
		static const String what[] = {
			"Move", "Fire", "Reload", "Use / talk", "Jump", "Crouch", "Flashlight", "Throw debris (hold)", "Next debris", "Flashbang (hold)", "Smoke grenade (hold)",
			"Talk to: all / Alpha / Bravo", "Regroup on me", "Hold", "Move there (aim)", "Advance on waypoints", "Rules of engagement",
			"Go codes X / Y / Z", "Command map" };
		static const String cmd[] = {
			"+forward", "+attack", "+reload", "+use", "+jump", "+crouch", "netevent nbc_flashlight", "+nbc_throw", "netevent nbc_debris_next", "+nbc_flashbang", "+nbc_smoke",
			"nbc_cmd_team", "nbc_cmd_follow", "nbc_cmd_hold", "nbc_cmd_move", "nbc_cmd_advance", "nbc_cmd_roe",
			"nbc_cmd_go_x", "nbc_cmd_map" };
		for (int i = 0; i < what.Size(); i++)
		{
			double y = 104 + i * 22;
			if (i == 11) Fill(30, y - 5, 392, 1, C_PANEL_HI);
			Text(NewSmallFont, i >= 11 ? Font.CR_GOLD : Font.CR_GRAY, 30, y, what[i], 11);
			String k = Keys(cmd[i]);
			if (i == 0) k = String.Format("%s %s %s %s", Keys("+forward"), Keys("+moveleft"), Keys("+back"), Keys("+moveright"));
			else if (i == 17) k = String.Format("%s  %s  %s", Keys("nbc_cmd_go_x"), Keys("nbc_cmd_go_y"), Keys("nbc_cmd_go_z"));
			Text(NewSmallFont, k == "UNBOUND" ? Font.CR_DARKGRAY : Font.CR_WHITE, 422, y, k, 11, 2);
		}
		Text(NewSmallFont, Font.CR_DARKGRAY, 30, 104 + 19 * 22, "Weapons: 1 fists and blades, 2 pistols, 3 shotguns, 4 SMGs, 5 rifles, 6 Molotov", 10);

		// the job
		double x = 450, w = VW - 16 - x;
		Panel(x, 70, w, 470, "THE JOB");
		static const String head[] = { "THE CASE", "PLANNING A RAID", "ON THE BLOCK", "BETWEEN RAIDS" };
		static const String body[] = {
			"Four gangs hold eight districts of the Bricks. You have 30 days. Topple three and the Landlord's tower, the Crown, opens: take it to close the case. Backing at zero is a strike; three strikes and Internal Affairs takes your badge. Talk to Captain Harrow or use the raid board at Checkpoint 9.",
			"Pick a district on the raid board. On the deploy screen pick up to four officers, split them into Alpha and Bravo, and kit everyone out of the Evidence Locker. READY, then talk to Rook: choose the hour, the way in (street or rooftop) and the motorcade.",
			"Take down the gang's leader and get to the exit to topple them. Leaving with the leader alive is a retreat. Command your squad with the keys on the left. A hit that would kill you is OFFICER DOWN: a strike.",
			"Promote and recruit officers, sell what you seized and buy supplies, repair and buy vehicles, or close the day to let the wounded heal. Each morning, check the radio for the day's event." };
		double y = 104;
		for (int i = 0; i < 4; i++)
		{
			Text(BigFont, Font.CR_GOLD, x + 18, y, head[i], 13);
			y += 20;
			y += Wrap(NewSmallFont, Font.CR_WHITE, x + 18, y, w - 36, body[i], 11, 3) + 12;
		}
		Button(1, 0, VW - 16 - 160, VH - 52, 160, 38, "BACK", true, 15, C_AMBER);
		Hints("ESC / RIGHT CLICK  back");
	}

	clearscope static bool InGameBackdrop() { return gamestate == GS_LEVEL; }
}

// The credits: nbc/CREDITS.txt, scrolling by itself; the wheel or the arrows take over.
class NBC_CreditsScreen : NBC_UI
{
	Array<String> lines;
	double scrollY;
	int idle;

	override bool KeepsRunning() { return false; }

	override void Init(Menu parent)
	{
		Super.Init(parent);
		int lump = Wads.CheckNumForFullName("CREDITS.txt");
		String all = lump >= 0 ? Wads.ReadLump(lump) : "NEW BRICKS CITY";
		all.Split(lines, "\n");
		for (int i = 0; i < lines.Size(); i++) lines[i].Replace("\r", "");
	}

	override void Activate(int id, int arg) { if (id == 1) Leave(); }
	override void Scroll(int dir) { scrollY = max(0, scrollY + dir * 80); idle = 0; }

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Up) { Scroll(-1); return true; }
		if (mkey == MKEY_Down) { Scroll(1); return true; }
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Ticker()
	{
		Super.Ticker();
		if (++idle > 70) scrollY += 0.6;
	}

	override void DrawScreen()
	{
		NBC_TitleScreen.DrawSplash();
		Fill(0, 0, VW, VH, C_BG, 0.8);
		TopBar("CREDITS", "NEW BRICKS CITY  -  A UZDOOM MOD");
		double x = 40, y = 74, w = VW - 80, h = 466;
		Inset(x, y, w, h);
		double lh = 14, total = lines.Size() * lh;
		if (scrollY > total) scrollY = 0;
		int first = int(scrollY / lh);
		double off = scrollY - first * lh;
		for (int i = first; i < lines.Size(); i++)
		{
			double ly = y + 10 + (i - first) * lh - off;
			if (ly > y + h - 20) break;
			if (ly < y + 4) continue;
			String l = lines[i];
			bool head = l.Left(3) == "== " || l.Left(5) == "// ==" || (i > 0 && lines[i - 1].Left(5) == "-----") || i == 0;
			if (l.Left(5) == "-----" || l.Left(5) == "=====") { Fill(x + 16, ly + 6, w - 32, 1, C_PANEL_HI); continue; }
			Text(NewSmallFont, head ? Font.CR_GOLD : Font.CR_WHITE, x + 16, ly, l, 10);
		}
		Button(1, 0, VW - 16 - 160, VH - 52, 160, 38, "BACK", true, 15, C_AMBER);
		Hints("WHEEL / ARROWS  scrollY     ESC  back");
	}
}
