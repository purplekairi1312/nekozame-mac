#!/bin/bash
# the macOS menu bar's icons (Tailscale, Bitwarden...), mirrored into the bar:
# the menu bar itself is under it. clicks go through to the real icon. needs
# Screen Recording for SketchyBar (System Settings → Privacy & Security)
items=$(sketchybar --query default_menu_items 2>/dev/null | jq -r '.[]?' 2>/dev/null) || exit 0
# macOS's own: the bar has its own clock and volume, and spotlight is Cmd+Space
echo "$items" | grep -v -E '^(Control Center|Clock|Spotlight|Siri|Window Manager|TextInputMenuAgent|SystemUIServer|BentoBox|Battery|Wi-Fi|Sound|Display|Focus|Now Playing|Screen Mirroring|AudioVideoModule|Bluetooth|Passwords|SketchyBar)' \
    | grep -v '^$' | while read -r item; do
    sketchybar --add alias "$item" right \
               --set "$item" alias.color=0xffffffff alias.scale=0.9 padding_left=0 padding_right=0 \
                     background.drawing=off
done
