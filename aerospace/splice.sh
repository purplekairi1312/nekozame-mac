#!/bin/bash
# splice next to the DAW on workspace 4, to drag samples over, laid out by the
# screen's shape and size (in points, after macOS's scaling):
#   ultrawide (2:1 or wider)          side by side
#   tall enough for both one above the other (Bitwig needs about 575, Splice
#   640, plus the gaps)               splice under the DAW
#   anything else (a laptop)          splice floats over the bottom of the DAW
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
sleep 0.3  # aerospace is still placing the new window
id=$(aerospace list-windows --monitor all --app-bundle-id com.splice.Splice --format '%{window-id}' | head -1)
[ -n "$id" ] || exit 0

read -r x y w h < <(osascript -l JavaScript -e '
ObjC.import("AppKit");
var s = $.NSScreen.mainScreen, f = s.frame, v = s.visibleFrame;
[v.origin.x, f.size.height - v.origin.y - v.size.height, v.size.width, v.size.height].map(Math.round).join(" ")')

BOTH_TALL=1240
if [ $((w * 10 / h)) -ge 20 ]; then
    aerospace layout --window-id "$id" tiling
    aerospace layout --window-id "$id" h_tiles
elif [ "$h" -ge "$BOTH_TALL" ]; then
    aerospace layout --window-id "$id" tiling
    aerospace layout --window-id "$id" v_tiles
else
    aerospace layout --window-id "$id" floating
    sh=$((h * 11 / 20))  # a little over half: splice's own minimum height
    osascript -e "tell application \"System Events\" to tell process \"Splice\"
        set position of window 1 to {$((x + 10)), $((y + h - sh - 10))}
        set size of window 1 to {$((w - 20)), $sh}
    end tell" >/dev/null
fi
