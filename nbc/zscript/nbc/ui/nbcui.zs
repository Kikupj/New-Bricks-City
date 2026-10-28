// The precinct's screens (PLAN.md M7c): a shared look and shared controls for the terminal, the deploy screen
// and the after-action report. Layouts and the screen flow follow Hamburger Hill (docs/hamburger-hill-analysis.md:
// mechanics and layouts only); the look is ours: slate-blue precinct panels, amber for whatever is selected.
//
// Everything is laid out on a 960x600 canvas, scaled and centered on the real screen. Each frame a screen
// draws itself and registers its controls (Button / Region); input then works on those:
//   mouse      hover to highlight, click to select or use, wheel to scroll, right click to go back (hovering
//              never selects anything: owner playtest, the pointer crossing a list on its way to a button
//              picked whatever it passed over)
//   keyboard   arrows move to the nearest control that way, Enter uses it, Esc goes back,
//              Q / E (or Tab) switch tabs where there are tabs
// Screens only read the case state; every change goes out as a netevent (Send), so the menus never pause the
// game while they're open (the changes have to be processed for the screen to show them).

class NBC_UI : GenericMenu
{
	const VW = 960;
	const VH = 600;

	// palette
	const C_BG = 0x0A0E13;
	const C_PANEL = 0x1F2B38;
	const C_PANEL_HI = 0x3D5064;
	const C_PANEL_LO = 0x080B10;
	const C_INSET = 0x0B1016;
	const C_INSET_LINE = 0x2B394A;
	const C_PLATE = 0x2C3B4D;
	const C_AMBER = 0xF2A93B;
	const C_AMBER_DIM = 0x8A5E1E;
	const C_RED = 0xC8352B;
	const C_GREEN = 0x58B04A;
	const C_BLUE = 0x3F7CC4;
	const C_GREY = 0x6A7684;

	double sc, ox, oy;
	// the controls registered by the last frame
	Array<double> rx, ry, rw, rh;
	Array<int> rid, rarg;
	bool registering;
	// the selected control (kept by id and arg across frames)
	int focusId, focusArg;
	bool focusSet;
	int wantId, wantArg;      // focus this control once it shows up (after a netevent has run)
	int mouseX, mouseY;
	bool mouseOn;
	int hoverId, hoverArg;    // what's under the pointer (highlighted only)
	int ticks;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		DontDim = true;
		DontBlur = true;
		if (KeepsRunning()) menuactive = Menu.OnNoPause;     // netevents have to run while a screen is open
		registering = true;
	}

	// false: the game pauses while the screen is up, like any menu (help, credits: they change nothing)
	virtual bool KeepsRunning() { return true; }

	override void Ticker()
	{
		Super.Ticker();
		ticks++;
		if (menuactive == Menu.On && KeepsRunning()) menuactive = Menu.OnNoPause;
	}

	// ------------------------------------------------------------ coordinates

	void Layout()
	{
		double w = Screen.GetWidth(), h = Screen.GetHeight();
		sc = max(0.01, min(w / VW, h / VH));
		ox = (w - VW * sc) / 2;
		oy = (h - VH * sc) / 2;
	}
	int PX(double v) { return int(ox + v * sc); }
	int PY(double v) { return int(oy + v * sc); }
	double VX(int real) { return (real - ox) / sc; }
	double VY(int real) { return (real - oy) / sc; }

	static Color RGB(int c, int a = 255) { return Color(a, (c >> 16) & 255, (c >> 8) & 255, c & 255); }

	// ------------------------------------------------------------ drawing

	void Fill(double x, double y, double w, double h, int c, double alpha = 1.0)
	{
		int x0 = PX(x), y0 = PY(y), x1 = PX(x + w), y1 = PY(y + h);
		if (x1 <= x0 || y1 <= y0) return;
		if (alpha >= 1.0) Screen.Clear(x0, y0, x1, y1, RGB(c));
		else Screen.Dim(RGB(c), alpha, x0, y0, x1 - x0, y1 - y0);
	}

	void Frame(double x, double y, double w, double h, int c, double t = 1, double alpha = 1.0)
	{
		Fill(x, y, w, t, c, alpha);
		Fill(x, y + h - t, w, t, c, alpha);
		Fill(x, y + t, t, h - 2 * t, c, alpha);
		Fill(x + w - t, y + t, t, h - 2 * t, c, alpha);
	}

	// the backdrop: a desaturated precinct wall in deep blue, a vignette at the edges
	void Backdrop()
	{
		Screen.Clear(0, 0, Screen.GetWidth(), Screen.GetHeight(), RGB(C_BG));
		TextureID wall = TexMan.CheckForTexture("BRICK12", TexMan.Type_Any);
		if (wall.IsValid())
		{
			double t = 96;
			for (double y = 0; y < VH; y += t)
				for (double x = 0; x < VW; x += t * 2)
					Screen.DrawTexture(wall, false, PX(x), PY(y), DTA_DestWidthF, t * 2 * sc + 1, DTA_DestHeightF, t * sc + 1,
						DTA_Desaturate, 255, DTA_ColorOverlay, RGB(0x060A10, 222), DTA_LeftOffsetF, 0., DTA_TopOffsetF, 0.);
		}
		for (int i = 0; i < 6; i++)
		{
			double a = 0.10 + i * 0.03;
			Fill(0, 0, VW, 6 - i, 0, a);
			Fill(0, VH - 6 + i, VW, 6 - i, 0, a);
		}
	}

	// a beveled panel with rivets, and an optional stencil title in its top left corner
	void Panel(double x, double y, double w, double h, String title = "")
	{
		Fill(x + 3, y + 3, w, h, 0, 0.5);
		Fill(x, y, w, h, C_PANEL);
		Fill(x, y, w, 2, C_PANEL_HI);
		Fill(x, y, 2, h, C_PANEL_HI);
		Fill(x, y + h - 2, w, 2, C_PANEL_LO);
		Fill(x + w - 2, y, 2, h, C_PANEL_LO);
		// rivets
		Fill(x + 5, y + 5, 3, 3, C_PANEL_LO); Fill(x + w - 8, y + 5, 3, 3, C_PANEL_LO);
		Fill(x + 5, y + h - 8, 3, 3, C_PANEL_LO); Fill(x + w - 8, y + h - 8, 3, 3, C_PANEL_LO);
		if (title != "") Text(BigFont, Font.CR_WHITE, x + 14, y + 8, title, 15, 0, 0.9);
	}

	// a dark recessed slot
	void Inset(double x, double y, double w, double h, int line = -1)
	{
		Fill(x, y, w, h, C_INSET);
		Frame(x, y, w, h, line >= 0 ? line : C_INSET_LINE);
		Fill(x + 1, y + 1, w - 2, 1, 0, 0.6);
	}

	// a label plate (the "KILLS" boxes)
	void Plate(double x, double y, double w, double h, String s, double size = 14)
	{
		Fill(x, y, w, h, C_PLATE);
		Frame(x, y, w, h, C_PANEL_HI);
		Fill(x + 1, y + h - 2, w - 2, 1, C_PANEL_LO);
		Text(BigFont, Font.CR_WHITE, x + w / 2, y + (h - size) / 2, s, size, 1);
	}

	// the small font reads small next to the stencil titles (owner feedback): it's drawn a size up everywhere
	const SMALL_GROW = 1.15;
	static double Grow(Font f, double size) { return f == NewSmallFont ? size * NBC_UI.SMALL_GROW : size; }

	// size: the text's height on the canvas. align 0 left, 1 center, 2 right
	double Text(Font f, int cr, double x, double y, String s, double size = 12, int align = 0, double alpha = 1.0)
	{
		if (!f || s == "") return 0;
		size = Grow(f, size);
		// a leading $ would make the engine look the text up in the string table ("$620" -> "620")
		if (s.Left(1) == "$") s = "\c-" .. s;
		double k = size / max(1, f.GetHeight());
		double w = f.StringWidth(s) * k;
		if (align == 1) x -= w / 2;
		else if (align == 2) x -= w;
		Screen.DrawText(f, cr, ox + x * sc, oy + y * sc, s, DTA_ScaleX, k * sc, DTA_ScaleY, k * sc, DTA_Alpha, alpha);
		return w;
	}
	// money: the stencil font has no dollar sign, so the sum is drawn in the small font, a size up
	double MoneyText(int cr, double x, double y, int v, double size = 16, int align = 0, bool sign = false)
	{
		String s = NBC_Cat.Money(v);
		if (sign && v >= 0) s = "+" .. s;
		return Text(NewSmallFont, cr, x, y, s, size, align);
	}
	double TextWidth(Font f, String s, double size) { return f ? f.StringWidth(s) * Grow(f, size) / max(1, f.GetHeight()) : 0; }

	// text wrapped to a width; returns the height used
	double Wrap(Font f, int cr, double x, double y, double w, String s, double size = 11, double lineGap = 3)
	{
		Array<String> words;
		s.Split(words, " ");
		String line = "";
		double yy = y;
		for (int i = 0; i < words.Size(); i++)
		{
			String test = line == "" ? words[i] : line .. " " .. words[i];
			if (line != "" && TextWidth(f, test, size) > w)
			{
				Text(f, cr, x, yy, line, size);
				yy += Grow(f, size) + lineGap;
				line = words[i];
			}
			else line = test;
		}
		if (line != "") { Text(f, cr, x, yy, line, size); yy += Grow(f, size) + lineGap; }
		return yy - y;
	}

	// a graphic fitted inside a box, keeping its shape (sprite offsets ignored)
	void Pic(String name, double x, double y, double w, double h, double alpha = 1.0, bool grey = false, int tint = -1, double tintA = 0)
	{
		TextureID t = TexMan.CheckForTexture(name, TexMan.Type_Any);
		if (!t.IsValid()) return;
		Vector2 sz = TexMan.GetScaledSize(t);
		if (sz.x <= 0 || sz.y <= 0) return;
		double k = min(w / sz.x, h / sz.y);
		double dw = sz.x * k, dh = sz.y * k;
		Color ov = tint >= 0 ? RGB(tint, int(255 * tintA)) : Color(0, 0, 0, 0);
		Screen.DrawTexture(t, false, ox + (x + (w - dw) / 2) * sc, oy + (y + (h - dh) / 2) * sc,
			DTA_DestWidthF, dw * sc, DTA_DestHeightF, dh * sc, DTA_LeftOffsetF, 0., DTA_TopOffsetF, 0.,
			DTA_Alpha, alpha, DTA_Desaturate, grey ? 255 : 0, DTA_ColorOverlay, ov);
	}

	// a segmented bar (HH's support meter)
	void Bar(double x, double y, double w, double h, double frac, int c, int segs = 10)
	{
		Inset(x, y, w, h);
		double sw = (w - 4) / segs;
		int lit = int(ceil(clamp(frac, 0, 1) * segs - 0.001));
		for (int i = 0; i < segs; i++)
			Fill(x + 2 + i * sw + 1, y + 2, sw - 2, h - 4, i < lit ? c : C_PANEL, i < lit ? 1.0 : 0.6);
	}

	// a red ink stamp across a portrait
	void Stamp(double cx, double cy, String s, int c, double size = 14)
	{
		double w = TextWidth(BigFont, s, size) + 10;
		Frame(cx - w / 2, cy - size / 2 - 4, w, size + 8, c, 2);
		Text(BigFont, Font.CR_UNTRANSLATED, cx, cy - size / 2, s, size, 1);
		Text(BigFont, c == C_RED ? Font.CR_RED : (c == C_GREEN ? Font.CR_GREEN : Font.CR_GOLD), cx, cy - size / 2, s, size, 1);
	}

	// ------------------------------------------------------------ controls

	// register a clickable area (no drawing)
	void Region(int id, int arg, double x, double y, double w, double h)
	{
		if (!registering) return;
		rx.Push(x); ry.Push(y); rw.Push(w); rh.Push(h); rid.Push(id); rarg.Push(arg);
		if (!focusSet) { focusSet = true; focusId = id; focusArg = arg; }
	}

	void FocusLater(int id, int arg) { wantId = id; wantArg = arg; }

	// highlighted: under the pointer while the mouse is in use, else the keyboard's focus
	bool IsFocus(int id, int arg)
	{
		if (mouseOn && !HoverFocuses()) return hoverId == id && hoverArg == arg;
		return focusSet && focusId == id && focusArg == arg;
	}

	// true: the pointer moves the focus as it hovers (the command map: the map under the pointer is what it plots on)
	virtual bool HoverFocuses() { return false; }

	// the selection frame: amber, double
	void FocusFrame(double x, double y, double w, double h)
	{
		double pulse = 0.75 + 0.25 * sin(ticks * 12.0);
		Frame(x - 2, y - 2, w + 4, h + 4, C_AMBER, 2, pulse);
		Frame(x - 4, y - 4, w + 8, h + 8, C_AMBER_DIM, 1, 0.6 * pulse);
	}

	// a button: a raised plate with a stencil label; disabled ones are dim and can't be picked
	bool Button(int id, int arg, double x, double y, double w, double h, String label, bool enabled = true, double size = 16, int accent = -1)
	{
		bool f = enabled && IsFocus(id, arg) && registering;
		Fill(x + 2, y + 2, w, h, 0, 0.45);
		Fill(x, y, w, h, enabled ? (f ? 0x3A4F66 : C_PLATE) : 0x1A232E);
		Fill(x, y, w, 2, enabled ? C_PANEL_HI : C_PANEL);
		Fill(x, y + h - 2, w, 2, C_PANEL_LO);
		if (accent >= 0 && enabled) Fill(x, y, 4, h, accent);
		// the stencil font has no dollar sign: prices go in the small font, a size up
		bool money = label.IndexOf("$") >= 0;
		Font lf = money ? NewSmallFont : BigFont;
		// a label that won't fit shrinks to the button
		double fit = TextWidth(lf, label, size);
		if (fit > w - 14) size *= (w - 14) / fit;
		double ls = Grow(lf, size);
		Text(lf, enabled ? (f ? Font.CR_GOLD : Font.CR_WHITE) : Font.CR_DARKGRAY, x + w / 2, y + (h - ls) / 2 + 1, label, size, 1);
		if (enabled) Region(id, arg, x, y, w, h);
		if (f) FocusFrame(x, y, w, h);
		return f;
	}

	// a tile (inventory slot, pick option): inset with an icon, a caption, a count in the corner
	bool Tile(int id, int arg, double x, double y, double w, double h, String icon, String caption, String count = "", bool enabled = true,
		bool chosen = false)
	{
		bool f = IsFocus(id, arg) && registering;
		Inset(x, y, w, h, chosen ? C_AMBER_DIM : -1);
		if (icon != "") Pic(icon, x + 8, y + 6, w - 16, h - 30, enabled ? 1.0 : 0.35, !enabled);
		Text(NewSmallFont, enabled ? (f ? Font.CR_GOLD : Font.CR_WHITE) : Font.CR_DARKGRAY, x + w / 2, y + h - 18, caption, 11, 1);
		if (count != "") Text(BigFont, enabled ? Font.CR_GOLD : Font.CR_DARKGRAY, x + w - 6, y + 5, count, 13, 2);
		Region(id, arg, x, y, w, h);
		if (f) FocusFrame(x, y, w, h);
		return f;
	}

	// the control hints along the bottom
	void Hints(String s)
	{
		Text(NewSmallFont, Font.CR_GRAY, 18, VH - 22, s, 11);
	}

	// ------------------------------------------------------------ the frame

	override void Drawer()
	{
		Layout();
		rx.Clear(); ry.Clear(); rw.Clear(); rh.Clear(); rid.Clear(); rarg.Clear();
		registering = true;
		DrawScreen();
		if (wantId)
			for (int i = 0; i < rid.Size(); i++)
				if (rid[i] == wantId && rarg[i] == wantArg) { focusId = wantId; focusArg = wantArg; focusSet = true; wantId = 0; break; }
		// the focused control went away (a popup closed, a list changed): take the first one
		bool found = false;
		for (int i = 0; i < rid.Size() && !found; i++) if (rid[i] == focusId && rarg[i] == focusArg) found = true;
		if (!found && rid.Size()) { focusId = rid[0]; focusArg = rarg[0]; focusSet = true; }
		Super.Drawer();
	}

	virtual void DrawScreen() {}
	virtual void Activate(int id, int arg) {}
	virtual bool Back() { return false; }      // true: handled (a popup closed); false: the screen closes
	virtual void Scroll(int dir) {}
	virtual void SwitchTab(int dir) {}

	// ------------------------------------------------------------ input

	int RegionAt(double vx, double vy)
	{
		// last registered wins (popups are drawn last)
		for (int i = rid.Size() - 1; i >= 0; i--)
			if (vx >= rx[i] && vx < rx[i] + rw[i] && vy >= ry[i] && vy < ry[i] + rh[i]) return i;
		return -1;
	}

	int FocusIndex()
	{
		for (int i = 0; i < rid.Size(); i++) if (rid[i] == focusId && rarg[i] == focusArg) return i;
		return -1;
	}

	// arrows: the nearest control in that direction
	void Move(int dx, int dy)
	{
		int cur = FocusIndex();
		if (cur < 0)
		{
			if (rid.Size()) { focusId = rid[0]; focusArg = rarg[0]; focusSet = true; }
			return;
		}
		double cx = rx[cur] + rw[cur] / 2, cy = ry[cur] + rh[cur] / 2;
		int best = -1;
		double bestScore = 1e9;
		for (int i = 0; i < rid.Size(); i++)
		{
			if (i == cur) continue;
			double tx = rx[i] + rw[i] / 2, ty = ry[i] + rh[i] / 2;
			double along = dx != 0 ? (tx - cx) * dx : (ty - cy) * dy;
			// it has to be that way, and not overlapping on that axis
			if (along <= 4) continue;
			if (dx != 0 && (dx > 0 ? rx[i] < rx[cur] + rw[cur] - 4 : rx[i] + rw[i] > rx[cur] + 4)) continue;
			if (dy != 0 && (dy > 0 ? ry[i] < ry[cur] + rh[cur] - 4 : ry[i] + rh[i] > ry[cur] + 4)) continue;
			double across = dx != 0 ? abs(ty - cy) : abs(tx - cx);
			// controls lined up with this one first
			bool lined = dx != 0 ? (ry[i] < ry[cur] + rh[cur] && ry[i] + rh[i] > ry[cur]) : (rx[i] < rx[cur] + rw[cur] && rx[i] + rw[i] > rx[cur]);
			double score = along + across * (lined ? 0.5 : 3.0);
			if (score < bestScore) { bestScore = score; best = i; }
		}
		if (best >= 0)
		{
			focusId = rid[best]; focusArg = rarg[best];
			MenuSound("menu/cursor");
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		mouseOn = false;
		switch (mkey)
		{
		case MKEY_Up: Move(0, -1); return true;
		case MKEY_Down: Move(0, 1); return true;
		case MKEY_Left: Move(-1, 0); return true;
		case MKEY_Right: Move(1, 0); return true;
		case MKEY_PageUp: Scroll(-1); return true;
		case MKEY_PageDown: Scroll(1); return true;
		case MKEY_Enter:
		{
			int i = FocusIndex();
			if (i >= 0) { MenuSound("menu/choose"); Activate(rid[i], rarg[i]); }
			return true;
		}
		case MKEY_Back:
			if (Back()) { MenuSound("menu/backup"); return true; }
			Leave();
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	// close this screen (back to the one that opened it, or to the game)
	void Leave()
	{
		Close();
		let m = GetCurrentMenu();
		MenuSound(m ? "menu/backup" : "menu/clear");
		if (!m) menuDelegate.MenuDismissed();
	}

	// close every screen, back to the game
	static void LeaveAll()
	{
		for (int guard = 0; guard < 8; guard++)
		{
			let m = GetCurrentMenu();
			if (!m) break;
			m.Close();
		}
		menuDelegate.MenuDismissed();
	}

	override bool OnUIEvent(UIEvent ev)
	{
		Layout();     // input can come before the first frame
		switch (ev.Type)
		{
		case UIEvent.Type_MouseMove:
		{
			mouseX = ev.MouseX; mouseY = ev.MouseY; mouseOn = true;
			int i = RegionAt(VX(mouseX), VY(mouseY));
			hoverId = i >= 0 ? rid[i] : 0;
			hoverArg = i >= 0 ? rarg[i] : 0;
			if (HoverFocuses() && i >= 0 && (rid[i] != focusId || rarg[i] != focusArg))
			{
				focusId = rid[i]; focusArg = rarg[i]; focusSet = true;
			}
			return true;
		}
		case UIEvent.Type_LButtonDown:
		{
			mouseX = ev.MouseX; mouseY = ev.MouseY; mouseOn = true;
			int i = RegionAt(VX(mouseX), VY(mouseY));
			if (i >= 0)
			{
				focusId = rid[i]; focusArg = rarg[i]; focusSet = true;
				MenuSound("menu/choose");
				Activate(rid[i], rarg[i]);
			}
			return true;
		}
		case UIEvent.Type_RButtonDown:
			MenuEvent(MKEY_Back, false);
			return true;
		case UIEvent.Type_WheelUp: Scroll(-1); return true;
		case UIEvent.Type_WheelDown: Scroll(1); return true;
		case UIEvent.Type_KeyDown:
		{
			int ch = ev.KeyChar;
			if (ch == UIEvent.Key_Tab) { SwitchTab(ev.IsShift ? -1 : 1); return true; }
			if (ch == 0x71 || ch == 0x51 || ch == 0x5B) { SwitchTab(-1); return true; }   // q Q [
			if (ch == 0x65 || ch == 0x45 || ch == 0x5D) { SwitchTab(1); return true; }    // e E ]
			break;
		}
		}
		return Super.OnUIEvent(ev);
	}

	// ------------------------------------------------------------ case state, for every screen

	static void Send(int op, int a = 0, int b = 0, int c = 0)
	{
		EventHandler.SendNetworkEvent(String.Format("nbc_dept.%d", op), a, b, c);
	}

	NBC_RunManager RM() { return NBC_RunManager(EventHandler.Find("NBC_RunManager")); }

	// the top bar: a title on the left, the case on the right
	void TopBar(String title, String sub = "")
	{
		Fill(0, 0, VW, 54, C_PANEL_LO, 0.85);
		Fill(0, 54, VW, 2, C_AMBER_DIM);
		Text(BigFont, Font.CR_WHITE, 18, 9, title, 26);
		if (sub != "") Text(NewSmallFont, Font.CR_GRAY, 20, 37, sub, 11);
		let rd = NBC_RunData.Find();
		if (rd && rd.caseActive)
		{
			double x = VW - 18;
			x -= MoneyText(Font.CR_GOLD, x, 11, rd.cash, 18, 2) + 8;
			x -= Text(NewSmallFont, Font.CR_GRAY, x, 15, "CASH", 11, 2) + 22;
			// strikes as marks
			for (int i = NBC_RunData.MAX_STRIKES - 1; i >= 0; i--)
			{
				Fill(x - 14, 13, 12, 14, i < rd.strikes ? C_RED : C_PANEL);
				Frame(x - 14, 13, 12, 14, C_PANEL_HI);
				x -= 16;
			}
			x -= Text(NewSmallFont, Font.CR_GRAY, x - 4, 15, "STRIKES", 11, 2) + 26;
			x -= Text(BigFont, Font.CR_WHITE, x, 12, String.Format("%d/%d", rd.day, NBC_RunData.MAX_DAYS), 16, 2) + 8;
			Text(NewSmallFont, Font.CR_GRAY, x, 15, "DAY", 11, 2);
			Text(NewSmallFont, Font.CR_DARKGRAY, VW - 18, 37, String.Format("%d of %d gangs toppled", rd.ToppledCount(), rd.gangToppled.Size()), 10, 2);
		}
		else Text(NewSmallFont, Font.CR_DARKGRAY, VW - 18, 18, "NO OPEN CASE", 12, 2);
	}

	// an officer's portrait card: portrait, name, class, a health bar; stamps for the hospital
	void OfficerCard(int id, int arg, double x, double y, double w, double h, NBC_Officer o, bool chosen = false, bool enabled = true)
	{
		bool f = IsFocus(id, arg) && registering;
		Inset(x, y, w, h, chosen ? C_AMBER : -1);
		if (!o) { Region(id, arg, x, y, w, h); if (f) FocusFrame(x, y, w, h); return; }
		double ps = min(h - 30, w - 8);
		bool hurt = o.state == NBC_Officer.ST_HOSPITAL;
		Pic(o.Portrait(), x + (w - ps) / 2, y + 4, ps, ps, enabled ? 1.0 : 0.5, hurt);
		// rank chevrons
		for (int r = 0; r < o.rank; r++) Fill(x + 6, y + 6 + r * 5, 10, 3, C_AMBER);
		Text(NewSmallFont, f ? Font.CR_GOLD : Font.CR_WHITE, x + w / 2, y + ps + 6, o.surname, 11, 1);
		double frac = o.health / double(max(1, o.MaxHealth()));
		Fill(x + 6, y + h - 10, w - 12, 5, C_PANEL_LO);
		Fill(x + 6, y + h - 10, (w - 12) * clamp(frac, 0, 1), 5, frac > 0.6 ? C_GREEN : (frac > 0.3 ? C_AMBER : C_RED));
		if (hurt) Stamp(x + w / 2, y + ps / 2, String.Format("HOSP %d", o.hospital), C_RED, 11);
		if (o.CanPromote()) Fill(x + w - 14, y + 6, 8, 8, C_GREEN);
		Region(id, arg, x, y, w, h);
		if (f) FocusFrame(x, y, w, h);
	}

	static String ClassIcon(int cls)
	{
		static const String icons[] = { "MUZPA0", "XSOTA0", "AK4IA0", "MEDIA0" };
		return icons[clamp(cls, 0, 3)];
	}
}
