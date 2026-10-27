#!/bin/bash
# Maglock test: stand at a secured door, tap USE (should stay shut), hold USE 4 s (forced), then a pass on a 2nd door.
G=/home/claude/game; OUT=$G/$1; SEED=${2:-1234}; ROLE=${3:-1}
export WINEDEBUG=-all WINEPREFIX=/tmp/wp HOME=/tmp/wphome DISPLAY=:55
rm -rf $OUT; mkdir -p $OUT; rm -rf $G/ss_tmp; mkdir -p $G/ss_tmp
wineserver -k 2>/dev/null; sleep 1
Xvfb :55 -screen 0 1280x800x24 >/dev/null 2>&1 & XP=$!
sleep 1
cat > $G/auto.cfg <<CFG
bind 1 "netevent tksec 0"
bind 2 "netevent tksec 1"
bind 3 "netevent tkdoorinfo"
bind 4 "netevent tkgivepass"
bind i "+use"
bind 5 "screenshot"
bind 6 "kill monsters"
bind 7 "netevent tkentered"
bind u "+forward"
r_drawplayersprites 0
god
notarget
con_notifytime 0
gl_texture_filter 0
CFG
cd $G
wine uzdoom.exe -iwad freedoom2.wad -file src testkit -nosound -width 960 -height 600 +vid_fullscreen 0 +sv_cheats 1 \
  +cw_procseed $SEED +cw_floorrole $ROLE +screenshot_dir ss_tmp +map G02 +exec auto.cfg > $OUT/stdout.txt 2>&1 &
for i in $(seq 1 90); do grep -q "Floor generated\|Script error" $OUT/stdout.txt 2>/dev/null && break; sleep 1; done
sleep 5
for t in 1 2 3 4 5 6 7 8 9 10; do W=$(xdotool search --name "UZDoom" 2>/dev/null | head -1); [ -z "$W" ] && W=$(xdotool search --class uzdoom 2>/dev/null | head -1); [ -n "$W" ] && break; sleep 1; done; echo "win=$W"
xdotool windowfocus $W >/dev/null 2>&1; sleep 1
k() { xdotool key --window $W $1; sleep ${2:-1}; }
k 6; k 1 2; k 5; k 3
xdotool keydown --window $W i; sleep 0.25; xdotool keyup --window $W i; sleep 1; k 3   # tap USE: must stay shut
xdotool keydown --window $W i; sleep 4.5; xdotool keyup --window $W i; sleep 1.5; k 3; k 5   # hold: forced
xdotool keydown --window $W u; sleep 1.5; xdotool keyup --window $W u; sleep 0.5; k 7
k 2 2; k 4; xdotool keydown --window $W i; sleep 0.25; xdotool keyup --window $W i; sleep 1.2; k 3; k 5    # second door with a pass
sleep 1; wineserver -k; sleep 1; kill $XP
i=0; for f in $(ls $G/ss_tmp/* 2>/dev/null | sort); do cp "$f" $OUT/shot_$(printf %02d $i).png; i=$((i+1)); done
grep "TKSEC\|TKDOOR\|TKPASS\|Lock forced\|Script error\|Objective" $OUT/stdout.txt
