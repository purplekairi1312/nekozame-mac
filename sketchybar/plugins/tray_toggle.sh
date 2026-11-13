#!/bin/bash
# the tray button: the bar steps aside so the macOS menu bar (and its icons) shows,
# then comes back after 8 seconds; click again to bring it back sooner.
# (mirroring the icons into the bar doesn't work on macOS 27 yet: SketchyBar #849)
if [ "$(sketchybar --query bar | jq -r .hidden)" = on ]; then
    sketchybar --bar hidden=off
else
    sketchybar --bar hidden=on
    ( sleep 8; sketchybar --bar hidden=off ) &
fi
