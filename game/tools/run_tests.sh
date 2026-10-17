#!/usr/bin/env bash
# Lance les tests gdUnit4 en headless (nécessite addons/gdUnit4 — tâche Q-1).
set -e
cd "$(dirname "$0")/.."
G=/tmp/Godot_v4.7.2-stable_linux.x86_64
[ -x "$G" ] || bash tools/install_godot_sandbox.sh >/dev/null
if [ ! -d addons/gdUnit4 ]; then echo "gdUnit4 non installé (tâche Q-1) — tests ignorés"; exit 0; fi
timeout 300 "$G" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests --ignoreHeadlessMode
