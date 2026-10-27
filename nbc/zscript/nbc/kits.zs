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
			if (seed == 0) seed = NBC_RunManager.NewSeed() & 0x7fffffff;
			if (v < 0 || v >= kit.VariantCount()) v = (seed >>> 3) % kit.VariantCount();
		}
		kit.Generate(seed, v);
		insertPending = true;
	}

	override void WorldTick()
	{
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
		if (!(e.Name ~== "nbc_kittest")) return;
		// netevent nbc_kittest <kit 1/2/4> <variant, -1 = from the seed> <seed, 0 = random>
		int k = e.Args[0];
		String m = NBC_KitGen.MapOfKit(k);
		if (m == "")
		{
			Console.Printf("nbc_kittest <kit> <variant> <seed>: kit is 1 (street), 2 (tower floor / rooftops) or 4 (underground).");
			return;
		}
		CVar.GetCVar("nbc_kitvariant").SetInt(e.Args[1]);
		CVar.GetCVar("nbc_kitseed").SetInt(e.Args[2]);
		let rd = NBC_RunData.Find();
		if (rd) rd.raidActive = false;    // a test floor is never a raid
		level.ChangeLevel(m, 0, CHANGELEVEL_NOINTERMISSION);
	}
}

// ---------------------------------------------------------------- doors
// A door in a kit doorway strip (tag doorTag). Use opens it from either side (a line special on both faces,
// which monsters can also trigger); an officer walking up opens it too; it shuts again a few seconds after
// the doorway is clear, never on anyone. Built on Corpo Wars' CW_Door without its locks, passes and hacking.
class NBC_KitDoor : Actor
{
	int doorTag;
	double shutZ, openZ;
	int doorIdx;
	int idle;
	bool isOpen, primed;

	const SPEED = 48;
	const USE_SPECIAL = 47;        // Ceiling_MoveToValue
	const PRIME_TICS = 12;         // the carved strip starts open; the door shuts itself silently after this
	const CLOSE_AFTER = 35 * 4;

	Default { +NOBLOCKMAP; +NOGRAVITY; +NOSECTOR; +DONTSPLASH; Radius 8; Height 8; }

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		Sector strip = level.PointInSector(pos.xy);
		if (strip) { strip.seqType = -1; strip.SeqName = 'NBCDoorSilent'; }   // no looping ceiling grind
		SetUsable();
		isOpen = true;
	}

	// both long faces of the doorway strip open the door when used (players) or bumped (monsters)
	void SetUsable()
	{
		Sector strip = level.PointInSector(pos.xy);
		if (!strip) return;
		for (int l = 0; l < strip.lines.Size(); l++)
		{
			Line ln = strip.lines[l];
			if (!ln.sidedef[1] || ln.delta.Length() < 48) continue;
			ln.special = USE_SPECIAL;
			ln.args[0] = doorTag; ln.args[1] = SPEED; ln.args[2] = abs(int(openZ)); ln.args[3] = openZ < 0 ? 1 : 0;
			ln.activation = SPAC_Use | SPAC_UseBack | SPAC_MUse;
			ln.flags |= Line.ML_REPEAT_SPECIAL | Line.ML_MONSTERSCANACTIVATE;
		}
	}

	double CurTop() { return level.PointInSector(pos.xy).ceilingplane.ZAtPoint(pos.xy); }
	bool IsShut() { return CurTop() <= shutZ + 4; }

	void SetDoor(bool open)
	{
		double z = open ? openZ : shutZ;
		level.ExecuteSpecial(USE_SPECIAL, null, null, false, doorTag, SPEED, abs(int(z)), z < 0 ? 1 : 0);
		if (primed) DoorSound(open);
		primed = true;
		isOpen = open;
		idle = 0;
	}

	void DoorSound(bool open)
	{
		A_StartSound(open ? "doors/dr1_open" : "doors/dr1_clos", CHAN_BODY, 0, open ? 0.45 : 0.35, 2.2, frandom(0.85, 1.1));
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

	// an officer at the door: allies don't press Use, so the door opens for them
	bool OfficerWaiting()
	{
		let it = BlockThingsIterator.CreateFromPos(pos.x, pos.y, pos.z, 64, 72, false);
		while (it.Next())
		{
			let a = NBC_Ally(it.thing);
			if (a && a.health > 0 && a.Distance2D(self) < 72) return true;
		}
		return false;
	}

	override void Tick()
	{
		Super.Tick();
		if (!primed)
		{
			if (GetAge() >= PRIME_TICS) SetDoor(false);
			return;
		}
		bool shut = IsShut();
		if (shut && !isOpen)
		{
			if (level.maptime % 8 == 0 && OfficerWaiting()) SetDoor(true);
			return;
		}
		if (!shut && !isOpen)
		{
			// opened by a line special (the player's Use, a monster's bump)
			isOpen = true;
			idle = 0;
			DoorSound(true);
			return;
		}
		if (isOpen && ++idle >= CLOSE_AFTER && level.maptime % 8 == 0)
		{
			if (Occupied()) idle = CLOSE_AFTER - 35;
			else SetDoor(false);
		}
	}

	States { Spawn: TNT1 A -1; Stop; }
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
		NBC_LightSource.Make(pos + (0, 0, 88), 60, 220, 90, 72);
		let sign = Spawn("NBC_ExitSign", pos + (0, 0, 92));
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
