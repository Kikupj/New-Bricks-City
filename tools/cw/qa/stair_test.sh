#!/bin/bash
# walk-through test of the stair-tower door teleports: face door, press USE, report position
G=/home/claude/game; OUT=$G/stt; SEED=${1:-1234}
export WINEDEBUG=-all WINEPREFIX=/tmp/wp HOME=/tmp/wphome DISPLAY=:55
rm -rf $OUT; mkdir -p $OUT; rm -rf $G/ss_tmp; mkdir -p $G/ss_tmp
wineserver -k 2>/dev/null; sleep 1
Xvfb :55 -screen 0 1280x800x24 >/dev/null 2>&1 & XP=$!
sleep 1
cat > $G/auto.cfg <<CFG
bind 1 "netevent tkstair 0 0"
bind 2 "netevent tkstair 0 2"
bind 3 "netevent tkstair 0 1"
bind 4 "netevent tkstair 1 3"
bind y "netevent tkwhere"
bind e "+use"
bind F12 "screenshot"
gl_texture_filter 0
crosshair 0
god
notarget
CFG
cd $G
wine uzdoom.exe -iwad freedoom2.wad -file src testkit -nosound -width 960 -height 600 +vid_fullscreen 0 +sv_cheats 1 \
  +cw_procseed $SEED +cw_floorrole 1 +developer 1 +screenshot_dir ss_tmp +map G02 +exec auto.cfg > $OUT/stdout.txt 2>&1 &
for i in $(seq 1 90); do grep -q "Floor generated\|Script error" $OUT/stdout.txt 2>/dev/null && break; sleep 1; done
sleep 8
W=$(xdotool search --name "UZDoom" 2>/dev/null | head -1); [ -z "$W" ] && W=$(xdotool search --class uzdoom | head -1)
xdotool windowfocus $W >/dev/null 2>&1; sleep 1
k() { xdotool key --window $W $1; sleep ${2:-1}; }
u() { xdotool keydown --window $W e; sleep 0.2; xdotool keyup --window $W e; sleep 2; }
# plate -> tower
k 1 2; k F12; u; k y; k F12
# tower own-floor door -> plate
k 2 2; k F12; u; k y; k F12
# locked landing door
k 3 2; u; k F12; k y
k 4 2; u; k F12; k y
sleep 1; wineserver -k 2>/dev/null; sleep 1; kill $XP 2>/dev/null
i=0; for f in $(ls $G/ss_tmp/* 2>/dev/null | sort); do cp "$f" $OUT/shot_$(printf %02d $i).png; i=$((i+1)); done
grep "TKSTAIR\|TKWHERE\|Script error\|another tenant\|chained\|alarmed" $OUT/stdout.txt
