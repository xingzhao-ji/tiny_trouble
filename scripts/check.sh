#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
TASK_ENGINE=./tools/Godot.app/Contents/MacOS/Godot
mkdir -p evidence
for TASK_TEST in test_puzzle_state test_scene_persistence test_scene_safety test_scene_recovery test_settings test_flight_clearance test_crumb_state test_chapter_progress test_crumb_scene test_ballast_state test_ballast_scene; do
  TASK_LOG="evidence/${TASK_TEST}.log"
  if ! "$TASK_ENGINE" --headless --path . --script "tests/${TASK_TEST}.gd" > "$TASK_LOG" 2>&1; then
    cat "$TASK_LOG"
    exit 1
  fi
  if rg -q 'SCRIPT ERROR|ERROR:|FAIL' "$TASK_LOG"; then
    cat "$TASK_LOG"
    exit 1
  fi
  printf '%s\n' "PASS ${TASK_TEST}"
done
