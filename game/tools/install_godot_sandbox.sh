#!/usr/bin/env bash
# Installe Godot 4.7.2 headless dans /tmp (environnement agent Arena). Idempotent.
set -e
G=/tmp/Godot_v4.7.2-stable_linux.x86_64
if [ ! -x "$G" ]; then
  cd /tmp
  curl -sL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
  unzip -oq godot.zip && chmod +x "$G"
fi
"$G" --version
