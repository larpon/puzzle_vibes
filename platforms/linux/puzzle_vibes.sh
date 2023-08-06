#!/bin/bash
#
# This is a launcher script for puzzle_vibes
# Copyright (c) 2022 Lars Pontoppidan <lp@blackgrain.dk>

# The program location
TOP="$(cd "${0%/*}" && echo ${PWD})"

BIN=puzzle_vibes
PROGRAM="$TOP/$BIN"

# Maintain icon if application is moved (from https://stackoverflow.com/a/3464561/1904615)
mv "$PROGRAM".desktop "$PROGRAM".desktop-bak
sed -e "s,Icon=.*,Icon=$TOP/assets/images/icon_128x128.png,g" "$PROGRAM".desktop-bak > "$PROGRAM".desktop
rm "$PROGRAM".desktop-bak

# Add the current directory to the library path to pick up any *.so distributed with the app
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:."
exec "${PROGRAM}" "$@"
