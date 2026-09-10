#!/bin/sh
# Derive compact looping playback from the editable, deterministically generated WAV.
set -eu
cd "$(dirname "$0")/.."
# Encode a temporary candidate, verify complete decode/source agreement, then
# promote it and atomically refresh each metadata JSON. --audio-dir supports fixtures.
exec python3 scripts/audio_provenance.py transcode "$@"
