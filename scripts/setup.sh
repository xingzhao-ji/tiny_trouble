#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p tools
if [ ! -x tools/Godot.app/Contents/MacOS/Godot ]; then
  curl -fL --retry 2 -o tools/godot-macos.zip https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_macos.universal.zip
  unzip -q tools/godot-macos.zip -d tools
fi
tools/Godot.app/Contents/MacOS/Godot --headless --path . --import
