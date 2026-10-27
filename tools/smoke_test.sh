#!/usr/bin/env bash
# Linux twin of tools/smoke_test.ps1, for cloud sessions without Windows.
# Boots UZDoom with nbc/, loads each map, kills the engine after a few seconds, and fails on any line that
# looks like an error (same patterns as the PowerShell script). Runs headless under xvfb-run.
#
#   tools/smoke_test.sh NBC_TEST NBC_HUB          # maps (default NBC_TEST)
#   SECONDS_PER_MAP=15 tools/smoke_test.sh NBC_K2
#   EXTRA="+nbc_kitvariant 5" tools/smoke_test.sh NBC_K2
#
# The engine is $UZDOOM, else ./uzdoom, else /home/user/uzdoom/uzdoom/build/uzdoom (a source build of
# UZDoom 5.0.3; uzdoom.pk3 must sit next to the binary). The IWAD is freedoom-0.13.0/freedoom2.wad.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
engine="${UZDOOM:-}"
[ -z "$engine" ] && [ -x ./uzdoom ] && engine=./uzdoom
[ -z "$engine" ] && engine=/home/user/uzdoom/uzdoom/build/uzdoom
if [ ! -x "$engine" ]; then echo "smoke_test: no UZDoom binary (set UZDOOM=...)"; exit 2; fi
if [ ! -f freedoom-0.13.0/freedoom2.wad ]; then echo "smoke_test: freedoom-0.13.0/freedoom2.wad is missing"; exit 2; fi
mkdir -p build
secs="${SECONDS_PER_MAP:-12}"
maps=("$@"); [ ${#maps[@]} -eq 0 ] && maps=(NBC_TEST)
pattern=', line [0-9]+:|script error|error|unknown|not found|bad state|could not|missing|invalid|warning|failed|can.t|cannot'
failed=0

for m in "${maps[@]}"; do
	out="build/smoke_$m.txt"
	rm -f "$out"
	# shellcheck disable=SC2086
	timeout -s KILL "$secs" xvfb-run -a -s "-screen 0 1024x768x24" \
		"$engine" -iwad freedoom-0.13.0/freedoom2.wad -file nbc -nosound -stdout -config build/smoke.ini \
		+vid_fullscreen 0 +map "$m" ${EXTRA:-} > "$out" 2>&1
	code=$?
	reasons=()
	[ "$code" -ne 137 ] && [ "$code" -ne 124 ] && reasons+=("engine exited by itself (code $code)")
	grep -q '^Init complete\.' "$out" || reasons+=("never reached 'Init complete.'")
	grep -q "^$m - " "$out" || reasons+=("map $m never loaded")
	while IFS= read -r line; do reasons+=("log: $line"); done < <(grep -Ei "$pattern" "$out" | head -25)
	if [ ${#reasons[@]} -eq 0 ]; then
		echo "PASS  $m  ($(wc -l < "$out") log lines, $out)"
	else
		echo "FAIL  $m  ($out)"
		for r in "${reasons[@]}"; do echo "      $r"; done
		failed=1
	fi
done
exit $failed
