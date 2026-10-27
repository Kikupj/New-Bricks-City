// =============================================================================
// Corpo Wars — tactical lean (Q / E)
// Based on "Tactical Lean" (lean.pk3; see CREDITS.txt), reworked for stealth play:
//  - the body stays put behind cover; only the camera tilts and slides out to peek
//    (the original shoved the whole player sideways, out of cover)
//  - the slide is traced against walls, so you can't see through them
//  - per-player state, no stuck tilt after death / map change, one key per side
//  - guards can spot your head when you peek (CW_Lean.Peeking / PeekPos, used by CW_Guard.Sense)
// Shots still leave from the body: leaning is for looking, not for firing round corners.
// =============================================================================
class CW_Lean : EventHandler
{
	int want[MAXPLAYERS];       // -1 left, 0 none, 1 right (held keys)
	bool holdL[MAXPLAYERS], holdR[MAXPLAYERS];
	double amount[MAXPLAYERS];  // -1..1, eased toward want
	double slide[MAXPLAYERS];   // current sideways camera offset (after the wall trace), + = right

	static clearscope CW_Lean Get() { return CW_Lean(EventHandler.Find("CW_Lean")); }

	// Is this player peeking round something (leaning far enough to show a head)? And where is that head?
	static clearscope bool Peeking(Actor pm)
	{
		let h = Get();
		if (!h || !pm || !pm.player) return false;
		int p = pm.PlayerNumber();
		return p >= 0 && p < MAXPLAYERS && abs(h.slide[p]) >= 6;
	}
	static clearscope Vector3 PeekPos(Actor pm)
	{
		let h = Get();
		if (!h || !pm || !pm.player) return pm ? pm.pos : (0, 0, 0);
		int p = pm.PlayerNumber();
		Vector2 side = Actor.AngleToVector(pm.angle - 90) * h.slide[p];   // + slide = right
		return pm.pos + (side, pm.player.viewheight - 4);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		int p = e.Player;
		if (p < 0 || p >= MAXPLAYERS || !playeringame[p]) return;
		if      (e.Name == "cw_lean_l")   holdL[p] = true;
		else if (e.Name == "cw_unlean_l") holdL[p] = false;
		else if (e.Name == "cw_lean_r")   holdR[p] = true;
		else if (e.Name == "cw_unlean_r") holdR[p] = false;
		else return;
		want[p] = holdL[p] == holdR[p] ? 0 : (holdL[p] ? -1 : 1);
	}

	override void PlayerEntered(PlayerEvent e) { Reset(e.PlayerNumber); }
	override void PlayerRespawned(PlayerEvent e) { Reset(e.PlayerNumber); }

	void Reset(int p)
	{
		if (p < 0 || p >= MAXPLAYERS) return;
		want[p] = 0; holdL[p] = false; holdR[p] = false; amount[p] = 0; slide[p] = 0;
		let pm = players[p].mo;
		if (pm) { pm.A_SetRoll(0); pm.SetViewPos((0, 0, 0), 0); }
	}

	override void WorldTick()
	{
		for (int p = 0; p < MAXPLAYERS; p++)
		{
			if (!playeringame[p] || !players[p].mo) continue;
			let pm = players[p].mo;
			if (pm.health <= 0)   // dead: drop the lean but leave the roll to the death roll (CW_Player)
			{
				if (amount[p] != 0 || slide[p] != 0) { amount[p] = 0; slide[p] = 0; pm.SetViewPos((0, 0, 0), 0); }
				continue;
			}
			bool can = !(players[p].cheats & CF_TOTALLYFROZEN);
			double goal = can ? want[p] : 0;
			if (amount[p] == 0 && goal == 0)
			{
				slide[p] = 0;
				if (pm.ViewPos && pm.ViewPos.Offset != (0, 0, 0)) { pm.SetViewPos((0, 0, 0), 0); pm.A_SetRoll(0); }
				continue;
			}

			amount[p] += clamp(goal - amount[p], -0.2, 0.2);
			if (abs(amount[p]) < 0.01 && goal == 0) amount[p] = 0;

			double maxAng = CVar.GetCVar('cw_leanangle', players[p]).GetFloat();
			double maxDist = CVar.GetCVar('cw_leandist', players[p]).GetFloat();
			double off = amount[p] * maxDist;   // + right, - left

			// keep the camera out of walls: trace from the eye toward the lean side
			double d = abs(off);
			if (d > 0)
			{
				double side = off > 0 ? -90 : 90;
				FLineTraceData t;
				double eyez = players[p].viewheight - 4;
				if (pm.LineTrace(pm.angle + side, d + 10, 0, TRF_THRUACTORS | TRF_THRUHITSCAN, eyez, 0, 0, t))
					d = max(0, t.Distance - 10);
			}
			slide[p] = off > 0 ? d : -d;

			pm.A_SetRoll(amount[p] * maxAng, SPF_INTERPOLATE);
			// relative view offset: +y is to the player's left
			pm.SetViewPos((0, -slide[p], -abs(amount[p]) * 4), 0);
			// leaning is a planted stance: movement slows right down
			if (abs(amount[p]) > 0.2 && pm.player.onground) pm.vel.xy *= 0.7;
		}
	}
}
