#!/bin/bash
v="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
case "$v" in
    0) i=󰖁 ;; [0-9]|[1-2][0-9]) i=󰕿 ;; [3-6][0-9]) i=󰖀 ;; *) i=󰕾 ;;
esac
sketchybar --set "$NAME" icon="$i" label="$v%"
