// New Bricks City — thrown debris art. Every key is an exact Doom PLAYPAL color (doom.hex).
// Lumps are named as UZDoom sprite lumps; tools copy out/ to nbc/sprites/debris with grAb offsets.
pal({
  k: "#000000",                                                       // edge shadow
  a: "#2f1b0b", b: "#3f2b1b", c: "#731313", d: "#8f2b2b", e: "#a33b3b", f: "#ab6f43", // brick, dark -> dusty tan light
  m: "#6f6f6f", n: "#9f9f9f", o: "#bfbfbf",                         // mortar crust
  1: "#272727", 2: "#3b3b3b", 3: "#575757", 4: "#777777", 5: "#979797", 6: "#b7b7b7", // concrete
  r: "#4f3b2b", R: "#6b4727",                                         // rusted rebar
})
ramps("abcdef", "123456", "mno")

// ---------- First-person hand: the frag grenade's hold frame, grenade recolored into a brick ----------
// HGRNA0 and HGRNQ0 are the same pixels (only grAb differs), so this one image ships as BRKHA0 and BRKHB0.
// The thumb ends at x 46; the grenade's orange band starts at x 53, so the band is taken by position + hue.
const GRENADE = (x, y) => x >= 44 && y >= 80
sprite("BRKHA0", { png: "src/HGRNA0.png" },
  rampmap("bcdef", { hue: [55, 110], where: GRENADE }),                // olive body -> brick
  rampmap("cde", { hue: [10, 50], where: (x, y) => x >= 50 && y >= 80 }),    // orange band -> the same brick, no top light (it read as a blob)
  (c) => {                                                              // the grenade's grooves read as two parts: fill the inner greys, keep the outline
    const grey = (v) => { const r = (v >>> 24) & 255, g = (v >>> 16) & 255, b = (v >>> 8) & 255; return (v & 255) && Math.abs(r - g) < 9 && Math.abs(g - b) < 9 ? r : -1 }
    const nearClear = (x, y) => { for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) if (c.is(x + dx, y + dy, ".")) return true; return false }
    for (let y = 80; y < c.h; y++) for (let x = 44; x < c.w; x++) {
      const v = grey(c.get(x, y)); if (v < 0 || nearClear(x, y)) continue
      c.px(x, y, v < 0x1c ? "b" : "c")
    }
  },
  (c) => {                                                              // dried mortar along the brick's top edge
    const rng = c.rng(7)
    for (let i = 0; i < 70; i++) {
      const x = 50 + Math.floor(rng() * 48), y = 88 + Math.floor(rng() * 44)
      if (!c.is(x, y, "def")) continue
      const k = rng() < 0.6 ? "n" : "o"
      c.px(x, y, k); if (c.is(x + 1, y, "cdef")) c.px(x + 1, y, rng() < 0.5 ? "m" : k)
    }
  })

// ---------- World: a loose brick, seen from above and in front (pickup) ----------
sprite("BRKPA0", { w: 15, h: 8 },
  poly([0, 3, 3, 0, 15, 0, 12, 3], "e"),                              // top face
  rect(0, 3, 12, 5, "d"),                                              // long face
  poly([12, 3, 15, 0, 15, 5, 12, 8], "b"),                             // end face
  hline(0, 3, 12, "f"), hline(0, 7, 12, "c"), vline(12, 3, 5, "a"),
  px(4, 4, "c"), px(8, 5, "c"), px(5, 1, "f"), px(10, 1, "d"), px(2, 6, "c"),
  px(1, 3, "n"), px(2, 3, "o"), px(3, 2, "n"),                         // mortar on the near corner
  px(13, 4, "c"), px(13, 2, "c"))

// ---------- World: half a brick, broken end on the right ----------
sprite("HBRKA0", { w: 10, h: 8 },
  poly([0, 3, 3, 0, 9, 0, 7, 3], "e"),
  rect(0, 3, 7, 5, "d"),
  poly([7, 3, 9, 0, 10, 2, 9, 5, 8, 8, 7, 8], "c"),                   // broken face, rough and darker
  hline(0, 3, 7, "f"), hline(0, 7, 7, "c"),
  px(8, 2, "b"), px(8, 5, "b"), px(9, 3, "a"), px(7, 6, "b"),
  px(3, 5, "c"), px(4, 1, "f"), px(1, 3, "n"))

// ---------- World: a chunk of concrete with a rebar stub ----------
sprite("CNCKA0", { w: 13, h: 11 },
  poly([1, 4, 4, 1, 9, 0, 12, 3, 11, 8, 7, 11, 2, 10, 0, 7], "4"),
  poly([1, 4, 4, 1, 9, 0, 12, 3, 8, 5, 3, 5], "5"),                   // lit top
  poly([8, 5, 12, 3, 11, 8, 7, 11], "3"),                              // shadow side
  hline(3, 5, 5, "6"), px(9, 1, "6"), px(5, 7, "3"), px(3, 8, "3"), px(9, 7, "2"),
  px(10, 9, "2"), px(4, 10, "3"), px(1, 8, "3"),
  vline(6, 0, 3, "R"), px(7, 0, "r"), px(6, 3, "r"))                   // rebar sticking out of the top

// ---------- Rubble pile, three stages as it is picked over (RUBL A full, B half, C nearly gone) ----------
sprite("_pb", { w: 7, h: 4 }, rect(0, 1, 6, 3, "d"), hline(1, 0, 6, "e"), vline(6, 0, 3, "b"), hline(0, 3, 6, "c"), px(2, 1, "c"))
sprite("_pbe", { w: 4, h: 4 }, rect(0, 1, 3, 3, "c"), hline(0, 0, 3, "d"), vline(3, 1, 3, "a"), px(1, 1, "d"))   // a brick seen end-on
sprite("_pc", { w: 6, h: 5 }, poly([0, 2, 2, 0, 5, 0, 6, 3, 4, 5, 1, 5], "4"), poly([0, 2, 2, 0, 5, 0, 4, 2], "5"), px(4, 3, "3"), px(5, 3, "3"))
sprite("_dust", { w: 3, h: 1 }, hline(0, 0, 3, "3"))

const dustBase = (w, h) => (c) => {
  c.poly([0, h, 4, h - 4, w - 4, h - 4, w, h], "3")
  c.poly([2, h - 1, 6, h - 4, w - 6, h - 4, w - 2, h - 1], "4")
  const rng = c.rng(w)
  for (let i = 0; i < w / 3; i++) c.px(2 + Math.floor(rng() * (w - 4)), h - 1 - Math.floor(rng() * 3), rng() < 0.5 ? "5" : "2")
}
sprite("RUBLA0", { w: 40, h: 20 }, dustBase(40, 20),
  stamp("_pc", 3, 12), stamp("_pb", 8, 11), stamp("_pbe", 15, 13), stamp("_pb", 21, 12), stamp("_pc", 28, 12), stamp("_pbe", 33, 14),
  stamp("_pb", 11, 7), stamp("_pc", 17, 6), stamp("_pb", 23, 7), stamp("_pbe", 30, 9),
  stamp("_pb", 15, 3), stamp("_pbe", 22, 3), stamp("_pc", 19, 0),
  px(6, 17, "n"), px(27, 18, "n"), px(18, 16, "o"))
sprite("RUBLB0", { w: 32, h: 14 }, dustBase(32, 14),
  stamp("_pc", 3, 6), stamp("_pb", 9, 6), stamp("_pbe", 16, 7), stamp("_pb", 21, 7),
  stamp("_pb", 11, 2), stamp("_pc", 17, 1), px(7, 11, "n"), px(24, 12, "n"))
sprite("RUBLC0", { w: 22, h: 8 }, dustBase(22, 8),
  stamp("_pbe", 6, 2), stamp("_pc", 11, 1), px(4, 6, "n"), px(16, 6, "o"))

// ---------- Fragments: tiny shards a broken piece throws off (BFRG A-D, one per frame, picked at random) ----------
sprite("BFRGA0", "de\ncd")
sprite("BFRGB0", ".e\ndc\nc.")
sprite("BFRGC0", "54\n43")
sprite("BFRGD0", "dee\n.cb")

// ---------- Thrown: tumbling in flight, 4 frames each (a quarter turn per 2 frames, so A-D loops a half spin) ----------
for (const [base, lump] of [["BRKPA0", "BRKT"], ["HBRKA0", "HBKT"], ["CNCKA0", "CNKT"]]) {
  sprite(`${lump}A0`, { base })
  sprite(`${lump}B0`, { base, angle: 45 })
  sprite(`${lump}C0`, { base, rot: 90 })
  sprite(`${lump}D0`, { base, angle: 135 })
}

sheet("debris_world", ["BRKPA0", "HBRKA0", "CNCKA0", "RUBL*", "BFRG*"], { pad: 2 })
sheet("debris_thrown", ["BRKT*", "HBKT*", "CNKT*"], { pad: 2 })
