#!/bin/bash
# splice next to the DAW on workspace 4, to drag samples over, laid out by the
# screen's shape and size (in points, after macOS's scaling):
#   ultrawide (2:1 or wider)          side by side
#   tall enough for both one above the other (Bitwig needs about 575, Splice
#   640, plus the gaps)               splice under the DAW
#   anything else (a laptop)          still one above the other, splice at its
#                                     full height over the DAW's bottom edge
# (floating doesn't work: the DAW comes in front of it whenever it's clicked)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
sleep 0.3  # aerospace is still placing the new window
id=$(aerospace list-windows --monitor all --app-bundle-id com.splice.Splice --format '%{window-id}' | head -1)
[ -n "$id" ] || exit 0

read -r w h < <(osascript -l JavaScript -e '
ObjC.import("AppKit");
var v = $.NSScreen.mainScreen.visibleFrame;
[v.size.width, v.size.height].map(Math.round).join(" ")')

aerospace layout --window-id "$id" tiling
if [ $((w * 10 / h)) -ge 20 ]; then
    aerospace layout --window-id "$id" h_tiles
else
    aerospace layout --window-id "$id" v_tiles
    # not tall enough for both: splice gets its own minimum (about 640)
    [ "$h" -ge 1240 ] || aerospace resize --window-id "$id" height 650
fi
