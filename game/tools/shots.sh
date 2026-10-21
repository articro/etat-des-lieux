#!/usr/bin/env bash
# Captures d'écran du niveau en rendu logiciel (Xvfb + Mesa). Sortie : docs/shots/*.png
# Usage : bash game/tools/shots.sh [spot1,spot2]   (sans argument : tous les spots de tools/shots.json)
set -e
cd "$(dirname "$0")/.."
G=/tmp/Godot_v4.7.2-stable_linux.x86_64
[ -x "$G" ] || bash tools/install_godot_sandbox.sh >/dev/null
command -v xvfb-run >/dev/null || sudo -n apt-get install -y -qq xvfb >/dev/null 2>&1 || { echo "xvfb indisponible"; exit 1; }
OUT="$(pwd)/../docs/shots"; mkdir -p "$OUT"
timeout 240 xvfb-run -a -s "-screen 0 1280x720x24" "$G" --path . --rendering-driver "${DRIVER:-vulkan}" --resolution 1280x720 --script res://tools/shot.gd -- "$OUT" "$1" 2>&1 | grep -E "shot :|ERROR|error" | grep -v "still in use" || true
ls -1 "$OUT"/*.png 2>/dev/null | sed 's|.*/||' | tr '\n' ' '; echo
