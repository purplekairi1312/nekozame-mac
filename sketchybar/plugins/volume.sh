#!/bin/bash
# some outputs (hdmi, many audio interfaces) have no volume macOS can read: then
# just the speaker icon
v="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
case "$v" in
    ''|*[!0-9]*) sketchybar --set "$NAME" icon=󰕾 label.drawing=off; exit 0 ;;
    0) i=󰖁 ;; [0-9]|[1-2][0-9]) i=󰕿 ;; [3-6][0-9]) i=󰖀 ;; *) i=󰕾 ;;
esac
sketchybar --set "$NAME" icon="$i" label.drawing=on label="$v%"
