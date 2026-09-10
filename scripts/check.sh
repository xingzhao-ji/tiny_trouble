#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
TASK_ENGINE=./tools/Godot.app/Contents/MacOS/Godot
mkdir -p evidence
python3 scripts/sync_design_tokens.py --check
python3 scripts/audio_provenance.py check
for TASK_TEST in test_puzzle_state test_scene_persistence test_scene_safety test_scene_recovery test_settings test_flight_clearance test_crumb_state test_chapter_progress test_crumb_scene test_ballast_state test_ballast_scene test_harbor_state test_harbor_scene; do
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
for TASK_TEST in test_lifecycle test_audio_feedback; do
  TASK_LOG="evidence/platform_audio/${TASK_TEST}_regression.log"
  TASK_FLAG=""
  if [ "$TASK_TEST" = test_lifecycle ]; then TASK_FLAG="--touch-ui"; fi
  mkdir -p evidence/platform_audio
  if ! "$TASK_ENGINE" --headless --path . --script "tests/platform/${TASK_TEST}.gd" -- "$TASK_FLAG" > "$TASK_LOG" 2>&1; then
    cat "$TASK_LOG"
    exit 1
  fi
  if rg -q 'SCRIPT ERROR|ERROR:|FAIL' "$TASK_LOG"; then
    cat "$TASK_LOG"
    exit 1
  fi
  printf '%s\n' "PASS ${TASK_TEST}"
done
