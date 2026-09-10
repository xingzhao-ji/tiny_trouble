#!/bin/sh
# Local manual study: isolated profiles, normal gameplay, no automated scores.
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TASK_ENGINE="$TASK_ROOT/builds/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express"
if [ ! -x "$TASK_ENGINE" ]; then
  TASK_ENGINE="$TASK_ROOT/tools/Godot.app/Contents/MacOS/Godot"
fi
exec "$TASK_ENGINE" --path "$TASK_ROOT" --script "$TASK_ROOT/tests/platform/human_playtest.gd" -- "$@"
