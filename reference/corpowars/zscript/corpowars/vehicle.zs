// =============================================================================
// Corpo Wars — drivable car (city prototype, see citygen.zs).
// Parked CW_Car actors use the Voxel Vehicles Pack sprites (decorate.vehicles.txt). USE next to one: the player
// is hidden, parked inside the car, and forward/side move keys become throttle and steering. The view is a chase
// camera (CW_CarCam). USE again to get out beside the car.
// Technique after szeba99/auto (arcade car: speed + steering + friction, moved with TryMove), written from scratch.
// =============================================================================
class CW_CarCam : Actor
{
	Default { +NOINTERACTION; +NOGRAVITY; +NOBLOCKMAP; Radius 4; Height 4; }
	States { Spawn: TNT1 A -1; Stop; }
}

class CW_Car : Actor
{
	const ACCEL = 0.7;          // units/tic gained per tic of throttle
	const BRAKE = 1.1;           // throttle against the direction of travel
	const DRAG = 0.985;          // rolling friction per tic with no throttle
	const MAXFWD = 26.0;         // top speed (units per tic; the player runs ~12)
	const MAXREV = 6.0;
	const TURN = 3.2;            // degrees per tic at full lock and speed
	const CAMDIST = 176.0;
	const CAMHEIGHT = 82.0;
	// The voxels' nose may not point along the actor's angle; this rotates the model relative to the driving
	// direction only if you change it in Spawn (kept 0: voxel front = actor angle).
	PlayerInfo driver;
	double speed;                // signed forward speed
	CW_CarCam cam;
	bool wasClip, wasShootable, wasNoTarget, wasInvis, wasSolid;
	int enterTic;
	int colour;                  // index into the sprite table

	Default
	{
		Radius 28; Height 36; Mass 1000;
		+SOLID; +SHOOTABLE; +NODAMAGE; +NOBLOOD; +CANPASS; +DONTTHRUST; +NOTARGET;
		Tag "Car";
	}
	States { Spawn: RCAR A -1; Stop; }

	static int SpriteCount() { return 11; }

	void SetColour(int c)
	{
		static const String names[] = { "RCAR", "BCAR", "GCAR", "OCAR", "PCAR", "WCAR", "RMOD", "BMOD", "GMOD", "OMOD", "PMOD" };
		colour = abs(c) % SpriteCount();
		sprite = GetSpriteIndex(Name(names[colour]));
	}

	// nearest car within range of the actor (2D), or null
	static CW_Car Find(Actor who, double range)
	{
		let it = ThinkerIterator.Create("CW_Car");
		CW_Car c;
		CW_Car best = null;
		double bd = range;
		while (c = CW_Car(it.Next()))
		{
			double d = (c.pos.xy - who.pos.xy).Length() - c.radius;
			if (d < bd && abs(c.pos.z - who.pos.z) < 64) { bd = d; best = c; }
		}
		return best;
	}

	static CW_Car DrivenBy(PlayerInfo p)
	{
		let it = ThinkerIterator.Create("CW_Car");
		CW_Car c;
		while (c = CW_Car(it.Next())) if (c.driver == p) return c;
		return null;
	}

	void Enter(PlayerInfo p)
	{
		if (driver || !p || !p.mo) return;
		driver = p;
		let pm = p.mo;
		wasClip = pm.bNOCLIP; wasShootable = pm.bSHOOTABLE; wasNoTarget = pm.bNOTARGET; wasInvis = pm.bINVISIBLE; wasSolid = pm.bSOLID;
		pm.bNOCLIP = true; pm.bSHOOTABLE = false; pm.bNOTARGET = true; pm.bINVISIBLE = true; pm.bSOLID = false;
		cam = CW_CarCam(Actor.Spawn("CW_CarCam", pos + (0, 0, CAMHEIGHT)));
		speed = 0;
		enterTic = level.time;
		p.camera = cam;
		UpdateCamera(true);
		Console.MidPrint(SmallFont, "Driving: forward/back = throttle, strafe = steer, USE = get out", true);
	}

	void Exit(bool force = false)
	{
		if (!driver) return;
		let p = driver;
		let pm = p.mo;
		driver = null;
		speed = 0;
		if (pm)
		{
			pm.bNOCLIP = wasClip; pm.bSHOOTABLE = wasShootable; pm.bNOTARGET = wasNoTarget; pm.bINVISIBLE = wasInvis; pm.bSOLID = wasSolid;
			// step out on the left side, else the right, behind, in front. A spot counts only if its floor is
			// level with the street (never onto a raised building lot) and nothing blocks the player there.
			double d = radius + pm.radius + 6;
			Vector2 outp = pos.xy;
			bool found = false;
			static const double tries[] = { 90, -90, 180, 0 };
			for (int i = 0; i < 4 && !found; i++)
			{
				Vector2 q = pos.xy + AngleToVector(angle + tries[i], d + (i >= 2 ? 10 : 0));
				Sector qs = level.PointInSector(q);
				double fz = qs.floorplane.ZAtPoint(q);
				if (abs(fz - pos.z) > 24 || qs.ceilingplane.ZAtPoint(q) - fz < pm.height) continue;
				pm.SetOrigin((q, fz), false);
				if (pm.CheckPosition(q) && pm.floorz <= pos.z + 24) { outp = q; found = true; }
			}
			if (!found && !force)
			{
				// boxed in: stay in the car
				pm.bNOCLIP = true; pm.bSHOOTABLE = false; pm.bNOTARGET = true; pm.bINVISIBLE = true; pm.bSOLID = false;
				pm.SetOrigin(pos, false);
				driver = p;
				if (p == players[consoleplayer]) Console.MidPrint(null, "No room to get out");
				return;
			}
			pm.SetOrigin((outp, level.PointInSector(outp).floorplane.ZAtPoint(outp)), false);
			pm.vel = (0, 0, 0);
			pm.angle = angle;
			p.camera = pm;
		}
		if (cam) { cam.Destroy(); cam = null; }
	}

	void UpdateCamera(bool snap = false)
	{
		if (!cam) return;
		double dist = CAMDIST;
		Vector2 back = -AngleToVector(angle);
		// pull the camera in when it would end up inside a raised block or outside the map
		for (int i = 0; i < 6; i++)
		{
			Vector2 q = pos.xy + back * dist;
			Sector s = level.PointInSector(q);
			if (s && s.floorplane.ZAtPoint(q) <= pos.z + 36 && s.ceilingplane.ZAtPoint(q) > pos.z + CAMHEIGHT) break;
			dist *= 0.7;
		}
		cam.SetOrigin((pos.xy + back * dist, pos.z + CAMHEIGHT), !snap);
		cam.angle = angle;
		cam.pitch = 14;
	}

	override void Tick()
	{
		Super.Tick();
		if (!driver || !driver.mo) { if (driver) Exit(true); return; }
		let pm = driver.mo;
		if (pm.health <= 0) { Exit(true); return; }
		int fm = driver.cmd.forwardmove;
		int sm = driver.cmd.sidemove;
		int thr = fm > 0 ? 1 : (fm < 0 ? -1 : 0);
		int str = sm > 0 ? 1 : (sm < 0 ? -1 : 0);   // + = right
		// throttle, brake, friction
		if (thr != 0)
		{
			bool against = (thr > 0 && speed < -0.1) || (thr < 0 && speed > 0.1);
			speed += thr * (against ? BRAKE : ACCEL);
		}
		else
		{
			speed *= DRAG;
			if (abs(speed) < 0.08) speed = 0;
		}
		speed = clamp(speed, -MAXREV, MAXFWD);
		// steering: needs speed, reverses when backing up
		if (str != 0 && abs(speed) > 0.3)
		{
			double grip = clamp(abs(speed) / 6.0, 0, 1);
			angle -= str * TURN * grip * (speed < 0 ? -1 : 1);
		}
		// move; slide along walls, lose speed on impact
		if (speed != 0)
		{
			Vector2 d = AngleToVector(angle, speed);
			if (!TryMove(pos.xy + d, 1))
			{
				bool moved = TryMove(pos.xy + (d.x, 0), 1) || TryMove(pos.xy + (0, d.y), 1);
				speed *= moved ? 0.85 : 0.3;
			}
		}
		// keep the driver with the car and the chase view behind it
		pm.SetOrigin(pos, false);
		pm.vel = (0, 0, 0);
		pm.angle = angle;
		UpdateCamera();
	}

	override void OnDestroy()
	{
		if (driver) Exit(true);
		Super.OnDestroy();
	}
}

// USE handling (any map): get in next to a car, get out again.
class CW_CarHandler : EventHandler
{
	override void WorldTick()
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i]) continue;
			PlayerInfo p = players[i];
			if (!p.mo) continue;
			bool press = (p.cmd.buttons & BT_USE) && !(p.oldbuttons & BT_USE);
			if (!press) continue;
			let cur = CW_Car.DrivenBy(p);
			if (cur)
			{
				if (level.time - cur.enterTic > 10) cur.Exit();
				continue;
			}
			if (p.mo.health <= 0) continue;
			let c = CW_Car.Find(p.mo, 40);
			if (c && !c.driver) c.Enter(p);
		}
	}
}
