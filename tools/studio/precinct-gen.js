'use strict';
// Checkpoint 9 (NBC_HUB) as an iDoom Studio project (PLAN.md §2.6, M2e step 5): the precinct post built into the
// Wall, with every precinct room in it. build_maps.js sends it to the editor through its MCP, like the districts.
//
// The map, south to north:
//   the street      asphalt along the city's edge (a ring of lit towers round the map, the 3D skyline beyond)
//   the precinct    a brick building on a raised sidewalk, its back against the Wall. Inside, a corridor runs
//                   west to east between two rows of rooms:
//                     south (open)    the Armory cage, the Bullpen (raid board, the captain, the desks; the front
//                                     door from the street; you start here), the Squad Room, the Motor Pool (shut)
//                     north (shut)    Captain's Office, Radio Room, Infirmary, Range, Crime Lab, Holding Cells
//                                     (flooded), Roof Access
//                   The shut rooms are dark behind boarded doorways, with their furniture under the dust: M8's Merit
//                   reopens them (each has an NBC_RoomMarker with its room number in arg0).
//   the yards       west: the helipad (the pilot waits by the corridor's back door); east: the car park, where the
//                   motor pool's vehicles stand (NBC_HubBay); north: the Wall, with the checkpoint's gate.
// The officers fit for duty stand at the NBC_HQSpot things; the raid board, the Evidence Locker and the squad room
// are Use targets in front of their furniture (nbc/zscript/nbc/hub.zs, hq.zs).

const { Builder, T, R, inset, cx, cy, snap, overlaps, facadeDecor, mass, editorTheme, doorFit, CARS, FACADE_LIT } = require('./district-gen');

const P = {
    raidBoard: 26010, armoryLocker: 26011, squadRoom: 26012, captain: 26013, pilot: 26014, hqSpot: 26015, hubBay: 26031,
    deskExec: 26202, chairExec: 26204, chair: 26203, confTable: 26209, serverRack: 26214, copier: 26217, cooler: 26218,
    labBench: 26220, partition: 26227, whiteboard: 26228, wallTV: 26229, pew: 26241,
    clock: 26407, certificate: 26409, bulletin: 26411, noSmoking: 26412, extinguisher: 26413, corkboard: 26446, painting: 26453
};
const ROOM = { squad: 0, armory: 1, captain: 2, motor: 3, radio: 4, infirmary: 5, range: 6, lab: 7, cells: 8, roof: 9 };

const W = 3072, H = 2048;
const SKY = 384;                    // the yard's sky
const FLOOR = 8;                    // the building and the sidewalk round it
const WALL_Y = 1664;                // the Wall's face
const B = R(832, 512, 1536, WALL_Y - 512);
const I = inset(B, 8);
const CORR = R(I.x, I.y + 528, I.w, 112);
const FACADE = 'ADBRICK';
const IN = { wall: 'ADGREYW', trim: 'ADMETL1', floor: 'ADFDARK', ceil: 'CWTILEF', door: 'CWDOORS' };
const SHUT_LIGHT = 96;

function generatePrecinct({ seed = 9, name = 'Checkpoint 9', mapLump = 'NBC_HUB', skybox = 'nbc_dusk' } = {}) {
    const b = new Builder(seed);

    // ---------------------------------------------------------------- outside
    b.room(R(0, 0, W, H), { prefix: 'ground', name: 'Precinct yard', theme: 'nbc_yard', floor: 0, ceil: SKY, light: 168,
        ceilingTexture: 'F_SKY1', floorTexture: 'CWPAVE', lowerTexture: 'CWCONCW', upperTexture: 'ADBRICK', wallTexture: 'ADBRICK' });
    const E = 96;
    // the city round the post: lit towers and brick on three sides
    const ring = (rect, side) => facadeDecor(b, rect, mass(b, rect, [...FACADE_LIT, 'ADBRICK', 'AXW85']), SKY, [side]);
    let u = 0;
    while (u < W) { const w = Math.min(W - u, snap(b.int(256, 512))); ring(R(u, 0, w, E), 'N'); u += w; }
    u = E;
    while (u < WALL_Y) { const h = Math.min(WALL_Y - u, snap(b.int(256, 512))); ring(R(0, u, E, h), 'E'); ring(R(W - E, u, E, h), 'W'); u += h; }
    // the Wall: poured concrete in slabs, buttresses out in the yards, and the checkpoint's gate (shut)
    const GATE = R(2560, WALL_Y, 256, 48);
    u = 0;
    const slabs = ['CWCONCW', 'AXW43A', 'ADCONC1'];
    while (u < W) {
        let w = Math.min(W - u, snap(b.int(320, 576)));
        if (u < GATE.x && u + w > GATE.x) w = GATE.x - u;
        if (u === GATE.x) w = GATE.w;
        const slab = R(u, WALL_Y, w, H - WALL_Y);
        if (u === GATE.x) b.wall(R(u, WALL_Y + GATE.h, w, H - WALL_Y - GATE.h), 'AXW28', 'Gate');
        else b.wall(slab, slabs[Math.floor(u / 320) % slabs.length], 'The Wall');
        u += w;
    }
    b.opening({ type: 'window', name: 'Gate arch', floorHeight: 0, ceilingHeight: 192, floorTexture: 'CWASPH', ceilingTexture: 'CWCONCF',
        wallTexture: 'CWCONCW', upperTexture: 'CWCONCW', lowerTexture: 'CWCONCW', blocking: false }, GATE);
    for (const x of [E + 160, E + 512, 2496, 2880]) b.wall(R(x, WALL_Y - 32, 48, 32), 'CWCONCW', 'Buttress');
    // the street and the sidewalk round the building
    b.room(R(E, E, W - 2 * E, 320), { prefix: 'street', name: 'Street', theme: 'nbc_street', floor: 0, ceil: SKY, light: 160, ceilingTexture: 'F_SKY1', floorTexture: 'CWASPH', lowerTexture: 'CWCONCW' });
    b.room(R(B.x - 64, B.y - 96, B.w + 128, B.h + 96), { prefix: 'walk', name: 'Sidewalk', theme: 'nbc_yard', floor: FLOOR, ceil: SKY, light: 176, ceilingTexture: 'F_SKY1', floorTexture: 'AXF39', lowerTexture: 'CWCONCW' });
    // the helipad (west) and the car park (east)
    const PAD = R(224, 736, 448, 448);
    b.room(PAD, { prefix: 'pad', name: 'Helipad', theme: 'nbc_yard', floor: FLOOR, ceil: SKY, light: 184, ceilingTexture: 'F_SKY1', floorTexture: 'CWCONCF', lowerTexture: 'ADMETL1' });
    const pc = { x: cx(PAD), y: cy(PAD) };
    for (const r of [R(pc.x - 96, pc.y - 128, 40, 256), R(pc.x + 56, pc.y - 128, 40, 256), R(pc.x - 56, pc.y - 20, 112, 40)])
        b.room(r, { prefix: 'pad', name: 'Pad marking', theme: 'nbc_yard', floor: FLOOR, ceil: SKY, light: 192, ceilingTexture: 'F_SKY1', floorTexture: 'CWTILEF', lowerTexture: 'ADMETL1' });
    b.thing(P.hubBay, pc.x, pc.y, 0, { args: [1] });
    b.solid.push(inset(PAD, -16));
    for (const [x, y] of [[PAD.x - 24, PAD.y - 24], [PAD.x + PAD.w + 24, PAD.y - 24], [PAD.x - 24, PAD.y + PAD.h + 24], [PAD.x + PAD.w + 24, PAD.y + PAD.h + 24]]) lamp(b, x, y);
    const PARK = R(2448, 448, 480, 1120);
    b.room(PARK, { prefix: 'park', name: 'Car park', theme: 'nbc_street', floor: 0, ceil: SKY, light: 160, ceilingTexture: 'F_SKY1', floorTexture: 'CWASPH', lowerTexture: 'CWCONCW' });
    for (const x of [PARK.x + 112, PARK.x + PARK.w - 112]) {
        for (let y = PARK.y + 128; y <= PARK.y + PARK.h - 128; y += 224) {
            b.thing(P.hubBay, x, y, 90, { args: [0] });
            b.solid.push(R(x - 48, y - 80, 96, 160));
        }
        // bay lines
        for (let y = PARK.y + 16; y <= PARK.y + PARK.h - 16; y += 224) b.room(R(x - 56, y, 112, 8), { prefix: 'park', name: 'Bay line', theme: 'nbc_street', floor: 0, ceil: SKY, light: 160, ceilingTexture: 'F_SKY1', floorTexture: 'CWTILEF', lowerTexture: 'CWCONCW' });
    }
    lamp(b, cx(PARK), PARK.y + 160); lamp(b, cx(PARK), PARK.y + PARK.h - 160);
    // the checkpoint: sandbags and barriers before the gate and the front door, lamps along the street
    for (const [x, y, a, t] of [[GATE.x + 40, WALL_Y - 96, 0, T.sandbags], [GATE.x + GATE.w - 40, WALL_Y - 96, 0, T.sandbags], [cx(GATE), WALL_Y - 200, 0, T.barrier]]) placed(b, t, x, y, a);
    for (let x = E + 256; x < W - E - 128; x += 512) lamp(b, x, E + 300);
    const street = R(E + 24, E + 24, W - 2 * E - 48, 200);
    for (let i = 0; i < 4; i++) b.propIn(street, b.pick(CARS), b.pick([0, 180]));
    for (const t of [T.trashBag, T.cone, T.cone, T.bin, T.barrel]) b.propIn(street, t);
    // the west yard: fuel for the bird, a generator, crates; the east: a dumpster
    for (const [t, x, y, a] of [[T.tank, 200, 1400, 0], [T.generator, 360, 1470, 90], [T.drums, 520, 1480, 0], [T.crates, 200, 560, 0], [T.palletCrates, 290, 520, 0], [T.dumpster, 2480, 1616, 270]]) placed(b, t, x, y, a);

    // ---------------------------------------------------------------- the building
    b.wall(R(B.x, B.y, B.w, 8), FACADE, 'Facade'); b.wall(R(B.x, B.y + B.h - 8, B.w, 8), FACADE, 'Facade');
    b.wall(R(B.x, B.y, 8, B.h), FACADE, 'Facade'); b.wall(R(B.x + B.w - 8, B.y, 8, B.h), FACADE, 'Facade');
    facadeDecor(b, B, FACADE, SKY, ['S', 'W', 'E']);
    const leaf = (rect, o) => {
        const ceil = FLOOR + (o.height || 112);
        const l = { rect, area: inset(rect, 8), name: o.name, open: o.open, ceil, light: o.light || (o.open ? 184 : SHUT_LIGHT), id: o.id };
        l.room = b.room(rect, { prefix: 'room', name: o.name, theme: 'nbc_precinct', floor: FLOOR, ceil, light: l.light,
            floorTexture: o.floorTexture || IN.floor, ceilingTexture: o.ceilingTexture || IN.ceil, wallTexture: IN.wall, upperTexture: IN.wall, lowerTexture: IN.wall });
        const wt = o.wallTexture || IN.wall;
        b.wall(R(rect.x, rect.y, rect.w, 8), wt); b.wall(R(rect.x, rect.y + rect.h - 8, rect.w, 8), wt);
        b.wall(R(rect.x, rect.y + 8, 8, rect.h - 16), wt); b.wall(R(rect.x + rect.w - 8, rect.y + 8, 8, rect.h - 16), wt);
        if (o.id !== undefined) b.thing(T.roomMarker, cx(l.area), cy(l.area), 0, { args: [o.id] });
        return l;
    };
    const S0 = I.y, S1 = CORR.y, N0 = CORR.y + CORR.h, N1 = I.y + I.h;
    const corridor = leaf(CORR, { name: 'Corridor', open: true, height: 104, light: 160, floorTexture: 'CWTILEF' });
    const armory = leaf(R(I.x, S0, 320, S1 - S0), { name: 'Armory cage', open: true, id: ROOM.armory, light: 176, floorTexture: 'AXF02' });
    const bullpen = leaf(R(I.x + 320, S0, 640, S1 - S0), { name: 'Bullpen', open: true, height: 144, light: 192 });
    const squad = leaf(R(I.x + 960, S0, 304, S1 - S0), { name: 'Squad Room', open: true, id: ROOM.squad, light: 176, floorTexture: 'CWCARP3' });
    const motor = leaf(R(I.x + 1264, S0, I.w - 1264, S1 - S0), { name: 'Motor Pool', id: ROOM.motor, height: 136, floorTexture: 'AXF02', ceilingTexture: 'AXF16', wallTexture: 'CWCONCW' });
    const north = [['Captain’s Office', ROOM.captain, 240, 'CWCARP2'], ['Radio Room', ROOM.radio, 192], ['Infirmary', ROOM.infirmary, 240, 'CWTILEF'],
        ['Range', ROOM.range, 272, 'AXF02'], ['Crime Lab', ROOM.lab, 208, 'CWTILEF'], ['Holding Cells', ROOM.cells, 224, 'AXF02'], ['Roof Access', ROOM.roof, 0, 'CWSTAIF']];
    const shut = [];
    let x = I.x;
    for (const [n, id, w, floorTexture] of north) {
        const width = w || I.x + I.w - x;
        shut.push(leaf(R(x, N0, width, N1 - N0), { name: n, id, floorTexture }));
        x += width;
    }
    const [captain, radio, infirmary, range, lab, cells, roof] = shut;

    // doorways: arches into the open rooms, boards over the shut ones
    const arch = (rect, top = 80) => {
        b.opening({ type: 'window', name: 'Doorway', floorHeight: FLOOR, ceilingHeight: FLOOR + top, floorTexture: IN.floor, ceilingTexture: IN.ceil,
            wallTexture: IN.wall, upperTexture: IN.wall, lowerTexture: IN.wall, blocking: false }, rect);
        b.keepClear.push(rect.w > rect.h ? R(rect.x - 8, rect.y - 56, rect.w + 16, rect.h + 112) : R(rect.x - 56, rect.y - 8, rect.w + 112, rect.h + 16));
    };
    const boarded = rect => {
        b.opening({ type: 'window', name: 'Boarded doorway', floorHeight: FLOOR, ceilingHeight: FLOOR + 72, floorTexture: IN.floor, ceilingTexture: IN.ceil,
            wallTexture: IN.wall, upperTexture: IN.wall, lowerTexture: IN.wall, midTexture: 'AXB03', blocking: true }, rect);
        b.keepClear.push(R(rect.x - 8, rect.y - 48, rect.w + 16, rect.h + 96));
    };
    arch(R(bullpen.rect.x + 520, S1 - 8, 96, 16));
    arch(R(squad.rect.x + 168, S1 - 8, 72, 16));
    arch(R(armory.rect.x + 208, S1 - 8, 64, 16));
    arch(R(bullpen.rect.x + bullpen.rect.w - 8, S0 + 120, 16, 72));            // bullpen <-> squad room
    boarded(R(motor.rect.x + 96, S1 - 8, 64, 16));
    for (const l of shut) boarded(R(snap(cx(l.rect) - 32), N0 - 8, 64, 16));
    // the cage: a chain-link wall between the armory and the bullpen, floor to ceiling, with a gate
    const cageX = armory.rect.x + armory.rect.w - 8;
    arch(R(cageX, S0 + 56, 16, 64));
    b.opening({ type: 'window', name: 'Cage', floorHeight: FLOOR, ceilingHeight: FLOOR + 112, floorTexture: 'AXF02', ceilingTexture: IN.ceil,
        wallTexture: 'ADMETL1', upperTexture: IN.wall, lowerTexture: 'ADMETL1', midTexture: 'CWFENCE', midWrap: true, blocking: true }, R(cageX, S0 + 152, 16, S1 - S0 - 176));
    // the ways in: the front door off the street, the corridor's back doors to the helipad and the car park
    exteriorDoor(b, 'S', bullpen.rect.x + 288, 64, 'CWDOORWL');
    exteriorDoor(b, 'W', CORR.y + 24, 56, IN.door);
    exteriorDoor(b, 'E', CORR.y + 24, 56, IN.door);
    // the motor pool's roll-up shutter on the street, shut
    b.wall(R(motor.rect.x + 64, B.y, 128, 8), 'AXW28', 'Shutter');
    // windows: glass on the open rooms, boards on the shut ones
    const win = (side, lo, hi, boardedUp) => {
        for (let p = lo + 40; p + 48 <= hi - 40; p += 128) {
            const rect = side === 'S' ? R(p, B.y, 48, 16) : side === 'W' ? R(B.x, p, 16, 48) : R(B.x + B.w - 16, p, 16, 48);
            if (b.keepClear.some(k => overlaps(k, rect, 8))) continue;
            b.opening({ type: 'window', name: boardedUp ? 'Boarded window' : 'Window', floorHeight: FLOOR + 32, ceilingHeight: FLOOR + 72, floorTexture: 'CWCONCF', ceilingTexture: 'CWCONCF',
                wallTexture: 'CWCONCW', upperTexture: FACADE, lowerTexture: FACADE, ...(boardedUp ? { midTexture: 'AXB03', blocking: true } : { blocking: false }) }, rect);
        }
    };
    win('S', armory.rect.x, armory.rect.x + armory.rect.w, false);
    win('S', bullpen.rect.x, bullpen.rect.x + bullpen.rect.w, false);
    win('S', squad.rect.x, squad.rect.x + squad.rect.w, false);
    win('W', captain.rect.y, captain.rect.y + captain.rect.h, true);
    win('E', motor.rect.y, motor.rect.y + motor.rect.h, true);
    win('E', roof.rect.y, roof.rect.y + roof.rect.h, true);

    // ---------------------------------------------------------------- lights
    fixtures(b, corridor, 256);
    fixtures(b, bullpen, 224);
    for (const l of [armory, squad]) fixtures(b, l, 0);
    for (const l of [motor, ...shut]) fixtures(b, l, 0, true);

    // ---------------------------------------------------------------- the bullpen: the raid board, the captain, the desks
    const bp = bullpen.area;
    const boardX = bp.x + 296;
    b.thing(P.whiteboard, boardX, bp.y + bp.h - 11, 270);
    b.thing(P.raidBoard, boardX, bp.y + bp.h - 32, 270);
    wallDecor(b, P.bulletin, boardX - 112, bp.y + bp.h, 270);
    wallDecor(b, P.corkboard, boardX + 112, bp.y + bp.h, 270);
    wallDecor(b, P.clock, boardX, bp.y + bp.h, 270, { z: 96 });
    b.thing(P.wallTV, bp.x + bp.w - 11, bp.y + 470, 180);
    b.thing(P.captain, boardX + 120, bp.y + bp.h - 72, 270);
    b.thing(T.start, bp.x + 296, bp.y + 72, 90);
    // the pilot waits out by the helipad, at the corridor's back door
    b.thing(P.pilot, B.x - 112, CORR.y + 24, 0);
    const spots = [];
    for (const dx of [-136, 136]) {
        for (const dy of [180, 320]) {
            const x0 = bp.x + 296 + dx, y0 = bp.y + dy;
            b.thing(T.deskWork, x0, y0, 270);
            b.thing(T.chair, x0, y0 + 30, 270);
            spots.push([x0 + (dx < 0 ? -56 : 56), y0 + 24, dx < 0 ? 0 : 180]);
        }
    }
    for (const [t, x0, y0, a] of [[T.fileCab, bp.x + bp.w - 14, bp.y + 380, 180], [T.fileCab, bp.x + bp.w - 14, bp.y + 400, 180], [T.fileCab, bp.x + bp.w - 14, bp.y + 420, 180],
        [P.cooler, bp.x + bp.w - 10, bp.y + 300, 180], [T.vending, bp.x + bp.w - 20, bp.y + 40, 180], [T.planter, bp.x + 120, bp.y + 16, 90], [T.planter, bp.x + 472, bp.y + 16, 90],
        [P.copier, bp.x + bp.w - 16, bp.y + 90, 180]]) b.thing(t, x0, y0, a);
    wallDecor(b, P.noSmoking, bp.x + bp.w, bp.y + 260, 180);
    spots.push([bp.x + bp.w - 64, bp.y + 300, 180]);

    // the armory cage: lockers down the west wall (the Evidence Locker), a gun bench, crates of seized kit
    const ar = armory.area;
    for (let i = 0; i < 6; i++) b.thing(T.locker, ar.x + 12, ar.y + 200 + i * 36, 0);
    b.thing(P.armoryLocker, ar.x + 44, ar.y + 290, 0);
    b.thing(T.workbench, ar.x + 160, ar.y + 17, 90);
    b.thing(T.rackStocked, ar.x + 100, ar.y + ar.h - 14, 270);
    for (const [t, x0, y0, a] of [[T.crates, ar.x + 240, ar.y + 40, 0], [T.caseGreen, ar.x + 100, ar.y + 24, 90], [T.drums, ar.x + 30, ar.y + ar.h - 30, 0]]) b.thing(t, x0, y0, a);
    wallDecor(b, P.extinguisher, ar.x, ar.y + 120, 0);
    spots.push([ar.x + 120, ar.y + 240, 180], [ar.x + 120, ar.y + 340, 180]);

    // the squad room: the sofa (Use it: the roster), a screen, the memorial wall
    const sq = squad.area;
    const sy = sq.y + 248;
    b.thing(T.sofa, sq.x + sq.w - 18, sy, 180);
    b.thing(P.squadRoom, sq.x + sq.w - 45, sy, 180);
    b.thing(T.coffee, sq.x + sq.w - 79, sy, 0);
    b.thing(T.armchair, sq.x + sq.w - 120, sy - 84, 45);
    b.thing(T.armchair, sq.x + sq.w - 120, sy + 84, 315);
    b.thing(P.wallTV, sq.x + 11, sy, 0);
    wallDecor(b, P.painting, sq.x + sq.w, sy + 140, 180);
    for (let i = 0; i < 4; i++) wallDecor(b, P.certificate, sq.x + 24 + i * 36, sq.y + sq.h, 270);
    for (const [t, x0, y0, a] of [[T.vending, sq.x + 20, sq.y + 40, 0], [T.bin, sq.x + 60, sq.y + 16, 0], [T.roundTable, sq.x + 120, sq.y + 100, 0], [T.chair, sq.x + 96, sq.y + 100, 0], [T.chair, sq.x + 144, sq.y + 100, 180]])
        b.thing(t, x0, y0, a);
    spots.push([sq.x + 130, sy, 0], [sq.x + 200, sq.y + 60, 90], [sq.x + 100, sq.y + sq.h - 80, 270]);

    for (const [x0, y0, a] of spots) b.thing(P.hqSpot, x0, y0, a);

    // the corridor: benches, a cooler, notices
    const co = corridor.area;
    for (const [t, x0, y0, a] of [[T.pew, 1068, co.y + co.h - 14, 270], [T.pew, 1520, co.y + co.h - 14, 270], [P.cooler, 1300, co.y + 10, 90],
        [T.bin, 1400, co.y + 10, 90], [T.planter, 1768, co.y + co.h - 15, 270]]) {
        const rect = R(x0 - 24, y0 - 24, 48, 48);
        if (!b.keepClear.some(k => overlaps(k, rect, 0))) b.thing(t, x0, y0, a);
    }
    wallDecor(b, P.bulletin, 1290, co.y + co.h, 270);
    wallDecor(b, P.noSmoking, 1848, co.y, 90);
    wallDecor(b, P.extinguisher, 1148, co.y, 90);

    // ---------------------------------------------------------------- the shut rooms, as they were left
    const c = captain.area;
    b.thing(P.deskExec, cx(c), c.y + c.h - 120, 270);
    b.thing(P.chairExec, cx(c), c.y + c.h - 80, 270);
    b.thing(T.bookshelf, c.x + 9, c.y + 420, 0);
    b.thing(T.fileCab, c.x + c.w - 14, c.y + 360, 180);
    b.thing(T.planter, cx(c), c.y + c.h - 15, 270);
    b.thing(T.armchair, c.x + 60, c.y + 120, 45);
    const rr = radio.area;
    b.thing(P.serverRack, rr.x + 23, rr.y + rr.h - 60, 0);
    b.thing(P.serverRack, rr.x + 23, rr.y + rr.h - 120, 0);
    b.thing(T.deskWork, rr.x + rr.w - 17, rr.y + 300, 180);
    b.thing(T.chair, rr.x + rr.w - 50, rr.y + 300, 180);
    b.thing(T.crates, rr.x + 60, rr.y + 120, 0);
    const inf = infirmary.area;
    for (let i = 0; i < 3; i++) b.thing(T.bed, inf.x + 40 + i * 72, inf.y + inf.h - 42, 270);
    b.thing(T.credenza, inf.x + 12, inf.y + 200, 0);
    b.thing(T.bin, inf.x + inf.w - 16, inf.y + 120, 0);
    const rg = range.area;
    // the firing line: booths, a counter, the lanes north to the sandbags
    for (const px of [rg.x + 64, rg.x + 192]) b.thing(P.partition, px, rg.y + 72, 0);
    b.thing(T.counter, cx(rg), rg.y + 122, 90);
    b.thing(T.sandbags, cx(rg), rg.y + rg.h - 14, 270);
    const lb = lab.area;
    b.thing(P.labBench, lb.x + 17, lb.y + 280, 0);
    b.thing(P.labBench, lb.x + lb.w - 17, lb.y + 200, 180);
    b.thing(T.fileCab, lb.x + 60, lb.y + lb.h - 14, 270);
    // the holding cells: two cells behind bars, and the water's come in
    const ce = cells.area;
    const barsY = ce.y + ce.h - 168;
    b.opening({ type: 'window', name: 'Cell bars', floorHeight: FLOOR, ceilingHeight: FLOOR + 112, floorTexture: 'AXF02', ceilingTexture: IN.ceil,
        wallTexture: 'ADMETL1', upperTexture: IN.wall, lowerTexture: 'ADMETL1', midTexture: 'MIDBARS3', midWrap: true, blocking: true }, R(ce.x, barsY, ce.w, 8));
    b.wall(R(snap(cx(ce)) - 4, barsY + 8, 8, ce.y + ce.h - barsY - 8), IN.wall, 'Cell wall');
    b.thing(T.bed, ce.x + 40, ce.y + ce.h - 42, 270);
    b.thing(T.bed, ce.x + ce.w - 40, ce.y + ce.h - 42, 270);
    b.top({ type: 'pool', name: 'Floodwater', hazard: 'water', floorHeight: FLOOR - 8, floorTexture: 'CWWATER', ceilingTexture: IN.ceil, ceilingHeight: cells.ceil, lightLevel: SHUT_LIGHT }, R(ce.x, ce.y, ce.w, barsY - ce.y));
    // roof access: the stairs up to a hatch
    const ra = roof.area;
    b.opening({ type: 'stairs', name: 'Roof stairs', direction: 'N', steps: 8, startFloor: FLOOR, endFloor: FLOOR + 96, ceilingHeight: FLOOR + 176, ceilingTexture: 'CWCONCF',
        floorTexture: 'CWSTAIF', wallTexture: 'CWCONCW', lowerTexture: 'AXSTEP23', upperTexture: 'CWCONCW' }, R(ra.x + 32, ra.y + ra.h - 200, 64, 192));
    // the motor pool: a work pit and tools; the car's gone
    const mp = motor.area;
    b.thing(T.workbench, mp.x + mp.w - 17, mp.y + 300, 180);
    b.thing(T.drums, mp.x + 40, mp.y + 420, 0);
    b.thing(T.cylinders, mp.x + 40, mp.y + 360, 0);
    b.thing(T.hazardBarrel, mp.x + 200, mp.y + 440, 0);
    // dust and rubble in the dark
    for (const l of [motor, ...shut]) if (b.chance(0.6)) b.thing(T.rubble, l.area.x + 40 + b.r() * (l.area.w - 80), l.area.y + 60 + b.r() * 80, 0);

    const project = b.project(name, mapLump, skybox);
    for (const room of project.rooms) room.theme = editorTheme(room.theme);
    for (const obj of project.smartObjects) if (obj.theme) obj.theme = editorTheme(obj.theme);
    const stats = { spots: spots.length, decks: 0, rooms: project.rooms.length, objects: project.smartObjects.length, things: project.things.length };
    return { project, stats };
}

// a door through the facade behind a 72-high header (the districts' way): side S, W or E at p along it
function exteriorDoor(b, side, p, w, texture) {
    let header, door, clear;
    if (side === 'S') { header = R(p, B.y, w, 8); door = R(p, B.y + 8, w, 8); clear = R(p - 16, B.y - 64, w + 32, 160); }
    else if (side === 'W') { header = R(B.x, p, 8, w); door = R(B.x + 8, p, 8, w); clear = R(B.x - 64, p - 16, 160, w + 32); }
    else { header = R(B.x + B.w - 8, p, 8, w); door = R(B.x + B.w - 16, p, 8, w); clear = R(B.x + B.w - 96, p - 16, 160, w + 32); }
    b.opening({ type: 'window', name: 'Entrance', floorHeight: FLOOR, ceilingHeight: FLOOR + 72, floorTexture: 'AXF39', ceilingTexture: 'CWCONCF',
        wallTexture: FACADE, upperTexture: FACADE, lowerTexture: FACADE, blocking: false }, header);
    b.opening({ type: 'door', name: side === 'S' ? 'Front door' : 'Back door', theme: 'nbc_precinct', wallTexture: texture, lock: 0, speed: 32, wait: 105, ...doorFit(texture, door, 72) }, door);
    b.keepClear.push(clear);
}

// ceiling fixtures: a lit one with a dynamic light in a working room, a dead one in a shut room
function fixtures(b, l, step, dead = false) {
    const a = l.area;
    const centers = [];
    if (step) {
        // a grid inset from the walls; a narrow room (a corridor) gets one row down its middle
        const xs = [], ys = [];
        const along = (lo, len) => {
            if (len < 192) return [lo + len / 2];
            const out = [], g0 = lo + 64, gl = len - 128;
            for (let v = g0 + (gl % step) / 2; v <= g0 + gl; v += step) out.push(v);
            return out;
        };
        xs.push(...along(a.x, a.w)); ys.push(...along(a.y, a.h));
        for (const x of xs) for (const y of ys) centers.push([snap(x), snap(y)]);
    } else centers.push([snap(cx(a)), snap(cy(a))]);
    for (const [x, y] of centers) {
        b.room(R(x - 16, y - 16, 32, 32), { prefix: 'fixture', name: 'Light', theme: 'nbc_precinct', floor: FLOOR, ceil: l.ceil, light: dead ? l.light : Math.min(255, l.light + 24),
            floorTexture: l.room.floorTexture || IN.floor, ceilingTexture: dead ? 'CWCONCF' : 'ADCLRND', wallTexture: IN.wall });
        if (!dead) b.thing(T.roomLight, x, y, 0);
    }
}

// a sprite on a wall: at the wall face (x, y), turned out of it
function wallDecor(b, type, x, y, angle, extra = {}) {
    const off = { 0: [1, 0], 90: [0, 1], 180: [-1, 0], 270: [0, -1] }[angle];
    b.thing(type, x + off[0], y + off[1], angle, extra);
}

function lamp(b, x, y) {
    b.thing(T.lampPost, x, y, 0);
    b.thing(T.streetLight, x, y, 0);
    b.solid.push(R(x - 8, y - 8, 16, 16));
}

function placed(b, type, x, y, angle) {
    b.thing(type, x, y, angle);
    b.solid.push(R(x - 24, y - 24, 48, 48));
}

module.exports = { generatePrecinct };
