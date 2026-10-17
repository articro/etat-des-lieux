#!/usr/bin/env bash
# Vérification headless du projet : import + lancement 3 frames. Échoue si "SCRIPT ERROR" ou "ERROR:" apparaît.
# Usage : bash game/tools/check.sh   (depuis la racine du dépôt)
set -e
cd "$(dirname "$0")/.."
G=/tmp/Godot_v4.7.2-stable_linux.x86_64
[ -x "$G" ] || bash tools/install_godot_sandbox.sh >/dev/null
timeout 180 "$G" --headless --path . --import >/dev/null 2>&1 || true
OUT=$(timeout 90 "$G" --headless --path . --quit-after 3 2>&1 || true)
echo "$OUT" | grep -v "^$"
if echo "$OUT" | grep -qE "SCRIPT ERROR|^ERROR:|Parse Error|Compile Error"; then
  echo "❌ CHECK FAILED : erreurs ci-dessus"; exit 1
fi
echo "✅ CHECK OK : le projet se lance sans erreur"
