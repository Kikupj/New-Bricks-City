#!/usr/bin/env node
'use strict';
// Builds New Bricks City's maps in iDoom Studio, through its MCP server (PLAN.md M2e): for each map in MAPS, the
// layout from district-gen.js goes in as a new project (batched edits), gets its map lump and sky, is validated
// and Map Checked, saved as an editor project, and exported into nbc/maps/<LUMP>.wad. Then this writes the mod's
// side: nbc/mapinfo/studio_maps.txt, nbc/districts.txt (the raid board's pool) and a copy of every project in
// tools/studio/projects/ (open one in the editor to change a map by hand; rebuilding overwrites it).
//
//   node tools/studio/build_maps.js                     # every map
//   node tools/studio/build_maps.js NBC_D03 NBC_CRWN    # some of them
//
// iDoom Studio: IDOOM_STUDIO_DIR (default ../idoom-studio-map-editor next to this repo), its npm packages
// installed. The editor server (New Bricks City profile) is used if it's running at IDOOM_STUDIO_URL (default
// http://127.0.0.1:3456); otherwise this starts one pointed at this repo's nbc/ folder. A server started before
// this repo gained a map thing (NBC_RoofStart) doesn't know it: restart it.

const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');
const { createRequire } = require('module');
const { generateDistrict } = require('./district-gen');

const ROOT = path.resolve(__dirname, '..', '..');
const NBC = path.join(ROOT, 'nbc');
const STUDIO = path.resolve(process.env.IDOOM_STUDIO_DIR || path.join(ROOT, '..', 'idoom-studio-map-editor'));
const URL_BASE = process.env.IDOOM_STUDIO_URL || 'http://127.0.0.1:3456';
const PROJECTS = path.join(__dirname, 'projects');
const STUDIO_MAPS = path.resolve(process.env.IDOOM_MAPS_DIR || path.join(STUDIO, 'maps'));   // where the editor saves projects

// The district pool, in raid board order (names and environments as before), and the Crown. levelnum 301+.
const MAPS = [
    { lump: 'NBC_D01', name: 'Pike Water Towers', env: 'rooftops', seed: 101 },
    { lump: 'NBC_D02', name: 'Fulton Junction', env: 'subway', seed: 202 },
    { lump: 'NBC_D03', name: 'Mercer Block', env: 'streets', seed: 303 },
    { lump: 'NBC_D04', name: 'Wexford Commons', env: 'parks', seed: 404 },
    { lump: 'NBC_D05', name: 'Sutter Storm Drains', env: 'underground', seed: 505 },
    { lump: 'NBC_D06', name: 'Cypress Houses', env: 'towers', seed: 606 },
    { lump: 'NBC_D07', name: 'Carver Row', env: 'streets', seed: 707 },
    { lump: 'NBC_D08', name: 'Arden Docks', env: 'industrial', seed: 808 },
    { lump: 'NBC_CRWN', name: 'The Crown', env: 'crown', seed: 909, crown: true }
];
const SKY_FOR = { rooftops: 'nbc_dusk', subway: 'nbc_dusk', streets: 'nbc_dusk', parks: 'nbc_day', underground: 'nbc_dusk', towers: 'nbc_dusk', industrial: 'nbc_morning', crown: 'nbc_dusk' };

function get(url) {
    return new Promise((resolve, reject) => {
        http.get(url, res => { res.resume(); res.on('end', () => resolve(res.statusCode)); }).on('error', reject);
    });
}

async function ensureServer() {
    try { if (await get(`${URL_BASE}/api/catalog`) === 200) return null; } catch { }
    const port = new URL(URL_BASE).port || '3456';
    console.log(`[build] starting iDoom Studio on ${URL_BASE} (mod: ${NBC})`);
    const child = spawn(process.execPath, ['server.js'], { cwd: STUDIO, env: { ...process.env, PORT: port, IDOOM_MOD_DIR: NBC, IDOOM_PROFILE: 'new-bricks-city' }, stdio: ['ignore', 'pipe', 'pipe'] });
    child.stderr.on('data', d => process.stderr.write(d));
    for (let i = 0; i < 100; i++) {
        await new Promise(r => setTimeout(r, 200));
        try { if (await get(`${URL_BASE}/api/catalog`) === 200) return child; } catch { }
    }
    child.kill();
    throw new Error('iDoom Studio did not start');
}

async function connect() {
    const req = createRequire(path.join(STUDIO, 'package.json'));
    const { Client } = req('@modelcontextprotocol/sdk/client/index.js');
    const { StdioClientTransport } = req('@modelcontextprotocol/sdk/client/stdio.js');
    const client = new Client({ name: 'nbc-build-maps', version: '1.0.0' });
    await client.connect(new StdioClientTransport({ command: process.execPath, args: [path.join(STUDIO, 'src', 'mcp-server.js')], cwd: STUDIO, env: { ...process.env, IDOOM_STUDIO_URL: URL_BASE } }));
    const call = async (name, args = {}) => {
        const res = await client.callTool({ name, arguments: args });
        const data = res.structuredContent || JSON.parse(res.content?.[0]?.text || '{}');
        if (res.isError) throw new Error(`${name}: ${data.error || res.content?.map(c => c.text).join(' ')}`);
        return data;
    };
    return { client, call };
}

async function buildOne(call, map) {
    const { project, stats } = generateDistrict({ env: map.env, seed: map.seed, name: map.name, mapLump: map.lump, skybox: SKY_FOR[map.env] });
    let { revision } = await call('idoom_get_project');
    let r = await call('idoom_create_project', { revision, template: 'nbc_blank', name: map.name });
    revision = r.revision;
    // the starter's room and start out, then everything in batches of 100 (rooms first: objects sit on them)
    const ops = [{ type: 'delete', id: 'room_1' }, { type: 'delete', id: 'th_start' }];
    for (const room of project.rooms) ops.push({ type: 'add', collection: 'room', object: room });
    for (const obj of project.smartObjects) ops.push({ type: 'add', collection: 'smartObject', object: obj });
    for (const th of project.things) ops.push({ type: 'add', collection: 'thing', object: th });
    for (let i = 0; i < ops.length; i += 100) {
        r = await call('idoom_apply_batch', { revision, operations: ops.slice(i, i + 100) });
        revision = r.revision;
    }
    r = await call('idoom_set_project_settings', { revision, name: map.name, skybox: project.skybox, mapLump: map.lump });
    revision = r.revision;
    const valid = await call('idoom_validate_project', { revision });
    if (!valid.valid) throw new Error(`${map.lump}: ${valid.errors.slice(0, 5).join(' ')}`);
    const check = await call('idoom_map_check', { revision });
    const saveName = map.lump.toLowerCase();
    await call('idoom_save_project', { revision, name: saveName });
    const exported = await call('idoom_export_wad', { revision, name: saveName });
    if (!exported.modPath) throw new Error(`${map.lump}: the export didn't reach the mod (is the editor on the New Bricks City profile?)`);
    // the saved editor project, as the editor wrote it
    const saved = path.join(STUDIO_MAPS, `${saveName}.json`);
    fs.mkdirSync(PROJECTS, { recursive: true });
    if (fs.existsSync(saved)) fs.copyFileSync(saved, path.join(PROJECTS, `${saveName}.json`));
    console.log(`[build] ${map.lump} "${map.name}" (${map.env}): ${stats.rooms} rooms, ${stats.objects} objects, ${stats.things} things, ${stats.spots} gang spots, ${stats.decks} decks; ` +
        `${valid.stats.sectors} sectors, ${valid.stats.linedefs} lines; Map Check ${check.summary.error} errors, ${check.summary.warning} warnings -> ${path.relative(ROOT, exported.modPath)}`);
    return { ...map, stats };
}

function writeModSide(built, all) {
    const entries = all.map((map, i) => [
        `map ${map.lump} "${map.name}"`, '{', `  levelnum = ${301 + i}`, '  sky1 = "CITYSKY", 0', '  next = "NBC_HUB"', '  secretnext = "NBC_HUB"', '  nointermission', '}', ''
    ].join('\n'));
    fs.writeFileSync(path.join(NBC, 'mapinfo', 'studio_maps.txt'),
        `// Generated by tools/studio/build_maps.js: the districts and the Crown built in iDoom Studio. Rebuild; don't edit.\n\n${entries.join('\n')}`);
    const districts = all.filter(m => !m.crown).map(m => `${m.lump} "${m.name}" ${m.env}`);
    fs.writeFileSync(path.join(NBC, 'districts.txt'),
        '// District pool for the raid board: map lump, title, environment. Built in iDoom Studio by tools/studio/build_maps.js\n' +
        '// (PLAN.md M2e); the game assigns gangs to these at the start of a case. The Crown (NBC_CRWN) is in gangs.txt.\n' + districts.join('\n') + '\n');
}

async function main() {
    if (!fs.existsSync(path.join(STUDIO, 'server.js'))) throw new Error(`iDoom Studio not found at ${STUDIO} (set IDOOM_STUDIO_DIR)`);
    const only = process.argv.slice(2).map(s => s.toUpperCase());
    const todo = only.length ? MAPS.filter(m => only.includes(m.lump)) : MAPS;
    const server = await ensureServer();
    const { client, call } = await connect();
    const built = [];
    try {
        const catalog = await call('idoom_get_catalog');
        if (catalog.profile?.id !== 'new-bricks-city' || !catalog.profile?.modLoaded) throw new Error('iDoom Studio is not on the New Bricks City profile with the mod loaded');
        if (!catalog.things.some(t => t.type === 26020)) throw new Error('iDoom Studio does not know NBC_RoofStart (26020): restart it so it rereads the mod');
        for (const map of todo) built.push(await buildOne(call, map));
        writeModSide(built, MAPS);
    } finally {
        await client.close();
        if (server) server.kill();
    }
    console.log(`[build] ${built.length} map(s) built. nbc/mapinfo/studio_maps.txt and nbc/districts.txt written.`);
}

main().catch(error => { console.error(`[build] ${error.message}`); process.exit(1); });
