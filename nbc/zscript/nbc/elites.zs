// Elites (PLAN.md M4, §6.2): now and then a gang member is a cut above, with a modifier (two in a tier-3 gang or
// the Crown). The chance comes from the gang's tier: 5%, 10%, 15%, 20% in the Crown. Elites wear a gold
// translation (TRNSLATE: NBC_Elite) and the HUD names them, with their modifiers, when you aim at one.
//   Armored         half again the health, 30% less damage from bullets
//   Wired           40% faster
//   Volatile        goes up when it dies (the Rust Saints' are twice as common: gangs.txt volatile = 2)
//   Shot Caller     at half health, calls in three of the rank and file (NBC_Director.CallIn)
//   Landlord's Own  three times the cash when it drops (the Intel shard comes with M7)
// A gang's leader can be made an elite in the data (gangs.txt leaderelite = Armored Wired ...).

class NBC_Elite : Inventory
{
	enum EMod { MOD_ARMORED = 1, MOD_WIRED = 2, MOD_VOLATILE = 4, MOD_CALLER = 8, MOD_LANDLORD = 16, MOD_COUNT = 5 }
	static const String MOD_NAME[] = { "Armored", "Wired", "Volatile", "Shot Caller", "Landlord's Own" };
	static const int MOD_WEIGHT[] = { 3, 3, 2, 2, 1 };

	int mods, fullHealth;
	bool called;

	Default { +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; Inventory.MaxAmount 1; }

	// the elite chance for a gang (§6.2)
	static int Chance(NBC_GangDef g)
	{
		if (!g) return 0;
		if (g.crown) return 20;
		return clamp(g.tier, 1, 3) * 5;
	}

	// roll for a fresh gang member: maybe an elite, with one modifier (two, sometimes, in tier-3 gangs and the Crown)
	static void Roll(Actor a, NBC_GangDef g, NBC_RunData rd)
	{
		if (!a || !g || !rd || rd.Rand(0, 99) >= Chance(g)) return;
		int mods = PickMod(g, rd, 0);
		if ((g.tier >= 3 || g.crown) && rd.Rand(0, 99) < 35) mods |= PickMod(g, rd, mods);
		Make(a, mods);
	}

	static int PickMod(NBC_GangDef g, NBC_RunData rd, int have)
	{
		int total = 0;
		for (int i = 0; i < MOD_COUNT; i++) if (!(have & (1 << i))) total += Weight(g, i);
		if (total <= 0) return 0;
		int r = rd.Rand(0, total - 1);
		for (int i = 0; i < MOD_COUNT; i++)
		{
			if (have & (1 << i)) continue;
			r -= Weight(g, i);
			if (r < 0) return 1 << i;
		}
		return 0;
	}

	static int Weight(NBC_GangDef g, int i)
	{
		int w = NBC_Elite.MOD_WEIGHT[i];
		if (i == 2 && g) w = int(w * max(g.volatileMul, 0.0));       // Volatile: the Rust Saints' are twice as common
		return w;
	}

	// a modifier by name, for the data (gangs.txt leaderelite)
	clearscope static int ModByName(String s)
	{
		s = s.MakeLower();
		if (s == "armored") return MOD_ARMORED;
		if (s == "wired") return MOD_WIRED;
		if (s == "volatile") return MOD_VOLATILE;
		if (s == "shotcaller" || s == "caller") return MOD_CALLER;
		if (s == "landlord" || s == "landlordsown") return MOD_LANDLORD;
		return 0;
	}

	static NBC_Elite Make(Actor a, int mods)
	{
		if (!a || !mods) return null;
		let e = NBC_Elite(a.FindInventory("NBC_Elite"));
		if (!e) e = NBC_Elite(a.GiveInventoryType("NBC_Elite"));
		if (!e) return null;
		int added = mods & ~e.mods;
		e.mods |= mods;
		if (added & MOD_ARMORED) a.health = a.health * 3 / 2;
		if (added & MOD_WIRED) a.Speed *= 1.4;
		a.A_SetTranslation('NBC_Elite');
		e.fullHealth = a.health;
		return e;
	}

	clearscope bool Has(int m) const { return (mods & m) != 0; }

	clearscope String Title() const
	{
		String s = "";
		for (int i = 0; i < MOD_COUNT; i++)
		{
			if (!(mods & (1 << i))) continue;
			if (s != "") s = s .. ", ";
			s = s .. MOD_NAME[i];
		}
		return s;
	}

	// a readable name for the HUD: the actor's tag, unless it's only a class name
	static clearscope String NameOf(Actor a)
	{
		if (!a) return "";
		String t = a.GetTag("");
		if (t == "" || t ~== String.Format("%s", a.GetClassName())) return "Gang member";
		return t;
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		if (!passive || damage <= 0 || !(mods & MOD_ARMORED)) return;
		if (damageType == 'NBC_Light' || damageType == 'NBC_Shell' || damageType == 'NBC_Rifle')
			newdamage = max(1, newdamage * 7 / 10);
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if (!Owner || Owner.health <= 0 || called || !(mods & MOD_CALLER)) return;
		if (Owner.health * 2 > max(1, fullHealth)) return;
		called = true;
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		let rd = NBC_RunData.Find();
		if (!rm || !rd || !rm.director) return;
		int n = rm.director.CallIn(rm.GangAt(rd.raidGang), rd, Owner.pos, 3);
		if (n)
		{
			Owner.A_StartSound(Owner.SeeSound, CHAN_VOICE);
			rm.Announce(String.Format("%s is calling for backup!", NameOf(Owner)), 35 * 3);
		}
	}

	override void OwnerDied()
	{
		Super.OwnerDied();
		if (!Owner) return;
		if (mods & MOD_VOLATILE)
		{
			let b = Actor.Spawn("NBC_VolatileBlast", Owner.pos + (0, 0, Owner.height / 2), NO_REPLACE);
			if (b) b.target = Owner;
		}
		if (mods & MOD_LANDLORD)
		{
			// the run manager pays 10 a tier per kill; the Landlord's Own pay three times that
			let rd = NBC_RunData.Find();
			let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
			let g = rm && rd ? rm.GangAt(rd.raidGang) : null;
			if (rd && rd.raidActive) rd.cash += 20 * (g ? g.tier : 1);
		}
	}
}

// a Volatile elite going up: a grenade's worth of blast (it hurts its own too, the fire-immune included)
class NBC_VolatileBlast : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +DONTSPLASH; RenderStyle "Add"; Alpha 0.9; Scale 1.1; }
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_StartSound("FragGrenade/Explode", CHAN_AUTO, 0, 1.0, 0.6);
		A_Explode(96, 176, XF_HURTSOURCE);                  // plain blast damage: fire-immune gangs get hurt too
		A_Quake(3, 14, 0, 640, "");
		for (int i = 0; i < 20; i++)
			A_SpawnParticle(random[nbcfx](0, 1) ? 0xFF8020 : 0x504840, SPF_FULLBRIGHT, random[nbcfx](20, 40), random[nbcfx](6, 14), 0,
				frandom[nbcfx](-12, 12), frandom[nbcfx](-12, 12), frandom[nbcfx](-12, 12), frandom[nbcfx](-4, 4), frandom[nbcfx](-4, 4), frandom[nbcfx](0, 3),
				0, 0, -0.1, 0.9, -1, -0.2);
	}
	States { Spawn: BEXP C 4 Bright; BEXP D 4 Bright; BEXP E 6 Bright; Stop; }
}
