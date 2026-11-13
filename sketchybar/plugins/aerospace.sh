#!/bin/bash
# an AeroSpace workspace button: pink when it's the one showing, hidden when empty
i="$1"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
if [ "$i" = "$focused" ]; then
    sketchybar --set "$NAME" drawing=on background.drawing=on background.color=0xffffc0e5 icon.highlight=on
elif [ -n "$(aerospace list-windows --workspace "$i" 2>/dev/null)" ]; then
    sketchybar --set "$NAME" drawing=on background.drawing=off icon.highlight=off
else
    sketchybar --set "$NAME" drawing=off
fi
