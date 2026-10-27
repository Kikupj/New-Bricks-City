#!/bin/bash
# usage: run.sh <seed> <role> <shots file: lines "x y a p [z]"> <outdir>
G=/home/claude/game; SEED=$1; ROLE=$2; SHOTS=$3; OUT=$4
export WINEDEBUG=-all WINEPREFIX=/tmp/wp HOME=/tmp/wphome DISPLAY=:55
rm -rf $G/$OUT; mkdir -p $G/$OUT; rm -rf $G/ss_tmp; mkdir -p $G/ss_tmp
wineserver -k 2>/dev/null; sleep 1
Xvfb :55 -screen 0 1280x800x24 >/dev/null 2>&1 &
XP=$!
sleep 1
SH=S$(awk 'NF{printf "%s%s,%s,%s,%s,%s", "|", $1,$2,$3,($4==""?0:$4),($5==""?-1:$5)}' $SHOTS)
N=$(grep -c . $SHOTS)
cat > $G/auto.cfg <<CFG
bind o "netevent tknext; wait 6; screenshot"
bind p "netevent tkdump"
bind k "netevent tkdoors"
bind t "netevent tktest"
bind x "netevent tkshow"
bind c "netevent tkcover"
bind u "+forward"
bind y "netevent tkwhere"
gl_texture_filter 0
r_drawplayersprites 0
crosshair 0
screenblocks 11
con_notifytime 0
god
notarget
CFG
cd $G
wine uzdoom.exe -iwad freedoom2.wad -file src testkit -nosound -width 960 -height 600 +vid_fullscreen 0 +sv_cheats 1 \
  +cw_procseed $SEED +cw_floorrole $ROLE +cw_theme ${THEME:--1} +screenshot_dir ss_tmp +tk_shots "$SH" +map G02 +exec auto.cfg > $OUT/stdout.txt 2>&1 &
for i in $(seq 1 90); do grep -q "Floor generated\|Script error" $OUT/stdout.txt 2>/dev/null && break; sleep 1; done
sleep 4
W=$(xdotool search --name "UZDoom" 2>/dev/null | head -1); [ -z "$W" ] && W=$(xdotool search --class uzdoom | head -1)
xdotool windowfocus $W >/dev/null 2>&1
sleep 1
xdotool key --window $W p; sleep 2
[ -n "$PRE" ] && { for kk in $PRE; do xdotool key --window $W $kk; sleep 1; done; }
[ -n "$OPEN" ] && { xdotool key --window $W k; sleep 2; }
for i in $(seq 1 $N); do xdotool key --window $W o; sleep 2.5
  if [ -n "$WALK" ]; then xdotool keydown --window $W u; sleep $WALK; xdotool keyup --window $W u; sleep 0.5; xdotool key --window $W y; sleep 0.5; xdotool key --window $W F12; sleep 1; fi
done
sleep 2
wineserver -k 2>/dev/null; sleep 1; kill $XP 2>/dev/null
i=0; for f in $(ls $G/ss_tmp/* 2>/dev/null | sort); do cp "$f" $G/$OUT/shot_$(printf %02d $i).png; i=$((i+1)); done
echo "shots: $i / $N"; grep -c "^SEC" $OUT/stdout.txt
