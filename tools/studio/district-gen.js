'use strict';
// District layouts for New Bricks City, as iDoom Studio projects (PLAN.md M2e). build_maps.js sends them to the
// editor through its MCP; this file only plans them. Everything comes from a seed, so a district rebuilds the same.
//
// How a district is put together, in the editor's terms (rooms below smart objects; later ones on top):
//   ground      one outdoor room over the whole map: the street, the roof plane, the tunnels
//   blocks      a grid of blocks between the streets. Each is a building, a solid mass with a lit facade, a yard
//               behind a fence, a raised deck reached by stairs, a park plot, a container yard...
//   buildings   leaf rooms that tile the inside (corridor-and-flats, a hall, or a random split). Every leaf has an
//               8-unit band of wall (solid pillars in its own wall texture) on each side, so two leaves make a
//               16-unit wall, and the building an 8-unit facade ring outside them. Doorways, arches and windows
//               are objects laid over the walls; an exterior door has a 72-high header on the street side, so the
//               door reads at human scale under a tall street.
//   things      the player start (south), the roof starts (NBC_RoofStart on the decks), gang member spots (a raid
//               clears them and stands the holding gang there), the exit (a breaker box in the far building),
//               Corpo Wars furniture and street props as cover, rubble piles, lamp posts, parked cars.
// Scale (PLAN.md 4.4): a person is 56 units; rooms 96 high, doors 56 wide, windows 32-72 above the floor.

// ------------------------------------------------------------------ seeded randomness, rects
function mulberry32(seed) {
    let a = seed >>> 0;
    return () => {
        a = (a + 0x6D2B79F5) >>> 0;
        let t = a;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

const snap = v => Math.round(v / 8) * 8;
const R = (x, y, w, h) => ({ x: snap(x), y: snap(y), w: snap(w), h: snap(h) });
const inset = (r, d) => ({ x: r.x + d, y: r.y + d, w: r.w - 2 * d, h: r.h - 2 * d });
const grow = (r, d) => inset(r, -d);
const cx = r => r.x + r.w / 2;
const cy = r => r.y + r.h / 2;
const overlaps = (a, b, m = 0) => a.x < b.x + b.w + m && b.x < a.x + a.w + m && a.y < b.y + b.h + m && b.y < a.y + a.h + m;
const dist = (ax, ay, bx, by) => Math.hypot(ax - bx, ay - by);

// ------------------------------------------------------------------ the catalog of things we place
const T = {
    start: 1, roofStart: 26020, gang: 3004, barrel: 2035, rubble: 26004, brick: 26000, bottle: 26003,
    sofa: 26206, armchair: 26207, coffee: 26208, roundTable: 26210, chair: 26205, deskWork: 26200, reception: 26211,
    fileCab: 26212, bookshelf: 26213, shelving: 26215, vending: 26216, counter: 26219, bin: 26221, planter: 26222,
    credenza: 26223, lampPost: 26233, container: 26234, crates: 26236, pallet: 26237, barCounter: 26238,
    stool: 26239, bed: 26240, pew: 26241, tank: 26242, scaffold: 26244, dumpster: 26245, stall: 26246,
    generator: 26250, turnstile: 26251, locker: 26252, workbench: 26254, acUnit: 26255, waterTower: 26256,
    barrier: 26257, sandbags: 26258,
    tvStand: 26469, kitchen: 26472, washer: 26475, dryer: 26476, pantry: 26477, drums: 26580, cylinders: 26581,
    rackStocked: 26578, rackSparse: 26579, palletBoxes: 26574, palletCrates: 26575, cone: 26516, hazardBarrel: 26515,
    pumpMotor: 26522, trashBag: 26546, caseGreen: 26524,
    roomLight: 26021, streetLight: 26022, winLit: 26459, winDark: 26458, vent: 26460
};
// footprints (depth along the facing, width across it) from the furniture classes; sprites get a small square
const SIZE = {
    [T.sofa]: [36, 84], [T.armchair]: [32, 32], [T.coffee]: [28, 48], [T.roundTable]: [32, 32], [T.chair]: [24, 24],
    [T.deskWork]: [30, 60], [T.reception]: [40, 116], [T.fileCab]: [26, 18], [T.bookshelf]: [14, 36],
    [T.shelving]: [22, 66], [T.vending]: [32, 36], [T.counter]: [24, 96], [T.bin]: [16, 16], [T.planter]: [26, 82],
    [T.credenza]: [20, 62], [T.lampPost]: [10, 10], [T.container]: [80, 200], [T.crates]: [40, 40], [T.pallet]: [40, 48],
    [T.barCounter]: [28, 128], [T.stool]: [16, 16], [T.bed]: [80, 44], [T.pew]: [24, 96], [T.tank]: [64, 64],
    [T.scaffold]: [32, 96], [T.dumpster]: [36, 72], [T.stall]: [48, 80], [T.generator]: [40, 72], [T.turnstile]: [32, 12],
    [T.locker]: [18, 36], [T.workbench]: [30, 80], [T.acUnit]: [40, 56], [T.waterTower]: [72, 72], [T.barrier]: [20, 72],
    [T.sandbags]: [24, 72], [T.tvStand]: [24, 48], [T.kitchen]: [28, 64], [T.washer]: [28, 28], [T.dryer]: [28, 28],
    [T.pantry]: [20, 40], [T.drums]: [40, 40], [T.cylinders]: [24, 32], [T.rackStocked]: [24, 72], [T.rackSparse]: [24, 72],
    [T.palletBoxes]: [40, 48], [T.palletCrates]: [40, 48], [T.cone]: [12, 12], [T.hazardBarrel]: [20, 20],
    [T.pumpMotor]: [32, 40], [T.trashBag]: [16, 16], [T.caseGreen]: [24, 32], [T.barrel]: [20, 20], [T.rubble]: [36, 36]
};
// civilian voxel cars, vans, pickups, SUVs, taxis (no police, no UAC)
const CARS = [10600, 10601, 10602, 10603, 10604, 10606, 10613, 10616, 10617, 10618, 10619, 10620, 10621, 10622, 10624,
    10625, 10626, 10627, 10628, 10631, 10633, 10636, 10638, 10640, 10641, 10643, 10646, 10649, 10650, 10652, 10655,
    10657, 10659, 10661, 10663, 10666, 10668, 10670, 10753, 10755, 10756, 10758, 10761];
const CAR_SIZE = [72, 32];
const sizeOf = type => SIZE[type] || (CARS.includes(type) ? CAR_SIZE : [24, 24]);

// what dresses a room, by its kind: [type, chance] lists, tried in order along the walls
const ROOM_PROPS = {
    flat: [[T.sofa, 0.7], [T.coffee, 0.5], [T.tvStand, 0.4], [T.bed, 0.5], [T.roundTable, 0.4], [T.chair, 0.4], [T.credenza, 0.3], [T.kitchen, 0.4], [T.bin, 0.3]],
    corridor: [[T.bin, 0.3], [T.planter, 0.2], [T.trashBag, 0.4]],
    lobby: [[T.reception, 0.6], [T.planter, 0.6], [T.vending, 0.5], [T.sofa, 0.4], [T.armchair, 0.4]],
    shop: [[T.counter, 0.8], [T.shelving, 0.8], [T.shelving, 0.6], [T.vending, 0.5], [T.crates, 0.4]],
    office: [[T.deskWork, 0.8], [T.fileCab, 0.6], [T.bookshelf, 0.5], [T.chair, 0.6], [T.deskWork, 0.4]],
    den: [[T.barCounter, 0.6], [T.stool, 0.6], [T.sofa, 0.6], [T.roundTable, 0.5], [T.crates, 0.4], [T.drums, 0.3]],
    warehouse: [[T.rackStocked, 0.9], [T.rackSparse, 0.8], [T.palletBoxes, 0.7], [T.palletCrates, 0.7], [T.crates, 0.7], [T.drums, 0.5], [T.cylinders, 0.4], [T.workbench, 0.4], [T.generator, 0.3]],
    boiler: [[T.tank, 0.8], [T.generator, 0.7], [T.pumpMotor, 0.6], [T.drums, 0.5], [T.hazardBarrel, 0.5], [T.workbench, 0.3]],
    laundry: [[T.washer, 0.8], [T.dryer, 0.8], [T.washer, 0.5], [T.counter, 0.4], [T.bin, 0.4]],
    station: [[T.pew, 0.8], [T.pew, 0.6], [T.vending, 0.5], [T.bin, 0.5], [T.locker, 0.3]],
    stairhut: [[T.drums, 0.3], [T.crates, 0.4], [T.locker, 0.3]],
    penthouse: [[T.sofa, 0.8], [T.armchair, 0.7], [T.coffee, 0.6], [T.barCounter, 0.5], [T.planter, 0.6], [T.bookshelf, 0.4], [T.deskWork, 0.4]],
    barracks: [[T.bed, 0.8], [T.locker, 0.8], [T.locker, 0.6], [T.bed, 0.6], [T.crates, 0.4]],
    armory: [[T.rackStocked, 0.8], [T.crates, 0.7], [T.workbench, 0.6], [T.locker, 0.6], [T.sandbags, 0.4]]
};

// ------------------------------------------------------------------ the builder
class Builder {
    constructor(seed) {
        this.rand = mulberry32(seed);
        this.n = 0;
        this.rooms = [];
        this.walls = [];      // solid pillars: facades, wall bands, masses (lowest objects)
        this.openings = [];   // doors, arches, windows, headers, exits, stairs
        this.tops = [];       // parapets, pools, low cover (highest objects)
        this.things = [];
        this.keepClear = [];  // rects props and spots stay out of (doorways, stairs)
        this.solid = [];      // rects already taken by props, walls and masses
        this.spots = [];      // gang spots placed
        this.decks = [];
        this.windows = [];    // { rect, obj }: an exit can take a window's place
        this.areas = [];      // { rect, floor, kind }: where gang spots can go outdoors
    }
    r() { return this.rand(); }
    int(a, b) { return a + Math.floor(this.r() * (b - a + 1)); }
    pick(list) { return list[Math.floor(this.r() * list.length)]; }
    chance(p) { return this.r() < p; }
    id(prefix) { return `${prefix}_${++this.n}`; }

    room(rect, o) {
        const room = {
            id: this.id(o.prefix || 'room'), name: o.name || 'Room', shape: 'rect',
            x: rect.x, y: rect.y, width: rect.w, height: rect.h,
            floorHeight: o.floor || 0, ceilingHeight: o.ceil, lightLevel: o.light || 160, theme: o.theme
        };
        for (const key of ['floorTexture', 'ceilingTexture', 'wallTexture', 'upperTexture', 'lowerTexture']) if (o[key]) room[key] = o[key];
        this.rooms.push(room);
        return room;
    }
    wall(rect, texture, name = 'Wall') {
        if (rect.w <= 0 || rect.h <= 0) return;
        this.walls.push({ id: this.id('wall'), name, type: 'pillar', solid: true, x: rect.x, y: rect.y, width: rect.w, height: rect.h, wallTexture: texture });
        this.solid.push(rect);
    }
    opening(o, rect) {
        const obj = { id: this.id(o.type), x: rect.x, y: rect.y, width: rect.w, height: rect.h, ...o };
        this.openings.push(obj);
        return obj;
    }
    top(o, rect) {
        const obj = { id: this.id(o.type), x: rect.x, y: rect.y, width: rect.w, height: rect.h, ...o };
        this.tops.push(obj);
        return obj;
    }
    thing(type, x, y, angle = 0, extra = {}) {
        this.things.push({ id: this.id('th'), type, x: Math.round(x), y: Math.round(y), angle: ((Math.round(angle) % 360) + 360) % 360, ...extra });
    }
    free(rect, margin = 4) {
        return !this.solid.some(s => overlaps(s, rect, margin)) && !this.keepClear.some(s => overlaps(s, rect, margin));
    }
    // a prop against one wall of a room's walkable rect, facing into the room
    propOnWall(area, type, side) {
        const [d, w] = sizeOf(type);
        const horizontalWall = side === 'N' || side === 'S';
        const along = horizontalWall ? area.w : area.h;
        if (along < w + 16) return false;
        for (let tries = 0; tries < 6; tries++) {
            const u = (horizontalWall ? area.x : area.y) + w / 2 + 8 + this.r() * (along - w - 16);
            let x, y, angle, rect;
            if (side === 'N') { y = area.y + area.h - d / 2 - 2; x = u; angle = 270; rect = { x: u - w / 2, y: y - d / 2, w, h: d }; }
            else if (side === 'S') { y = area.y + d / 2 + 2; x = u; angle = 90; rect = { x: u - w / 2, y: y - d / 2, w, h: d }; }
            else if (side === 'W') { x = area.x + d / 2 + 2; y = u; angle = 0; rect = { x: x - d / 2, y: u - w / 2, w: d, h: w }; }
            else { x = area.x + area.w - d / 2 - 2; y = u; angle = 180; rect = { x: x - d / 2, y: u - w / 2, w: d, h: w }; }
            if (!this.free(rect, 6)) continue;
            this.thing(type, x, y, angle);
            this.solid.push(rect);
            return true;
        }
        return false;
    }
    // a prop anywhere in an area (cover in the open), any of the four facings
    propIn(area, type, angle = null) {
        const [d, w] = sizeOf(type);
        for (let tries = 0; tries < 10; tries++) {
            const a = angle === null ? this.pick([0, 90, 180, 270]) : angle;
            const along = a === 0 || a === 180;
            const rw = along ? d : w, rh = along ? w : d;
            if (area.w < rw + 16 || area.h < rh + 16) return false;
            const x = area.x + rw / 2 + 8 + this.r() * (area.w - rw - 16);
            const y = area.y + rh / 2 + 8 + this.r() * (area.h - rh - 16);
            const rect = { x: x - rw / 2, y: y - rh / 2, w: rw, h: rh };
            if (!this.free(rect, 24)) continue;
            this.thing(type, x, y, a);
            this.solid.push(rect);
            return { x, y };
        }
        return null;
    }
    // a gang member spot: clear of walls, props, doorways and other spots
    spot(area, z = 0) {
        for (let tries = 0; tries < 12; tries++) {
            if (area.w < 64 || area.h < 64) return false;
            const x = area.x + 28 + this.r() * (area.w - 56);
            const y = area.y + 28 + this.r() * (area.h - 56);
            const rect = { x: x - 22, y: y - 22, w: 44, h: 44 };
            if (!this.free(rect, 2)) continue;
            if (this.spots.some(s => dist(s.x, s.y, x, y) < 72)) continue;
            this.thing(T.gang, x, y, this.pick([0, 45, 90, 135, 180, 225, 270, 315]));
            this.spots.push({ x, y, z });
            this.solid.push({ x: x - 16, y: y - 16, w: 32, h: 32 });
            return true;
        }
        return false;
    }
    project(name, mapLump, skybox) {
        return {
            name, mapLump, skybox, schemaVersion: 1,
            rooms: this.rooms,
            smartObjects: [...this.walls, ...this.openings, ...this.tops],
            links: [],
            things: this.things
        };
    }
}

// ------------------------------------------------------------------ interiors
// Leaves tile the interior rect; links are pairs of leaves that share an edge (to be joined by an opening).
function corridorLayout(b, I, o) {
    const leaves = [], links = [];
    const horiz = I.w >= I.h;
    const len = horiz ? I.w : I.h, depth = horiz ? I.h : I.w;
    const cw = 112;                                                     // a 96 corridor between 8 bands
    if (depth < cw + 160) {
        // too shallow for flats off a corridor: one long room
        const hall = { rect: I, kind: 'corridor', theme: o.corridorTheme };
        return { leaves: [hall], links: [], entrances: ['S', 'N', 'W', 'E'].map(side => ({ leaf: hall, side })) };
    }
    const twoSided = depth >= cw + 2 * 176;
    const c0 = twoSided ? snap((depth - cw) / 2) : depth - cw;
    const corr = horiz ? R(I.x, I.y + c0, I.w, cw) : R(I.x + c0, I.y, cw, I.h);
    const corridor = { rect: corr, kind: 'corridor', theme: o.corridorTheme };
    leaves.push(corridor);
    const strips = [];
    if (c0 > 0) strips.push(horiz ? R(I.x, I.y, I.w, c0) : R(I.x, I.y, c0, I.h));
    const after = depth - c0 - cw;
    if (after > 0) strips.push(horiz ? R(I.x, I.y + c0 + cw, I.w, after) : R(I.x + c0 + cw, I.y, after, I.h));
    for (const strip of strips) {
        let u = 0;
        let prev = null;
        while (len - u >= 176) {
            let w = snap(o.flatMin + b.r() * (o.flatMax - o.flatMin));
            if (len - u - w < 176) w = len - u;
            const rect = horiz ? R(strip.x + u, strip.y, w, strip.h) : R(strip.x, strip.y + u, strip.w, w);
            const kind = b.pick(o.flatKinds);
            const leaf = { rect, kind, theme: o.flatTheme(kind) };
            leaves.push(leaf);
            links.push({ a: leaf, b: corridor, door: b.chance(o.doorChance) });
            if (prev && b.chance(0.25)) links.push({ a: prev, b: leaf, door: false });
            prev = leaf;
            u += w;
        }
    }
    // the corridor's ends are the way in
    const ends = horiz ? ['W', 'E'] : ['S', 'N'];
    return { leaves, links, entrances: ends.map(side => ({ leaf: corridor, side })) };
}

function bspLayout(b, I, o) {
    const leaves = [], splits = [];
    const min = o.minRoom || 192, max = o.maxRoom || 448;
    function split(r, depth) {
        const canX = r.w >= 2 * min, canY = r.h >= 2 * min;
        const small = r.w <= max && r.h <= max;
        if ((!canX && !canY) || (small && (depth > 1 || b.chance(0.5)))) {
            const kind = b.pick(o.roomKinds);
            leaves.push({ rect: r, kind, theme: o.themeFor(kind) });
            return;
        }
        const axis = canX && canY ? (r.w > r.h * 1.15 ? 'x' : (r.h > r.w * 1.15 ? 'y' : (b.chance(0.5) ? 'x' : 'y'))) : (canX ? 'x' : 'y');
        if (axis === 'x') {
            const c = snap(r.x + min + b.r() * (r.w - 2 * min));
            const A = R(r.x, r.y, c - r.x, r.h), B = R(c, r.y, r.x + r.w - c, r.h);
            const s = { axis, c, A: [], B: [] };
            splits.push(s);
            const before = leaves.length; split(A, depth + 1); s.A = leaves.slice(before);
            const mid = leaves.length; split(B, depth + 1); s.B = leaves.slice(mid);
        } else {
            const c = snap(r.y + min + b.r() * (r.h - 2 * min));
            const A = R(r.x, r.y, r.w, c - r.y), B = R(r.x, c, r.w, r.y + r.h - c);
            const s = { axis, c, A: [], B: [] };
            splits.push(s);
            const before = leaves.length; split(A, depth + 1); s.A = leaves.slice(before);
            const mid = leaves.length; split(B, depth + 1); s.B = leaves.slice(mid);
        }
    }
    split(I, 0);
    const links = [];
    for (const s of splits) {
        const pairs = [];
        for (const a of s.A) for (const c of s.B) {
            const touch = s.axis === 'x' ? a.rect.x + a.rect.w === s.c && c.rect.x === s.c : a.rect.y + a.rect.h === s.c && c.rect.y === s.c;
            if (!touch) continue;
            const lo = s.axis === 'x' ? Math.max(a.rect.y, c.rect.y) : Math.max(a.rect.x, c.rect.x);
            const hi = s.axis === 'x' ? Math.min(a.rect.y + a.rect.h, c.rect.y + c.rect.h) : Math.min(a.rect.x + a.rect.w, c.rect.x + c.rect.w);
            if (hi - lo >= 104) pairs.push({ a, c, span: hi - lo });
        }
        if (!pairs.length) continue;
        pairs.sort((p, q) => q.span - p.span);
        const pick = b.chance(0.5) ? pairs[0] : b.pick(pairs);
        links.push({ a: pick.a, b: pick.c, door: b.chance(o.doorChance) });
    }
    const entrances = [];
    for (const side of ['S', 'N', 'W', 'E']) {
        const touching = leaves.filter(l => (side === 'S' && l.rect.y === I.y) || (side === 'N' && l.rect.y + l.rect.h === I.y + I.h)
            || (side === 'W' && l.rect.x === I.x) || (side === 'E' && l.rect.x + l.rect.w === I.x + I.w));
        if (touching.length) entrances.push({ leaf: b.pick(touching), side });
    }
    return { leaves, links, entrances };
}

function hallLayout(b, I, o) {
    // one big hall; on a long hall, an office or two split off one end
    const leaves = [], links = [];
    const horiz = I.w >= I.h;
    const len = horiz ? I.w : I.h;
    let hallRect = I;
    if (len >= 768 && b.chance(0.7)) {
        const d = 224;
        const office = horiz ? R(I.x + I.w - d, I.y, d, I.h) : R(I.x, I.y + I.h - d, I.w, d);
        hallRect = horiz ? R(I.x, I.y, I.w - d, I.h) : R(I.x, I.y, I.w, I.h - d);
        const hall = { rect: hallRect, kind: o.hallKind, theme: o.hallTheme, hall: true };
        leaves.push(hall);
        const across = horiz ? I.h : I.w;
        if (across >= 448) {
            const half = snap(across / 2);
            const a = horiz ? R(office.x, office.y, d, half) : R(office.x, office.y, half, d);
            const c = horiz ? R(office.x, office.y + half, d, office.h - half) : R(office.x + half, office.y, office.w - half, d);
            const la = { rect: a, kind: o.officeKind, theme: o.officeTheme }, lc = { rect: c, kind: o.officeKind, theme: o.officeTheme };
            leaves.push(la, lc);
            links.push({ a: hall, b: la, door: true }, { a: hall, b: lc, door: b.chance(0.5) });
        } else {
            const la = { rect: office, kind: o.officeKind, theme: o.officeTheme };
            leaves.push(la);
            links.push({ a: hall, b: la, door: true });
        }
    } else leaves.push({ rect: hallRect, kind: o.hallKind, theme: o.hallTheme, hall: true });
    const hall = leaves[0];
    return { leaves, links, entrances: ['S', 'N', 'W', 'E'].map(side => ({ leaf: hall, side })) };
}

// the shared edge of two leaves: { axis: 'x' (a vertical wall at x = c) or 'y', c, lo, hi }
function sharedEdge(a, c) {
    const A = a.rect, C = c.rect;
    if (A.x + A.w === C.x || C.x + C.w === A.x) {
        const x = A.x + A.w === C.x ? C.x : A.x;
        return { axis: 'x', c: x, lo: Math.max(A.y, C.y), hi: Math.min(A.y + A.h, C.y + C.h) };
    }
    if (A.y + A.h === C.y || C.y + C.h === A.y) {
        const y = A.y + A.h === C.y ? C.y : A.y;
        return { axis: 'y', c: y, lo: Math.max(A.x, C.x), hi: Math.min(A.x + A.w, C.x + C.w) };
    }
    return null;
}

// Upper storeys on a facade: rows of window sprites (Corpo Wars' lit and dark brick windows, now and then a vent)
// hung on the outside face at 80-320 up, above the real windows. Only brick and concrete fronts; the lit-window
// facades have their windows painted in. sides: the faces that look out (N, S, W, E); top: the sky over the street.
const DECOR_FACADES = new Set([...['ADBRICK', 'AXW84', 'AXW85'], ...['CWCONCW', 'AXW43A', 'AXW24', 'ADCONC1']]);
function facadeDecor(b, F, texture, top, sides) {
    if (!DECOR_FACADES.has(texture) || !top) return;
    for (const side of sides) {
        const horizontalSide = side === 'S' || side === 'N';
        const lo = horizontalSide ? F.x : F.y, len = horizontalSide ? F.w : F.h;
        for (let z = 160; z <= top - 24; z += 80) {
            for (let u = lo + 40; u + 64 <= lo + len - 40; u += 96) {
                if (b.chance(0.12)) continue;
                const roll = b.r();
                const type = roll < 0.35 ? T.winLit : (roll < 0.92 ? T.winDark : T.vent);
                if (side === 'N') b.thing(type, u, F.y + F.h + 1, 90, { z });
                else if (side === 'S') b.thing(type, u + 64, F.y - 1, 270, { z });
                else if (side === 'E') b.thing(type, F.x + F.w + 1, u + 64, 0, { z });
                else b.thing(type, F.x - 1, u, 180, { z });
            }
        }
    }
}

// A room's lights: a ceiling fixture (a small sector with a light flat, a little brighter) with a dynamic light under
// it (NBC_RoomLight), one in a room, a grid of them in a hall or a long corridor. Flats, dens and penthouses get a rug
// first, so the fixture keeps the rug's floor.
function roomLights(b, leaf, o, themes) {
    const a = leaf.area;
    const t = themes[leaf.theme] || {};
    const base = { prefix: 'fixture', floor: leaf.floor, ceil: leaf.ceil, theme: leaf.theme, ...(t.overrides || {}) };
    const light = o.light(leaf.kind);
    let rug = null, rugTex = null;
    if (['flat', 'den', 'penthouse', 'office'].includes(leaf.kind) && a.w >= 160 && a.h >= 160 && b.chance(0.75)) {
        rugTex = leaf.kind === 'penthouse' ? 'CWCARP2' : b.pick(['CWCARP1', 'CWCARP2', 'CWCARP3']);
        rug = inset(a, snap(Math.max(40, Math.min(a.w, a.h) * 0.22)));
        b.room(rug, { ...base, prefix: 'rug', name: 'Rug', light, floorTexture: rugTex });
    }
    const centers = [];
    const long = Math.max(a.w, a.h) > 448;
    if (leaf.hall || long) {
        const g = inset(a, 96);
        const step = leaf.hall ? 288 : 256;
        for (let x = g.x + (g.w % step) / 2; x <= g.x + g.w; x += step)
            for (let y = g.y + (g.h % step) / 2; y <= g.y + g.h; y += step) centers.push([snap(x), snap(y)]);
    } else centers.push([snap(cx(a)), snap(cy(a))]);
    const fixture = b.pick(['ADCLRND', 'ADCLITE']);
    for (const [x, y] of centers) {
        const f = R(x - 16, y - 16, 32, 32);
        const onRug = rug && overlaps(rug, f, -1);
        b.room(f, { ...base, name: 'Light', light: Math.min(255, light + 24), ceilingTexture: fixture, ...(onRug ? { floorTexture: rugTex } : {}) });
        b.thing(T.roomLight, x, y, 0);
    }
}

// Puts a building on the map: leaf rooms, their wall bands, the facade ring, openings, windows, exterior doors,
// props and spots. Returns the leaves (for the exit and the start).
function building(b, B, o) {
    const floor = o.floor || 0;
    const ceil = floor + (o.roomCeil || 96);
    const I = inset(B, 8);
    let layout;
    if (o.layout === 'corridor') layout = corridorLayout(b, I, o);
    else if (o.layout === 'hall') layout = hallLayout(b, I, o);
    else layout = bspLayout(b, I, o);
    const { leaves, links } = layout;
    const themes = o.themes;
    // facade ring (one texture per building) and the leaves with their wall bands
    const facade = o.facade;
    b.wall(R(B.x, B.y, B.w, 8), facade, 'Facade');
    b.wall(R(B.x, B.y + B.h - 8, B.w, 8), facade, 'Facade');
    b.wall(R(B.x, B.y, 8, B.h), facade, 'Facade');
    b.wall(R(B.x + B.w - 8, B.y, 8, B.h), facade, 'Facade');
    facadeDecor(b, B, facade, o.facadeTop, ['N', 'S', 'W', 'E']);
    for (const leaf of leaves) {
        const t = themes[leaf.theme];
        const hallCeil = leaf.hall ? floor + (o.hallCeil || o.roomCeil || 96) : (leaf.kind === 'lobby' ? ceil + 16 : ceil);
        leaf.floor = floor; leaf.ceil = hallCeil;
        leaf.room = b.room(leaf.rect, { prefix: 'room', name: o.label(leaf.kind), floor, ceil: hallCeil, light: o.light(leaf.kind), theme: leaf.theme, ...(t.overrides || {}) });
        const r = leaf.rect, tex = t.wall;
        b.wall(R(r.x, r.y, r.w, 8), tex); b.wall(R(r.x, r.y + r.h - 8, r.w, 8), tex);
        b.wall(R(r.x, r.y + 8, 8, r.h - 16), tex); b.wall(R(r.x + r.w - 8, r.y + 8, 8, r.h - 16), tex);
        leaf.area = inset(r, 8);
        leaf.openings = [];
    }
    // openings between leaves
    for (const link of links) {
        const e = sharedEdge(link.a, link.b);
        if (!e) continue;
        const w = 56;
        if (e.hi - e.lo < w + 40) continue;
        const p = snap(e.lo + 20 + b.r() * (e.hi - e.lo - 40 - w));
        const rect = e.axis === 'x' ? R(e.c - 8, p, 16, w) : R(p, e.c - 8, w, 16);
        const tA = themes[link.a.theme], tB = themes[link.b.theme];
        if (link.door) b.opening({ type: 'door', name: 'Door', theme: link.a.theme, wallTexture: tA.door || tB.door, lock: 0, speed: 32, wait: 105 }, rect);
        else b.opening({ type: 'window', name: 'Doorway', floorHeight: floor, ceilingHeight: floor + 72, wallTexture: tA.wall, upperTexture: tA.wall, lowerTexture: tA.wall, blocking: false }, rect);
        const clear = e.axis === 'x' ? R(e.c - 56, p - 8, 112, w + 16) : R(p - 8, e.c - 56, w + 16, 112);
        b.keepClear.push(clear);
        link.a.openings.push(clear); link.b.openings.push(clear);
    }
    // the way in: a door behind a 72-high header in the facade
    const entrances = [];
    const wantSides = o.entranceSides || ['S'];
    for (const ent of layout.entrances) {
        if (!wantSides.includes(ent.side) || entrances.length >= (o.maxEntrances || 2)) continue;
        const r = ent.leaf.rect, w = 56;
        const horizontalSide = ent.side === 'S' || ent.side === 'N';
        const along = horizontalSide ? r.w : r.h;
        if (along < w + 48) continue;
        const p = snap((horizontalSide ? r.x : r.y) + 24 + b.r() * (along - w - 48));
        let header, door, clear;
        if (ent.side === 'S') { header = R(p, B.y, w, 8); door = R(p, B.y + 8, w, 8); clear = R(p - 16, B.y - 64, w + 32, 160); }
        else if (ent.side === 'N') { header = R(p, B.y + B.h - 8, w, 8); door = R(p, B.y + B.h - 16, w, 8); clear = R(p - 16, B.y + B.h - 96, w + 32, 160); }
        else if (ent.side === 'W') { header = R(B.x, p, 8, w); door = R(B.x + 8, p, 8, w); clear = R(B.x - 64, p - 16, 160, w + 32); }
        else { header = R(B.x + B.w - 8, p, 8, w); door = R(B.x + B.w - 16, p, 8, w); clear = R(B.x + B.w - 96, p - 16, 160, w + 32); }
        const t = themes[ent.leaf.theme];
        b.opening({ type: 'window', name: 'Entrance', floorHeight: o.outsideFloor ?? floor, ceilingHeight: floor + 72, wallTexture: facade, upperTexture: facade, lowerTexture: facade, blocking: false }, header);
        b.opening({ type: 'door', name: 'Front door', theme: ent.leaf.theme, wallTexture: o.frontDoor || t.door, lock: 0, speed: 32, wait: 105 }, door);
        b.keepClear.push(clear);
        ent.leaf.openings.push(clear);
        entrances.push({ side: ent.side, x: cx(door), y: cy(door), rect: door });
    }
    // windows on the outside walls of the leaves
    if (o.windows !== false) {
        for (const leaf of leaves) {
            const r = leaf.rect;
            const sides = [];
            if (r.y === I.y) sides.push('S');
            if (r.y + r.h === I.y + I.h) sides.push('N');
            if (r.x === I.x) sides.push('W');
            if (r.x + r.w === I.x + I.w) sides.push('E');
            for (const side of sides) {
                const horizontalSide = side === 'S' || side === 'N';
                const lo = horizontalSide ? r.x : r.y, len = horizontalSide ? r.w : r.h;
                for (let u = lo + 40; u + 48 <= lo + len - 40; u += b.int(96, 176)) {
                    let rect;
                    if (side === 'S') rect = R(u, B.y, 48, 16);
                    else if (side === 'N') rect = R(u, B.y + B.h - 16, 48, 16);
                    else if (side === 'W') rect = R(B.x, u, 16, 48);
                    else rect = R(B.x + B.w - 16, u, 16, 48);
                    if (b.keepClear.some(k => overlaps(k, rect, 8))) continue;
                    // the wall above and below the opening is the facade's (seen from the street it runs up to the sky)
                    const win = b.opening({ type: 'window', name: 'Window', floorHeight: floor + 32, ceilingHeight: floor + 72, wallTexture: o.trim, upperTexture: facade, lowerTexture: facade, blocking: false }, rect);
                    b.windows.push({ rect, obj: win });
                }
            }
        }
    }
    // props along the walls, then the gang's spots
    for (const leaf of leaves) {
        const list = ROOM_PROPS[leaf.kind] || [];
        const sides = ['N', 'S', 'W', 'E'];
        for (const [type, p] of list) {
            if (b.chance(p * (o.propDensity || 1))) b.propOnWall(leaf.area, type, b.pick(sides));
        }
        if (leaf.hall && o.hallColumns) hallColumns(b, leaf, o);
        roomLights(b, leaf, o, themes);
        const area = leaf.area.w * leaf.area.h;
        const n = Math.max(1, Math.min(5, Math.round(area / (o.spotArea || 70000))));
        for (let i = 0; i < n; i++) b.spot(leaf.area, floor);
    }
    return { leaves, entrances, rect: B };
}

// pillars down a big hall: cover, and the hall reads as a hall
function hallColumns(b, leaf, o) {
    const a = inset(leaf.area, 64);
    if (a.w < 128 || a.h < 128) return;
    const step = 192;
    for (let x = a.x + 32; x <= a.x + a.w - 32; x += step) {
        for (let y = a.y + 32; y <= a.y + a.h - 32; y += step) {
            const rect = R(x - 12, y - 12, 24, 24);
            if (!b.free(rect, 24)) continue;
            b.wall(rect, o.columnTexture || 'ADMETL1', 'Column');
        }
    }
}

// a lamp post placed in the open gets its glow
function lit(b, at, type) {
    if (at && type === T.lampPost) b.thing(T.streetLight, at.x, at.y, 0);
}

// a raised deck reached by stairs: perches for the gang, a roof start for the helicopter
function deck(b, D, o) {
    const floor = o.floor, base = o.base || 0, sky = o.sky;
    const room = b.room(D, { prefix: 'deck', name: o.name || 'Roof deck', floor, ceil: sky, light: o.light || 176, theme: o.theme, ceilingTexture: 'F_SKY1', lowerTexture: o.side || 'CWCONCW', wallTexture: o.side || 'CWCONCW' });
    // stairs cut into one edge, rising inward
    const rise = floor - base;
    const steps = Math.max(2, Math.ceil(rise / 16));
    const len = steps * 24;
    const side = o.stairSide || b.pick(['S', 'N', 'W', 'E']);
    const sw = 72;
    let stairs, dir;
    if (side === 'S') { const x = snap(cx(D) - sw / 2); stairs = R(x, D.y, sw, len); dir = 'N'; }
    else if (side === 'N') { const x = snap(cx(D) - sw / 2); stairs = R(x, D.y + D.h - len, sw, len); dir = 'S'; }
    else if (side === 'W') { const y = snap(cy(D) - sw / 2); stairs = R(D.x, y, len, sw); dir = 'E'; }
    else { const y = snap(cy(D) - sw / 2); stairs = R(D.x + D.w - len, y, len, sw); dir = 'W'; }
    const fits = (side === 'S' || side === 'N') ? D.h > len + 96 : D.w > len + 96;
    if (!fits) return null;
    b.opening({ type: 'stairs', name: 'Stairs', direction: dir, steps, startFloor: base, endFloor: floor, ceilingHeight: sky, ceilingTexture: 'F_SKY1', floorTexture: o.stairFloor || 'CWSTAIF', wallTexture: o.side || 'CWCONCW', lowerTexture: 'AXSTEP23', upperTexture: o.side || 'CWCONCW' }, stairs);
    b.keepClear.push(grow(stairs, 24));
    // a parapet round the edge (32 high: shoot over it, can't step over it), open where the stairs come up
    if (o.parapet !== false) {
        const pt = { type: 'pillar', solid: false, name: 'Parapet', floorHeight: floor + 32, ceilingHeight: sky, ceilingTexture: 'F_SKY1', floorTexture: o.parapetTop || 'CWCONCF', wallTexture: o.side || 'CWCONCW' };
        const seg = (rect) => { if (rect.w > 0 && rect.h > 0) b.top({ ...pt }, rect); };
        const gapLo = side === 'S' || side === 'N' ? stairs.x - 8 : stairs.y - 8;
        const gapHi = side === 'S' || side === 'N' ? stairs.x + stairs.w + 8 : stairs.y + stairs.h + 8;
        for (const s of ['S', 'N', 'W', 'E']) {
            if (s === 'S' || s === 'N') {
                const y = s === 'S' ? D.y : D.y + D.h - 8;
                if (s === side) { seg(R(D.x, y, gapLo - D.x, 8)); seg(R(gapHi, y, D.x + D.w - gapHi, 8)); }
                else seg(R(D.x, y, D.w, 8));
            } else {
                const x = s === 'W' ? D.x : D.x + D.w - 8;
                if (s === side) { seg(R(x, D.y + 8, 8, gapLo - D.y - 8)); seg(R(x, gapHi, 8, D.y + D.h - 8 - gapHi)); }
                else seg(R(x, D.y + 8, 8, D.h - 16));
            }
        }
    }
    const area = inset(D, 16);
    b.decks.push({ rect: D, floor, area, stairSide: side });
    for (const type of o.props || []) b.propIn(area, type);
    const n = Math.max(1, Math.min(3, Math.round(D.w * D.h / 120000)));
    for (let i = 0; i < n; i++) b.spot(area, floor);
    return room;
}

// a fence line: a see-through, blocking 8-thick strip (CWFENCE mid texture), with gaps where you get through
function fence(b, F, o) {
    b.opening({ type: 'window', name: 'Fence', floorHeight: o.floor || 0, ceilingHeight: o.top, ceilingTexture: o.ceilingTexture || 'F_SKY1', midTexture: 'CWFENCE', blocking: true, wallTexture: 'CWFENCE', upperTexture: 'ADMETL1', lowerTexture: 'ADMETL1' }, F);
}
function fencedYard(b, Y, o) {
    const gapSide = o.gapSide || b.pick(['S', 'N', 'W', 'E']);
    const gw = 96;
    for (const s of ['S', 'N', 'W', 'E']) {
        const horizontalSide = s === 'S' || s === 'N';
        const fixed = s === 'S' ? Y.y : s === 'N' ? Y.y + Y.h - 8 : s === 'W' ? Y.x : Y.x + Y.w - 8;
        const lo = horizontalSide ? Y.x : Y.y + 8, hi = horizontalSide ? Y.x + Y.w : Y.y + Y.h - 8;
        const parts = [];
        if (s === gapSide) {
            const g = snap((lo + hi) / 2 - gw / 2);
            parts.push([lo, g], [g + gw, hi]);
            const clear = horizontalSide ? R(g, fixed - 48, gw, 104) : R(fixed - 48, g, 104, gw);
            b.keepClear.push(clear);
        } else parts.push([lo, hi]);
        for (const [a, c] of parts) {
            if (c - a < 16) continue;
            fence(b, horizontalSide ? R(a, fixed, c - a, 8) : R(fixed, a, 8, c - a), o);
        }
    }
}

// a solid block with a facade: the city around and between
function mass(b, M, textures) {
    const tex = b.pick(textures);
    b.wall(M, tex, 'Building');
    return tex;
}

// ------------------------------------------------------------------ environments
const FACADE_LIT = ['CWUQB', 'CWUQC', 'CWUQF', 'CWUEE', 'CWUDC'];
const FACADE_BRICK = ['ADBRICK', 'AXW84', 'AXW85'];
const FACADE_CONCRETE = ['CWCONCW', 'AXW43A', 'AXW24', 'ADCONC1'];

// leaf kinds -> material theme ids (the editor profile's)
const TENEMENT_THEMES = {
    themes: {
        nbc_tenement: { wall: 'ADBRICK', door: 'CWDOOR1' },
        nbc_flat: { wall: 'CWWALL1', door: 'CWDOOR2' },
        nbc_stairwell: { wall: 'CWCONCW', door: 'CWFIRED' },
        nbc_lobby: { wall: 'ADMARBG', door: 'CWDOORS' },
        nbc_basement: { wall: 'AXW12', door: 'AXW86' },
        nbc_industrial: { wall: 'AXW86', door: 'AXW28' },
        nbc_precinct: { wall: 'ADGREYW', door: 'CWDOORS' },
        nbc_subway: { wall: 'CWTILEW', door: 'CWDOORS' },
        nbc_sewer: { wall: 'CWWALLD', door: 'AXW86' },
        nbc_den: { wall: 'CWWALL2', door: 'CWDOOR1', overrides: { floorTexture: 'CWCARP2' } },
        nbc_shop: { wall: 'AXCITY08', door: 'CWDOORS', overrides: { floorTexture: 'CWTILEF' } },
        nbc_penthouse: { wall: 'ADMARBG', door: 'CWDOORWL', overrides: { floorTexture: 'CWCARP2' } }
    }
};
// the editor has no nbc_den / nbc_shop / nbc_penthouse themes: they use a close one plus texture overrides
const THEME_OF = { nbc_den: 'nbc_flat', nbc_shop: 'nbc_precinct', nbc_penthouse: 'nbc_lobby' };
function editorTheme(id) { return THEME_OF[id] || id; }

const LABELS = { flat: 'Flat', corridor: 'Corridor', lobby: 'Lobby', shop: 'Corner store', office: 'Office', den: 'Den', warehouse: 'Warehouse',
    boiler: 'Boiler room', laundry: 'Laundry', station: 'Station hall', stairhut: 'Stair hut', penthouse: 'Penthouse', barracks: 'Bunk room', armory: 'Armory' };
const LIGHT = { flat: 152, corridor: 136, lobby: 176, shop: 176, office: 168, den: 128, warehouse: 144, boiler: 112, laundry: 160, station: 160, stairhut: 128, penthouse: 184, barracks: 136, armory: 152 };

function buildingOptions(b, kind, P) {
    const base = { themes: TENEMENT_THEMES.themes, label: k => LABELS[k] || 'Room', light: k => LIGHT[k] || 152, floor: P.blockFloor, outsideFloor: P.blockFloor, trim: 'CWCONCW',
        facadeTop: P.indoor ? 0 : P.ground.ceil };
    switch (kind) {
        case 'tenement': return { ...base, layout: 'corridor', facade: b.pick(FACADE_BRICK), corridorTheme: 'nbc_tenement', flatKinds: ['flat', 'flat', 'flat', 'den', 'laundry'],
            flatTheme: k => (k === 'den' ? 'nbc_den' : k === 'laundry' ? 'nbc_stairwell' : 'nbc_flat'), flatMin: 192, flatMax: 320, doorChance: 0.6, entranceSides: ['W', 'E', 'S', 'N'] };
        case 'tower': return { ...base, layout: 'corridor', facade: b.pick(FACADE_CONCRETE), corridorTheme: 'nbc_stairwell', flatKinds: ['flat', 'flat', 'lobby', 'den', 'laundry'],
            flatTheme: k => (k === 'lobby' ? 'nbc_lobby' : k === 'den' ? 'nbc_den' : k === 'laundry' ? 'nbc_stairwell' : 'nbc_flat'), flatMin: 224, flatMax: 352, doorChance: 0.5, entranceSides: ['W', 'E', 'S', 'N'] };
        case 'shops': return { ...base, layout: 'bsp', facade: b.pick(FACADE_BRICK), roomKinds: ['shop', 'shop', 'office', 'den'], themeFor: k => (k === 'shop' ? 'nbc_shop' : k === 'den' ? 'nbc_den' : 'nbc_precinct'),
            doorChance: 0.4, entranceSides: ['S', 'N', 'W', 'E'], minRoom: 208, maxRoom: 416 };
        case 'warehouse': return { ...base, layout: 'hall', facade: b.pick(['AXW86', 'AXW86', 'CWRETAIN']), hallKind: 'warehouse', hallTheme: 'nbc_industrial', officeKind: 'office', officeTheme: 'nbc_precinct',
            hallCeil: 160, hallColumns: true, columnTexture: 'AXW44', frontDoor: 'AXW28', entranceSides: ['S', 'N', 'W', 'E'], spotArea: 60000 };
        case 'boiler': return { ...base, layout: 'bsp', facade: 'AXW23', roomKinds: ['boiler', 'boiler', 'warehouse', 'laundry'], themeFor: k => (k === 'laundry' ? 'nbc_stairwell' : k === 'warehouse' ? 'nbc_industrial' : 'nbc_basement'),
            doorChance: 0.3, entranceSides: ['S', 'N', 'W', 'E'], minRoom: 192, maxRoom: 384, windows: false, roomCeil: 104 };
        case 'station': return { ...base, layout: 'hall', facade: 'CWTILEW', hallKind: 'station', hallTheme: 'nbc_subway', officeKind: 'office', officeTheme: 'nbc_precinct', hallCeil: 136, hallColumns: true,
            columnTexture: 'CWTILEW', entranceSides: ['S', 'N', 'W', 'E'], windows: false };
        case 'hut': return { ...base, layout: 'bsp', facade: 'CWCONCW', roomKinds: ['stairhut', 'stairhut', 'den'], themeFor: k => (k === 'den' ? 'nbc_den' : 'nbc_stairwell'), doorChance: 0.3,
            entranceSides: ['S', 'N', 'W', 'E'], minRoom: 160, maxRoom: 320, maxEntrances: 1 };
        case 'pavilion': return { ...base, layout: 'hall', facade: 'AXW85', hallKind: 'den', hallTheme: 'nbc_den', officeKind: 'laundry', officeTheme: 'nbc_stairwell', hallCeil: 112, entranceSides: ['S', 'N', 'W', 'E'] };
        case 'stronghold': return { ...base, layout: P.strongLayout || 'bsp', facade: P.strongFacade || b.pick(FACADE_BRICK), roomKinds: ['den', 'barracks', 'armory', 'office', 'den'], themeFor: k => (k === 'den' ? 'nbc_den' : k === 'office' ? 'nbc_precinct' : 'nbc_stairwell'),
            corridorTheme: 'nbc_tenement', flatKinds: ['den', 'barracks', 'armory', 'flat'], flatTheme: k => (k === 'flat' ? 'nbc_flat' : k === 'den' ? 'nbc_den' : 'nbc_stairwell'), flatMin: 224, flatMax: 352,
            doorChance: 0.5, entranceSides: ['S', 'W', 'E'], minRoom: 224, maxRoom: 448 };
        case 'penthouse': return { ...base, layout: 'corridor', facade: 'CWUQF', corridorTheme: 'nbc_lobby', flatKinds: ['penthouse', 'penthouse', 'barracks', 'armory', 'office'],
            flatTheme: k => (k === 'penthouse' ? 'nbc_penthouse' : k === 'office' ? 'nbc_precinct' : 'nbc_stairwell'), flatMin: 256, flatMax: 416, doorChance: 0.5, entranceSides: ['S', 'W', 'E'], roomCeil: 112 };
        default: throw new Error(`unknown building kind ${kind}`);
    }
}

// Each environment: the ground, the street grid, the mix of blocks, the backdrop
const ENV = {
    streets: {
        width: 3072, height: 3584, cols: 3, rows: 4, street: 288, edge: 96, sidewalk: 48,
        ground: { name: 'Street', theme: 'nbc_street', ceil: 384, light: 168, lowerTexture: 'AXSTEP23', upperTexture: 'AXW85', wallTexture: 'AXW85' },
        sidewalkRoom: { theme: 'nbc_yard', floor: 8, lowerTexture: 'AXW85', ceilingTexture: 'F_SKY1' },
        blockFloor: 8, edgeFacades: [...FACADE_LIT, ...FACADE_BRICK],
        mix: [['tenement', 5], ['shops', 4], ['yard', 1], ['deck', 2], ['mass', 1], ['parking', 1]],
        cars: 0.8, lamps: true, strongLayout: 'bsp'
    },
    towers: {
        width: 3328, height: 3584, cols: 2, rows: 3, street: 384, edge: 96, sidewalk: 64,
        ground: { name: 'Estate plaza', theme: 'nbc_yard', ceil: 448, light: 168, lowerTexture: 'CWCONCW', upperTexture: 'CWCONCW', wallTexture: 'CWCONCW' },
        sidewalkRoom: { theme: 'nbc_yard', floor: 8, lowerTexture: 'AXW43A', ceilingTexture: 'F_SKY1', floorTexture: 'AXF39' },
        blockFloor: 8, edgeFacades: FACADE_LIT,
        mix: [['tower', 5], ['deck', 2], ['yard', 1], ['mass', 1]],
        cars: 0.3, lamps: true, strongLayout: 'corridor', strongFacade: 'AXW43A'
    },
    rooftops: {
        width: 3072, height: 3328, cols: 3, rows: 4, street: 256, edge: 128, sidewalk: 0,
        ground: { name: 'Roofs', theme: 'nbc_rooftop', ceil: 384, light: 184, lowerTexture: 'ADBRICK', upperTexture: 'CWCONCW', wallTexture: 'CWCONCW' },
        alley: { floor: -224, theme: 'nbc_street', lowerTexture: 'ADBRICK', wallTexture: 'ADBRICK', light: 120 },
        blockFloor: 0, edgeFacades: FACADE_LIT,
        mix: [['hut', 4], ['deck', 4], ['roofplant', 3], ['mass', 1]],
        cars: 0, lamps: false, bridges: true, strongLayout: 'bsp'
    },
    industrial: {
        width: 3328, height: 3584, cols: 3, rows: 3, street: 256, edge: 96, sidewalk: 0,
        ground: { name: 'Yard', theme: 'nbc_yard', ceil: 384, light: 160, floorTexture: 'AXF02', lowerTexture: 'AXW86', upperTexture: 'AXW86', wallTexture: 'AXW86' },
        blockFloor: 0, edgeFacades: ['AXW86', 'CWRETAIN', 'AXW28', 'AXW44'],
        mix: [['warehouse', 5], ['containers', 3], ['deck', 1], ['mass', 1], ['yard', 1]],
        cars: 0.3, lamps: true, strongLayout: 'hall'
    },
    parks: {
        width: 3072, height: 3328, cols: 3, rows: 3, street: 160, edge: 128, sidewalk: 0,
        ground: { name: 'Park', theme: 'nbc_yard', ceil: 384, light: 168, floorTexture: 'GRASS1', lowerTexture: 'CWCONCW', upperTexture: 'ADBRICK', wallTexture: 'ADBRICK' },
        path: { theme: 'nbc_yard', floorTexture: 'CWPAVE' },
        blockFloor: 0, edgeFacades: [...FACADE_BRICK, ...FACADE_LIT],
        mix: [['plot', 4], ['court', 2], ['pavilion', 2], ['deck', 2], ['pond', 1]],
        cars: 0, lamps: true, strongLayout: 'bsp'
    },
    underground: {
        width: 2816, height: 3328, cols: 3, rows: 4, street: 192, edge: 96, sidewalk: 0, indoor: true,
        ground: { name: 'Storm drain', theme: 'nbc_sewer', ceil: 128, light: 104, ceilingTexture: 'CWCONCF', lowerTexture: 'CWSEAWAL', upperTexture: 'CWWALLD', wallTexture: 'CWWALLD' },
        blockFloor: 0, edgeFacades: ['CWWALLD', 'CWSEAWAL', 'AXW23'],
        mix: [['boiler', 5], ['mass', 3], ['cistern', 2], ['warehouse', 1]],
        cars: 0, lamps: false, channels: true, strongLayout: 'bsp', strongFacade: 'AXW23'
    },
    subway: {
        width: 2816, height: 3584, cols: 2, rows: 4, street: 256, edge: 96, sidewalk: 48, indoor: true,
        ground: { name: 'Track tunnel', theme: 'nbc_subway', ceil: 160, light: 112, floorTexture: 'AXF06B', ceilingTexture: 'AXF16', lowerTexture: 'CWTILEW', upperTexture: 'AXW23', wallTexture: 'AXW23' },
        sidewalkRoom: { theme: 'nbc_subway', floor: 24, lowerTexture: 'CWTILEW' },
        blockFloor: 24, edgeFacades: ['AXW23', 'CWTILEW', 'CWWALLD'],
        mix: [['station', 4], ['boiler', 2], ['mass', 2], ['shops', 1]],
        cars: 0, lamps: false, strongLayout: 'bsp', strongFacade: 'CWTILEW'
    },
    crown: {
        width: 3328, height: 3840, cols: 2, rows: 3, street: 384, edge: 96, sidewalk: 96,
        ground: { name: 'The plaza', theme: 'nbc_yard', ceil: 512, light: 176, floorTexture: 'ADFMARB', lowerTexture: 'AXW43A', upperTexture: 'CWCONCW', wallTexture: 'CWCONCW' },
        sidewalkRoom: { theme: 'nbc_yard', floor: 8, lowerTexture: 'AXW43A', ceilingTexture: 'F_SKY1', floorTexture: 'AXF39' },
        blockFloor: 8, edgeFacades: FACADE_LIT,
        mix: [['tower', 3], ['deck', 2], ['yard', 1]],
        cars: 0.4, lamps: true, strongLayout: 'corridor', strongKind: 'penthouse', strongSpan: 2, defenses: true
    }
};

// ------------------------------------------------------------------ a district
function generateDistrict({ env, seed, name, mapLump, skybox = 'nbc_dusk' }) {
    const P = ENV[env];
    if (!P) throw new Error(`unknown environment ${env}`);
    const b = new Builder(seed);
    const W = P.width, H = P.height;
    const G = P.ground;
    const sky = G.ceil;
    const outdoorCeil = P.indoor ? 'F_SKY1' : 'F_SKY1';
    b.room(R(0, 0, W, H), { prefix: 'ground', name: G.name, theme: G.theme, floor: 0, ceil: G.ceil, light: G.light,
        ceilingTexture: P.indoor ? G.ceilingTexture : outdoorCeil, floorTexture: G.floorTexture, lowerTexture: G.lowerTexture, upperTexture: G.upperTexture, wallTexture: G.wallTexture });

    // the edge of the map: a ring of buildings (the city round the district)
    const E = P.edge;
    let u = 0;
    const skyTop = P.indoor ? 0 : G.ceil;
    const ring = (rect, side) => facadeDecor(b, rect, mass(b, rect, P.edgeFacades), skyTop, [side]);
    while (u < W) { const w = Math.min(W - u, snap(b.int(192, 512))); ring(R(u, 0, w, E), 'N'); ring(R(u, H - E, w, E), 'S'); u += w; }
    u = E;
    while (u < H - E) { const h = Math.min(H - E - u, snap(b.int(192, 512))); ring(R(0, u, E, h), 'E'); ring(R(W - E, u, E, h), 'W'); u += h; }

    // the block grid
    const margin = E + P.street;
    const innerW = W - 2 * margin, innerH = H - 2 * margin;
    // uneven columns and rows, so the grid doesn't read as a grid
    const split = (total, n) => {
        const weights = Array.from({ length: n }, () => 0.7 + b.r() * 0.7);
        const sum = weights.reduce((p, q) => p + q, 0);
        const sizes = weights.map(w => snap(total * w / sum));
        sizes[n - 1] = total - sizes.slice(0, n - 1).reduce((p, q) => p + q, 0);
        return sizes;
    };
    const colW = split(innerW - (P.cols - 1) * P.street, P.cols), rowH = split(innerH - (P.rows - 1) * P.street, P.rows);
    const colX = colW.map((_, i) => margin + colW.slice(0, i).reduce((p, q) => p + q, 0) + i * P.street);
    const rowY = rowH.map((_, i) => margin + rowH.slice(0, i).reduce((p, q) => p + q, 0) + i * P.street);
    colX.push(W - margin + P.street); rowY.push(H - margin + P.street);   // where the street past the last block would start
    const bw = snap((innerW - (P.cols - 1) * P.street) / P.cols), bh = snap((innerH - (P.rows - 1) * P.street) / P.rows);
    const blocks = [];
    for (let row = 0; row < P.rows; row++) for (let col = 0; col < P.cols; col++)
        blocks.push({ row, col, rect: R(colX[col], rowY[row], colW[col], rowH[row]) });
    // the stronghold: the far row's middle (the Crown's spans two blocks)
    const top = P.rows - 1;
    const strongCol = Math.floor((P.cols - 1) / 2);
    let strong = blocks.find(k => k.row === top && k.col === strongCol);
    if (P.strongSpan === 2 && P.cols >= 2) {
        const right = blocks.find(k => k.row === top && k.col === strongCol + 1);
        strong.rect = R(strong.rect.x, strong.rect.y, right.rect.x + right.rect.w - strong.rect.x, strong.rect.h);
        blocks.splice(blocks.indexOf(right), 1);
    }
    strong.kind = 'stronghold';
    // the rest by the mix, a block split into two lots with an alleyway between when it's wide enough; at least
    // two decks for roof starts outdoors
    const bag = [];
    for (const [kind, n] of P.mix) for (let i = 0; i < n; i++) bag.push(kind);
    const lots = [];
    for (const k of blocks) {
        if (k === strong) continue;
        const r = k.rect, gap = 80;
        if (!P.noLots && r.w >= 2 * 320 + gap && b.chance(0.6)) {
            const w1 = snap((r.w - gap) * (0.4 + b.r() * 0.2));
            lots.push({ row: k.row, col: k.col, rect: R(r.x, r.y, w1, r.h) }, { row: k.row, col: k.col, rect: R(r.x + w1 + gap, r.y, r.w - w1 - gap, r.h) });
        } else if (!P.noLots && r.h >= 2 * 288 + gap && b.chance(0.4)) {
            const h1 = snap((r.h - gap) * (0.4 + b.r() * 0.2));
            lots.push({ row: k.row, col: k.col, rect: R(r.x, r.y, r.w, h1) }, { row: k.row, col: k.col, rect: R(r.x, r.y + h1 + gap, r.w, r.h - h1 - gap) });
        } else lots.push(k);
    }
    blocks.splice(0, blocks.length, strong, ...lots);
    const others = lots;
    // deal the kinds in proportion to the mix (a shuffled deck, not independent draws), so a district can't come
    // out all yards
    const total = P.mix.reduce((p, q) => p + q[1], 0);
    const deckOfKinds = [];
    for (const [kind, n] of P.mix) for (let i = 0; i < Math.round(n / total * others.length); i++) deckOfKinds.push(kind);
    while (deckOfKinds.length < others.length) deckOfKinds.push(b.pick(bag));
    for (let i = deckOfKinds.length - 1; i > 0; i--) { const j = Math.floor(b.r() * (i + 1)); [deckOfKinds[i], deckOfKinds[j]] = [deckOfKinds[j], deckOfKinds[i]]; }
    others.forEach((k, i) => { k.kind = deckOfKinds[i]; });
    if (!P.indoor) {
        let decks = others.filter(k => k.kind === 'deck').length;
        const mid = others.filter(k => k.row > 0 && k.row < top && k.kind !== 'deck');
        while (decks < 2 && mid.length) { const k = mid.splice(Math.floor(b.r() * mid.length), 1)[0]; k.kind = 'deck'; decks++; }
    }
    // the start row: no masses straight ahead of the start
    for (const k of others) if (k.row === 0 && k.kind === 'mass') k.kind = P.indoor ? 'boiler' : 'yard';

    // rooftops: the alleys between the blocks drop to the street below, with plank bridges across
    if (P.alley) {
        for (let col = 1; col < P.cols; col++) {
            const x = colX[col] - P.street;
            b.room(R(x + 32, margin - 64, P.street - 64, innerH + 128), { prefix: 'alley', name: 'Alley', theme: P.alley.theme, floor: P.alley.floor, ceil: sky, light: P.alley.light, ceilingTexture: 'F_SKY1', lowerTexture: P.alley.lowerTexture, wallTexture: P.alley.wallTexture });
        }
        for (let row = 1; row < P.rows; row++) {
            const y = rowY[row] - P.street;
            b.room(R(margin - 64, y + 32, innerW + 128, P.street - 64), { prefix: 'alley', name: 'Alley', theme: P.alley.theme, floor: P.alley.floor, ceil: sky, light: P.alley.light, ceilingTexture: 'F_SKY1', lowerTexture: P.alley.lowerTexture, wallTexture: P.alley.wallTexture });
        }
    }
    // parks: paths along the streets
    if (P.path) {
        for (let col = 0; col <= P.cols; col++) {
            const x = col === 0 ? E + 32 : (col === P.cols ? W - E - P.street + 32 : colX[col] - P.street + 16);
            b.room(R(x, E, P.street - 48, H - 2 * E), { prefix: 'path', name: 'Path', theme: P.path.theme, floor: 0, ceil: sky, light: G.light, ceilingTexture: 'F_SKY1', floorTexture: P.path.floorTexture, lowerTexture: G.lowerTexture });
        }
        for (let row = 0; row <= P.rows; row++) {
            const y = row === 0 ? E + 32 : (row === P.rows ? H - E - P.street + 32 : rowY[row] - P.street + 16);
            b.room(R(E, y, W - 2 * E, P.street - 48), { prefix: 'path', name: 'Path', theme: P.path.theme, floor: 0, ceil: sky, light: G.light, ceilingTexture: 'F_SKY1', floorTexture: P.path.floorTexture, lowerTexture: G.lowerTexture });
        }
    }
    // sidewalks round the blocks
    if (P.sidewalkRoom) {
        for (const k of [...others, strong]) {
            const S = P.sidewalkRoom;
            b.room(grow(k.rect, P.sidewalk), { prefix: 'walk', name: env === 'subway' ? 'Platform' : 'Sidewalk', theme: S.theme, floor: S.floor, ceil: sky, light: G.light + 8,
                ceilingTexture: P.indoor ? G.ceilingTexture : 'F_SKY1', floorTexture: S.floorTexture, lowerTexture: S.lowerTexture, wallTexture: G.wallTexture, upperTexture: G.upperTexture });
        }
    }

    // the blocks themselves
    const built = [];
    const order = [strong, ...others];
    for (const k of order) built.push(fillBlock(b, k, P, env, sky));
    const strongBuilding = built[0];

    // bridges over the alleys (after the blocks, so they sit on top)
    if (P.bridges) {
        for (let col = 1; col < P.cols; col++) {
            const x = colX[col] - P.street;
            for (let row = 0; row < P.rows; row++) {
                if (b.chance(0.35) && row !== 0) continue;
                const y = snap(rowY[row] + rowH[row] * (0.25 + b.r() * 0.5));
                b.room(R(x, y, P.street, 72), { prefix: 'bridge', name: 'Plank bridge', theme: 'nbc_rooftop', floor: 0, ceil: sky, light: 176, ceilingTexture: 'F_SKY1', floorTexture: 'ADFWOOD', lowerTexture: 'AXDW06A', wallTexture: 'AXDW06A' });
            }
        }
        for (let row = 1; row < P.rows; row++) {
            const y = rowY[row] - P.street;
            for (let col = 0; col < P.cols; col++) {
                if (b.chance(0.35) && col !== strongCol) continue;
                const x = snap(colX[col] + colW[col] * (0.25 + b.r() * 0.5));
                b.room(R(x, y, 72, P.street), { prefix: 'bridge', name: 'Plank bridge', theme: 'nbc_rooftop', floor: 0, ceil: sky, light: 176, ceilingTexture: 'F_SKY1', floorTexture: 'ADFWOOD', lowerTexture: 'AXDW06A', wallTexture: 'AXDW06A' });
            }
        }
        // stairs up out of each alley at its south end (a fall isn't a dead end)
        for (const room of b.rooms.filter(r => r.id.startsWith('alley'))) {
            const vertical = room.height > room.width;
            if (vertical) b.opening({ type: 'stairs', name: 'Alley stairs', direction: 'S', steps: 14, startFloor: P.alley.floor, endFloor: 0, ceilingHeight: sky, ceilingTexture: 'F_SKY1', floorTexture: 'CWSTAIF', wallTexture: 'ADBRICK', lowerTexture: 'AXSTEP23' }, R(room.x, room.y, 72, 336));
            else b.opening({ type: 'stairs', name: 'Alley stairs', direction: 'W', steps: 14, startFloor: P.alley.floor, endFloor: 0, ceilingHeight: sky, ceilingTexture: 'F_SKY1', floorTexture: 'CWSTAIF', wallTexture: 'ADBRICK', lowerTexture: 'AXSTEP23' }, R(room.x, room.y, 336, 72));
        }
    }

    // sewers: water channels down the middle of the north-south tunnels
    if (P.channels) {
        for (let col = 1; col < P.cols; col++) {
            const x = colX[col] - P.street;
            b.top({ type: 'pool', name: 'Water channel', hazard: 'water', floorHeight: -16, floorTexture: 'CWWATER', ceilingTexture: G.ceilingTexture, ceilingHeight: G.ceil, lightLevel: 96 }, R(x + P.street / 2 - 40, margin, 80, innerH));
        }
    }

    // the player's start: the south street, facing north; and the exit in the stronghold
    // at the south end of a street between two columns, looking up it (rooftops: on the roof plane, between blocks)
    const gap = Math.max(1, Math.floor(P.cols / 2));
    const startX = P.alley || P.cols < 2 ? snap(W / 2) : snap(colX[gap] - P.street / 2), startY = E + snap(P.street / 2);
    b.thing(T.start, startX, startY, 90);
    b.keepClear.push(R(startX - 96, startY - 96, 192, 192));
    placeExit(b, strongBuilding);

    // the roof starts: on the decks nearest the middle of the map (two at most); indoor maps get a shaft to the sky
    const decksByMiddle = [...b.decks].sort((p, q) => dist(cx(p.rect), cy(p.rect), W / 2, H / 2) - dist(cx(q.rect), cy(q.rect), W / 2, H / 2));
    for (const d of decksByMiddle.slice(0, 2)) {
        const a = inset(d.area, 24);
        b.thing(T.roofStart, cx(a), cy(a), 90);
    }
    if (!b.decks.length) {
        // an access shaft open to the sky in the start row's corner: the helicopter lowers the squad in
        const shaft = R(E + 64, E + 64, 256, 256);
        b.room(shaft, { prefix: 'shaft', name: 'Access shaft', theme: G.theme, floor: 0, ceil: sky + 256, light: 192, ceilingTexture: 'F_SKY1', floorTexture: G.floorTexture, wallTexture: G.wallTexture, upperTexture: G.upperTexture, lowerTexture: G.lowerTexture });
        b.thing(T.roofStart, cx(shaft), cy(shaft), 45);
    }

    // the streets: cars, lamps, rubble, barrels, and spots out in the open
    const streets = [];
    for (let col = 0; col <= P.cols; col++) {
        const x = col === 0 ? E : colX[col] - P.street;
        streets.push({ rect: R(x, margin - P.street, P.street, innerH + 2 * P.street), vertical: true });
    }
    for (let row = 0; row <= P.rows; row++) {
        const y = row === 0 ? E : rowY[row] - P.street;
        streets.push({ rect: R(margin - P.street, y, innerW + 2 * P.street, P.street), vertical: false });
    }
    for (const s of streets) {
        const lane = P.alley ? null : inset(s.rect, 24);
        if (!lane) continue;
        if (P.cars && !P.indoor) {
            const n = Math.round((s.vertical ? s.rect.h : s.rect.w) / 512 * P.cars);
            for (let i = 0; i < n; i++) b.propIn(lane, b.pick(CARS), s.vertical ? b.pick([90, 270]) : b.pick([0, 180]));
        }
        if (b.chance(0.5)) b.propIn(lane, b.pick([T.dumpster, T.barrier, T.crates, T.trashBag]));
        if (!P.indoor) for (let i = b.int(2, 4); i > 0; i--) b.propIn(lane, b.pick([T.trashBag, T.bin, T.cone, T.trashBag, T.planter]));
        if (P.lamps && !P.indoor) {
            for (let t = 384; t < (s.vertical ? s.rect.h : s.rect.w) - 256; t += 640) {
                const x = s.vertical ? s.rect.x + 12 : s.rect.x + t, y = s.vertical ? s.rect.y + t : s.rect.y + 12;
                const rect = R(x - 8, y - 8, 16, 16);
                if (b.free(rect, 8)) { b.thing(T.lampPost, x, y, 0); b.thing(T.streetLight, x, y, 0); b.solid.push(rect); }
            }
        }
        const nSpots = Math.round((s.vertical ? s.rect.h : s.rect.w) / 700);
        for (let i = 0; i < nSpots; i++) b.spot(lane, 0);
    }
    if (P.alley) {
        // the roof plane's outer ring and the alleys below: lookouts up top, a few down in the alleys
        for (const s of streets) {
            const n = Math.round((s.vertical ? s.rect.h : s.rect.w) / 500);
            for (let i = 0; i < n; i++) b.spot(inset(s.rect, 40), 0);
        }
        for (const k of others.filter(k => k.kind === 'hut' || k.kind === 'roofplant' || k.kind === 'mass')) {
            const ring = [R(k.rect.x, k.rect.y, k.rect.w, 64), R(k.rect.x, k.rect.y + k.rect.h - 64, k.rect.w, 64)];
            for (const r of ring) if (k.kind !== 'mass' || b.chance(0.5)) b.spot(r, 0);
        }
    }
    for (let i = 0; i < 3; i++) b.propIn(inset(b.pick(streets).rect, 32), T.rubble);
    for (let i = 0; i < 2; i++) b.propIn(inset(b.pick(streets).rect, 32), T.barrel);
    // the Crown's private army dug in on the plaza: sandbags and barriers before the tower
    if (P.defenses) {
        const front = R(strongBuilding.rect.x, strongBuilding.rect.y - P.street - P.sidewalk, strongBuilding.rect.w, P.street);
        for (let i = 0; i < 8; i++) b.propIn(front, b.pick([T.sandbags, T.barrier, T.sandbags]), 0);
        for (let i = 0; i < 4; i++) b.spot(front, 0);
    }

    const project = b.project(name, mapLump, skybox);
    for (const room of project.rooms) room.theme = editorTheme(room.theme);
    for (const obj of project.smartObjects) if (obj.theme) obj.theme = editorTheme(obj.theme);
    const kinds = {};
    for (const k of [strong, ...others]) kinds[k.kind] = (kinds[k.kind] || 0) + 1;
    return { project, stats: { spots: b.spots.length, decks: b.decks.length, rooms: project.rooms.length, objects: project.smartObjects.length, things: project.things.length, kinds } };
}

function fillBlock(b, k, P, env, sky) {
    const B = k.rect;
    const floor = P.blockFloor;
    switch (k.kind) {
        case 'stronghold': {
            const kind = P.strongKind || 'stronghold';
            const o = buildingOptions(b, kind, P);
            o.layout = P.strongLayout || o.layout;
            if (o.layout === 'hall') { o.hallKind = 'warehouse'; o.hallTheme = 'nbc_industrial'; o.officeKind = 'armory'; o.officeTheme = 'nbc_stairwell'; o.hallCeil = 160; o.hallColumns = true; }
            o.entranceSides = ['S', 'W', 'E'];
            const built = building(b, B, o);
            built.stronghold = true;
            return built;
        }
        case 'tenement': case 'tower': case 'shops': case 'warehouse': case 'boiler': case 'station': case 'hut': case 'pavilion': {
            const o = buildingOptions(b, k.kind, P);
            const shrink = k.kind === 'hut' || k.kind === 'pavilion' ? Math.min(B.w, B.h) * 0.25 : 0;
            return building(b, shrink ? inset(B, snap(shrink)) : B, o);
        }
        case 'mass': {
            mass(b, B, P.edgeFacades);
            return null;
        }
        case 'deck': {
            const height = env === 'rooftops' ? b.pick([64, 128]) : b.pick([128, 160, 192]);
            const D = env === 'rooftops' ? B : inset(B, snap(Math.min(B.w, B.h) * 0.1));
            deck(b, D, { floor: floor + height, base: floor, sky, theme: 'nbc_rooftop', side: env === 'towers' || env === 'crown' ? 'AXW43A' : 'ADBRICK',
                props: [T.acUnit, b.pick([T.waterTower, T.acUnit, T.tank]), T.crates] });
            return null;
        }
        case 'roofplant': {
            // a roof with machinery and a low hut: cover and perches at roof level
            const area = inset(B, 32);
            for (const type of [T.waterTower, T.acUnit, T.acUnit, T.tank, T.generator, T.crates, T.scaffold]) b.propIn(area, type);
            for (let i = 0; i < 2; i++) b.spot(area, floor);
            return null;
        }
        case 'yard': case 'parking': case 'containers': case 'court': {
            const theme = 'nbc_yard';
            const Y = B;
            b.room(Y, { prefix: 'yard', name: k.kind === 'court' ? 'Court' : 'Yard', theme, floor, ceil: sky, light: 168, ceilingTexture: P.indoor ? undefined : 'F_SKY1',
                floorTexture: k.kind === 'court' ? 'CWASPH' : (k.kind === 'containers' ? 'AXF02' : 'CWPAVE'), lowerTexture: 'CWCONCW' });
            fencedYard(b, Y, { floor, top: sky, gapSide: 'S' });
            const area = inset(Y, 24);
            if (k.kind === 'parking') for (let i = 0; i < 6; i++) b.propIn(area, b.pick(CARS), b.pick([90, 270]));
            else if (k.kind === 'containers') for (let i = 0; i < 6; i++) b.propIn(area, T.container, b.pick([0, 90]));
            else if (k.kind === 'court') { b.propIn(area, T.pew, 0); b.propIn(area, T.bin); }
            else for (const type of [T.dumpster, T.crates, T.pallet, T.drums, T.dumpster, T.trashBag, T.barrel]) b.propIn(area, type);
            const n = Math.max(1, Math.round(Y.w * Y.h / 140000));
            for (let i = 0; i < n; i++) b.spot(area, floor);
            return null;
        }
        case 'plot': {
            const area = inset(B, 32);
            for (const type of [T.planter, T.planter, T.pew, T.pew, T.lampPost, T.bin, T.planter]) lit(b, b.propIn(area, type), type);
            if (b.chance(0.6)) {
                // a fountain: a statue in a pool of water
                const f = R(cx(B) - 96, cy(B) - 96, 192, 192);
                if (b.free(f, 16)) {
                    b.top({ type: 'pool', name: 'Fountain', hazard: 'water', floorHeight: -16, floorTexture: 'CWWATER', ceilingTexture: 'F_SKY1', ceilingHeight: sky, lightLevel: 176 }, f);
                    b.wall(R(cx(B) - 16, cy(B) - 16, 32, 32), 'ADMARBG', 'Statue');
                    b.solid.push(f);
                }
            }
            for (let i = 0; i < 2; i++) b.spot(area, floor);
            return null;
        }
        case 'pond': {
            const f = inset(B, snap(Math.min(B.w, B.h) * 0.2));
            b.top({ type: 'pool', name: 'Pond', hazard: 'water', floorHeight: -16, floorTexture: 'CWWATER', ceilingTexture: 'F_SKY1', ceilingHeight: sky, lightLevel: 168 }, f);
            b.solid.push(f);
            const area = inset(B, 16);
            for (const type of [T.pew, T.planter, T.lampPost]) lit(b, b.propIn(area, type), type);
            b.spot(area, floor);
            return null;
        }
        case 'cistern': {
            // a flooded chamber: a hall of water with a walkway round it
            const o = buildingOptions(b, 'boiler', P);
            o.layout = 'hall'; o.hallKind = 'boiler'; o.hallTheme = 'nbc_sewer'; o.officeKind = 'boiler'; o.officeTheme = 'nbc_basement'; o.hallCeil = 160;
            const built = building(b, B, o);
            const hall = built.leaves[0];
            if (hall && hall.area.w > 256 && hall.area.h > 256) b.top({ type: 'pool', name: 'Cistern', hazard: 'water', floorHeight: -24, floorTexture: 'CWWATER', ceilingTexture: 'CWCONCF', ceilingHeight: hall.ceil, lightLevel: 96 }, inset(hall.area, 72));
            return built;
        }
        default: return null;
    }
}

// the exit: a breaker box under a lit EXIT sign, set into the far wall of the stronghold's deepest room
function placeExit(b, built) {
    const leaves = [...built.leaves].sort((p, q) => (q.rect.y + q.rect.h) - (p.rect.y + p.rect.h) || q.rect.w * q.rect.h - p.rect.w * p.rect.h);
    for (const leaf of leaves) {
        const r = leaf.rect;
        const xs = [];
        for (let x = r.x + 32; x + 64 <= r.x + r.w - 32; x += 16) xs.push(x);
        for (let i = xs.length - 1; i > 0; i--) { const j = Math.floor(b.r() * (i + 1)); [xs[i], xs[j]] = [xs[j], xs[i]]; }
        for (const x of xs) {
            const niche = R(x, r.y + r.h - 8, 64, 8);
            if (b.keepClear.some(k => overlaps(k, niche, 16))) continue;
            // a window in the way gives up its place
            for (const w of b.windows.filter(w => overlaps(w.rect, niche, 16))) b.openings.splice(b.openings.indexOf(w.obj), 1);
            b.windows = b.windows.filter(w => !overlaps(w.rect, niche, 16));
            b.opening({ type: 'exit', name: 'Exit', floorHeight: leaf.ceil, ceilingHeight: leaf.ceil, lowerTexture: 'NBCSWEX1', upperTexture: 'NBCSWEX1', wallTexture: 'CWCONCW', lightLevel: 192 }, niche);
            b.keepClear.push(R(x - 16, r.y + r.h - 112, 96, 104));
            built.exit = { x: x + 32, y: r.y + r.h - 8 };
            return;
        }
    }
    throw new Error('no wall for the exit');
}

module.exports = { generateDistrict, ENV, T };
