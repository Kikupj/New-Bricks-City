// =============================================================================
// Corpo Wars — Navigation graph + pathfinding
//
// Built automatically when a level loads, so it works on hand-made maps AND on
// maps assembled from prefab rooms (no authoring required):
//   * a node at every passable two-sided line (doorways, openings; long openings
//     get one node every ~192 units)
//   * a node at every sector centre, plus a grid of nodes inside large sectors
//   * any hand-placed CW_NavNode (thing 20003) for tricky spots
// Nodes are linked when a guard-width corridor between them is clear.
// Guards walk straight when they can and use Dijkstra over the graph when not.
// =============================================================================
class CW_NavNode : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; RenderStyle "None"; }
	States { Spawn: TNT1 A -1; Stop; }
}

class CW_NavMarker : Actor   // debug only (cw_navdebug 1)
{
	Default { +NOINTERACTION; +NOBLOCKMAP; +BRIGHT; Scale 0.5; }
	States { Spawn: BON1 A -1 Bright; Stop; }
}

class CW_NavProbe : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; +NOGRAVITY; RenderStyle "None"; Radius 1; Height 1; }
	States { Spawn: TNT1 A -1; Stop; }
}

class CW_NavGraph play
{
	const LINK_RANGE = 900.0;
	const GUARD_HALF = 18.0;     // half-width used for clearance traces
	const STEP = 24.0;           // max floor step a guard can take
	const MIN_GAP = 56.0;        // min floor-to-ceiling opening

	Array<double> nx, ny;
	Array<int> adj;              // flattened adjacency: for node i -> adj[adjStart[i] .. +adjCount[i]]
	Array<int> adjStart, adjCount;
	Array<int> path;             // result of the last Route(), node indices
	Actor probe;

	// Furniture: solid CW_Blockers bucketed on a 128u grid (counting sort), so links and nodes route around
	// desks and counters.
	const BUCKET = 128.0;
	int GW;                                 // buckets per side, sized to the map (at least 32)
	double gox, goy;                        // the grid's origin (map's lower-left corner, less a bucket)
	Array<double> fbx, fby, fbr;
	Array<int> bStart, bList;               // bucket b holds bList[bStart[b] .. bStart[b + 1])

	int BucketOf(double x, double y)
	{
		int bx = clamp(int(floor((x - gox) / BUCKET)), 0, GW - 1), by = clamp(int(floor((y - goy) / BUCKET)), 0, GW - 1);
		return by * GW + bx;
	}

	void CollectFurniture()
	{
		fbx.Clear(); fby.Clear(); fbr.Clear(); bStart.Clear(); bList.Clear();
		// size the bucket grid to the map (hand-made and kit maps sit near the origin; Obsidian's are big)
		double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
		for (int v = 0; v < level.vertexes.Size(); v++)
		{
			Vector2 p = level.vertexes[v].p;
			x0 = min(x0, p.x); y0 = min(y0, p.y); x1 = max(x1, p.x); y1 = max(y1, p.y);
		}
		if (x1 < x0) { x0 = -1024; y0 = -1024; x1 = 3072; y1 = 3072; }
		gox = x0 - BUCKET; goy = y0 - BUCKET;
		GW = clamp(int(ceil(max(x1 - x0, y1 - y0) / BUCKET)) + 3, 32, 192);
		let it = ThinkerIterator.Create("CW_Blocker");
		Actor a;
		while (a = Actor(it.Next()))
		{
			if (!a.bSOLID) continue;
			fbx.Push(a.pos.x); fby.Push(a.pos.y); fbr.Push(a.radius);
		}
		Array<int> cnt;
		for (int b = 0; b <= GW * GW; b++) { cnt.Push(0); bStart.Push(0); }
		for (int i = 0; i < fbx.Size(); i++) cnt[BucketOf(fbx[i], fby[i])]++;
		for (int b = 0; b < GW * GW; b++) bStart[b + 1] = bStart[b] + cnt[b];
		for (int i = 0; i < fbx.Size(); i++) bList.Push(0);
		for (int b = 0; b < GW * GW; b++) cnt[b] = bStart[b];
		for (int i = 0; i < fbx.Size(); i++) { int b = BucketOf(fbx[i], fby[i]); bList[cnt[b]++] = i; }
	}

	bool BlockerHit(int i, Vector2 a, Vector2 d, double len)
	{
		Vector2 c = (fbx[i], fby[i]);
		double t = len > 0 ? clamp(((c - a) dot d) / (len * len), 0, 1) : 0;
		Vector2 q = a + d * t;
		double reach = fbr[i] + GUARD_HALF - 2;
		return abs(q.x - c.x) < reach && abs(q.y - c.y) < reach;
	}

	// Does a guard-width segment a->b clip any furniture?
	bool HitsFurniture(Vector2 a, Vector2 b)
	{
		if (fbx.Size() == 0) return false;
		Vector2 d = b - a;
		double len = d.Length();
		int x0 = clamp(int(floor((min(a.x, b.x) - gox) / BUCKET)) - 1, 0, GW - 1), x1 = clamp(int(floor((max(a.x, b.x) - gox) / BUCKET)) + 1, 0, GW - 1);
		int y0 = clamp(int(floor((min(a.y, b.y) - goy) / BUCKET)) - 1, 0, GW - 1), y1 = clamp(int(floor((max(a.y, b.y) - goy) / BUCKET)) + 1, 0, GW - 1);
		for (int by = y0; by <= y1; by++)
			for (int bx = x0; bx <= x1; bx++)
			{
				int bk = by * GW + bx;
				for (int k = bStart[bk]; k < bStart[bk + 1]; k++) if (BlockerHit(bList[k], a, d, len)) return true;
			}
		return false;
	}

	bool InsideFurniture(Vector2 p)
	{
		if (bStart.Size() == 0) return false;
		int bx = clamp(int(floor((p.x - gox) / BUCKET)), 1, GW - 2), by = clamp(int(floor((p.y - goy) / BUCKET)), 1, GW - 2);
		for (int oy = -1; oy <= 1; oy++)
			for (int ox = -1; ox <= 1; ox++)
			{
				int bk = (by + oy) * GW + bx + ox;
				for (int k = bStart[bk]; k < bStart[bk + 1]; k++)
				{
					int i = bList[k];
					if (abs(p.x - fbx[i]) < fbr[i] + GUARD_HALF && abs(p.y - fby[i]) < fbr[i] + GUARD_HALF) return true;
				}
			}
		return false;
	}


	int Count() { return nx.Size(); }

	const OFFMAP_X = 2200;   // G02 stair towers live out here; guards never patrol them
	double offmapX, linkRange;       // 0 = the defaults (OFFMAP_X, LINK_RANGE); site-pack maps (sitemission.zs) are big: no off-map limit, nearby links only
	// nodes bucketed on the furniture grid (BUCKET): dedupe and link candidates look at a few buckets, not every node
	Array<int> nHead, nNext;
	void AddNode(Vector2 p)
	{
		if (p.x > (offmapX > 0 ? offmapX : OFFMAP_X)) return;
		if (InsideFurniture(p)) return;
		int bx = clamp(int(floor((p.x - gox) / BUCKET)), 0, GW - 1), by = clamp(int(floor((p.y - goy) / BUCKET)), 0, GW - 1);
		for (int oy = max(by - 1, 0); oy <= min(by + 1, GW - 1); oy++)
			for (int ox = max(bx - 1, 0); ox <= min(bx + 1, GW - 1); ox++)
				for (int i = nHead[oy * GW + ox]; i >= 0; i = nNext[i])
					if ((p - (nx[i], ny[i])).Length() < 40) return;   // dedupe
		nNext.Push(nHead[by * GW + bx]);
		nHead[by * GW + bx] = nx.Size();
		nx.Push(p.x); ny.Push(p.y);
	}

	double FloorAt(Vector2 p) { let sec = level.PointInSector(p); return sec.floorplane.ZAtPoint(p); }

	// Is a guard-width corridor from a to b free of walls, steps and low ceilings?
	bool Clear(Vector2 a, Vector2 b)
	{
		Vector2 d = b - a;
		double len = d.Length();
		if (len < 1) return true;
		if (!probe) probe = Actor.Spawn("CW_NavProbe", (a, 0));
		probe.SetOrigin((a, FloorAt(a)), false);
		double ang = VectorAngle(d.x, d.y);
		static const double sides[] = { 0, -18.0, 18.0 };
		for (int i = 0; i < 3; i++)
		{
			FLineTraceData t;
			probe.LineTrace(ang, len, 0, TRF_THRUACTORS, STEP + 4, 0, sides[i], t);
			if (t.HitType != TRACE_HitNone) return false;
		}
		// ceiling / big drops along the way: sample a few points
		for (int k = 1; k <= 3; k++)
		{
			Vector2 p = a + d * (k / 4.0);
			let sec = level.PointInSector(p);
			double f = sec.floorplane.ZAtPoint(p), c = sec.ceilingplane.ZAtPoint(p);
			if (c - f < MIN_GAP) return false;
		}
		return !HitsFurniture(a, b);
	}

	void Build()
	{
		nx.Clear(); ny.Clear(); adj.Clear(); adjStart.Clear(); adjCount.Clear();
		int t0 = MSTime();
		CollectFurniture();
		nHead.Clear(); nNext.Clear();
		for (int b = 0; b < GW * GW; b++) nHead.Push(-1);

		// 1) hand-placed nodes
		let it = ThinkerIterator.Create("CW_NavNode");
		Actor a;
		while (a = Actor(it.Next())) AddNode(a.pos.xy);

		// 2) doorways / openings
		for (int i = 0; i < level.Lines.Size(); i++)
		{
			Line ln = level.Lines[i];
			if (!ln.sidedef[1] || (ln.flags & (Line.ML_BLOCKING | Line.ML_BLOCKEVERYTHING | Line.ML_BLOCKMONSTERS))) continue;
			Sector f = ln.frontsector, b = ln.backsector;
			if (!f || !b) continue;
			Vector2 v1 = ln.v1.p, v2 = ln.v2.p;
			Vector2 mid = (v1 + v2) / 2;
			double ff = f.floorplane.ZAtPoint(mid), bf = b.floorplane.ZAtPoint(mid);
			if (abs(ff - bf) > STEP) continue;
			double gap = min(f.ceilingplane.ZAtPoint(mid), b.ceilingplane.ZAtPoint(mid)) - max(ff, bf);
			if (gap < MIN_GAP) continue;
			double len = (v2 - v1).Length();
			if (len < GUARD_HALF * 2 + 4) continue;
			int n = max(1, int(len / 192));
			for (int k = 0; k < n; k++) AddNode(v1 + (v2 - v1) * ((k + 0.5) / n));
		}

		// 3) sector centres + grid inside big sectors
		for (int s = 0; s < level.Sectors.Size(); s++)
		{
			Sector sec = level.Sectors[s];
			if (sec.ceilingplane.ZAtPoint(sec.centerspot) - sec.floorplane.ZAtPoint(sec.centerspot) < MIN_GAP) continue;
			double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
			for (int l = 0; l < sec.lines.Size(); l++)
			{
				Line ln = sec.lines[l];
				x0 = min(x0, min(ln.v1.p.x, ln.v2.p.x)); x1 = max(x1, max(ln.v1.p.x, ln.v2.p.x));
				y0 = min(y0, min(ln.v1.p.y, ln.v2.p.y)); y1 = max(y1, max(ln.v1.p.y, ln.v2.p.y));
			}
			if (level.PointInSector(sec.centerspot) == sec) AddNode(sec.centerspot);
			if (x1 - x0 > 448 || y1 - y0 > 448)
			{
				// thin sectors (corridors) get a single line of nodes down the middle
				double sx = x1 - x0 > 448 ? 320 : 1e9, sy = y1 - y0 > 448 ? 320 : 1e9;
				double gx0 = x1 - x0 > 448 ? x0 + 160 : (x0 + x1) / 2;
				double gy0 = y1 - y0 > 448 ? y0 + 160 : (y0 + y1) / 2;
				for (double gx = gx0; gx <= max(gx0, x1 - 64); gx += sx)
					for (double gy = gy0; gy <= max(gy0, y1 - 64); gy += sy)
						if (level.PointInSector((gx, gy)) == sec) AddNode((gx, gy));
			}
		}

		// 4) links (candidates from the node buckets, adjacency by counting sort)
		int n = nx.Size();
		Array<int> tmpA, tmpB;
		double linkR = linkRange > 0 ? linkRange : LINK_RANGE;
		int reach = int(ceil(linkR / BUCKET));
		for (int i = 0; i < n; i++)
		{
			Vector2 pi = (nx[i], ny[i]);
			int bx = clamp(int(floor((pi.x - gox) / BUCKET)), 0, GW - 1), by = clamp(int(floor((pi.y - goy) / BUCKET)), 0, GW - 1);
			for (int oy = max(by - reach, 0); oy <= min(by + reach, GW - 1); oy++)
				for (int ox = max(bx - reach, 0); ox <= min(bx + reach, GW - 1); ox++)
					for (int j = nHead[oy * GW + ox]; j >= 0; j = nNext[j])
					{
						if (j <= i) continue;
						Vector2 pj = (nx[j], ny[j]);
						if ((pi - pj).Length() > linkR) continue;
						if (Clear(pi, pj)) { tmpA.Push(i); tmpB.Push(j); }
					}
		}
		Array<int> deg, fill;
		for (int i = 0; i < n; i++) { deg.Push(0); fill.Push(0); }
		for (int k = 0; k < tmpA.Size(); k++) { deg[tmpA[k]]++; deg[tmpB[k]]++; }
		for (int i = 0; i < n; i++) { adjStart.Push(adj.Size()); adjCount.Push(deg[i]); for (int d = 0; d < deg[i]; d++) adj.Push(0); }
		for (int k = 0; k < tmpA.Size(); k++)
		{
			adj[adjStart[tmpA[k]] + fill[tmpA[k]]++] = tmpB[k];
			adj[adjStart[tmpB[k]] + fill[tmpB[k]]++] = tmpA[k];
		}

		if (CVar.FindCVar("cw_navdebug").GetBool())
		{
			for (int i = 0; i < n; i++) Actor.Spawn("CW_NavMarker", (nx[i], ny[i], FloorAt((nx[i], ny[i]))));
			Console.Printf("\cfNav graph: %d nodes, %d links, %d furniture blockers, %d ms", n, tmpA.Size(), fbx.Size(), MSTime() - t0);
		}
	}

	// Closest few nodes with a clear line to p.
	int NearestClear(Vector2 p)
	{
		// simple version: sort by distance, test up to 8
		Array<int> order;
		Array<double> dist;
		for (int i = 0; i < nx.Size(); i++)
		{
			double d = (p - (nx[i], ny[i])).Length();
			int at = dist.Size();
			for (int k = 0; k < dist.Size(); k++) if (d < dist[k]) { at = k; break; }
			dist.Insert(at, d); order.Insert(at, i);
			if (dist.Size() > 8) { dist.Pop(); order.Pop(); }
		}
		for (int k = 0; k < order.Size(); k++)
			if (Clear(p, (nx[order[k]], ny[order[k]]))) return order[k];
		return order.Size() ? order[0] : -1;
	}

	// Dijkstra from the node nearest `from` to the node nearest `to`. Result in `path`.
	bool Route(Vector2 from, Vector2 to)
	{
		path.Clear();
		int n = nx.Size();
		if (n == 0) return false;
		int s = NearestClear(from), g = NearestClear(to);
		if (s < 0 || g < 0) return false;
		Array<double> dist; Array<int> prev; Array<bool> done;
		for (int i = 0; i < n; i++) { dist.Push(1e12); prev.Push(-1); done.Push(false); }
		dist[s] = 0;
		for (int iter = 0; iter < n; iter++)
		{
			int u = -1;
			double ud = 1e12;
			for (int i = 0; i < n; i++) if (!done[i] && dist[i] < ud) { ud = dist[i]; u = i; }
			if (u < 0 || u == g) break;
			done[u] = true;
			for (int k = 0; k < adjCount[u]; k++)
			{
				int v = adj[adjStart[u] + k];
				double nd = ud + ((nx[u], ny[u]) - (nx[v], ny[v])).Length();
				if (nd < dist[v]) { dist[v] = nd; prev[v] = u; }
			}
		}
		if (dist[g] >= 1e12) return false;
		for (int v = g; v >= 0; v = prev[v]) path.Insert(0, v);
		return true;
	}
}
