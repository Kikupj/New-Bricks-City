#!/usr/bin/env bash
# Linux twin of make_bricks.ps1 (cloud sessions): build New Bricks City levels with a source build of Obsidian.
#
#   tools/Obsidian/make_bricks.sh                          # 4 maps ("few") -> nbc/maps/NBC_CT01-04.wad
#   tools/Obsidian/make_bricks.sh --name test --length single --seed 42 --no-export
#
# Obsidian: $OBSIDIAN (a source checkout with the binary built into its root), default /home/user/obsidian-src.
# Build it once (console-only, no GUI needed):
#   git clone --depth 1 https://github.com/obsidian-level-maker/Obsidian.git /home/user/obsidian-src
#   apt-get install -y flex && cd /home/user/obsidian-src
#   cmake -B build/console -DCMAKE_BUILD_TYPE=Release -DCONSOLE_ONLY=ON && cmake --build build/console -j"$(nproc)"
# The binary lands in the checkout's root. This script links addons/NewBricksCity into it.
#
# Settings start from tools/Obsidian/CONFIG.txt if it's there (the owner's GUI settings, not in git), else
# Obsidian's own defaults (~/.local/share/Obsidian/CONFIG.txt), then get the same overrides as make_bricks.ps1.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
obs="${OBSIDIAN:-/home/user/obsidian-src}"
name=bricks; length=few; seed=0; export=1
while [ $# -gt 0 ]; do
	case "$1" in
		--name) name=$2; shift 2 ;;
		--length) length=$2; shift 2 ;;
		--seed) seed=$2; shift 2 ;;
		--no-export) export=0; shift ;;
		*) echo "make_bricks: unknown option $1"; exit 2 ;;
	esac
done
if [ ! -x "$obs/obsidian" ]; then echo "make_bricks: no Obsidian binary at $obs/obsidian (see the top of this script)"; exit 2; fi
ln -sfn "$here/addons/NewBricksCity" "$obs/addons/NewBricksCity"
out="$here/out"; mkdir -p "$out"

base="$here/CONFIG.txt"
if [ ! -f "$base" ]; then
	base="$HOME/.local/share/Obsidian/CONFIG.txt"
	# a first run writes Obsidian's defaults there
	[ -f "$base" ] || (cd "$obs" && ./obsidian -b "$out/_defaults.wad" >/dev/null 2>&1 || true)
fi
[ -f "$base" ] || { echo "make_bricks: no CONFIG.txt to start from"; exit 2; }

python3 - "$base" "$out/$name.settings.txt" "$length" "$seed" <<'EOF'
import sys
base, dest, length, seed = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
# the same overrides as make_bricks.ps1
settings = {
    "game": "doom2", "port": "zdoom", "theme": "nbc_bricks", "length": length,
    "@new_bricks_city": "1",
    "@armaetus_epic_textures": "0",    # injects its own textures and Urban room themes
    "@sky_generator": "0",             # paints its own sky graphics
    "@procedural_gotcha": "0", "@procedural_gotcha_zdoom": "0", "@iwad_mode": "0",
    "@compress_output": "0",           # plain WAD, not a zip
    "float_overall_lighting_mult": "1.1",   # interiors: 1.0 is gloomy, 1.3 washes everything out at 255
    "outdoors": "mixed", "caves": "mixed", "liquids": "mixed", "hallways": "mixed", "teleporters": "mixed",
    "steepness": "mixed", "parks": "mixed", "park_detail": "mixed", "porches": "mixed", "cages": "mixed",
    "natural_parks": "none", "traps": "none", "room_heights": "tall-ish", "float_mons": "0.6",
    "bool_allow_teleporter_emergency_breaks": "0",   # no teleporters in the Bricks, not even to mend a layout
}
lines, seen = [], set()
for line in open(base, encoding="latin-1").read().splitlines():
    k = line.split("=")[0].strip() if "=" in line and not line.lstrip().startswith("--") else None
    if k == "seed":
        continue
    if k in settings:
        seen.add(k)
        line = line[:len(line) - len(line.lstrip())] + "%s = %s" % (k, settings[k])
    lines.append(line)
missing = ["%s = %s" % (k, v) for k, v in settings.items() if k not in seen]
end = lines.index("-- END --") if "-- END --" in lines else len(lines)
lines = lines[:end] + missing + lines[end:]
if seed:
    lines = ["seed = %d" % seed] + lines
open(dest, "w", encoding="ascii", errors="replace").write("\n".join(lines) + "\n")
EOF

keep=(); [ "$seed" != 0 ] && keep=(-k)
log="$out/$name.log.txt"
rm -f "$out/$name.wad"
(cd "$obs" && timeout 900 ./obsidian -v -b "$out/$name.wad" -l "$out/$name.settings.txt" "${keep[@]}" -a NewBricksCity) > "$log" 2>&1 || true
if grep -qE "ERROR OCCURRED|ERROR MESSAGE|Script Error|ERROR: FAILED|Unable to load script|Unknown theme|No rooms themes" "$log" || [ ! -f "$out/$name.wad" ]; then
	echo "FAILED (see $log)"
	grep -E "ERROR|Script Error|Unable to load|Unknown theme" "$log" | head -10
	exit 1
fi
echo "Built tools/Obsidian/out/$name.wad ($(du -h "$out/$name.wad" | cut -f1))"
grep -E "^Theme for level|Streets Mode activated|New Bricks City:" "$log" | sed 's/^/  /' || true
if [ "$export" = 1 ]; then python3 "$here/export_maps.py" "$out/$name.wad"; fi
