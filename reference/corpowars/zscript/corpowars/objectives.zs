// =============================================================================
// Corpo Wars — interactable things (USE to interact; HUD shows a prompt)
// =============================================================================
class CW_Interactable : Actor
{
	Default
	{
		+SOLID;
		+SHOOTABLE;
		+NODAMAGE;
		+NOBLOOD;
		Radius 16;
		Height 48;
	}

	virtual String GetPrompt(Actor user) { return ""; }
	virtual void Interact(Actor user) {}

	override bool Used(Actor user)
	{
		if (!user || !user.player || health <= 0) return false;
		Interact(user);
		return true;
	}
}

// ------------------------------------------------------------------ hub
// Invisible hitbox placed in front of a computer-console wall. USE opens the terminal menu.
class CW_ContractBoard : CW_Interactable
{
	Default
	{
		Radius 34;
		Height 56;
		Tag "Broker's terminal";
	}
	override String GetPrompt(Actor user) { return "Broker's terminal"; }
	override void Interact(Actor user)
	{
		A_StartSound("switches/normbutn");
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		if (h) h.terminalRequests++;
	}
	States { Spawn: CWD1 A -1; Stop; }
}

// ------------------------------------------------------------------ mission objectives
class CW_Prototype : CW_Interactable
{
	Default { Radius 16; Height 27; Tag "Objective item"; }
	override String GetPrompt(Actor user)
	{
		let l = CW_Ledger.Of(user);
		let c = l ? l.job : null;
		if (done) return "";
		return c ? c.StealVerb() .. " " .. c.stealItem : "Take the prototype";
	}
	bool done;
	override void Interact(Actor user)
	{
		if (done) return;
		let l = CW_Ledger.Of(user);
		let c = l ? l.job : null;
		int mode = c ? c.stealMode : 0;
		if (l) l.CompleteObjective(OBJ_STEAL);
		if (mode == 1)
		{
			// photographed: the documents stay where they were, nobody the wiser
			done = true;
			user.A_StartSound("misc/w_pkup", CHAN_ITEM);
			return;
		}
		if (mode == 2)
		{
			// planted: the device stays behind
			done = true;
			user.A_StartSound("misc/k_pkup", CHAN_ITEM);
			bSOLID = false;
			A_SetScale(0.6);
			return;
		}
		user.A_StartSound("misc/i_pkup", CHAN_ITEM);
		Destroy();
	}
	States { Spawn: CWC4 A -1; Stop; }
}

class CW_Scientist : CW_Interactable
{
	bool turned, hitByPlayer;
	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		if (mod == 'Melee' && source && source.player) damage = min(damage, health - 1);   // fists never kill the recruit
		if (source && source.player) hitByPlayer = true;
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}
	Default
	{
		-NODAMAGE;
		Health 30;
		Height 56;
		Tag "Recruit target";
		Translation "112:127=192:207";
		DeathSound "grunt/death";
	}
	override String GetPrompt(Actor user)
	{
		if (turned) return "";
		let l = CW_Ledger.Of(user);
		let c = l ? l.job : null;
		return c ? c.TurnPrompt() : "Convince them to defect";
	}
	override void Interact(Actor user)
	{
		if (turned) return;
		turned = true;
		let l = CW_Ledger.Of(user);
		int mode = (l && l.job) ? l.job.turnMode : 0;
		if (l) l.CompleteObjective(OBJ_TURN);
		static const String lines[] = {
			"\"...fine. Get me out of here. I'll meet your people outside.\"",
			"\"All right, all right. I'll tell you what I know. Then you never saw me.\"",
			"\"I'm coming. Don't make a scene.\"",
			"\"About time. My bag's packed. See you outside.\"" };
		Console.Printf("\cj%s", lines[clamp(mode, 0, 3)]);
		SetStateLabel("Leave");
	}
	States
	{
	Spawn:
		PLAY A -1;
		Stop;
	Leave:
		PLAY A 1 A_NoBlocking;
		PLAY A 1 A_FadeOut(0.03);
		Wait;
	Death:
		PLAY H 5;
		PLAY I 5 A_Scream;
		PLAY J 5 A_NoBlocking;
		PLAY KLM 5;
		PLAY N -1;
		Stop;
	}
}

class CW_Server : Actor
{
	Default
	{
		Health 80;
		Radius 16;
		Height 76;
		Mass 10000;
		+SOLID;
		+SHOOTABLE;
		+NOBLOOD;
		+DONTTHRUST;
		Tag "Research server";
	}
	States
	{
	Spawn:
		CWSR A -1;
		Stop;
	Death:
		BEXP C 5 Bright
		{
			A_StartSound("world/barrelx");
			CW_Handler.EmitNoise(self, pos, 1600, 1.0);
			let l = CW_Ledger.Of(players[consoleplayer].mo);
			if (l) l.CompleteObjective(OBJ_DESTROY);
			A_NoBlocking();
		}
		BEXP D 5 Bright;
		BEXP E 10 Bright;
		Stop;
	}
}

// Stand here with the primary done to extract. USE here to abort.
class CW_Extraction : Actor
{
	Default
	{
		+NOINTERACTION;
		+NOBLOCKMAP;
		RenderStyle "None";
	}
	States { Spawn: TNT1 A -1; Stop; }
	int lastWarp;
	int holdTics;   // aborting takes a held USE (exits are everywhere, so a stray tap mustn't end the mission)
	const ABORT_TICS = 52;

	// USE aimed at a door, lift or switch belongs to that door: it never counts as "leave" (exits often sit at a door).
	static bool UseIsForALine(Actor pm)
	{
		for (int k = -1; k <= 1; k++)
		{
			FLineTraceData td;
			if (!pm.LineTrace(pm.angle + k * 12, 72, 0, TRF_THRUACTORS, pm.height * 0.5, 0, 0, td)) continue;
			if (td.HitType == TRACE_HitWall && td.HitLine && td.HitLine.special != 0 && (td.HitLine.activation & (SPAC_Use | SPAC_UseThrough | SPAC_UseBack))) return true;
		}
		return false;
	}

	override void Tick()
	{
		Super.Tick();
		if (level.maptime < 35) return;
		let pm = players[consoleplayer].mo;
		if (!pm || pm.health <= 0 || Distance2D(pm) > 72) { holdTics = 0; return; }

		let l = CW_Ledger.Of(pm);
		bool held = (pm.player.cmd.buttons & BT_USE) != 0;
		if (held && UseIsForALine(pm)) held = false;
		if (!held) holdTics = 0;
		bool usePressed = held && l && l.missionActive ? ++holdTics == ABORT_TICS : (held && !(pm.player.oldbuttons & BT_USE));
		let hh = CW_Handler(EventHandler.Find("CW_Handler"));
		if (hh) hh.abortProgress = (l && l.missionActive) ? double(holdTics) / ABORT_TICS : 0;
		if (l && l.missionActive && l.PrimaryDone())
		{
			// in the building, with the van waiting in the garage (garage insertion, or a hot run rerouted there)
			if (CW_Building.IsFloorMap(level.MapName))
			{
				if (!l.garageRun && !l.rerouted && !l.exitRolled)
				{
					l.exitRolled = true;   // one roll per run
					int chance = clamp(l.Heat() - 25, 0, 60);
					if (Random(0, 99) < chance)
					{
						l.rerouted = true;
						Console.MidPrint(NewSmallFont, "\cgExit's burned.\c- Your driver moved the van to the garage. Get down there.");
					}
				}
				if (l.garageRun || l.rerouted)
				{
					if (level.maptime - lastWarp < 70) return;
					lastWarp = level.maptime;
					l.arriveTower = 9;   // the garage lift
					level.ChangeLevel("G05", 0, CHANGELEVEL_NOINTERMISSION);
					return;
				}
			}
			l.FinishMission(true);
		}
		else if (usePressed)
		{
			// Don't abort if USE was aimed at something else (e.g. the transport crate), or was the USE
			// that just brought you through a stairwell fire door into this spot.
			let h = CW_Handler(EventHandler.Find("CW_Handler"));
			if (h && h.prompt.Length() && h.prompt.Left(8) != "Aborting") { holdTics = 0; return; }
			if (h && h.lastDoorWarp > 0 && level.maptime - h.lastDoorWarp < 35) return;
			if (l && l.missionActive) l.FinishMission(false);
			else level.ChangeLevel("HUB01", 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
		}
	}
}

class CW_LureSound : Actor
{
	Default { +NOINTERACTION; RenderStyle "None"; }
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_StartSound("plats/pt1_stop", CHAN_BODY, 0, 1.0, 0.6);
		TNT1 A 20 A_StartSound("plats/pt1_stop", CHAN_5, 0, 0.8, 0.6);
		Stop;
	}
}

// Oriole staff. Harmless, but a witness: if they spot you they scream and
// every guard nearby comes to look. USE from behind = non-lethal knockout.
class CW_Civilian : Actor
{
	bool panicked, knockedOut, bodyFound, hitByPlayer;
	int cleanTics;
	int panicTics;
	int tranqTics;

	Default
	{
		Health 20;
		Radius 16;
		Height 56;
		Speed 10;
		Mass 100;
		+SHOOTABLE;
		+SOLID;
		+CANPASS;
		Translation "112:127=96:111";   // grey lab coats
		PainSound "grunt/pain";
		DeathSound "grunt/death";
		PainChance 255;
		Tag "Oriole staff";
	}

	bool CanTakedown(Actor user)
	{
		return health > 0 && Distance2D(user) <= 80 && abs(DeltaAngle(angle, AngleTo(user))) >= 100;
	}

	override bool Used(Actor user)
	{
		if (!user || !user.player || !CanTakedown(user)) return false;
		knockedOut = true;
		DamageMobj(user, user, health + 10, 'Takedown', DMG_FORCED | DMG_THRUSTLESS | DMG_NO_PAIN);
		return true;
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		if (mod == 'Tranq') { if (health > 0 && !tranqTics) tranqTics = 70; return 0; }
		if (mod == 'Taser')
		{
			if (health <= 0) return 0;
			knockedOut = true;
			return Super.DamageMobj(inflictor, source, health + 10, 'Takedown', DMG_FORCED | DMG_NO_PAIN | DMG_THRUSTLESS);
		}
		if (mod == 'Melee' && source && source.player)   // fists knock out, never kill
		{
			if (health <= 0) return 0;
			knockedOut = true;
			return Super.DamageMobj(inflictor, source, health + 10, 'Takedown', DMG_FORCED | DMG_NO_PAIN | DMG_THRUSTLESS);
		}
		if (source && source.player) hitByPlayer = true;
		if (!panicked && mod != 'Takedown') Panic(source ? source.pos : pos);
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}

	void Panic(Vector3 where)
	{
		if (panicked || health <= 0) return;
		panicked = true;
		panicTics = 140;   // flee frames (~12 s)
		A_StartSound("grunt/sight", CHAN_VOICE);
		CW_Handler.RaiseAlarm(self, where, 1000);
		SetStateLabel("Flee");
	}

	void Watch()
	{
		if (panicked || level.maptime < 70 || level.maptime % 4) return;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo) continue;
			let pm = players[i].mo;
			double d = Distance3D(pm);
			if (d > 600 || abs(DeltaAngle(angle, AngleTo(pm))) > 70) continue;
			if (!CheckSight(pm, SF_IGNOREVISIBILITY)) continue;
			let st = EAI_StealthScript(pm.FindInventory("EAI_StealthScript"));
			double vis = st ? st.visibility : 1.0;
			if (vis < 0.3 && d > 96) continue;
			Panic(pm.pos);
			return;
		}
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
			if (--cleanTics < 35) A_SetRenderStyle(cleanTics / 35.0, STYLE_Translucent);
			if (cleanTics == 0) { bodyFound = true; Destroy(); }
		}
	}

	States
	{
	Spawn:
		PLAY A 4 Watch();
		Loop;
	Flee:
		PLAY ABCD 3
		{
			A_Wander();
			if (--panicTics <= 0) { panicked = false; return ResolveState("Spawn"); }
			return ResolveState(null);
		}
		Loop;
	Pain:
		PLAY G 4 A_Pain;
		Goto Flee;
	Death:
		PLAY H 5;
		PLAY I 5 A_Scream;
		PLAY J 5 A_NoBlocking;
		PLAY KLM 5;
		PLAY N -1;
		Stop;
	Death.Takedown:
		PLAY H 5;
		PLAY I 5 A_NoBlocking;
		PLAY JK 5;
		PLAY L -1;
		Stop;
	}
}
