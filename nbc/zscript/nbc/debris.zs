// M1c quick-throw debris, pickups, and reusable rubble piles.

enum NBC_DebrisKind
{
	NBC_DEBRIS_BRICK,
	NBC_DEBRIS_HALF_BRICK,
	NBC_DEBRIS_CONCRETE,
	NBC_DEBRIS_BOTTLE,
	NBC_DEBRIS_KIND_COUNT
}

// A dedicated named stream keeps debris outcomes isolated from weapon and AI randomness.
// RunData will own case/raid seeding when that later system is introduced.
class NBC_DebrisRandom : Actor {}

class NBC_DebrisHooks : Object
{
	// M9 hook: the later noise system consumes the impact position and optional radius.
	static void NBC_DebrisNoise(Vector3 pos, int radius = 0) {}

	// M9 hook: arrest behavior is intentionally not implemented in M1c.
	static void NBC_DebrisArrestStagger(Actor target) {}
}

class NBC_DebrisSatchel : Inventory
{
	int nbcCounts[NBC_DEBRIS_KIND_COUNT];
	int nbcSelected;

Default
{
	Inventory.Amount 1;
	Inventory.MaxAmount 1;
	Inventory.InterHubAmount 1;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}

States { Spawn: TNT1 A -1; Stop; }
}

// Hidden capability marker; all gameplay state stays on the player/satchel.
class NBC_QuickThrow : Inventory
{
Default
{
	Inventory.Amount 1;
	Inventory.MaxAmount 1;
	Inventory.InterHubAmount 1;
	+INVENTORY.UNDROPPABLE;
	+INVENTORY.UNTOSSABLE;
}

States { Spawn: TNT1 A -1; Stop; }
}

class NBC_DebrisPickup : Inventory
{
	virtual int NBC_GetPickupKind() { return -1; }

Default
{
	Inventory.Amount 1;
	Inventory.MaxAmount 1;
	Inventory.PickupSound "misc/i_pkup";
	Scale 0.6;
}

	override bool TryPickup(in out Actor toucher)
	{
		NBC_Player pawn = NBC_Player(toucher);
		if (!pawn || !pawn.NBC_AddDebris(NBC_GetPickupKind(), 1)) return false;
		GoAwayAndDie();
		return true;
	}
}

class NBC_LooseBrick : NBC_DebrisPickup
{
	override int NBC_GetPickupKind() { return NBC_DEBRIS_BRICK; }
	States { Spawn: BRKP A -1; Stop; }
}

class NBC_LooseHalfBrick : NBC_DebrisPickup
{
	override int NBC_GetPickupKind() { return NBC_DEBRIS_HALF_BRICK; }
	States { Spawn: HBRK A -1; Stop; }
}

class NBC_LooseConcrete : NBC_DebrisPickup
{
	override int NBC_GetPickupKind() { return NBC_DEBRIS_CONCRETE; }
	States { Spawn: CNCK A -1; Stop; }
}

class NBC_LooseBottle : NBC_DebrisPickup
{
	override int NBC_GetPickupKind() { return NBC_DEBRIS_BOTTLE; }
	States { Spawn: MOLP A -1; Stop; }
}

class NBC_DebrisShard : Actor
{
Default
{
	+NOBLOCKMAP;
	+NOINTERACTION;
	+NOGRAVITY;
	+NOBLOOD;
}

States
{
Spawn:
	BFRG ABCD 2;
	Stop;
}
}

// Concrete leaves two decorative half-brick pieces. These are deliberately not pickups.
class NBC_DebrisHalfBrickFragment : Actor
{
Default
{
	Radius 3;
	Height 3;
	+NOBLOCKMAP;
	+NOINTERACTION;
	+NOBLOOD;
	Gravity 0.8;
}

States
{
Spawn:
	HBKT ABCD 2;
	TNT1 A 8;
	Stop;
}
}

class NBC_DebrisGlassShard : Actor
{
Default
{
	Radius 2;
	Height 2;
	+NOBLOCKMAP;
	+NOINTERACTION;
	+NOBLOOD;
	Gravity 0.8;
}

States
{
Spawn:
	MDEB ABCDEFGH 2;
	TNT1 A 8;
	Stop;
}
}

class NBC_DebrisProjectile : Actor
{
	bool nbcTerminalNoiseSent;
	virtual int NBC_GetKind() { return -1; }
	virtual double NBC_SpeedFactor() { return 1.0; }

Default
{
	Radius 5;
	Height 5;
	Mass 9;
	Speed 10;
	DamageType "Blunt";
	BounceType "Doom";
	BounceFactor 0.8;
	WallBounceFactor 0.5;
	BounceCount 1;
	Gravity 0.55;
	+MISSILE;
	+FORCEPAIN;
	+CANBOUNCEWATER;
	-NOGRAVITY;
	+NOBLOOD;
	BounceSound "nbc_debris_bounce";
	WallBounceSound "nbc_debris_bounce";
}

override int DoSpecialDamage(Actor victim, int damage, Name damagetype, int flags, double hitAngle)
{
	NBC_DebrisHooks.NBC_DebrisNoise(pos, NBC_GetKind() == NBC_DEBRIS_BOTTLE ? 768 : 0);
	nbcTerminalNoiseSent = true;
	if (!victim || victim.bFriendly || victim.player || victim == target)
		return 0;

	if (NBC_GetKind() == NBC_DEBRIS_CONCRETE)
	{
		victim.vel += (cos(angle) * 3.5, sin(angle) * 3.5, 2.0);
	}

	int maxHealth = victim.GetMaxHealth();
	if (maxHealth > 0 && victim.health - damage < maxHealth * 0.35)
		NBC_DebrisHooks.NBC_DebrisArrestStagger(victim);
	return damage;
}

override int SpecialBounceHit(Actor bounceMobj, Line bounceLine, readonly<SecPlane> bouncePlane, bool is3DFloor)
{
	NBC_DebrisHooks.NBC_DebrisNoise(pos, NBC_GetKind() == NBC_DEBRIS_BOTTLE ? 768 : 0);
	return MHIT_DEFAULT;
}

void NBC_SpawnShards(Class<Actor> shardClass, int count)
{
	for (int i = 0; i < count; i++)
	{
		Actor shard = Spawn(shardClass, pos, NO_REPLACE);
		if (!shard) continue;
		shard.target = target;
		shard.vel = (Random[NBC_DebrisRandom](-3, 3), Random[NBC_DebrisRandom](-3, 3), Random[NBC_DebrisRandom](1, 5));
	}
}

void NBC_OnImpact()
{
	if (!nbcTerminalNoiseSent)
		NBC_DebrisHooks.NBC_DebrisNoise(pos, NBC_GetKind() == NBC_DEBRIS_BOTTLE ? 768 : 0);
	A_StartSound(NBC_GetKind() == NBC_DEBRIS_BOTTLE ? "nbc_debris_glass" : "nbc_debris_impact", CHAN_BODY);

	switch (NBC_GetKind())
	{
	case NBC_DEBRIS_BRICK:
		if (Random[NBC_DebrisRandom](0, 99) < 30)
			Spawn("NBC_LooseBrick", (pos.xy, floorz), NO_REPLACE);
		else
			NBC_SpawnShards("NBC_DebrisShard", 4);
		break;
	case NBC_DEBRIS_CONCRETE:
		for (int i = 0; i < 2; i++)
		{
			Actor piece = Spawn("NBC_DebrisHalfBrickFragment", pos, NO_REPLACE);
			if (piece)
				piece.vel = (Random[NBC_DebrisRandom](-3, 3), Random[NBC_DebrisRandom](-3, 3), Random[NBC_DebrisRandom](2, 6));
		}
		NBC_SpawnShards("NBC_DebrisShard", 3);
		break;
	case NBC_DEBRIS_BOTTLE:
		NBC_SpawnShards("NBC_DebrisGlassShard", 5);
		break;
	default:
		NBC_SpawnShards("NBC_DebrisShard", 3);
		break;
	}
}

action void NBC_DebrisImpactAction()
{
	NBC_DebrisProjectile projectile = NBC_DebrisProjectile(invoker);
	if (projectile) projectile.NBC_OnImpact();
}

States
{
Death:
	TNT1 A 0 NBC_DebrisImpactAction;
	TNT1 A 1;
	Stop;
}
}

class NBC_BrickProjectile : NBC_DebrisProjectile
{
	override int NBC_GetKind() { return NBC_DEBRIS_BRICK; }

Default
{
	Damage 18;
	BounceCount 1;
	Gravity 0.55;
}

States { Spawn: BRKT ABCD 2; Loop; }
}

class NBC_HalfBrickProjectile : NBC_DebrisProjectile
{
	override int NBC_GetKind() { return NBC_DEBRIS_HALF_BRICK; }
	override double NBC_SpeedFactor() { return 1.2; }

Default
{
	Damage 12;
	BounceCount 2;
	Gravity 0.4;
}

States { Spawn: HBKT ABCD 2; Loop; }
}

class NBC_ConcreteProjectile : NBC_DebrisProjectile
{
	override int NBC_GetKind() { return NBC_DEBRIS_CONCRETE; }
	override double NBC_SpeedFactor() { return 0.7; }

Default
{
	Damage 26;
	Mass 40;
	BounceCount 0;
	Gravity 0.85;
}

States { Spawn: CNKT ABCD 2; Loop; }
}

class NBC_BottleProjectile : NBC_DebrisProjectile
{
	override int NBC_GetKind() { return NBC_DEBRIS_BOTTLE; }
	override double NBC_SpeedFactor() { return 1.3; }

Default
{
	Damage 8;
	BounceCount 0;
	Gravity 0.25;
	Mass 3;
}

States { Spawn: MOLP A 2; Loop; }
}

class NBC_RubblePile : Actor
{
	int nbcInitialSupply;
	int nbcRemaining;
	int nbcHalfBricks;
	int nbcOtherPieces;
	bool nbcInitialized;

Default
{
	Radius 18;
	Height 20;
	Health 10000;
	+SOLID;
	+SHOOTABLE;
	+NODAMAGE;
	+NOBLOOD;
	Tag "Rubble pile";
}

override void PostBeginPlay()
{
	Super.PostBeginPlay();
	if (!nbcInitialized)
	{
		nbcInitialSupply = Random[NBC_DebrisRandom](3, 6);
		nbcRemaining = nbcInitialSupply;
		nbcHalfBricks = nbcInitialSupply / 2 + (Random[NBC_DebrisRandom](0, 1) ? 1 : 0);
		nbcHalfBricks = min(nbcHalfBricks, nbcInitialSupply);
		nbcOtherPieces = nbcInitialSupply - nbcHalfBricks;
		nbcInitialized = true;
	}
	NBC_UpdateAppearance();
}

void NBC_UpdateAppearance()
{
	if (nbcRemaining <= 0)
	{
		bSOLID = false;
		SetStateLabel("Spent");
	}
	else if (nbcRemaining * 3 > nbcInitialSupply * 2) SetStateLabel("Full");
	else if (nbcRemaining * 3 > nbcInitialSupply) SetStateLabel("Mid");
	else SetStateLabel("Low");
}

override bool Used(Actor user)
{
	NBC_Player pawn = NBC_Player(user);
	if (!pawn || nbcRemaining <= 0 || Distance2D(user) > 80) return false;

	int type;
	if (nbcHalfBricks > 0 && (nbcOtherPieces <= 0 || Random[NBC_DebrisRandom](0, 1) == 0))
	{
		type = NBC_DEBRIS_HALF_BRICK;
	}
	else
	{
		type = Random[NBC_DebrisRandom](0, 1) == 0 ? NBC_DEBRIS_BRICK : NBC_DEBRIS_CONCRETE;
	}
	if (!pawn.NBC_AddDebris(type, 1)) return false;

	if (type == NBC_DEBRIS_HALF_BRICK) nbcHalfBricks--;
	else nbcOtherPieces--;
	nbcRemaining--;
	A_StartSound("misc/i_pkup", CHAN_BODY);
	NBC_UpdateAppearance();
	return true;
}

States
{
Spawn:
	RUBL A -1;
	Stop;
Full:
	RUBL A -1;
	Stop;
Mid:
	RUBL B -1;
	Stop;
Low:
	RUBL C -1;
	Stop;
Spent:
	RUBL C -1;
	Stop;
}
}
