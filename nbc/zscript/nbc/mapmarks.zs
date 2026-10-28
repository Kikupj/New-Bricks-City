// Keys, key doors and switches you can pick out (owner playtest: "it's hard to identify switches and key doors;
// bring back Doom's colour coding, textured in the New Bricks City theme"). The Obsidian theme turns Doom's door
// and switch art into the Bricks set by name, which made every switch the same wall panel (AXW38) and every key
// door a plain door. When a map loads, this paints them back by what the line does
// (tools/art/make_key_art.py draws the textures; ANIMDEFS.txt flips the switches):
//   a locked door           NBCDRRED / NBCDRBLU / NBCDRYEL by its lock (cards, skulls, either)
//   a switch                NBCSW1A, a breaker box in a hazard frame (lever down and a green lamp once used)
//   an exit switch          NBCSWEX1, the breaker box under a lit EXIT sign
// The keycards themselves are ours too (sprites/keys/: an ID card on a lanyard in the key's colour), and the
// HUD bar shows the ones you carry.

class NBC_MapMarks play
{
	// a lock number's colour: 0 none, 1 red, 2 blue, 3 yellow
	static int LockColor(int lock)
	{
		switch (lock)
		{
		case 1: case 4: case 129: case 132: return 1;
		case 2: case 5: case 130: case 133: return 2;
		case 3: case 6: case 131: case 134: return 3;
		}
		return 0;
	}

	static int LockOf(Line l)
	{
		int lock = l.locknumber;
		if (!lock)
		{
			if (l.special == 13 || l.special == 14) lock = l.args[3];        // Door_LockedRaise, Door_Animated
			else if (l.special == 202) lock = l.args[4];                    // Generic_Door
		}
		return lock;
	}

	static bool IsDoor(int sp) { return (sp >= 10 && sp <= 14) || sp == 202 || sp == 105 || sp == 106; }
	static bool IsExit(int sp) { return sp == 243 || sp == 244; }

	static bool DoorArt(String tex)
	{
		tex = tex.MakeUpper();
		return tex.Left(6) == "ADDOOR" || tex.Left(6) == "CWDOOR" || tex == "CWFIRED";
	}

	static void Apply()
	{
		static const String doorTex[] = { "", "NBCDRRED", "NBCDRBLU", "NBCDRYEL" };
		TextureID panel = TexMan.CheckForTexture("AXW38", TexMan.Type_Any);
		TextureID sw = TexMan.CheckForTexture("NBCSW1A", TexMan.Type_Any);
		TextureID ex = TexMan.CheckForTexture("NBCSWEX1", TexMan.Type_Any);
		int doors = 0, switches = 0;
		for (int i = 0; i < level.Lines.Size(); i++)
		{
			Line l = level.Lines[i];
			int sp = l.special;
			if (!sp) continue;
			if (IsDoor(sp))
			{
				int c = LockColor(LockOf(l));
				if (!c) continue;
				TextureID t = TexMan.CheckForTexture(doorTex[c], TexMan.Type_Any);
				for (int s = 0; s < 2; s++)
				{
					Side sd = l.sidedef[s];
					if (!sd) continue;
					for (int tier = 0; tier < 3; tier++)
					{
						TextureID cur = sd.GetTexture(tier);
						if (cur.IsValid() && DoorArt(TexMan.GetName(cur))) { sd.SetTexture(tier, t); doors++; }
					}
				}
				// the door sector's own faces (the sides of the door that face along the corridor) stay as they were
				continue;
			}
			if (!(l.activation & SPAC_Use) && !(l.activation & SPAC_Impact)) continue;
			Side sd = l.sidedef[0];
			if (!sd) continue;
			for (int tier = 0; tier < 3; tier++)
			{
				if (sd.GetTexture(tier) != panel) continue;
				sd.SetTexture(tier, IsExit(sp) ? ex : sw);
				switches++;
			}
		}
		if (developer) Console.Printf("nbc map marks: %d key-door faces, %d switches", doors, switches);
	}
}
