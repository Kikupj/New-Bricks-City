// =============================================================================
// Corpo Wars — intel packages and hireable operatives (bought per contract)
// =============================================================================
class CW_Services
{
	const INTEL_COUNT = 2;
	const CREW_COUNT = 3;
	const MAX_CREW = 2;

	enum EIntel { INTEL_SURVEY, INTEL_PATROLS }
	enum ECrew  { CREW_HACKER, CREW_CLEANER, CREW_VOX }

	static clearscope String IntelName(int i)
	{
		switch (i) { case INTEL_SURVEY: return "Site survey"; case INTEL_PATROLS: return "Patrol schedule"; }
		return "";
	}
	static clearscope String IntelDesc(int i)
	{
		switch (i)
		{
		case INTEL_SURVEY:  return "Full floor plan on the automap. Objectives and the security pass marked on your radar.";
		case INTEL_PATROLS: return "Live guard positions on your radar, coloured by how alert they are.";
		}
		return "";
	}
	static clearscope int IntelCost(int i)
	{
		switch (i) { case INTEL_SURVEY: return 300; case INTEL_PATROLS: return 400; }
		return 0;
	}

	static clearscope String CrewName(int i)
	{
		switch (i) { case CREW_HACKER: return "Nyx"; case CREW_CLEANER: return "Marrow"; case CREW_VOX: return "Vox"; }
		return "";
	}
	static clearscope String CrewRole(int i)
	{
		switch (i) { case CREW_HACKER: return "Hacker"; case CREW_CLEANER: return "Cleaner"; case CREW_VOX: return "Distraction"; }
		return "";
	}
	static clearscope String CrewDesc(int i)
	{
		switch (i)
		{
		case CREW_HACKER:  return "[B] Blackout: 20 seconds of darkness, and maglocked doors release. One use.";
		case CREW_CLEANER: return "Downed guards are quietly removed. Nobody finds a body.";
		case CREW_VOX:     return "[N] Noise lure where you aim. Guards go look. Three uses.";
		}
		return "";
	}
	static clearscope int CrewCost(int i)
	{
		switch (i) { case CREW_HACKER: return 800; case CREW_CLEANER: return 600; case CREW_VOX: return 400; }
		return 0;
	}
	static clearscope Color CrewColor(int i)
	{
		switch (i) { case CREW_HACKER: return Color(60, 220, 200); case CREW_CLEANER: return Color(200, 200, 210); case CREW_VOX: return Color(240, 170, 40); }
		return Color(128, 128, 128);
	}
}

// Hanging light that spawns a real dynamic-light actor, so it counts for
// stealth and can be cut by Nyx's blackout.
class CW_LightSource : PointLight
{
	bool ups;        // battery-backed (monitor glow, exit signs, emergency lamps): stays on through a blackout
	bool cutByBlackout;
	// Small light at a spot, for the generator's accent lighting.
	static CW_LightSource Make(Vector3 at, int r, int g, int b, int radius, bool ups = false)
	{
		let l = CW_LightSource(Actor.Spawn("CW_LightSource", at));
		if (!l) return null;
		l.args[DynamicLight.LIGHT_RED] = r; l.args[DynamicLight.LIGHT_GREEN] = g; l.args[DynamicLight.LIGHT_BLUE] = b;
		l.args[DynamicLight.LIGHT_INTENSITY] = radius;
		l.ups = ups;
		return l;
	}
}
