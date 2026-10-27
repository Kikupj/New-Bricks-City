// =============================================================================
// Corpo Wars — 3D furniture (models built by CorpoWars_tools/make_models.py, see modeldef.props.txt)
//
// Each piece is a model actor whose +x points to its front (the side a person uses). Collision: the
// visual actor itself is not solid; on spawn it lays a row of invisible square CW_Blockers over its
// rectangular footprint (depth along its facing, width across), so long desks and counters block
// like the rectangles they are instead of one fat cylinder. Wall-mounted pieces have no footprint.
// Always place with angles in 90-degree steps.
// =============================================================================
class CW_Blocker : Actor
{
	Default
	{
		+SOLID; +NOGRAVITY; +DONTTHRUST; +NOBLOOD; +NOTAUTOAIMED; +DONTSPLASH;
		RenderStyle "None";
		Radius 8; Height 32;
	}
	States { Spawn: TNT1 A -1; Stop; }
}

// Furniture is cover: a guard can't see you if every line from his eyes to the top of your head passes
// through a piece of solid furniture below its top surface. Crouch behind a desk or counter to break line
// of sight; tall shelving and racks hide you standing up.
class CW_Cover play
{
	static bool Behind(Actor looker, Actor target)
	{
		Vector3 eye = looker.pos + (0, 0, looker.height * 0.85);
		Vector3 head = target.pos + (0, 0, max(target.height - 4, 8));
		Vector2 d = head.xy - eye.xy;
		double len = d.Length();
		if (len < 48) return false;
		for (double t = 16; t < len - 8; t += 24)
		{
			Vector2 p = eye.xy + d * (t / len);
			let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 0, 40, false);
			while (it.Next())
			{
				let b = CW_Blocker(it.thing);
				if (!b || !b.bSOLID) continue;
				double tb = clamp(((b.pos.xy - eye.xy) dot d) / (len * len), 0, 1);
				if (tb * len < 20 || (1 - tb) * len < 6) continue;
				Vector2 q = eye.xy + d * tb;
				if (abs(q.x - b.pos.x) > b.radius || abs(q.y - b.pos.y) > b.radius) continue;
				double z = eye.z + (head.z - eye.z) * tb;
				if (z < b.pos.z + b.height) return true;
			}
		}
		return false;
	}
}

class CW_Furniture : Actor
{
	double fDepth, fWidth;      // footprint: along the facing, across it
	property Footprint: fDepth, fWidth;
	Array<Actor> blockers;

	Default
	{
		+NOGRAVITY; +DONTSPLASH; +NOBLOOD; +DONTTHRUST; +NOTAUTOAIMED;
		Radius 8; Height 32;
		CW_Furniture.Footprint 0, 0;
	}
	States { Spawn: CWMD A -1; Stop; }

	// Largest half-extent: lets placement code test clearance before spawning.
	static double HalfSize(class<CW_Furniture> cls)
	{
		let d = CW_Furniture(GetDefaultByType(cls));
		return max(d.fDepth, d.fWidth) / 2;
	}

	// Lay the collision blockers now (the generator calls this right after placing a piece, so later
	// placement tests see it); PostBeginPlay covers pieces spawned any other way.
	void MakeBlockers()
	{
		if (blockers.Size() || fDepth <= 0 || fWidth <= 0) return;
		double a = angle;
		Vector2 fwd = AngleToVector(a), side = AngleToVector(a + 90);
		double shortS = min(fDepth, fWidth), longS = max(fDepth, fWidth);
		Vector2 along = fDepth >= fWidth ? fwd : side;
		int n = int(ceil(longS / shortS - 0.01));
		double r = shortS / 2;
		double span = longS - shortS;
		for (int k = 0; k < n; k++)
		{
			double t = n > 1 ? -span / 2 + span * k / (n - 1) : 0;
			let b = Spawn("CW_Blocker", pos + (along * t, 0));
			if (!b) continue;
			b.A_SetSize(r, Height);
			blockers.Push(b);
		}
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		MakeBlockers();
	}

	override void OnDestroy()
	{
		for (int k = 0; k < blockers.Size(); k++) if (blockers[k]) blockers[k].Destroy();
		Super.OnDestroy();
	}
}

// ---------------------------------------------------------------- desks & seating
class CW_FDeskWork   : CW_Furniture { Default { Height 31; CW_Furniture.Footprint 30, 60; Tag "Workstation"; } }
class CW_FDeskCode   : CW_Furniture { Default { Height 31; CW_Furniture.Footprint 30, 60; Tag "Workstation"; } }
class CW_FDeskExec   : CW_Furniture { Default { Height 32; CW_Furniture.Footprint 36, 84; Tag "Executive desk"; } }
class CW_FChair      : CW_Furniture { Default { Height 38; Tag "Office chair"; } }
class CW_FChairExec  : CW_Furniture { Default { Height 46; Tag "Executive chair"; } }
class CW_FChairGuest : CW_Furniture { Default { Height 34; Tag "Chair"; } }
class CW_FSofa       : CW_Furniture { Default { Height 32; CW_Furniture.Footprint 36, 84; Tag "Sofa"; } }
class CW_FArmchair   : CW_Furniture { Default { Height 30; CW_Furniture.Footprint 32, 32; Tag "Armchair"; } }
class CW_FCoffeeTable: CW_Furniture { Default { Height 16; CW_Furniture.Footprint 28, 48; Tag "Coffee table"; } }
class CW_FConfTable  : CW_Furniture { Default { Height 31; CW_Furniture.Footprint 88, 40; Tag "Conference table"; } }
class CW_FRoundTable : CW_Furniture { Default { Height 28; CW_Furniture.Footprint 32, 32; Tag "Table"; } }
class CW_FReception  : CW_Furniture { Default { Height 46; CW_Furniture.Footprint 40, 116; Tag "Reception desk"; } }

// ---------------------------------------------------------------- storage, tech, services
class CW_FFileCabinet: CW_Furniture { Default { Height 52; CW_Furniture.Footprint 26, 18; Tag "File cabinet"; } }
class CW_FBookshelf  : CW_Furniture { Default { Height 72; CW_Furniture.Footprint 14, 36; Tag "Bookshelf"; } }
class CW_FServerRack : CW_Furniture { Default { Height 80; CW_Furniture.Footprint 42, 24; Tag "Server rack"; } }
class CW_FShelving   : CW_Furniture { Default { Height 72; CW_Furniture.Footprint 22, 66; Tag "Pallet racking"; } }
class CW_FVending    : CW_Furniture { Default { Height 72; CW_Furniture.Footprint 32, 36; Tag "Vending machine"; } }
class CW_FCopier     : CW_Furniture { Default { Height 38; CW_Furniture.Footprint 24, 30; Tag "Copier"; } }
class CW_FWaterCooler: CW_Furniture { Default { Height 46; CW_Furniture.Footprint 14, 14; Tag "Water cooler"; } }
class CW_FCounter    : CW_Furniture { Default { Height 50; CW_Furniture.Footprint 24, 96; Tag "Kitchen counter"; } }
class CW_FLabBench   : CW_Furniture { Default { Height 58; CW_Furniture.Footprint 30, 96; Tag "Lab bench"; } }
class CW_FBin        : CW_Furniture { Default { Height 15; Tag "Waste bin"; } }
class CW_FPlanter    : CW_Furniture { Default { Height 30; CW_Furniture.Footprint 26, 82; Tag "Planter"; } }
class CW_FCredenza   : CW_Furniture { Default { Height 31; CW_Furniture.Footprint 20, 62; Tag "Low cabinet"; } }
class CW_FStalls     : CW_Furniture { Default { Height 62; CW_Furniture.Footprint 48, 76; Tag "Toilet stalls"; } }
class CW_FVanity     : CW_Furniture { Default { Height 36; CW_Furniture.Footprint 20, 64; Tag "Washbasins"; } }
class CW_FStairFlight: CW_Furniture { Default { Height 80; CW_Furniture.Footprint 90, 36; Tag "Stairs"; } }
class CW_FPartition  : CW_Furniture { Default { Height 48; CW_Furniture.Footprint 4, 66; Tag "Cubicle screen"; } }

// ---------------------------------------------------------------- wall-mounted (no footprint)
class CW_FWhiteboard : CW_Furniture { Default { Height 62; Tag "Whiteboard"; } }
class CW_FWallTV     : CW_Furniture { Default { Height 66; Tag "Screen"; } }
class CW_FElevRail   : CW_Furniture { Default { Height 34; Tag "Handrail"; } }
class CW_FDoorFrame  : CW_Furniture { Default { Height 85; +NOBLOCKMAP; Tag "Door frame"; } }
class CW_FDoorFrameW : CW_Furniture { Default { Height 85; +NOBLOCKMAP; Tag "Door frame"; } }
