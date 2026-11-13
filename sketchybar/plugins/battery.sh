#!/bin/bash
# the battery: how full, a bolt while charging, the warm pink when it's low
B=$(pmset -g batt)
PCT=$(echo "$B" | grep -o '[0-9]*%' | head -1 | tr -d '%')
[ -z "$PCT" ] && exit 0
if echo "$B" | grep -q 'AC Power'; then ICON=󰂄
else
    ICONS=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
    ICON=${ICONS[$((PCT / 10))]}
fi
COLOR=0xffffc0e5                                                    # Pretty in Pink
[ "$PCT" -le 20 ] && ! echo "$B" | grep -q 'AC Power' && COLOR=0xffffb3c8  # Baby Pink: low
sketchybar --set "$NAME" icon="$ICON" icon.color=$COLOR label="$PCT%"
