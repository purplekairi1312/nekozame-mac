#!/bin/bash
# the connection: ethernet when a cable is in, else wi-fi with its signal in bars,
# else crossed out. (macOS hides the wi-fi network's name from scripts)
active() { ifconfig "$1" 2>/dev/null | grep -q 'status: active' && ipconfig getifaddr "$1" >/dev/null; }
WIFI="" WIRED=""
while IFS='|' read -r port dev; do
    case "$port" in
        Wi-Fi) WIFI=$dev ;;
        *Ethernet*|*LAN*) active "$dev" && WIRED=$dev ;;
    esac
done < <(networksetup -listallhardwareports | awk -F': ' '/Hardware Port/{p=$2} /Device/{print p "|" $2}')
if [ -n "$WIRED" ]; then
    sketchybar --set "$NAME" icon=󰈀 click_script="open 'x-apple.systempreferences:com.apple.Network-Settings.extension'"
elif [ -n "$WIFI" ] && active "$WIFI"; then
    RSSI=$(system_profiler SPAirPortDataType 2>/dev/null | grep -m1 'Signal / Noise' | grep -o -- '-[0-9]*' | head -1)
    RSSI=${RSSI:--70}
    if [ "$RSSI" -ge -55 ]; then ICON=󰤨; elif [ "$RSSI" -ge -65 ]; then ICON=󰤥
    elif [ "$RSSI" -ge -75 ]; then ICON=󰤢; else ICON=󰤟; fi
    sketchybar --set "$NAME" icon=$ICON click_script="open 'x-apple.systempreferences:com.apple.wifi-settings-extension'"
else
    sketchybar --set "$NAME" icon=󰤮 click_script="open 'x-apple.systempreferences:com.apple.Network-Settings.extension'"
fi
