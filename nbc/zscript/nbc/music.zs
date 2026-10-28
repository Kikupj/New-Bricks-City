// Music (owner request, 2026-10-28; the owner's MIDI pack, art/music/ -> nbc/music/ by tools/art/import_music.py).
//   title           NBCO03 (gameinfo TitleMusic, MAPINFO.txt)
//   Checkpoint 9    an ambient track, a different one each day of the case
//   a raid          a track for the hour it goes in at: brisker by day, slower and darker after dark
//   shot down       NBCO10, the fastest
// The pick is a plain function of the day and the district (not the case RNG: music isn't the case).

class NBC_Music
{
	static const String HUB[] = { "NBCA04", "NBCA01", "NBCA10", "NBCA06", "NBCA02B", "NBCA01B" };
	static const String MORNING[] = { "NBCO07", "NBCO11", "NBCTACT" };
	static const String AFTERNOON[] = { "NBCO05", "NBCO02", "NBCO08" };
	static const String DUSK[] = { "NBCO04", "NBCO06", "NBCO09" };
	static const String NIGHT[] = { "NBCA07", "NBCO09", "NBCA05", "NBCA08" };
	const CRASH = "NBCO10";
	const TITLE = "NBCO03";

	static String ForHub(NBC_RunData rd)
	{
		int day = rd && rd.caseActive ? rd.day : 0;
		return NBC_Music.HUB[day % NBC_Music.HUB.Size()];
	}

	static String ForRaid(NBC_RunData rd)
	{
		if (!rd) return NBC_Music.AFTERNOON[0];
		if (rd.raidMode == NBC_Motor.MODE_CRASH) return NBC_Music.CRASH;
		int k = rd.day * 7 + rd.raidDistrict * 3;
		switch (rd.raidWindow)
		{
		case NBC_Clock.W_MORNING: return NBC_Music.MORNING[k % NBC_Music.MORNING.Size()];
		case NBC_Clock.W_DUSK: return NBC_Music.DUSK[k % NBC_Music.DUSK.Size()];
		case NBC_Clock.W_NIGHT: return NBC_Music.NIGHT[k % NBC_Music.NIGHT.Size()];
		}
		return NBC_Music.AFTERNOON[k % NBC_Music.AFTERNOON.Size()];
	}

	static void Start(String track)
	{
		if (track == "") return;
		bool ok = S_ChangeMusic(track);
		if (developer) Console.Printf("nbc music: %s%s", track, ok ? "" : " (didn't start)");
	}
}
