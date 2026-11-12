#!/bin/bash
# the current space gets a pink pill
if [ "$SELECTED" = true ]; then
    sketchybar --set "$NAME" background.drawing=on background.color=0xffffc0e5 icon.highlight=on
else
    sketchybar --set "$NAME" background.drawing=off icon.highlight=off
fi
