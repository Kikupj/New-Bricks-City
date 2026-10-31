// Breaching (PLAN.md M2e): on a raid a locked door is a breach point, not a keycard hunt. Use it without the key
// and you set a charge (stay by the door: 2 s, 1 s with a Breacher officer alongside), it beeps for a second and a
// half and blows: the door is open for good, the gang behind it is dazed for a moment, and the whole block hears it
// (anyone off guard wakes). With the key the door opens the quiet way, as ever. At the precinct nothing's breached.
// The district maps lock the stronghold's doors and leave a keycard somewhere for the quiet way in
// (tools/studio/district-gen.js).

class NBC_Breach : EventHandler
{
	const SET_TICS = 70;
	const SET_TICS_BREACHER = 35;
	const FUSE_TICS = 52;
	const STAY = 112.0;              // how far you can step from the door while setting the charge
	const DAZE_RADIUS = 288.0;
	const WAKE_RADIUS = 2048.0;

	int stage;                       // 0 none, 1 setting the charge, 2 the fuse
	Line door;
	int side, nextAt;
	PlayerPawn who;
	Actor charge;

	override void WorldLinePreActivated(WorldEvent e)
	{
		Line l = e.ActivatedLine;
		let p = PlayerPawn(e.Thing);
		if (!l || !p || !p.player || l.special != 13) return;            // Door_LockedRaise
		let rd = NBC_RunData.Find();
		if (!rd || !rd.raidActive) return;
		if (p.CheckKeys(NBC_MapMarks.LockOf(l), false, true)) return;     // the key: the quiet way
		e.ShouldActivate = false;
		if (stage) return;                                                 // one charge at a time
		Vector2 at = Mid(l);
		if (developer) Console.Printf("nbc breach: setting a charge on the door at (%d, %d)", int(at.x), int(at.y));
		door = l;
		who = p;
		side = level.PointOnLineSide(p.pos.xy, l);
		let ally = BreacherNear(at);
		stage = 1;
		nextAt = level.maptime + (ally ? SET_TICS_BREACHER : SET_TICS);
		p.A_StartSound("cw/breach/arm", CHAN_AUTO);
		Say(ally ? String.Format("%s: \"Charge going on, give me a second.\"", ally.GetTag()) : "Setting a breaching charge. Stay by the door.");
	}

	override void WorldTick()
	{
		if (!stage) return;
		if (!door || !who || who.health <= 0) { stage = 0; return; }
		Vector2 mid = Mid(door);
		if (stage == 1)
		{
			if ((who.pos.xy - mid).Length() > STAY) { stage = 0; Say("Breach called off."); return; }
			if (level.maptime < nextAt) return;
			// the charge on your side of the door
			Vector2 n = (door.delta.y, -door.delta.x).Unit();
			if (side == 1) n = -n;
			Vector2 at = mid + n * 6;
			charge = Actor.Spawn("NBC_BreachCharge", (at, who.CurSector.floorplane.ZatPoint(at) + 40), NO_REPLACE);
			stage = 2;
			nextAt = level.maptime + FUSE_TICS;
			Say("Charge set. Back off!");
			return;
		}
		if (level.maptime < nextAt) return;
		Blow(mid);
		stage = 0;
	}

	void Blow(Vector2 mid)
	{
		Sector sec = side == 0 ? door.backsector : door.frontsector;      // the door's own sector
		// the blast goes off just past the door, in the room behind it (the door's still shut this tic: a blast on
		// the line couldn't see, or be seen by, the people it's meant for)
		Vector2 n = (door.delta.y, -door.delta.x).Unit();
		if (side == 1) n = -n;                                             // toward your side
		Vector2 far = mid - n * 24;
		Sector beyond = level.PointInSector(far);
		Vector3 at = (far, beyond ? beyond.floorplane.ZatPoint(far) + 32 : who.pos.z + 32);
		let blast = Actor.Spawn("NBC_BreachBlast", at, NO_REPLACE);
		if (blast)
		{
			blast.target = who;
			// a concussive blast (Blunt): it hurts whoever's in the doorway, not you or the squad
			blast.A_Explode(48, 128, 0, damagetype: 'Blunt');
			blast.A_Quake(4, 18, 0, 768, "");
		}
		if (charge) charge.Destroy();
		// the door: open for good
		level.ExecuteSpecial(11, who, door, side, 0, 96);                 // Door_Open
		if (sec) for (int i = 0; i < sec.lines.Size(); i++) sec.lines[i].special = 0;
		door.special = 0;
		// those behind it reel; the block hears it
		let it = ThinkerIterator.Create("Actor");
		Actor mo;
		let rd = NBC_RunData.Find();
		Actor eye = blast;
		if (!eye) eye = who;
		int dazed = 0, woken = 0;
		while ((mo = Actor(it.Next())))
		{
			if (!mo.bIsMonster || mo.health <= 0 || mo is "NBC_Ally") continue;
			double d = (mo.pos.xy - mid).Length();
			if (d < DAZE_RADIUS && mo.CheckSight(eye, SF_IGNOREVISIBILITY)) { NBC_FlashStun.Daze(mo, 35 + int(35 * (1 - d / DAZE_RADIUS))); dazed++; }
			if (d < WAKE_RADIUS)
			{
				let off = NBC_OffGuard(mo.FindInventory("NBC_OffGuard"));
				if (off) { off.WakeIn(rd ? rd.Rand(8, 40) : 20); woken++; }
				else if (!mo.target) mo.target = who;
			}
		}
		if (developer) Console.Printf("nbc breach: door at (%d, %d) blown open; %d dazed, %d woken", int(mid.x), int(mid.y), dazed, woken);
		Say("BREACH!", 35 * 2);
	}

	// a Breacher officer up and close to the door
	NBC_Ally BreacherNear(Vector2 at)
	{
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (!rm) return null;
		for (int i = 0; i < rm.squad.Size(); i++)
		{
			let a = NBC_Ally(rm.squad[i]);
			if (a && a.health > 0 && a.cls == NBC_Cat.C_BREACHER && (a.pos.xy - at).Length() < 640) return a;
		}
		return null;
	}

	static Vector2 Mid(Line l) { return (l.v1.p + l.v2.p) / 2; }

	void Say(String text, int tics = 35 * 3)
	{
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (rm) rm.Announce(text, tics);
	}
}

// the charge on the door: a blinking light and a beep, then nothing (the blast is NBC_BreachBlast)
class NBC_BreachCharge : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +DONTSPLASH; RenderStyle "None"; }
	override void Tick()
	{
		Super.Tick();
		if (GetAge() % 12 == 0)
		{
			A_StartSound("cw/breach/beep", CHAN_AUTO);
			A_SpawnParticle(0xFF2020, SPF_FULLBRIGHT, 6, 4, 0, 0, 0, 0);
		}
	}
	States { Spawn: TNT1 A -1; Stop; }
}

class NBC_BreachBlast : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +DONTSPLASH; RenderStyle "Add"; Alpha 0.9; Scale 0.8; }
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_StartSound("cw/breach/boom", CHAN_AUTO, 0, 1.0, 0.5);
		for (int i = 0; i < 24; i++)
			A_SpawnParticle(random[nbcfx](0, 1) ? 0x8A8070 : 0x5A5048, 0, random[nbcfx](30, 60), random[nbcfx](8, 18), 0,
				frandom[nbcfx](-16, 16), frandom[nbcfx](-16, 16), frandom[nbcfx](-16, 16), frandom[nbcfx](-3, 3), frandom[nbcfx](-3, 3), frandom[nbcfx](0, 2.5),
				0, 0, -0.08, 0.8, -1, -0.15);
	}
	States { Spawn: BEXP C 4 Bright; BEXP D 4 Bright; BEXP E 6 Bright; Stop; }
}
