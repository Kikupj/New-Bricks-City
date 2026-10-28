// Our own level architecture (PLAN.md §4.4, M2b): runs the Bricks kits (nbc/zscript/cw/kit*.zs) on the
// kit template maps NBC_K1 (street), NBC_K2 (tower floor, rooftops) and NBC_K4 (underground).
//
// On a kit map the generator carves a fresh layout from a seed when the map loads (never on a loaded save:
// the moved sectors and spawned things are in the save already), then the player is put at the insertion
// on the first tic. On a raid the seed and variant come from NBC_RunData (the case RNG); otherwise from
// nbc_kitseed / nbc_kitvariant, which `nbc_kittest` sets.

class NBC_KitRunner : EventHandler
{
	transient NBC_KitGen kit;     // the floor's generator (not saved; only needed while the raid is set up)
	bool insertPending, testFloor;

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame || e.IsReopen) return;
		int k = NBC_KitGen.KitOfMap(level.MapName);
		if (!k) return;
		kit = NBC_KitGen.Make(k);
		if (!kit) return;

		int seed, v;
		let rd = NBC_RunData.Find();
		if (rd && rd.raidActive && rd.raidMap ~== level.MapName)
		{
			seed = rd.raidKitSeed;
			v = rd.raidVariant;
			kit.entryPref = rd.raidEntry;
		}
		else
		{
			testFloor = true;
			seed = CVar.GetCVar("nbc_kitseed").GetInt();
			v = CVar.GetCVar("nbc_kitvariant").GetInt();
			let sw = NBC_KitSweep.Find();
			if (sw && sw.seed) { seed = sw.seed; v = sw.variant; }
			if (seed == 0) seed = NBC_RunManager.NewSeed() & 0x7fffffff;
			if (v < 0 || v >= kit.VariantCount()) v = (seed >>> 3) % kit.VariantCount();
		}
		kit.Generate(seed, v);
		insertPending = true;
		if (testFloor && (CVar.GetCVar("nbc_kitsweep").GetInt() > 0 || NBC_KitSweep.Find())) kit.Summary();
	}

	// a kit door's face: use opens it (see NBC_KitDoor)
	override void WorldLinePreActivated(WorldEvent e)
	{
		Line ln = e.ActivatedLine;
		if (!ln || ln.special != NBC_KitDoor.USE_SPECIAL) return;
		let it = ThinkerIterator.Create("NBC_KitDoor");
		NBC_KitDoor d;
		while (d = NBC_KitDoor(it.Next()))
		{
			if (d.panel != ln.Index()) continue;
			e.ShouldActivate = false;
			d.Toggle(e.Thing);
			return;
		}
	}

	override void WorldTick()
	{
		// testing: nbc_kitsweep N regenerates the floor N more times, the next seed and variant each time
		if (testFloor && kit && !insertPending && level.maptime == 8)
		{
			let sw = NBC_KitSweep.Get();
			if (sw.left < 0) sw.left = CVar.GetCVar("nbc_kitsweep").GetInt();
			if (sw.left > 0)
			{
				sw.left--;
				sw.seed = kit.seed0 + 1;
				sw.variant = (kit.variant + 1) % kit.VariantCount();
				level.ChangeLevel(level.MapName, 0, CHANGELEVEL_NOINTERMISSION);
				return;
			}
		}
		if (!insertPending || !kit) return;
		let pm = players[consoleplayer].mo;
		if (!pm) return;
		insertPending = false;
		kit.Insert(pm);
		if (testFloor)
			pm.A_Print(String.Format("\cg%s\n\cj%s, seed %d\n\cjIn by %s. The exit sign is over %s.\n\cdnbc_debug_kit lists the rooms.",
				level.LevelName.MakeUpper(), kit.VariantName(), kit.seed0, kit.insertName, kit.enName[kit.exitIdx]), 6);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "nbc_debug_kit")
		{
			if (kit) kit.Describe();
			else Console.Printf(NBC_KitGen.KitOfMap(level.MapName) ? "nbc: this floor was loaded from a save; its plan isn't kept." : "nbc: not a kit map (NBC_K1, NBC_K2, NBC_K4).");
			return;
		}
		if (e.Name ~== "nbc_goto")
		{
			// testing: netevent nbc_goto <x> <y> <angle> puts the player there on the floor, facing that way
			let pm = players[consoleplayer].mo;
			if (!pm) return;
			Vector2 at = (e.Args[0], e.Args[1]);
			pm.SetOrigin((at, level.PointInSector(at).floorplane.ZAtPoint(at)), false);
			pm.angle = e.Args[2];
			pm.pitch = 0;
			pm.vel = (0, 0, 0);
			return;
		}
		if (!(e.Name ~== "nbc_kittest")) return;
		// netevent nbc_kittest <kit 1/2/4> <variant, -1 = from the seed> <seed, 0 = random>
		int k = e.Args[0];
		String m = NBC_KitGen.MapOfKit(k);
		if (m == "")
		{
			Console.Printf("nbc_kittest <kit> <variant> <seed>: kit is 1 (tower floor), 2 (street), 3 (basement) or 4 (roof).");
			return;
		}
		CVar.GetCVar("nbc_kitvariant").SetInt(e.Args[1]);
		CVar.GetCVar("nbc_kitseed").SetInt(e.Args[2]);
		let rd = NBC_RunData.Find();
		if (rd) rd.raidActive = false;    // a test floor is never a raid
		level.ChangeLevel(m, 0, CHANGELEVEL_NOINTERMISSION);
	}
}

// testing: where nbc_kitsweep has got to (it lives across the level changes it makes)
class NBC_KitSweep : Thinker
{
	int left, seed, variant;
	static NBC_KitSweep Find() { return NBC_KitSweep(ThinkerIterator.Create("NBC_KitSweep", STAT_STATIC).Next()); }
	static NBC_KitSweep Get()
	{
		let sw = Find();
		if (!sw) { sw = new("NBC_KitSweep"); sw.ChangeStatNum(STAT_STATIC); sw.left = -1; }
		return sw;
	}
}

// ---------------------------------------------------------------- doors
// A door in a kit doorway. The opening is fixed; the door is a panel across it, the door art hung as the mid
// texture of one face of the doorway strip, that slides up into the lintel (the mid texture scrolls up and is
// clipped by the opening). Shut, that face blocks walking, shots and sight. Use opens it from either side (the
// face carries a no-op special that NBC_KitRunner.WorldLinePreActivated catches, so monsters that use walls
// open it too); an officer or a gang member walking up opens it; it shuts again a few seconds after the doorway
// is clear, never on anyone.
class NBC_KitDoor : Actor
{
	int panel;                  // the line the door hangs on (an index: lines survive saves as indexes)
	double frac;                // 0 shut .. 1 open
	double doorH;
	int doorIdx;
	int idle;
	bool isOpen;
	TextureID art;
	double artH;

	const SLIDE_TICS = 14;
	const CLOSE_AFTER = 35 * 4;
	const USE_SPECIAL = 173;    // NoiseAlert: never runs, the event handler eats the activation
	const SHUT_FLAGS = Line.ML_BLOCKING | Line.ML_BLOCKSIGHT | Line.ML_BLOCKHITSCAN | Line.ML_BLOCKPROJECTILE;

	Default { +NOBLOCKMAP; +NOGRAVITY; +NOSECTOR; +DONTSPLASH; Radius 8; Height 8; }

	// hang the door on the doorway face nearest `face` (a point in the room the door faces)
	void Hang(Vector2 face, String tex, double h)
	{
		panel = -1; doorH = h;
		Sector strip = level.PointInSector(pos.xy);
		if (!strip) return;
		double bd = 1e9;
		for (int l = 0; l < strip.lines.Size(); l++)
		{
			Line ln = strip.lines[l];
			if (!ln.sidedef[1] || ln.delta.Length() < 40) continue;   // the two door faces, not the 16u jambs
			double d = ((ln.v1.p + ln.v2.p) / 2 - face).Length();
			if (d < bd) { bd = d; panel = ln.Index(); }
		}
		if (panel < 0) return;
		Line ln = level.lines[panel];
		art = TexMan.CheckForTexture(tex, TexMan.Type_Any);
		if (!art.IsValid()) art = TexMan.CheckForTexture("DOOR3", TexMan.Type_Any);
		int tw, th;
		[tw, th] = TexMan.GetSize(art);
		artH = max(th, 1);
		double len = ln.delta.Length();
		for (int z = 0; z < 2; z++)
		{
			Side sd = ln.sidedef[z];
			sd.SetTexture(Side.mid, art);
			if (tw > 0) sd.SetTextureXScale(Side.mid, tw / len);
			sd.SetTextureYScale(Side.mid, artH / h);
			sd.SetTextureYOffset(Side.mid, 0);
		}
		ln.flags &= ~Line.ML_WRAP_MIDTEX;
		ln.flags |= Line.ML_DONTPEGBOTTOM | SHUT_FLAGS;      // the door stands on the floor
		ln.special = USE_SPECIAL;
		ln.activation = SPAC_Use | SPAC_UseBack;
		ln.flags |= Line.ML_REPEAT_SPECIAL | Line.ML_MONSTERSCANACTIVATE;
	}

	bool IsShut() { return !isOpen && frac <= 0; }

	// Use (the player), a wall-using monster, or someone walking up
	void Toggle(Actor user)
	{
		if (panel < 0) return;
		if (!isOpen) SetDoor(true);
		else if (user && user.player && frac >= 1 && !Occupied()) SetDoor(false);
	}

	void SetDoor(bool open)
	{
		if (open == isOpen) return;
		isOpen = open;
		idle = 0;
		Line ln = level.lines[panel];
		if (!open)
		{
			ln.flags |= SHUT_FLAGS;
			for (int z = 0; z < 2; z++) ln.sidedef[z].SetTexture(Side.mid, art);
		}
		A_StartSound(open ? "doors/dr1_open" : "doors/dr1_clos", CHAN_BODY, 0, open ? 0.45 : 0.35, 2.2, frandom(0.85, 1.1));
	}

	// slide the panel: the art scrolls up and the lintel clips it
	void Slide()
	{
		Line ln = level.lines[panel];
		double was = frac;
		frac = clamp(frac + (isOpen ? 1.0 : -1.0) / SLIDE_TICS, 0, 1);
		if (frac == was) return;
		for (int z = 0; z < 2; z++) ln.sidedef[z].SetTextureYOffset(Side.mid, frac * artH);
		if (isOpen && frac > 0.6) ln.flags &= ~SHUT_FLAGS;
		if (frac >= 1) for (int z = 0; z < 2; z++) ln.sidedef[z].SetTexture(Side.mid, TexMan.CheckForTexture("-", TexMan.Type_Any));
	}

	// anyone (or anything solid) standing in the doorway
	bool Occupied()
	{
		let it = BlockThingsIterator.CreateFromPos(pos.x, pos.y, pos.z, 64, 40, false);
		while (it.Next())
		{
			let t = it.thing;
			if (t == self || !(t.bSOLID || t.player || t.bIsMonster)) continue;
			if ((t.pos.xy - pos.xy).Length() < t.radius + 28) return true;
		}
		return false;
	}

	// an officer or a gang member at the door: allies don't press Use and not every monster uses walls
	bool SomeoneWaiting()
	{
		let it = BlockThingsIterator.CreateFromPos(pos.x, pos.y, pos.z, 64, 64, false);
		while (it.Next())
		{
			let a = it.thing;
			if (a.health <= 0 || a.player || !(a.bIsMonster || a is "NBC_Ally")) continue;
			if (a.Distance2D(self) < a.radius + 40) return true;
		}
		return false;
	}

	override void Tick()
	{
		Super.Tick();
		if (panel < 0) return;
		Slide();
		if (!isOpen)
		{
			if (level.maptime % 4 == 0 && SomeoneWaiting()) SetDoor(true);
			return;
		}
		if (++idle >= CLOSE_AFTER && level.maptime % 8 == 0)
		{
			if (Occupied() || SomeoneWaiting()) idle = CLOSE_AFTER - 35;
			else SetDoor(false);
		}
	}
}

// ---------------------------------------------------------------- lights
// A small dynamic light at a spot (the generator's accent lighting: street lamps, fire escapes, signs).
class NBC_LightSource : PointLight
{
	static NBC_LightSource Make(Vector3 at, int r, int g, int b, int radius)
	{
		let l = NBC_LightSource(Actor.Spawn("NBC_LightSource", at));
		if (!l) return null;
		l.args[DynamicLight.LIGHT_RED] = r; l.args[DynamicLight.LIGHT_GREEN] = g; l.args[DynamicLight.LIGHT_BLUE] = b;
		l.args[DynamicLight.LIGHT_INTENSITY] = radius;
		return l;
	}
}

// A fixture hanging from the ceiling that casts a real light (models in MODELDEF.txt). One class per style:
// recessed troffer, drum pendant, industrial batten, round downlight. `unlit` rooms (RF_DARK) keep it off.
class NBC_CeilingLight : Actor
{
	bool unlit;

	Default
	{
		+SPAWNCEILING;
		+NOGRAVITY;
		+NOBLOCKMAP;
		Radius 8;
		Height 19;
		Tag "Ceiling light";
	}

	virtual int Style() { return 0; }

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (unlit) { SetStateLabel("Off"); return; }
		// warm white, warm pendant, cool batten, halogen downlight; tight pools with shadow between them
		static const int LR[] = { 255, 255, 214, 255 };
		static const int LG[] = { 240, 214, 232, 230 };
		static const int LB[] = { 214, 160, 255, 196 };
		static const int LI[] = { 136, 112, 128, 104 };
		int s = clamp(Style(), 0, 3);
		NBC_LightSource.Make(pos - (0, 0, 12), LR[s], LG[s], LB[s], LI[s]);
	}

	States
	{
	Spawn:
		CWMD A -1 Bright;
		Stop;
	Off:
		CWMD A -1;
		Stop;
	}
}
class NBC_CeilingLightPendant : NBC_CeilingLight { override int Style() { return 1; } }
class NBC_CeilingLightStrip : NBC_CeilingLight { override int Style() { return 2; } }
class NBC_CeilingLightDown : NBC_CeilingLight { override int Style() { return 3; } }

// ---------------------------------------------------------------- the exit and the markers
// The way out of a kit floor: the entry farthest from where you came in, with a lit exit sign over it.
// Use it to leave. On a raid, leaving is how the raid ends (topple or retreat, NBC_RunManager.ResolveRaid).
class NBC_KitExit : Actor
{
	Default
	{
		Radius 16;
		Height 64;
		Health 10000;
		+SOLID;
		+SHOOTABLE;
		+NODAMAGE;
		+NOBLOOD;
		+DONTTHRUST;
		+NOGRAVITY;
		+NOTAUTOAIMED;
		Tag "Exit";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		// NBC: indoors the sign hangs under the ceiling; outdoors (no ceiling) it sits on a barricade behind the exit
		double signZ = 92;
		Sector sec = level.PointInSector(pos.xy);
		if (sec && sec.GetTexture(Sector.ceiling) == skyflatnum)
		{
			Vector2 back = pos.xy - AngleToVector(angle, 28);
			let bar = Spawn("CW_FBarrier", (back, pos.z));
			if (bar) bar.angle = angle + 90;
			NBC_LightSource.Make((back, pos.z + 56), 60, 220, 90, 72);
			let sign = Spawn("NBC_ExitSign", (back, pos.z + 34));
			if (sign) sign.angle = angle;
			return;
		}
		if (sec) signZ = min(signZ, sec.ceilingplane.ZAtPoint(pos.xy) - pos.z - 12);
		NBC_LightSource.Make(pos + (0, 0, signZ - 4), 60, 220, 90, 72);
		let sign = Spawn("NBC_ExitSign", pos + (0, 0, signZ));
		if (sign) sign.angle = angle;
	}

	override bool Used(Actor user)
	{
		if (!user || !user.player || user.health <= 0) return false;
		A_StartSound("doors/dr1_open", CHAN_BODY);
		level.ChangeLevel(NBC_RunManager.HUB_MAP, 0, CHANGELEVEL_NOINTERMISSION);
		return true;
	}

	States { Spawn: TNT1 A -1; Stop; }
}

class NBC_ExitSign : Actor
{
	Default { +NOGRAVITY; +NOBLOCKMAP; Radius 6; Height 10; Tag "Exit sign"; }
	States { Spawn: CWMD A -1 Bright; Stop; }
}

// Where a resident stands (M9 fills these with Civilians2 residents).
class NBC_ResidentSpot : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOSECTOR; +DONTSPLASH; Radius 8; Height 8; }
	States { Spawn: TNT1 A -1; Stop; }
}

// A room the objective planner picked; args[0] is the kind (NBC_KitGen.OBJ_STEAL / OBJ_DESTROY / OBJ_TURN).
class NBC_ObjectiveMarker : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOSECTOR; +DONTSPLASH; Radius 8; Height 8; }
	States { Spawn: TNT1 A -1; Stop; }
}
