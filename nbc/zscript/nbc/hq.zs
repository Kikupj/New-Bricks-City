// The people at Checkpoint 9 (PLAN.md §2.6): the captain, the pilot, and whichever officers on the roster are
// fit for duty. Owner request (2026-10-28): use the new captain and pilot billboards in the HQ, have NPCs there,
// and start a raid by talking to the pilot.
//
// Talk to anyone with Use: they say a line (a subtitle at the bottom of the screen, NBC_RunManager.Speak).
// Use them again while the line is up and they get down to business:
//   the captain        the raid board (the case, the districts)
//   an officer         the squad room, on their service file
//   the pilot          with a raid planned (READY on the deploy screen): the wheels-up check, NBC_WheelsUp,
//                      where GO starts the raid; with nothing planned: the raid board
// Officers stand at the NBC_HQSpot things in the hub map (tools/make_hub_map.py), in roster order; officers in
// the hospital stay away. The captain and the pilot are map things too.

class NBC_HQNpc : Actor
{
	String speaker;
	int lastTalk;
	double turnTo;

	Default
	{
		Radius 16;
		Height 56;
		Mass 10000;
		+SOLID;
		+SHOOTABLE;
		+NODAMAGE;
		+NOBLOOD;
		+DONTTHRUST;
		+NOTARGET;
		+NEVERTARGET;
		+FLOORCLIP;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		lastTalk = -10000;
		turnTo = 1e9;
	}

	virtual String Line() { return ""; }
	virtual String Hint() { return ""; }
	virtual String Face() { return ""; }
	virtual void Business(Actor user) {}

	override bool Used(Actor user)
	{
		if (!user || !user.player) return false;
		turnTo = AngleTo(user);
		// a second Use while they're still talking: down to business
		if (level.maptime - lastTalk < 35 * 6)
		{
			lastTalk = -10000;
			Business(user);
			return true;
		}
		lastTalk = level.maptime;
		Talk(Line(), Hint());
		return true;
	}

	void Talk(String text, String hint = "")
	{
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (rm) rm.Speak(speaker, text, hint, Face());
	}

	// ask the UI for a screen (the UI opens menus: NBC_RunManager.UiTick)
	static void OpenTerminal(int tab, int officer = 0)
	{
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (!rm) return;
		rm.menuKind = NBC_RunManager.MK_TERMINAL;
		rm.menuTab = tab;
		rm.menuOfficer = officer;
		rm.menuRequests++;
	}

	override void Tick()
	{
		Super.Tick();
		// turn to whoever's talking to them, slowly; now and then look round the room
		if (turnTo < 1e8)
		{
			double d = DeltaAngle(angle, turnTo);
			if (abs(d) < 6) { angle = turnTo; turnTo = 1e9; }
			else angle += clamp(d, -6, 6);
		}
		else if (!(GetAge() % 35) && random[nbchq](0, 99) < 4)
		{
			let p = players[consoleplayer].mo;
			turnTo = p && Distance2D(p) < 320 ? AngleTo(p) : angle + random[nbchq](-60, 60);
		}
	}
}

// ---------------------------------------------------------------- the captain
class NBC_Captain : NBC_HQNpc
{
	Default
	{
		Tag "Captain Harrow";
		Scale 0.68;
		Radius 18;
	}

	override void BeginPlay() { Super.BeginPlay(); speaker = "CAPT. HARROW"; }
	override String Hint() { return "Use again: the raid board"; }

	override String Line()
	{
		let rd = NBC_RunData.Find();
		let dept = NBC_Department.Find();
		if (!rd || !rd.caseActive)
		{
			if (rd && rd.caseResult == NBC_CASE_WON) return "Case closed. They'll want the Bricks quiet for the cameras. Open another file when you're ready.";
			if (rd && rd.caseResult != NBC_CASE_RUNNING) return "That one's gone, Vance. Wipe the board. We start again.";
			return "Thirty days, Vance. City Hall signed the order. Open the case file on the board and let's make them count.";
		}
		// a unit pinned down comes before anything else
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (rm && rd.evKind == NBC_Clock.EV_PINNED)
			return String.Format("Drop everything. A unit's pinned down in %s. Get them out by %s or IA hangs it on you.", rm.TurfTitle(rd.evDistrict), NBC_Clock.WIN_NAME[rd.evWindow].MakeLower());
		Array<String> say;
		say.Push(String.Format("Day %d of %d. %d of the gangs are still standing.", rd.day, NBC_RunData.MAX_DAYS, rd.GangsLeft()));
		if (rm && rd.evKind != NBC_Clock.EV_NONE)
		{
			String ev = NBC_Clock.EventLine(rd.evKind, rm.TurfTitle(rd.evDistrict), rd.evWindow);
			say.Push(ev); say.Push(ev);      // the news of the day, twice as likely
		}
		say.Push("Pick your hour. Some of them sleep all day, some never sleep. Read the file.");
		if (rd.strikes > 0) say.Push(String.Format("Internal Affairs called again. You're on %d strike%s. Don't make it three.", rd.strikes, rd.strikes == 1 ? "" : "s"));
		if (dept)
		{
			int hurt = 0;
			for (int i = 0; i < dept.roster.Size(); i++)
			{
				let o = dept.roster[i];
				if (o.state == NBC_Officer.ST_HOSPITAL) hurt++;
				else if (o.CanPromote()) say.Push(String.Format("%s has earned a promotion. Sign the paper in the squad room.", o.RankedName()));
			}
			if (hurt) say.Push(String.Format("%d of ours are at Mercy General. Don't send me more.", hurt));
			if (!dept.squad.Size()) say.Push("You're not going in there alone. Pick a squad.");
		}
		if (rd.readyDistrict >= 0) say.Push("Rook's waiting at the bird. Go when you're ready.");
		if (rd.cash > 500) say.Push("That seized cash buys rounds and vests. Spend it at the locker.");
		say.Push("Downtown wants arrests. I want my people home. Do both.");
		return say[random[nbchq](0, say.Size() - 1)];
	}

	override void Business(Actor user) { OpenTerminal(NBC_Terminal.TAB_BOARD); }

	// standing, then a pull on the cigar now and then
	States
	{
	Spawn:
		NCAP A 35;
		NCAP A 35 A_SetTics(random[nbchq](70, 200));
		NCAP BCD 5;
		NCAP E 12;
		NCAP FG 6;
		Loop;
	}
}

// ---------------------------------------------------------------- the pilot
class NBC_Pilot : NBC_HQNpc
{
	Default
	{
		Tag "Rook";
		Scale 0.7;
	}

	override void BeginPlay() { Super.BeginPlay(); speaker = "ROOK (PILOT)"; }

	override String Hint()
	{
		let rd = NBC_RunData.Find();
		return rd && rd.readyDistrict >= 0 ? "" : "Use again: the raid board";
	}

	override String Line()
	{
		let rd = NBC_RunData.Find();
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		let dept = NBC_Department.Find();
		if (rd && rd.readyDistrict >= 0 && rm)
			return dept && dept.insertion == NBC_Motor.INS_ROOFTOP && dept.HasHeli() ?
				String.Format("Bird's fueled for %s, %s. Say the word.", rm.TurfTitle(rd.readyDistrict), NBC_Clock.WindowLine(rd.WindowFor(rd.readyDistrict))) :
				String.Format("Motorcade's gassed up for %s, %s. Say the word.", rm.TurfTitle(rd.readyDistrict), NBC_Clock.WindowLine(rd.WindowFor(rd.readyDistrict)));
		if (!rd || !rd.caseActive) return "No case, no flight. The captain's got the files.";
		if (dept && !dept.HasHeli()) return "No bird in the motor pool, so I drive. Get us a helicopter and I'll put you on the roofs.";
		static const String idle[] = {
			"Nothing on the board for me, Detective. Plan a raid and I'll warm her up.",
			"She's held together with tape and prayers, but she flies.",
			"I can put you on a roof. Getting you out past their guns is the hard part." };
		return idle[random[nbchq](0, 2)];
	}

	override bool Used(Actor user)
	{
		// with a raid planned, the pilot goes straight to the wheels-up check
		let rd = NBC_RunData.Find();
		if (user && user.player && rd && rd.readyDistrict >= 0)
		{
			turnTo = AngleTo(user);
			Talk(Line());
			let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
			if (rm) { rm.menuKind = NBC_RunManager.MK_WHEELSUP; rm.menuRequests++; }
			return true;
		}
		return Super.Used(user);
	}

	override void Business(Actor user) { OpenTerminal(NBC_Terminal.TAB_BOARD); }

	States
	{
	Spawn:
		NPLT A -1;
		Stop;
	}
}

// ---------------------------------------------------------------- the officers
// Where an officer stands in the HQ (map thing; the angle is the way they face).
class NBC_HQSpot : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; RenderStyle "None"; }
	States { Spawn: TNT1 A -1; Stop; }
}

class NBC_HQOfficer : NBC_HQNpc
{
	int officerId;
	String portrait;

	Default
	{
		Radius 16;
		Height 56;
	}

	// look like the officer does on a raid: the class's sprite set, their own clothes
	void Dress(NBC_Officer o)
	{
		officerId = o.id;
		speaker = o.RankedName().MakeUpper();
		portrait = o.Portrait();
		SetTag(o.RankedName());
		sprite = GetSpriteIndex(NBC_Cat.CLASS_SPRITE[clamp(o.cls, 0, NBC_Cat.C_COUNT - 1)]);
		frame = 0;
		A_SetTranslation(String.Format("NBC_Outfit%d", o.face * 3 % 8));
	}

	override String Face() { return portrait; }
	override String Hint() { return "Use again: the squad room"; }

	override String Line()
	{
		let dept = NBC_Department.Find();
		let o = dept ? dept.OfficerById(officerId) : null;
		if (!o) return "...";
		Array<String> say;
		if (o.CanPromote()) say.Push("Heard there's a promotion with my name on it.");
		if (o.health < o.MaxHealth()) say.Push("Still feeling the last one. I'll live.");
		if (o.raids == 0) say.Push("First week on the job. Don't get me killed, Detective.");
		if (dept.InSquad(o.id)) say.Push("I'm on the list for the next one. Ready when you are.");
		else say.Push("Put me on the next raid. I'm getting soft in here.");
		if (o.kills >= 10) say.Push(String.Format("%d of them so far. They keep coming.", o.kills));
		if (o.cls == NBC_Cat.C_BREACHER) say.Push("Door goes in, I go in. That's the job.");
		else if (o.cls == NBC_Cat.C_MARKSMAN) say.Push("Give me a roof and a long street.");
		else if (o.cls == NBC_Cat.C_MEDIC) say.Push("Keep your head down out there. I'm low on gauze.");
		else say.Push("Bricks never sleeps. Neither do we.");
		return String.Format("%s, %s.  \"%s\"", o.RankName(), o.ClassName(), say[random[nbchq](0, say.Size() - 1)]);
	}

	override void Business(Actor user) { OpenTerminal(NBC_Terminal.TAB_SQUAD, officerId); }

	States
	{
	Spawn:
		EW1A A -1;     // the class's sprite (Dress), standing
		Stop;
	}
}
