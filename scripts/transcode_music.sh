#!/bin/sh
# Derive compact looping playback from the editable, deterministically generated WAV.
set -eu
cd "$(dirname "$0")/.."
ffmpeg -hide_banner -loglevel error -y -i assets/audio/music.wav -c:a vorbis -strict -2 -q:a 5 assets/audio/music.ogg
