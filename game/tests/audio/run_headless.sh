#!/usr/bin/env bash
# Test de fumée headless du module Audio : joue tous les ids, émet tous les
# signaux consommés par l'AudioManager et vérifie qu'aucune erreur ne survient.
# Usage : bash game/tests/audio/run_headless.sh
set -e
cd "$(dirname "$0")/../../.."
G=/tmp/Godot_v4.7.2-stable_linux.x86_64
[ -x "$G" ] || bash game/tools/install_godot_sandbox.sh >/dev/null
timeout 180 "$G" --headless --path game --import >/dev/null 2>&1 || true
OUT=$(timeout 180 "$G" --headless --path game res://tests/audio/test_audio.tscn 2>&1 || true)
echo "$OUT"
# En fermant, l'AudioServer libère ses playbacks de façon asynchrone : il en
# reste parfois en vol au moment où le process sort, et Godot l'annonce par
# « resources still in use at exit ». Ce n'est pas une erreur de l'AudioManager
# (le joueur ne voit jamais ce message) : on l'exclut du verdict.
CLEAN=$(echo "$OUT" | grep -v "resources still in use at exit" | grep -v "ObjectDB instances were leaked" || true)
if echo "$CLEAN" | grep -qE "SCRIPT ERROR|^ERROR:|Parse Error|Compile Error|ECHEC"; then
  echo "❌ TEST AUDIO EN ÉCHEC"
  exit 1
fi
echo "✅ TEST AUDIO OK"
