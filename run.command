#!/bin/zsh
cd "${0:A:h}"
exec ./tools/Godot.app/Contents/MacOS/Godot --path . "$@"
