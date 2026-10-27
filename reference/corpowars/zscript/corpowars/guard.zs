// =============================================================================
// Corpo Wars — Guard AI
// Three awareness states layered on top of Universal Enhanced AI:
//   UNAWARE     patrols, limited vision cone, suspicion builds from sight
//   SUSPICIOUS  walks to the last thing it saw/heard, looks around, calms down
//   ALERT       hands over to vanilla combat + UEAI chase/search
// =============================================================================

// Patrol waypoint. Place in the map with a TID.
//   arg0 = TID of the next point (0 = stop here)
//   arg1 = tics to wait at this point (35 = 1 second)
class CW_PatrolPoint : Actor
{
	Default
	{
		+NOINTERACTION;
		+NOBLOCKMAP;
		RenderStyle "None";
	}
	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}
}

// Guard. arg0 = TID of the first patrol point (0 = stationary post).
class CW_Guard : ZombieMan
{
	enum EAwareness
	{
		AW_UNAWARE,
		AW_SUSPICIOUS,
		AW_ALERT
	}

	int awareness;
	double suspicion;       // 0..100
	bool cautious;          // has been alerted before: wider cone, longer sight
	bool bodyFound;         // (as a corpse) someone already found this body
	bool knockedOut;        // went down to a takedown, not killed
	int cleanTics;          // Marrow removes the body when this hits 0
	bool hitByPlayer;       // player caused damage (for kill credit / fines)
	int tranqTics;          // >0 = dart in, drops when it hits 0
	int stunTics;           // flashbanged
	int taserHits;
	Vector3 investigatePos;
	double scanPhase;       // stationary posts: where in the sweep this guard starts
	int lookAroundTics;     // >0 = arrived at investigate point, scanning
	int investigateTics;    // gives up walking if stuck
	int waitTics;
	double postAngle;
	Actor patrolNode;
	bool moving;
	int avoidTics, stuckTics;
	// pathfinding state
	Array<double> routeX, routeY;
	int routeIdx, routeAge, directCheck;
	bool directOk;
	Vector2 routeGoal;
	double avoidAngle;
	bool hasPass;           // carries a security pass (drops it when downed, lethal or not)
	enum EAppearance { LOOK_MALE, LOOK_FEMALE, LOOK_SUPERVISOR }
	int appearance;
	double sightRange;
	property SightRange: sightRange;

	const FOV_NORMAL = 50.0;     // half-angle, degrees
	const FOV_CAUTIOUS = 70.0;
	const SPEED_PATROL = 1.6;
	const SPEED_INVESTIGATE = 2.4;
	static const Name SKIN_TONES[] = { 'CWGuardLight', 'CWGuardTan', 'CWGuardBrown', 'CWGuardDeep' };
	static const Name MILITIA_TONES[] = { 'CWGuardMilitiaLight', 'CWGuardMilitiaTan', 'CWGuardMilitiaBrown', 'CWGuardMilitiaDeep' };
	static const Name LIVE_SPRITES[] = { 'CWMA', 'CWFA', 'CWGA' };
	static const Name DOWN_SPRITES[] = { 'CWMB', 'CWFB', 'CWGB' };

	Default
	{
		Tag "Security Guard";
		CW_Guard.SightRange 1024;
		// one security team: a stray round from a colleague never starts a firefight between guards
		Species "CWSecurity";
		+NOINFIGHTING;
		+DONTHARMSPECIES;
		AttackSound "cw/guard/fire";
		ActiveSound "";
		Obituary "%o was taken down by corporate security.";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		// Pick once: the actor's translation persists through every animation and saves.
		appearance = self is "CW_SecuritySupervisor" ? LOOK_SUPERVISOR : Random(LOOK_MALE, LOOK_FEMALE);
		int tone = Random(0, SKIN_TONES.Size() - 1);
		A_SetTranslation(appearance == LOOK_SUPERVISOR ? SKIN_TONES[tone] : MILITIA_TONES[tone]);
		// voices (DeePayback Enemies): PMC male / female for the guards, USA male for the supervisor
		static const String VOICE[] = { "cw/guardm/", "cw/guardf/", "cw/guards/" };
		String v = VOICE[appearance];
		SeeSound = v .. "see"; PainSound = v .. "pain"; DeathSound = v .. "die";
		SetLook(false);
		postAngle = angle;
		scanPhase = frandom(0, 360);
		if (args[0])
			patrolNode = level.CreateActorIterator(args[0], "CW_PatrolPoint").Next();
	}

	// Switch to this guard's sprite set; keeps the current sprite if the name isn't registered.
	void SetLook(bool down)
	{
		int a = clamp(appearance, LOOK_MALE, LOOK_SUPERVISOR);
		int idx = GetSpriteIndex(down ? DOWN_SPRITES[a] : LIVE_SPRITES[a]);
		if (idx >= 0) sprite = idx;
	}
	// ---------------------------------------------------------------- think
	void CW_Think()
	{
		// Spawn names a real sprite; subsequent #### states keep this appearance.
		SetLook(false);
		// Coming back from combat (lost the target): stay on edge.
		if (awareness == AW_ALERT)
		{
			awareness = AW_SUSPICIOUS;
			cautious = true;
			suspicion = 50;
			investigatePos = pos;
			lookAroundTics = 1;
		}

		Sense();
		if (awareness == AW_ALERT) return;   // just switched to combat

		if (level.maptime % 8 == 0) CheckBodies();

		moving = false;
		let eai = EnhancedAIScript(FindInventory("EnhancedAIScript"));
		bool uaiSearching = eai && eai.AIMode == 2;   // UEAI is wandering us around
		if (!uaiSearching)
		{
			if (awareness == AW_SUSPICIOUS) Investigate();
			else Patrol();
		}
		else moving = true;

		// Shared DeePayback frame layout: A-D walk, T relaxed pistol stance.
		frame = moving ? (level.maptime / 6) % 4 : 19;
	}

	// ---------------------------------------------------------------- senses
	// A leaning player's head, out past the corner: clear line from our eyes to it?
	bool SeesPeek(Actor pm)
	{
		if (!CW_Lean.Peeking(pm)) return false;
		Vector3 head = CW_Lean.PeekPos(pm);
		double eyez = height * 0.85;
		Vector3 d = level.Vec3Diff(pos + (0, 0, eyez), head);
		double dist = d.Length();
		if (dist < 1) return true;
		FLineTraceData t;
		LineTrace(VectorAngle(d.x, d.y), dist, -atan2(d.z, d.xy.Length()), TRF_THRUACTORS | TRF_THRUHITSCAN, eyez, 0, 0, t);
		return t.HitType == TRACE_HitNone || t.Distance >= dist - 4;
	}

	void Sense()
	{
		if (level.maptime < 35 * 2) return;   // grace period on map start

		double best = 0;
		Actor seen = null;
		double range = cautious ? sightRange * 1.25 : sightRange;
		double fov = (cautious || awareness == AW_SUSPICIOUS) ? FOV_CAUTIOUS : FOV_NORMAL;

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i]) continue;
			let pm = players[i].mo;
			if (!pm || pm.health <= 0 || (players[i].cheats & CF_NOTARGET)) continue;

			double d = Distance3D(pm);
			if (d > range) continue;
			if (d > 56 && abs(DeltaAngle(angle, AngleTo(pm))) > fov) continue;
			// the body in view (and not behind furniture), or else only a head peeking round a corner (lean)
			double peek = 1.0;
			if (!CheckSight(pm, SF_IGNOREVISIBILITY) || CW_Cover.Behind(self, pm))
			{
				if (!SeesPeek(pm)) continue;
				peek = 0.4;
			}

			double vis = 1.0;
			let st = EAI_StealthScript(pm.FindInventory("EAI_StealthScript"));
			if (st) vis = st.visibility;
			vis *= peek;

			double nearness = 1.0 - d / range;
			double gain = vis * (0.12 + 3.0 * nearness * nearness);
			if (awareness == AW_SUSPICIOUS) gain *= 1.5;
			if (d < 96 && vis > 0.15) gain = 100;   // bumped into them

			if (gain > best) { best = gain; seen = pm; }
		}

		if (seen)
		{
			suspicion += best;
			if (suspicion >= 100)
			{
				BecomeAlert(seen);
				return;
			}
			if (suspicion >= 25)
			{
				if (awareness == AW_UNAWARE) BeginInvestigate(seen.pos);
				investigatePos = seen.pos;
				lookAroundTics = 0;
				investigateTics = 0;
			}
		}
		else if (awareness == AW_UNAWARE)
		{
			suspicion = max(0.0, suspicion - 0.2);
		}
	}

	void CheckBodies()
	{
		let it = BlockThingsIterator.Create(self, 700);
		while (it.Next())
		{
			Actor g = it.thing;
			let gg = CW_Guard(g);
			let cv = CW_Civilian(g);
			if ((!gg && !cv) || g == self || g.health > 0) continue;
			if ((gg && gg.bodyFound) || (cv && cv.bodyFound)) continue;
			if (Distance2D(g) > 700) continue;
			if (abs(DeltaAngle(angle, AngleTo(g))) > FOV_CAUTIOUS) continue;
			if (!CheckSight(g, SF_IGNOREVISIBILITY)) continue;

			if (gg) gg.bodyFound = true; else cv.bodyFound = true;
			let lb = CW_Ledger.Of(players[consoleplayer].mo);
			if (lb && lb.missionActive) lb.bodiesFound++;
			cautious = true;
			BeginInvestigate(g.pos);
			suspicion = max(suspicion, 60.0);
			A_StartSound(SeeSound, CHAN_VOICE);
			CW_Handler.RaiseAlarm(self, g.pos, 1200);
			return;
		}
	}

	// Called by the noise system and by allies raising the alarm.
	// loud: 0..1
	void HearNoise(Vector3 at, double loud)
	{
		if (health <= 0 || awareness == AW_ALERT) return;
		suspicion = max(suspicion, 25 + loud * 50);
		if (loud >= 0.5) cautious = true;
		BeginInvestigate(at);
	}

	void BeginInvestigate(Vector3 at)
	{
		if (awareness == AW_UNAWARE) A_StartSound(ActiveSound, CHAN_VOICE);
		awareness = AW_SUSPICIOUS;
		investigatePos = at;
		lookAroundTics = 0;
		investigateTics = 0;
	}

	void BecomeAlert(Actor who)
	{
		awareness = AW_ALERT;
		suspicion = 100;
		cautious = true;
		target = who;
		A_StartSound(SeeSound, CHAN_VOICE);
		CW_Handler.RaiseAlarm(self, who.pos, 900);
		SetStateLabel("See");
	}

	// ---------------------------------------------------------------- movement
	void Investigate()
	{
		if (lookAroundTics == 0)
		{
			investigateTics++;
			double d = (pos.xy - investigatePos.xy).Length();
			if (d > 40 && investigateTics < 35 * 10 && stuckTics < 50)
			{
				NavTo(investigatePos.xy, SPEED_INVESTIGATE);
				return;
			}
			lookAroundTics = 1;
			stuckTics = 0;
		}

		// Scan left and right.
		lookAroundTics++;
		angle += 3.0 * sin(lookAroundTics * 3.0);
		if (lookAroundTics > 35 * 5)
		{
			awareness = AW_UNAWARE;
			suspicion = 0;
			lookAroundTics = 0;
		}
	}

	void Patrol()
	{
		if (!patrolNode)
		{
			// Stationary post: slowly sweep a 70-degree arc around the post direction (a pause at each end),
			// so a posted guard covers the area he's watching instead of staring at one spot.
			double sweep = 35 * clamp(1.4 * sin(level.maptime * 0.9 + scanPhase), -1.0, 1.0);
			angle += clamp(DeltaAngle(angle, postAngle + sweep), -2.0, 2.0);
			return;
		}
		if (waitTics > 0) { waitTics--; return; }

		if ((pos.xy - patrolNode.pos.xy).Length() < 24)
		{
			waitTics = patrolNode.args[1];
			int nextTid = patrolNode.args[0];
			if (nextTid) patrolNode = level.CreateActorIterator(nextTid, "CW_PatrolPoint").Next();
			else { postAngle = angle; patrolNode = null; }
			return;
		}
		NavTo(patrolNode.pos.xy, SPEED_PATROL);
		if (stuckTics > 70)   // can't reach it: skip to the next point
		{
			stuckTics = 0;
			int nextTid = patrolNode.args[0];
			patrolNode = nextTid ? level.CreateActorIterator(nextTid, "CW_PatrolPoint").Next() : null;
		}
	}

	// Steering: head for dest; when blocked, commit to a sidestep heading for a moment.
	// Walk to dest: straight if the way is clear, otherwise along the nav graph.
	bool NavTo(Vector2 dest, double spd)
	{
		let nav = CW_Handler.Nav();
		if (!nav || nav.Count() == 0) return MoveToward(dest, spd);

		bool newGoal = (routeGoal - dest).Length() > 48;
		if (newGoal || --directCheck <= 0)
		{
			directOk = nav.Clear(pos.xy, dest);
			directCheck = 10;
		}
		if (directOk)
		{
			routeX.Clear(); routeY.Clear();
			routeGoal = dest;
			return MoveToward(dest, spd);
		}

		if (newGoal || routeX.Size() == 0 || ++routeAge > 35 * 4 || stuckTics > 35)
		{
			routeX.Clear(); routeY.Clear();
			routeIdx = 0; routeAge = 0; routeGoal = dest; stuckTics = 0;
			if (nav.Route(pos.xy, dest))
				for (int i = 0; i < nav.path.Size(); i++) { routeX.Push(nav.nx[nav.path[i]]); routeY.Push(nav.ny[nav.path[i]]); }
			routeX.Push(dest.x); routeY.Push(dest.y);
		}

		// reached this waypoint, or can already see the next one -> advance
		if (routeIdx < routeX.Size() - 1)
		{
			Vector2 wp = (routeX[routeIdx], routeY[routeIdx]);
			Vector2 nxt = (routeX[routeIdx + 1], routeY[routeIdx + 1]);
			if ((pos.xy - wp).Length() < 28 || (level.maptime % 8 == 0 && nav.Clear(pos.xy, nxt))) routeIdx++;
		}
		return MoveToward((routeX[routeIdx], routeY[routeIdx]), spd);
	}

	bool MoveToward(Vector2 dest, double spd)
	{
		moving = true;
		Vector2 delta = dest - pos.xy;
		double want = VectorAngle(delta.x, delta.y);

		// Currently walking around an obstacle.
		if (avoidTics > 0)
		{
			avoidTics--;
			angle += clamp(DeltaAngle(angle, avoidAngle), -15.0, 15.0);
			if (TryMove(Vec2Angle(spd, avoidAngle, true), 0)) { stuckTics = 0; return true; }
			avoidTics = 0;
		}

		double diff = DeltaAngle(angle, want);
		angle += clamp(diff, -10.0, 10.0);
		if (abs(diff) > 45) return true;   // turn in place first

		if (TryMove(Vec2Angle(spd, want, true), 0)) { stuckTics = 0; return true; }

		// Blocked: try progressively wider detours, preferring one side at random.
		static const double offsets[] = { 35, 60, 90, 120 };
		double side = random(0, 1) ? 1 : -1;
		for (int i = 0; i < offsets.Size(); i++)
		{
			for (int j = 0; j < 2; j++)
			{
				double a = want + offsets[i] * (j == 0 ? side : -side);
				if (TryMove(Vec2Angle(spd, a, true), 0))
				{
					avoidAngle = a;
					avoidTics = 12 + i * 6;
					stuckTics = 0;
					return true;
				}
			}
		}
		stuckTics++;
		return false;
	}

	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath)
	{
		if (hasPass)
		{
			hasPass = false;
			let p = Spawn("CW_SecurityPass", pos + (0, 0, 16));
			let h = CW_Handler(EventHandler.Find("CW_Handler"));
			let sp = CW_SecurityPass(p);
			if (sp && h && h.floorGen) sp.tier = h.floorGen.mapIdx;
			if (p) p.vel = (frandom(-1.5, 1.5), frandom(-1.5, 1.5), 3);
		}
		Super.Die(source, inflictor, dmgflags, MeansOfDeath);
	}

	// ---------------------------------------------------------------- player interaction
	// Press USE behind a guard who isn't in combat = silent non-lethal takedown.
	override bool Used(Actor user)
	{
		if (health <= 0 || !user || !user.player || awareness == AW_ALERT)
			return Super.Used(user);
		if (Distance2D(user) > 80) return false;
		if (abs(DeltaAngle(angle, AngleTo(user))) < 100) return false;   // must be behind

		knockedOut = true;
		DamageMobj(user, user, health + 10, 'Takedown', DMG_FORCED | DMG_THRUSTLESS | DMG_NO_PAIN);
		return true;
	}

	void Stun(int tics, Vector3 from)
	{
		if (health <= 0) return;
		stunTics = tics;
		target = null;
		awareness = AW_SUSPICIOUS;
		cautious = true;
		suspicion = 60;
		investigatePos = from;
		lookAroundTics = 0;
		investigateTics = 0;
		A_StartSound(PainSound, CHAN_VOICE);
		SetStateLabel("Stunned");
	}

	override void Tick()
	{
		Super.Tick();
		if (health > 0 && tranqTics > 0 && --tranqTics == 0)
		{
			knockedOut = true;
			DamageMobj(null, null, health + 10, 'Takedown', DMG_FORCED | DMG_NO_PAIN | DMG_THRUSTLESS);
			return;
		}
		if (health <= 0 && cleanTics > 0)
		{
			if (--cleanTics < 35) { A_SetRenderStyle(cleanTics / 35.0, STYLE_Translucent); }
			if (cleanTics == 0) { bodyFound = true; Destroy(); }
		}
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		if (mod == 'Taser')
		{
			if (health <= 0) return 0;
			if (++taserHits >= 4)   // ~1 second of contact
			{
				knockedOut = true;
				return Super.DamageMobj(inflictor, source, health + 10, 'Takedown', DMG_FORCED | DMG_NO_PAIN | DMG_THRUSTLESS);
			}
			// staggered: can't fight back while the current flows
			stunTics = max(stunTics, 20);
			target = null;
			awareness = AW_SUSPICIOUS;
			cautious = true;
			suspicion = max(suspicion, 70.0);
			if (source) investigatePos = source.pos;
			if (!InStateSequence(CurState, FindState("Stunned"))) SetStateLabel("Stunned");
			return 0;
		}
		if (mod == 'Tranq')
		{
			if (health > 0 && tranqTics == 0)
			{
				tranqTics = 70;
				if (awareness == AW_UNAWARE) { suspicion = max(suspicion, 40.0); BeginInvestigate(pos); }
			}
			return 0;
		}
		// Player melee (fists) never kills: a blow on an unaware or staggered guard, or one that would have
		// finished him, knocks him out instead (counts as a takedown, no casualty fine).
		if (mod == 'Melee' && source && source.player && health > 0)
		{
			if (awareness == AW_UNAWARE || stunTics > 0 || damage >= health)
			{
				knockedOut = true;
				return Super.DamageMobj(inflictor, source, health + 10, 'Takedown', DMG_FORCED | DMG_NO_PAIN | DMG_THRUSTLESS);
			}
			// dazed: a moment where he can't fight back, so a follow-up punch drops him
			stunTics = max(stunTics, 14);
			target = null;
			awareness = AW_ALERT;
			cautious = true;
			suspicion = 100;
			if (!InStateSequence(CurState, FindState("Stunned"))) SetStateLabel("Stunned");
			return Super.DamageMobj(inflictor, source, damage, 'Takedown', flags | DMG_NO_PAIN, angle);
		}
		if (source && source.player) hitByPlayer = true;
		if (source && source.player && health > 0 && mod != 'Takedown')
		{
			if (awareness == AW_UNAWARE) damage *= 2;   // sneak-attack bonus
			awareness = AW_ALERT;
			cautious = true;
			suspicion = 100;
		}
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}

	States
	{
	Spawn:
		CWGA T 1 CW_Think();
		Loop;
	See:
		#### AABBCCDD 4 A_Chase;
		Loop;
	Missile:
		#### F 10 A_FaceTarget;
		#### G 8 Bright A_PosAttack;
		#### F 8;
		Goto See;
	Pain:
		#### H 3;
		#### H 3 A_Pain;
		Goto See;
	Stunned:
		#### H 1
		{
			if (--stunTics <= 0) { invoker.taserHits = 0; return ResolveState("Spawn"); }
			angle += random(-6, 6);
			return ResolveState(null);
		}
		Loop;
	Death:
		#### I 5;
		#### J 5 A_Scream;
		#### K 5 A_NoBlocking;
		#### L 5;
		#### M -1;
		Stop;
	XDeath:
		Goto Death;
	Death.Takedown:
		#### I 5 { SetLook(true); }
		#### J 5 A_NoBlocking;
		#### KL 5;
		#### M -1;
		Stop;
	Raise:
		#### M 5 { SetLook(false); }
		#### LKJI 5;
		Goto See;
	// Never entered. The engine only loads sprites that some state names: without these lines CWMA/CWFA
	// (regular guards) and every knocked-out sprite were unregistered, GetSpriteIndex returned -1, and the
	// renderer read garbage (guards flickering into furniture models, crashes to desktop).
	SpriteRegistry:
		CWMA ABCDEFGHIJKLMTUV 0;
		CWFA ABCDEFGHIJKLMTUV 0;
		CWGA ABCDEFGHIJKLMTUV 0;
		CWMB IJKLM 0;
		CWFB IJKLM 0;
		CWGB IJKLM 0;
		Stop;
	}
}

// A distinct map actor; inherits guard alarms, patrols, inventory and non-lethal behavior.
class CW_SecuritySupervisor : CW_Guard
{
	Default
	{
		Tag "Security Supervisor";
		Obituary "%o was taken down by a security supervisor.";
		CW_Guard.SightRange 1280;
	}
}
