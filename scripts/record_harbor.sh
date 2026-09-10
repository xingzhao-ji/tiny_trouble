#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
TASK_ROOT=$(pwd)
TASK_ENGINE="$TASK_ROOT/builds/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express"
if [ ! -x "$TASK_ENGINE" ]; then
  TASK_ENGINE="$TASK_ROOT/tools/Godot.app/Contents/MacOS/Godot"
fi
mkdir -p evidence/harbor_recording
"$TASK_ENGINE" --path . --resolution 1280x720 --write-movie "$TASK_ROOT/evidence/milk_harbor.avi" --fixed-fps 60 --script "$TASK_ROOT/tests/chapter/replay_harbor.gd" -- --evidence-dir="$TASK_ROOT/evidence/harbor_recording" --evidence-mode=movie --evidence-fixed-fps=60 > evidence/harbor_recording/engine.log 2>&1
ffmpeg -hide_banner -loglevel error -y -i evidence/milk_harbor.avi -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart evidence/Milk-Harbor-playthrough.mp4
