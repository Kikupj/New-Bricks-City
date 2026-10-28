// The time of day (owner request, 2026-10-28; Hamburger Hill's mission hours, docs/hamburger-hill-analysis.md):
// every raid goes in at an hour you pick on Rook's roll-out screen: MORNING, AFTERNOON, DUSK or NIGHT.
//   the gang    how many of them are out, and how many of those are off guard (asleep, high, half-watching:
//               slow to react, NBC_OffGuard), per gang and per hour in gangs.txt (strength, offguard, hours)
//   the block   the sky, the light (outdoors most) and its tint; night is dark and the flashlight matters
//   the squad   officers see less far and shoot wider at dusk and at night
//
// The day's event (rolled each morning with the case RNG, NBC_RunData.RollEvent): something going down in one
// district at a set hour. Raid that district today and you go in at that hour, in that situation:
//   GANG WAR         a rival crew hit them: fewer of them, and hurt                      dusk or night
//   CROWDED STREETS  the block's full of people: more of them off guard (the crowd       afternoon or dusk
//                    covers you), but the first shot wakes the whole block, and fire in
//                    a crowd is a strike
//   THE DEAL         the leader's out for a deal: two more guards, double the bounty      any hour
//   BLACKOUT         the power's out: darker still, more of them off guard               night
//   OFFICER PINNED   a patrol unit's pinned down: everyone's awake and waiting. Urgent:  morning or afternoon
//   DOWN             leave it and Internal Affairs gives you a strike; get them out
//                    and City Hall pays

class NBC_Clock
{
	enum EWindow { W_MORNING, W_AFTERNOON, W_DUSK, W_NIGHT, W_COUNT }
	static const String WIN_NAME[] = { "MORNING", "AFTERNOON", "DUSK", "NIGHT" };
	static const String WIN_HOUR[] = { "07:00", "14:00", "19:30", "02:00" };
	// the sky (tools/art/make_sky_variants.py; "" keeps the map's own night sky)
	static const String WIN_SKY[] = { "NBCSKYMR", "NBCSKYDY", "NBCSKYDK", "" };
	// the light: added outdoors (under the sky) and indoors; the tint outdoors
	static const int LIGHT_OUT[] = { 40, 72, 0, -40 };
	static const int LIGHT_IN[] = { 12, 20, 0, -20 };
	static const int TINT[] = { 0xFFE4CC, 0xFFFFFF, 0xFFC090, 0x9CA8E0 };
	// the squad: how far officers see, how wide they shoot
	static const double SIGHT[] = { 1.0, 1.0, 0.85, 0.7 };
	static const double SPREAD[] = { 1.0, 1.0, 1.1, 1.25 };

	enum EEvent { EV_NONE, EV_WAR, EV_CROWD, EV_DEAL, EV_BLACKOUT, EV_PINNED, EV_COUNT }
	static const String EV_NAME[] = { "", "GANG WAR", "CROWDED STREETS", "THE DEAL", "BLACKOUT", "OFFICER PINNED DOWN" };
	static const double EV_STRENGTH[] = { 1.0, 0.7, 1.0, 1.0, 0.9, 1.0 };
	static const int EV_OFFGUARD[] = { 0, 0, 30, 0, 20, -100 };
	static const int EV_ESCORTS[] = { 0, 0, 0, 2, 0, 0 };
	static const double EV_HEALTH[] = { 1.0, 0.7, 1.0, 1.0, 1.0, 1.0 };
	static const int EV_DARK[] = { 0, 0, 0, 0, 48, 0 };
	const PINNED_PAY = 400;
	const EVENT_CHANCE = 55;           // percent, each morning from day 2

	clearscope static String WindowLine(int w)
	{
		w = clamp(w, 0, W_COUNT - 1);
		return String.Format("%s %s", NBC_Clock.WIN_HOUR[w], NBC_Clock.WIN_NAME[w]);
	}

	// what the hour does to this gang, for the board and the roll-out screen: "x1.25 out, 10% off guard"
	clearscope static String GangLine(NBC_GangDef g, int w, int ev = EV_NONE)
	{
		if (!g) return "";
		ev = clamp(ev, 0, EV_COUNT - 1);
		int pct = int(round(100 * g.StrengthAt(w) * NBC_Clock.EV_STRENGTH[ev]));
		int off = clamp(g.OffGuardAt(w) + NBC_Clock.EV_OFFGUARD[ev], 0, 90);
		return String.Format("%d%% out, %d%% off guard", pct, off);
	}

	// the event, as the board and the radio put it
	clearscope static String EventLine(int ev, String place, int w)
	{
		String at = NBC_Clock.WindowLine(w);
		switch (ev)
		{
		case EV_WAR: return String.Format("A rival crew hit %s. Go in at %s: fewer of them standing, and hurt.", place, at);
		case EV_CROWD: return String.Format("%s is packed with people. Go in at %s: the crowd covers you, but the first shot wakes the block. Fire in a crowd is a strike.", place, at);
		case EV_DEAL: return String.Format("A deal goes down in %s at %s. The leader's out with two more guards. Double the bounty.", place, at);
		case EV_BLACKOUT: return String.Format("The power's out in %s. Go in at %s: pitch dark, and half of them can't see their own hands.", place, at);
		case EV_PINNED: return String.Format("A patrol unit is pinned down in %s. Get them out at %s, today, or Internal Affairs gives you a strike. City Hall pays $%d.", place, at, NBC_Clock.PINNED_PAY);
		}
		return "";
	}

	// the hours an event can happen at
	play static int EventWindow(int ev, NBC_RunData rd)
	{
		switch (ev)
		{
		case EV_WAR: return rd.Rand(0, 1) ? W_NIGHT : W_DUSK;
		case EV_CROWD: return rd.Rand(0, 1) ? W_DUSK : W_AFTERNOON;
		case EV_BLACKOUT: return W_NIGHT;
		case EV_PINNED: return rd.Rand(0, 1) ? W_AFTERNOON : W_MORNING;
		}
		return rd.Rand(0, W_COUNT - 1);
	}

	// The block at the hour: the sky, the light, the tint. dark: the blackout's extra darkness.
	play static void LightTheBlock(int w, int dark)
	{
		w = clamp(w, 0, W_COUNT - 1);
		if (NBC_Clock.WIN_SKY[w] != "")
		{
			TextureID sky = TexMan.CheckForTexture(NBC_Clock.WIN_SKY[w], TexMan.Type_Any);
			if (sky.IsValid()) level.ChangeSky(sky, sky);
		}
		for (int i = 0; i < level.Sectors.Size(); i++)
		{
			Sector s = level.Sectors[i];
			bool outdoors = s.GetTexture(Sector.ceiling) == skyflatnum;
			int add = (outdoors ? NBC_Clock.LIGHT_OUT[w] : NBC_Clock.LIGHT_IN[w]) - dark;
			if (add) s.SetLightLevel(clamp(s.lightlevel + add, dark > 0 ? 16 : 32, 255));
			if (outdoors && NBC_Clock.TINT[w] != 0xFFFFFF) s.SetColor(NBC_Clock.TINT[w]);
		}
	}
}

// A gang member off guard (asleep, high, half-watching): stands frozen where they are and notices nothing until
// they're shot, someone fires nearby (they're up a few seconds later), an officer walks right up to them, or your
// flashlight's beam falls on them (NBC_Player's F toggle: in the dark it's see or be seen). On a crowded street the
// first shot at any of them wakes the whole block (NBC_RunManager.blockAwake).
class NBC_OffGuard : Inventory
{
	const SEE_RANGE = 320.0;
	const BEAM_RANGE = 512.0;        // the flashlight's reach (NBC_Player.UpdateNBCFlashlight)
	const BEAM_ANGLE = 24.0;
	int wakeAt, startHealth;
	Actor noticed;

	Default
	{
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		Inventory.MaxAmount 1;
	}

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		wakeAt = -1;
		startHealth = other.health;
		other.target = null;
		other.tics = -1;            // frozen in their standing frame: no looking about
	}

	void WakeIn(int delay, Actor who = null)
	{
		int t = level.maptime + delay;
		if (wakeAt < 0 || t < wakeAt) wakeAt = t;
		if (who && !noticed) noticed = who;
	}

	void Up()
	{
		let o = Owner;
		if (o && o.health > 0 && o.InStateSequence(o.CurState, o.SpawnState))
		{
			if (noticed && noticed.health > 0)
			{
				o.target = noticed;
				o.SetState(o.SeeState);
			}
			else o.SetState(o.SpawnState);
		}
		Destroy();
	}

	override void DoEffect()
	{
		Super.DoEffect();
		let o = Owner;
		if (!o || o.health <= 0) { Destroy(); return; }
		// shot: wide awake (the pain state has already taken over)
		if (o.health < startHealth || !o.InStateSequence(o.CurState, o.SpawnState)) { Destroy(); return; }
		if (wakeAt >= 0 && level.maptime >= wakeAt) { Up(); return; }
		o.tics = -1;
		o.target = null;
		if (level.maptime % 8) return;
		// gunfire nearby: up in a few seconds
		if (o.CurSector.SoundTarget && wakeAt < 0) WakeIn(random[nbcoff](35 * 2, 35 * 5), o.CurSector.SoundTarget);
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (rm && rm.blockAwake && wakeAt < 0) WakeIn(random[nbcoff](10, 50), players[consoleplayer].mo);
		// someone right on top of them
		let p = players[consoleplayer].mo;
		if (p && o.Distance3D(p) < SEE_RANGE && o.CheckSight(p)) WakeIn(random[nbcoff](20, 45), p);
		// a light in their face
		let np = NBC_Player(p);
		if (np && np.nbcFlashlightOn && o.Distance3D(p) < BEAM_RANGE && abs(Actor.DeltaAngle(p.angle, p.AngleTo(o))) < BEAM_ANGLE && o.CheckSight(p))
			WakeIn(random[nbcoff](10, 30), p);
		if (rm)
			for (int i = 0; i < rm.squad.Size(); i++)
			{
				let a = rm.squad[i];
				if (a && a.health > 0 && o.Distance3D(a) < SEE_RANGE * 0.75 && o.CheckSight(a)) { WakeIn(random[nbcoff](20, 45), a); break; }
			}
	}
}
