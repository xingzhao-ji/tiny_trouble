#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
TASK_ROOT=$(pwd)
TASK_ENGINE="$TASK_ROOT/builds/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express"
if [ ! -x "$TASK_ENGINE" ]; then
  TASK_ENGINE="$TASK_ROOT/tools/Godot.app/Contents/MacOS/Godot"
fi
mkdir -p evidence/ballast_recording
"$TASK_ENGINE" --path . --resolution 1280x720 --write-movie "$TASK_ROOT/evidence/blueberry_ballast.avi" --fixed-fps 60 --script "$TASK_ROOT/tests/chapter/replay_ballast.gd" -- --evidence-dir="$TASK_ROOT/evidence/ballast_recording" --evidence-mode=movie --evidence-fixed-fps=60 > evidence/ballast_recording/engine.log 2>&1
ffmpeg -hide_banner -loglevel error -y -i evidence/blueberry_ballast.avi -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart evidence/Blueberry-Ballast-playthrough.mp4
