// Gang definitions (nbc/gangs.txt) and the turfs on the raid board (nbc/districts.txt). Both are plain
// data; nothing gang-specific lives in code.

class NBC_GangDef
{
	String id, name, shortName, color, leader, leaderTitle, trait;
	int tier, escorts;
	double budget, health, leaderHealth, painChance;
	Array<String> roster1, roster2, roster3;
	Array<String> mansion;     // kit floors the gang holds, "K2:tenement" (kit:variant name); one is picked per raid
	Array<Name> damageTypes;
	Array<double> damageFactors;
	// by the clock (NBC_Clock windows): how many are out, how many of those are off guard (percent), the board line
	Array<double> strength;
	Array<int> offGuard;
	String hours;
	// the Crown (crown = 1): never dealt to a district; its own map, name on the board and environment
	bool crown;
	String crownMap, crownTurf, crownEnv;

	clearscope int TextColor() const
	{
		int c = Font.FindFontColor(color);
		return c == Font.CR_UNDEFINED ? Font.CR_WHITE : c;
	}

	clearscope double StrengthAt(int w) const { return w >= 0 && w < strength.Size() ? strength[w] : 1.0; }
	clearscope int OffGuardAt(int w) const { return w >= 0 && w < offGuard.Size() ? offGuard[w] : 0; }

	clearscope double DamageFactorFor(Name type) const
	{
		for (int i = 0; i < damageTypes.Size(); i++)
			if (damageTypes[i] == type) return damageFactors[i];
		return 1.0;
	}
}

class NBC_Gangs
{
	// Split a line into words; "quoted strings" stay one word (without the quotes).
	static void Tokenize(String line, out Array<String> words)
	{
		words.Clear();
		int i = 0, n = line.Length();
		while (i < n)
		{
			int c = line.ByteAt(i);
			if (c == 32 || c == 9 || c == 13 || c == 61) { i++; continue; }   // space, tab, CR, '='
			if (c == 34)
			{
				int j = line.IndexOf("\"", i + 1);
				if (j < 0) j = n;
				words.Push(line.Mid(i + 1, j - i - 1));
				i = j + 1;
				continue;
			}
			int j = i;
			while (j < n)
			{
				int d = line.ByteAt(j);
				if (d == 32 || d == 9 || d == 13 || d == 61) break;
				j++;
			}
			words.Push(line.Mid(i, j - i));
			i = j;
		}
	}

	static String ReadText(String fullName)
	{
		int lump = Wads.CheckNumForFullName(fullName);
		return lump >= 0 ? Wads.ReadLump(lump) : "";
	}

	static void LoadGangs(out Array<NBC_GangDef> gangs)
	{
		gangs.Clear();
		Array<String> lines, w;
		ReadText("gangs.txt").Split(lines, "\n");
		NBC_GangDef g = null;
		for (int i = 0; i < lines.Size(); i++)
		{
			String line = lines[i];
			int cut = line.IndexOf("//");
			if (cut >= 0) line = line.Left(cut);
			Tokenize(line, w);
			if (w.Size() == 0) continue;
			String key = w[0].MakeLower();
			if (key == "gang" && w.Size() > 1)
			{
				g = new("NBC_GangDef");
				g.id = w[1];
				g.name = w[1]; g.shortName = w[1]; g.color = "White";
				g.tier = 1; g.budget = 1; g.health = 1; g.leaderHealth = 4; g.painChance = 1; g.escorts = 2;
				for (int k = 0; k < NBC_Clock.W_COUNT; k++) { g.strength.Push(1.0); g.offGuard.Push(0); }
				gangs.Push(g);
				continue;
			}
			if (!g || key == "{" || key == "}") continue;
			if (key == "name") g.name = w.Size() > 1 ? w[1] : g.name;
			else if (key == "short") g.shortName = w[1];
			else if (key == "tier") g.tier = w[1].ToInt();
			else if (key == "color") g.color = w[1];
			else if (key == "budget") g.budget = w[1].ToDouble();
			else if (key == "health") g.health = w[1].ToDouble();
			else if (key == "leader") g.leader = w[1];
			else if (key == "leadertitle") g.leaderTitle = w[1];
			else if (key == "leaderhealth") g.leaderHealth = w[1].ToDouble();
			else if (key == "escorts") g.escorts = w[1].ToInt();
			else if (key == "painchance") g.painChance = w[1].ToDouble();
			else if (key == "trait") g.trait = w[1];
			else if (key == "hours") g.hours = w[1];
			else if (key == "crown") g.crown = w[1].ToInt() != 0;
			else if (key == "map") g.crownMap = w[1];
			else if (key == "turf") g.crownTurf = w[1];
			else if (key == "env") g.crownEnv = w[1];
			else if (key == "strength") { for (int k = 1; k < w.Size() && k <= NBC_Clock.W_COUNT; k++) g.strength[k - 1] = w[k].ToDouble(); }
			else if (key == "offguard") { for (int k = 1; k < w.Size() && k <= NBC_Clock.W_COUNT; k++) g.offGuard[k - 1] = clamp(w[k].ToInt(), 0, 100); }
			else if (key == "mansion") { for (int k = 1; k < w.Size(); k++) g.mansion.Push(w[k]); }
			else if (key == "roster1" || key == "roster2" || key == "roster3")
			{
				for (int k = 1; k < w.Size(); k++)
				{
					if (key == "roster1") g.roster1.Push(w[k]);
					else if (key == "roster2") g.roster2.Push(w[k]);
					else g.roster3.Push(w[k]);
				}
			}
			else if (key == "damage")
			{
				for (int k = 1; k + 1 < w.Size(); k += 2)
				{
					g.damageTypes.Push(w[k]);
					g.damageFactors.Push(w[k + 1].ToDouble());
				}
			}
		}
	}

	// map, "Title", environment (rooftops, streets, towers, underground, subway, parks, industrial)
	static void LoadDistricts(out Array<String> maps, out Array<String> titles, out Array<String> envs)
	{
		maps.Clear(); titles.Clear(); envs.Clear();
		Array<String> lines, w;
		ReadText("districts.txt").Split(lines, "\n");
		for (int i = 0; i < lines.Size(); i++)
		{
			String line = lines[i];
			int cut = line.IndexOf("//");
			if (cut >= 0) line = line.Left(cut);
			Tokenize(line, w);
			if (w.Size() == 0) continue;
			maps.Push(w[0]);
			titles.Push(w.Size() > 1 ? w[1] : w[0]);
			envs.Push(w.Size() > 2 ? w[2] : "streets");
		}
	}

	// The helicopter's rooftop map for each district (nbc/rooftops.txt: "district-map rooftop-map" per line),
	// in district order; "" where a district has none.
	static void LoadRooftops(Array<String> maps, out Array<String> roofs)
	{
		roofs.Clear();
		for (int i = 0; i < maps.Size(); i++) roofs.Push("");
		Array<String> lines, w;
		ReadText("rooftops.txt").Split(lines, "\n");
		for (int i = 0; i < lines.Size(); i++)
		{
			String line = lines[i];
			int cut = line.IndexOf("//");
			if (cut >= 0) line = line.Left(cut);
			Tokenize(line, w);
			if (w.Size() < 2) continue;
			for (int d = 0; d < maps.Size(); d++) if (maps[d] ~== w[0]) roofs[d] = w[1];
		}
	}

	// A choice spawner (RandomSpawner) resolved to the actor it would spawn, by its drop list weights.
	static play class<Actor> Resolve(String className, NBC_RunData rd)
	{
		class<Actor> cls = className;
		for (int depth = 0; cls && depth < 4; depth++)
		{
			if (!(cls is "RandomSpawner")) return cls;
			let def = GetDefaultByType(cls);
			Array<class<Actor> > picks;
			Array<int> weights;
			int total = 0;
			for (DropItem di = def.GetDropItems(); di; di = di.Next)
			{
				class<Actor> c = di.Name;
				if (!c) continue;
				int wgt = max(1, di.Probability);
				picks.Push(c); weights.Push(wgt); total += wgt;
			}
			if (!picks.Size()) return null;
			int roll = rd.Rand(0, total - 1);
			cls = picks[picks.Size() - 1];
			for (int k = 0; k < picks.Size(); k++)
			{
				if (roll < weights[k]) { cls = picks[k]; break; }
				roll -= weights[k];
			}
		}
		return cls;
	}
}

// Hidden item that applies a gang's damage profile to its members.
class NBC_GangProfile : Inventory
{
	Array<Name> types;
	Array<double> factors;

	Default
	{
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		Inventory.MaxAmount 1;
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		if (!passive || damage <= 0) return;
		for (int i = 0; i < types.Size(); i++)
		{
			if (types[i] == damageType)
			{
				newdamage = int(damage * factors[i]);
				return;
			}
		}
	}
}

// Marks the gang leader; the run manager watches for its death.
class NBC_LeaderToken : Inventory
{
	Default
	{
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		Inventory.MaxAmount 1;
	}
}
