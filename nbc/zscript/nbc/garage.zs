// The motor pool (owner request, 2026-10-28): the department's vehicles. Each raid rolls out as a motorcade.
//   STREET insertion   the land vehicles you pick; they park at the start of the district map
//   ROOFTOP insertion  the helicopter: the raid runs on the district's rooftop map (nbc/rooftops.txt), with
//                      fewer of the gang watching the roofs, but it can be shot down on the way in, and the
//                      raid becomes a crash landing on the street map: a survival ambush round the wreck
// The seats (you included) have to carry the squad. Vehicles wear down on raids (the armored truck doesn't),
// go to the shop below 30% condition, and are wrecked at 0; repairs cost cash. The garage belongs to the case,
// like the Evidence Locker: a new case starts with the department's panel van and an unmarked sedan.

class NBC_Motor
{
	enum EType { V_SEDAN, V_VAN, V_TRUCK, V_HELI, V_COUNT }
	enum EInsertion { INS_STREET, INS_ROOFTOP }
	enum EMode { MODE_STREET, MODE_ROOF, MODE_CRASH }        // NBC_RunData.raidMode
	const CRASH_WAVES = 4;
	const SHOP_BELOW = 30;          // condition under which a vehicle can't roll out
	const MAX_VEHICLES = 8;

	static const String TYPE_NAME[] = { "Unmarked Sedan", "Panel Van", "Armored Truck", "Helicopter" };
	static const String TYPE_SHORT[] = { "SEDAN", "VAN", "TRUCK", "HELI" };
	static const int TYPE_SEATS[] = { 2, 4, 5, 5 };           // you included
	static const int TYPE_PRICE[] = { 350, 800, 2200, 4000 };
	static const String TYPE_ART[] = { "NBCVSEDN", "NBCVVAN", "NBCVTRUK", "NBCHELI" };
	// what parks at the insertion (the voxel vehicle pack, actors/cw/vehicles.txt)
	static const String TYPE_ACTOR[] = { "ModernCarDarkBlue", "VanDarkBlue", "ArmoredUACtruckBrown", "HelicopterDarkGreen" };
	static const String TYPE_PERK[] = {
		"Low profile: a motorcade of sedans only means 15% fewer of them on the block.",
		"Room for the stack. The department's own.",
		"Officers ride armored: they take 15% less damage on the raid. Never wears down.",
		"Rooftop insertion: the raid starts on the district's roofs, 20% fewer of them up there. Can be shot down." };

	clearscope static bool Flies(int t) { return t == V_HELI; }
	clearscope static int RepairCost(int t, int cond) { return (100 - clamp(cond, 0, 100)) * NBC_Motor.TYPE_PRICE[clamp(t, 0, V_COUNT - 1)] / 250; }
	clearscope static int SellValue(int t, int cond) { return NBC_Motor.TYPE_PRICE[clamp(t, 0, V_COUNT - 1)] * clamp(cond, 0, 100) / 200; }

	// the chance a helicopter is shot down on the way in, in percent
	clearscope static int ShootDownRisk(int tier, int alert, int cond)
	{
		return clamp(6 + 4 * tier + 6 * alert + (100 - cond) / 4, 5, 60);
	}
}

class NBC_Vehicle
{
	int id, type, cond;
	String plate;
	bool rolling;        // picked for the next motorcade

	clearscope String Name() const { return String.Format("%s %s", NBC_Motor.TYPE_NAME[clamp(type, 0, NBC_Motor.V_COUNT - 1)], plate); }
	clearscope bool Ready() const { return cond >= NBC_Motor.SHOP_BELOW; }
	clearscope int Seats() const { return NBC_Motor.TYPE_SEATS[clamp(type, 0, NBC_Motor.V_COUNT - 1)]; }
}

// The crash site: the wreck burns and smokes for the whole raid (particles only, no damage).
class NBC_WreckFire : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; RenderStyle "None"; }

	override void Tick()
	{
		Super.Tick();
		if (GetAge() % 2) return;
		for (int i = 0; i < 3; i++)
			A_SpawnParticle(random[nbcfx](0, 1) ? 0xFF8A20 : 0xFFC040, SPF_FULLBRIGHT | SPF_RELATIVE, random[nbcfx](10, 22), random[nbcfx](6, 12), 0,
				frandom[nbcfx](-40, 40), frandom[nbcfx](-24, 24), frandom[nbcfx](8, 40), 0, 0, frandom[nbcfx](0.8, 2.0), 0, 0, -0.02);
		A_SpawnParticle(0x403C38, 0, 70, 22, 0, frandom[nbcfx](-24, 24), frandom[nbcfx](-16, 16), 48, frandom[nbcfx](-0.3, 0.3), frandom[nbcfx](-0.3, 0.3),
			frandom[nbcfx](0.8, 1.4), 0, 0, 0, 0.6, -1, 0.25);
	}
	States { Spawn: TNT1 A -1; Stop; }
}
