#!/bin/bash
# what's playing (media-control reads macOS's now playing), hidden when nothing is
j=$(media-control get 2>/dev/null)
if [ -z "$j" ] || [ "$j" = null ]; then sketchybar --set "$NAME" drawing=off; exit 0; fi
title=$(jq -r '.title // empty' <<< "$j"); artist=$(jq -r '.artist // empty' <<< "$j")
playing=$(jq -r '.playing // false' <<< "$j")
[ "$playing" = true ] && icon=󰎈 || icon=󰏤
sketchybar --set "$NAME" drawing=on icon="$icon" label="${artist:+$artist · }$title"
