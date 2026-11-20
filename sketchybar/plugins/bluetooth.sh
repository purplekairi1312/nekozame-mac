#!/bin/bash
# bluetooth: on, something connected (with how many), or off. needs blueutil
BU=$(command -v blueutil || echo /opt/homebrew/bin/blueutil)
if [ "$("$BU" -p 2>/dev/null)" != 1 ]; then
    sketchybar --set "$NAME" icon=󰂲 label.drawing=off
    exit 0
fi
N=$("$BU" --connected 2>/dev/null | grep -c 'address:')
if [ "$N" -gt 0 ]; then
    sketchybar --set "$NAME" icon=󰂱 label="$N" label.drawing=on
else
    sketchybar --set "$NAME" icon=󰂯 label.drawing=off
fi
