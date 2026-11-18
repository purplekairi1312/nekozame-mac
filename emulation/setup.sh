#!/bin/bash
# nekozame-mac's emulation, asked by setup.sh (off unless you say yes). run it again any time:
# what's done stays done. every part is your choice:
#   where your games are   this Mac (~/Emulation), a network share (a NAS: every machine plays
#                          from the same library), or another folder
#   the emulators          RetroArch, PCSX2, Dolphin, PPSSPP: pick any, from Homebrew
#   your saves             synced with the share by nekozame-saves, like on nekozame os: the
#                          newest wins and nothing is thrown away
# the same layout and settings as nekozame os (its docs/emulation.md has the whole story).
# your own emulator settings are kept: only the folders are set, after a backup.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OS=https://raw.githubusercontent.com/purplekairi1312/nekozame-os/main
CONF="$HOME/.config/nekozame/emulation.json"
SAVES_CONF="$HOME/.config/nekozame/saves.json"
AGENTS="$HOME/Library/LaunchAgents"
PY=/opt/homebrew/bin/python3

pink() { gum style --foreground "#ffc0e5" --bold "$*"; }
step() { echo; pink "▸ $*"; }
ask() { gum confirm --default="${2:-true}" "$1"; }
ok() { echo "  ✓ $*"; }
setting() {  # setting KEY JSON: one key of emulation.json set, the rest kept
    "$PY" - "$CONF" "$1" "$2" <<'EOF'
import json, os, sys
path, key, value = sys.argv[1:]
try:
    s = json.load(open(path))
except (OSError, ValueError):
    s = {}
s[key] = json.loads(value)
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(s, open(path, "w"), indent=2)
EOF
}
current() {  # the library folder already set up, if any
    "$PY" -c 'import json,sys; r=(json.load(open(sys.argv[1])).get("roms") or [""])[0]; print(r[:-5] if r.endswith("/roms") else "")' "$CONF" 2>/dev/null || true
}
agent() {  # agent LABEL INTERVAL COMMAND...: a login agent, run at login and every INTERVAL seconds (0: once)
    local label="$1" every="$2"; shift 2
    local args="" a
    for a in "$@"; do args="$args<string>$a</string>"; done
    mkdir -p "$AGENTS"
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
        echo "<plist version=\"1.0\"><dict><key>Label</key><string>$label</string>"
        echo "<key>ProgramArguments</key><array>$args</array><key>RunAtLoad</key><true/>"
        [ "$every" = 0 ] || echo "<key>StartInterval</key><integer>$every</integer>"
        echo "</dict></plist>"
    } > "$AGENTS/$label.plist"
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    for _ in 1 2 3 4 5; do launchctl bootstrap "gui/$(id -u)" "$AGENTS/$label.plist" 2>/dev/null && break; sleep 1; done
}

step "Your games"
ROOT=$(current)
SHARED=
if [ -n "$ROOT" ] && ! ask "They're in $ROOT. Change that?" false; then
    ok "$ROOT"
    [[ "$ROOT" == /Volumes/* ]] && SHARED=1
else
    LOCAL="On this Mac (~/Emulation)"; NAS="On a network share (a NAS)"; ELSE="In another folder"
    echo "  this Mac: a folder here. a NAS: connected for you, and again at every login (the"
    echo "  best for a NAS). another folder: a second drive, or a share you already connect to"
    case "$(gum choose --header "Where are your games?" --selected="$NAS" "$LOCAL" "$NAS" "$ELSE")" in
        "$LOCAL") ROOT="$HOME/Emulation" ;;
        "$NAS")
            server=$(gum input --header "The NAS (its name or address, e.g. nas.local, or its Tailscale name):")
            share=$(gum input --header "The shared folder with your games:" --value Emulation)
            [ -n "$server" ] && [ -n "$share" ] || exit 1
            ROOT="/Volumes/$share" SHARED=1
            if [ ! -d "$ROOT" ]; then
                echo "  macOS asks for your login on the NAS once: tick \"Remember this password in my keychain\""
                open "smb://$server/$share"
                for _ in $(seq 120); do [ -d "$ROOT" ] && break; sleep 1; done
                [ -d "$ROOT" ] || { echo "  the share didn't open: check the name and the login, then run this again"; exit 1; }
            fi
            # mounted again at every login, with the login from the keychain
            agent com.nekozame.emulation-share 0 /usr/bin/osascript -e "mount volume \"smb://$server/$share\""
            ok "$ROOT, mounted at every login"
            ;;
        "$ELSE") ROOT=$(gum input --header "The folder that holds roms/, bios/... (the layout ES-DE and EmuDeck use):") ;;
        *) exit 0 ;;
    esac
    mkdir -p "$ROOT/roms" "$ROOT/bios" "$ROOT/saves" 2>/dev/null || true
    setting roms "[\"$ROOT/roms\"]"
    setting bios "\"$ROOT/bios\""
    ok "$ROOT: one folder per system in roms/ (psx, snes, megadrivejp...)"
fi

step "Emulators"
have="" want=""  # (bash 3.2: lines, not arrays)
for c in "retroarch-metal:RetroArch" "pcsx2:PCSX2" "dolphin:Dolphin" "ppsspp-emulator:PPSSPP"; do
    if [ -d "/Applications/${c#*:}.app" ]; then have="$have ${c#*:}"; else want="$want${c#*:} (${c%%:*})
"; fi
done
[ -z "$have" ] || ok "here already:$have"
if [ -n "$want" ]; then
    printf '%s' "$want" | gum choose --no-limit --header "Install (space to pick, enter when done; none is fine):" |
        while read -r e; do
            [ -n "$e" ] || continue
            cask="${e##*(}"; brew install --cask "${cask%)}" || true
        done
fi
"$PY" "$HERE/configure.py" "$ROOT"

step "Your saves"
if [ -s "$SAVES_CONF" ]; then
    ok "syncing (where to: nekozame-saves setup)"
elif [ -n "$SHARED" ] && ask "Sync your saves with $ROOT/saves, like your other machines? (the newest wins, nothing thrown away)"; then
    curl -fsSL -o "$HOME/.local/bin/nekozame-saves" "$OS/system_files/usr/bin/nekozame-saves"
    chmod +x "$HOME/.local/bin/nekozame-saves"
    printf '{\n  "remote": {"type": "folder", "path": "%s/saves"}\n}\n' "$ROOT" > "$SAVES_CONF"
    chmod 600 "$SAVES_CONF"
    ok "saves: $ROOT/saves"
fi
if [ -s "$SAVES_CONF" ]; then
    # updated with the rest; every 10 minutes, but never while an emulator is open
    curl -fsSL -o "$HOME/.local/bin/nekozame-saves" "$OS/system_files/usr/bin/nekozame-saves" &&
        chmod +x "$HOME/.local/bin/nekozame-saves"
    agent com.nekozame.saves 600 /bin/sh -c \
        "pgrep -xq 'RetroArch|PCSX2|Dolphin|PPSSPP' || $PY $HOME/.local/bin/nekozame-saves sync"
    ok "synced every 10 minutes while no emulator is open (now: nekozame-saves sync)"
fi
echo "  RetroArch's own saves: its Cloud Sync (Settings → Saving), the same server as on your other machines"
