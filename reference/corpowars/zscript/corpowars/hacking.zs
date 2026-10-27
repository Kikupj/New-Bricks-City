// =============================================================================
// Corpo Wars — getting through a maglock without the pass (playtest round 5)
//   * Security pass / Nyx blackout: tap USE, the door opens (unchanged).
//   * HACK (tap USE, no pass): a timing minigame at the keypad. The game keeps running while you work.
//     Three misses trip the lock: a loud alarm tone at the door and a 20 s lockout.
//   * BYPASS DEVICE (hold USE, one in your kit): opens the lock silently in 3 s. One use per device.
//   * BREACHING CHARGE ([K] at the door): 3 s fuse, then the door is blown open for good. Very loud and
//     it hurts anyone close, you included.
// =============================================================================

// ---------------------------------------------------------------- hack minigame (UI)
// A marker sweeps a bar; stop it inside the lit window. Each hit clears one node and the next window is
// narrower and faster. Nodes = 3 + building floor tier (+1 on high-security contracts).
class CW_HackMenu : CW_UiMenu
{
	int doorIdx, nodes, done, misses;
	double pos, dir, speed, winC, winW;
	int flash, flashCol;     // feedback blink
	int endTics;             // >0: result shown, closes when it runs out
	bool won;

	const MAX_MISSES = 3;

	void Setup(int door, int n)
	{
		doorIdx = door; nodes = clamp(n, 3, 7); done = 0; misses = 0;
		pos = 0; dir = 1;
		NextWindow();
	}
	void NextWindow()
	{
		speed = 0.011 + 0.0035 * done + 0.0015 * nodes;
		winW = max(0.08, 0.20 - 0.022 * done - 0.008 * (nodes - 3));
		winC = frandom(winW / 2 + 0.05, 1 - winW / 2 - 0.05);
	}

	override void Init(Menu parent)
	{
		Super.Init(parent);
		menuactive = OnNoPause;   // the floor doesn't stop while you work the lock
		DontDim = true;
	}

	override void Ticker()
	{
		Super.Ticker();
		if (endTics > 0)
		{
			if (--endTics == 0) Finish();
			return;
		}
		if (flash > 0) flash--;
		pos += dir * speed;
		if (pos >= 1) { pos = 1; dir = -1; }
		if (pos <= 0) { pos = 0; dir = 1; }
		// spotted mid-hack: drop it
		let h = Hnd();
		if (h && h.worstAwareness == CW_Guard.AW_ALERT) { won = false; misses = -1; Finish(); }
	}

	void Strike()
	{
		if (endTics > 0) return;
		if (abs(pos - winC) <= winW / 2)
		{
			done++; flash = 8; flashCol = 1;
			MenuSound("menu/choose");
			if (done >= nodes) { won = true; endTics = 18; return; }
			NextWindow();
		}
		else
		{
			misses++; flash = 8; flashCol = 2;
			MenuSound("menu/invalid");
			if (misses >= MAX_MISSES) { won = false; endTics = 24; }
		}
	}

	void Finish()
	{
		EventHandler.SendNetworkEvent("cw_hackdone", doorIdx, won ? 1 : (misses < 0 ? 2 : 0));
		Close();
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Enter) { Strike(); return true; }
		if (mkey == MKEY_Back) { won = false; misses = -1; Finish(); return true; }
		return Super.MenuEvent(mkey, fromcontroller);
	}
	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.type == UIEvent.Type_KeyDown && (ev.KeyChar == 32 || ev.KeyString ~== "e" || ev.KeyString ~== "f")) { Strike(); return true; }
		if (ev.type == UIEvent.Type_LButtonDown) { Strike(); return true; }
		return Super.OnUIEvent(ev);
	}

	override void Drawer()
	{
		double sw = Screen.GetWidth(), sh = Screen.GetHeight();
		s = max(1.0, sh / 620.0);
		double w = 420 * s, hh = 150 * s;
		double x = (sw - w) / 2, y = sh * 0.60 - hh / 2;
		Color amber = Color(240, 170, 40), green = Color(80, 200, 110), red = Color(230, 70, 60);
		Box(x, y, w, hh, Color(6, 10, 16), 0.9);
		Box(x, y, w, 3 * s, amber);
		Txt(x + 12 * s, y + 10 * s, "MAGLOCK OVERRIDE", Font.CR_GOLD);
		String st = String.Format("Nodes %d/%d", done, nodes);
		Txt(x + w - 12 * s - TW(st), y + 10 * s, st, Font.CR_GRAY);
		// node lights
		double nx = x + 12 * s, ny = y + 12 * s + LH() + 4 * s;
		for (int k = 0; k < nodes; k++) Box(nx + k * 22 * s, ny, 16 * s, 8 * s, k < done ? green : Color(40, 48, 60));
		for (int k = 0; k < MAX_MISSES; k++) Box(x + w - 12 * s - (k + 1) * 22 * s + 6 * s, ny, 16 * s, 8 * s, k < misses ? red : Color(40, 48, 60));
		// bar, window, marker
		double bx = x + 12 * s, bw = w - 24 * s, by = ny + 24 * s, bh = 26 * s;
		Color bg = flash > 0 ? (flashCol == 1 ? Color(20, 60, 30) : Color(70, 20, 20)) : Color(22, 28, 38);
		Box(bx, by, bw, bh, bg);
		if (endTics == 0) Box(bx + (winC - winW / 2) * bw, by, winW * bw, bh, Color(60, 200, 190), 0.55);
		Box(bx + pos * bw - 2 * s, by - 4 * s, 4 * s, bh + 8 * s, Color(255, 255, 255));
		String hint = endTics > 0 ? (won ? "\cdLOCK RELEASED" : "\cgLOCK TRIPPED - ALARM") : "SPACE / ENTER: lock the signal    ESC: back off";
		Txt(bx, by + bh + 10 * s, hint, Font.CR_DARKGRAY);
	}
}

// ---------------------------------------------------------------- breaching charge (play)
class CW_BreachCharge : Actor
{
	CW_Door door;
	int fuse;
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; Radius 4; Height 8; }
	override void Tick()
	{
		Super.Tick();
		if (++fuse % 18 == 0 && fuse < FUSE_TICS) A_StartSound("cw/breach/beep", CHAN_VOICE, 0, 0.7);
		if (fuse == 1) A_StartSound("cw/breach/arm", CHAN_BODY);
		if (fuse >= FUSE_TICS) Detonate();
	}
	const FUSE_TICS = 105;
	void Detonate()
	{
		A_StartSound("cw/breach/boom", CHAN_AUTO, 0, 1.0, 0.3);
		A_Explode(90, 144, XF_HURTSOURCE, false, 48);
		Spawn("CW_BreachBlast", pos);
		CW_Handler.EmitNoise(target ? target : Actor(self), pos, 1600, 1.0);
		if (door) door.Breached(target);
		Destroy();
	}
	States { Spawn: SPMN ABCB 3 Bright; Loop; }
}
class CW_BreachBlast : Actor
{
	Default { +NOINTERACTION; +NOGRAVITY; RenderStyle "Add"; Scale 1.4; }
	States { Spawn: MISL BCD 5 Bright; Stop; }
}
