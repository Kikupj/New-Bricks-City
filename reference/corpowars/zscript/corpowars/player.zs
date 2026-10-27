// =============================================================================
// Corpo Wars — the player
// Ledge climbing, from "Ledge Climbing" by Dodopod (climbing.pk3; see CREDITS.txt), fixed and extended:
//  - climbs furniture and props too (crates, pallets, dumpsters, desks...), not only map ledges, so a prop
//    the generator dropped in a doorway or passage is something to climb over, not a dead end
//  - no crash with no weapon raised; the weapon comes back up cleanly
//  - arrives crouched on top without the view jerk, and stands up only where there's room
//  - probes left and right of centre too, so a crate a little off-centre is still climbable
// Hold JUMP facing a ledge 25..60 units high. cw_climb 0 turns it off.
//
// Grounded movement, from "Build Movement" by Pato Fanatico (buildmovev2.pk3; after Nash Muhandes' NashMove,
// see CREDITS.txt): on the ground the player gets extra friction every tic and more push to compensate, so you
// stop almost dead when you let go and top out slower than vanilla Doom. Tuned slower than the original for
// stealth (cw_movespeed 1.6 vs 1.9: running ~12 u/tic instead of ~16.7). Also from it: a camera flinch on a hard
// landing (with a brief slowdown) and a roll + red flash on death. Changes from the mod: per player, works when
// standing on props (the mod only checked the map floor), off while climbing, no weapon-offset drift, no
// level-wide air-control changes, none of the other-mod compatibility code. cw_buildmove 0 = vanilla movement.
// =============================================================================
class CW_Player : DoomPlayer
{
	Default
	{
		Player.ViewHeight 48;   // eye height (DoomPlayer default 41); crouch, lean and climb all scale from this
	}

	const CLIMB_REACH = 10;     // how far past our radius we feel for a ledge
	const CLIMB_SPEED = 3;      // units per tic going up
	const CLIMB_THRUST = 4;     // push onto the ledge at the top
	const MAX_LEDGE = 60;       // highest thing we can pull up on (containers and tanks are too tall)

	bool climbing;
	double climbTop;     // absolute z of the ledge we're pulling up on
	Vector2 climbFrom;
	// grounded movement / landing flinch
	const GROUND_FRICTION = 0.88;
	int fallState, fallTics, flinchTics;
	bool deathRolled;
	bool waitRelease;    // just climbed up: ignore JUMP until it's let go (no hop on arrival)

	// Height of what's in front of us relative to our feet: map floor (incl. 3D floors) or the top of a
	// solid prop. Returns a big number for a wall / something too tall.
	double LedgeAt(double sideOfs)
	{
		Vector2 dir = AngleToVector(angle);
		Vector2 p = pos.xy + dir * (radius + CLIMB_REACH) + AngleToVector(angle + 90) * sideOfs;

		// map geometry: look from just above the reachable height so thin 3D floors count
		double top;
		{
			Vector3 old = pos;
			SetXYZ(pos + (0, 0, MAX_LEDGE));
			top = GetZAt(p.x, p.y, 0, GZF_ABSOLUTEPOS | GZF_ABSOLUTEANG);
			SetXYZ(old);
		}
		double ceil = GetZAt(p.x, p.y, 0, GZF_ABSOLUTEPOS | GZF_ABSOLUTEANG | GZF_CEILING);
		if (ceil - pos.z < MAX_LEDGE) return 1e6;   // low opening / wall face

		// solid props (furniture blockers, crates, dumpsters) standing there
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, pos.z, MAX_LEDGE + 8, 8, false);
		while (it.Next())
		{
			let a = it.thing;
			if (!a || a == self || !a.bSOLID || a.bISMONSTER || a.player || (a.bSHOOTABLE && a.health > 0)) continue;
			if (abs(a.pos.x - p.x) > a.radius + 2 || abs(a.pos.y - p.y) > a.radius + 2) continue;
			double az = a.pos.z + a.height;
			if (a.pos.z > pos.z + MAX_LEDGE) continue;       // hanging above us
			if (az > pos.z + MAX_LEDGE) return 1e6;          // too tall to pull up on
			top = max(top, az);
		}
		return top - pos.z;
	}

	double Clearance(double over)
	{
		Vector2 p = pos.xy + AngleToVector(angle) * (radius + CLIMB_REACH);
		double c = GetZAt(p.x, p.y, 0, GZF_ABSOLUTEPOS | GZF_ABSOLUTEANG | GZF_CEILING);
		return c - (pos.z + over);
	}

	void EndClimb()
	{
		climbing = false;
		bNoGravity = false;
		viewBob = 1.0;
		let wpn = player.readyWeapon;
		if (wpn) player.SetPsprite(PSP_WEAPON, wpn.GetUpState());
		player.jumpTics = -1;
	}

	override void CheckJump()
	{
		if (!player || health <= 0 || !CVar.GetCVar('cw_climb', player).GetBool())
		{
			if (climbing) EndClimb();
			Super.CheckJump();
			return;
		}
		bool jump = player.cmd.buttons & BT_JUMP;
		if (waitRelease)
		{
			if (jump) return;
			waitRelease = false;
		}

		// straight ahead first; if that's a wall or open floor, the sides (a crate off-centre still counts)
		double ledge = LedgeAt(0);
		if (!climbing && (ledge <= MaxStepHeight || ledge > MAX_LEDGE))
			for (int k = -1; k <= 1; k += 2)
			{
				double h = LedgeAt(k * radius * 0.7);
				if (h > MaxStepHeight && h <= MAX_LEDGE) { ledge = h; break; }
			}

		if (!climbing)
		{
			if (jump && player.onground && ledge > MaxStepHeight && ledge <= MAX_LEDGE)
			{
				climbing = true;
				climbTop = pos.z + ledge;
				climbFrom = pos.xy;
				bNoGravity = true;   // hold on to the wall while climbing
				A_StartSound("*climb", CHAN_BODY);
				viewBob = 0.0;
			}
		}
		else if (!jump || (pos.xy - climbFrom).Length() > 24)
		{
			EndClimb();                                                          // let go / pushed off the wall
		}
		else if (pos.z >= climbTop - MaxStepHeight)                              // at the top
		{
			if (Clearance(climbTop - pos.z) >= FullHeight * 0.5)
			{
				// arrive crouched; CheckCrouch stands us up again where there's headroom
				player.crouchfactor = 0.5;
				player.viewheight = ViewHeight * 0.5;
				player.crouchviewdelta = player.viewheight - ViewHeight;
				A_SetSize(-1, FullHeight * 0.5);
				SetOrigin((pos.xy, climbTop + 1), true);
				VelFromAngle(CLIMB_THRUST, angle);
				EndClimb();
				waitRelease = true;
				return;
			}
			vel = (0, 0, 0);                                                     // hang on: no room on top
			return;
		}

		if (climbing)
		{
			let wpn = player.readyWeapon;
			if (wpn)
			{
				player.SetPsprite(PSP_WEAPON, wpn.GetDownState());
				let psp = player.GetPsprite(PSP_WEAPON);
				if (psp) psp.y = min(psp.y + 6, WEAPONBOTTOM);
			}
			// pull up: move the body directly (velocity alone doesn't lift a grounded player here)
			vel = (0, 0, 0);
			if (ceilingz - (pos.z + height) >= CLIMB_SPEED) SetZ(pos.z + CLIMB_SPEED);
			return;   // no jump while on the wall
		}
		Super.CheckJump();
	}

	// ---------------------------------------------------------------- grounded movement
	override void Tick()
	{
		Super.Tick();
		if (!player || player.mo != self) return;
		bool on = CVar.GetCVar('cw_buildmove', player).GetBool();
		bool frozen = player.cheats & CF_TOTALLYFROZEN;
		bool grounded = player.onground || bOnMobj || pos.z <= floorz;
		if (!on || frozen || climbing || waterlevel >= 2)
		{
			if (Speed != Default.Speed) A_SetSpeed(Default.Speed);
		}
		else if (grounded)
		{
			A_SetSpeed(Default.Speed * CVar.GetCVar('cw_movespeed', player).GetFloat());
			vel.xy *= GROUND_FRICTION;
		}

		if (health <= 0)
		{
			if (!deathRolled && CVar.GetCVar('cw_deathroll', player).GetBool())
			{
				deathRolled = true;
				A_SetRoll(randompick(-1, 1) * random(60, 110), SPF_INTERPOLATE);
				A_SetBlend("Red", 0.5, 35, "Red", 0.025);
			}
			return;
		}
		deathRolled = false;

		// landing flinch: after a real fall (not a step down) the view dips and you're slowed a moment
		if (!CVar.GetCVar('cw_landflinch', player).GetBool() || waterlevel || bFly || climbing) { fallState = 0; fallTics = 0; return; }
		int grav = max(1, CVar.GetCVar('sv_gravity').GetInt());
		switch (fallState)
		{
		case 0:
			if (vel.z < 0 && !grounded) { if (++fallTics > 8000 / grav) fallState = 1; }
			else fallTics = 0;
			break;
		case 1:
			if (grounded)
			{
				A_SetViewPitch(ViewPitch + 8, SPF_INTERPOLATE);
				flinchTics = 10;
				fallState = 2; fallTics = 0;
			}
			break;
		case 2:
			if (flinchTics > 0)
			{
				if (flinchTics > 6) vel.xy *= 0.77;
				A_SetViewPitch(ViewPitch - 0.8, SPF_INTERPOLATE);
				flinchTics--;
			}
			else { A_SetViewPitch(0, SPF_INTERPOLATE); fallState = 0; }
			break;
		}
	}
}
