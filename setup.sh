#!/bin/bash
# nekozame-mac setup. run it again any
# time: what's done stays done, and it updates what it installed.
#   on for everyone: AeroSpace and the shortcuts, the bar, the catshark
#   wallpaper, the nekozame theme, Zen with the privacy extensions, Doom Emacs as
#   $EDITOR, fastfetch, Tailscale and Moonlight
#   asked: evil mode or another editor, music production, Helium
# your own configs are kept: where you have one, nekozame's isn't put in its place.
# (macOS's bash is 3.2: nothing newer in here)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SHARE="$HOME/.local/share/nekozame"
OS=https://raw.githubusercontent.com/purplekairi1312/nekozame-os/main
THEME=https://raw.githubusercontent.com/purplekairi1312/nekozame-theme/main/themes
# renovate: datasource=git-refs depName=https://github.com/mogenson/PaperWM.spoon
PAPERWM=630411e7f1401fa124cc5fe7cad3ee562e328624
mkdir -p "$SHARE" "$HOME/.local/bin" "$HOME/.config"

command -v brew >/dev/null || { echo "install homebrew first: https://brew.sh" >&2; exit 1; }
echo "installing what nekozame-mac uses (brew bundle)..."
# newer homebrew only installs from taps you trust: sketchybar's, emacs-plus's, aerospace's
for t in felixkratz/formulae d12frosted/emacs-plus nikitabobko/tap; do
    brew tap -q "$t"
    brew trust "$t" 2>/dev/null || true  # (older homebrew has no trust: nothing to do)
done
brew bundle --file="$HERE/Brewfile"

pink() { gum style --foreground "#ffc0e5" --bold "$*"; }
step() { echo; pink "▸ $*"; }
ask() { gum confirm --default="${2:-true}" "$1"; }
ok() { echo "  ✓ $*"; }
# link FILE into place unless something else is there already: a file, or a
# link of your own (dotfiles), stays. only links nekozame made are replaced
place() {  # place SOURCE TARGET
    local now; now=$(readlink "$2" 2>/dev/null || true)
    if [ ! -e "$2" ] && [ ! -L "$2" ] || [[ "$now" == "$SHARE"* || "$now" == "$HERE"* ]]; then
        mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; ok "${2/#$HOME/~}"
    else echo "  · ${2/#$HOME/~} is yours, kept"; fi
}
fetch() { curl -fsSL -o "$2" "$1"; }  # fetch URL FILE

gum style --border rounded --border-foreground "#ffc0e5" --padding "0 2" \
    "nekozame-mac 🦈" "" "the defaults are already picked: press enter to keep them."

step "Windows: AeroSpace"
mkdir -p "$HOME/.config/nekozame"
[ -s "$HOME/.config/nekozame/wm" ] || echo aerospace > "$HOME/.config/nekozame/wm"
place "$HERE/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
# one set of spaces across screens: what aerospace works best with (from the next login)
defaults write com.apple.spaces spans-displays -bool true
# Ctrl+Cmd+drag moves a window from anywhere on it, not just the title bar
defaults write -g NSWindowShouldDragOnGesture -bool true
open -g -a AeroSpace
# PaperWM (scrolling tiling) is ready for when hammerspoon reads macOS 27's spaces

if [ -d "$HOME/.hammerspoon/Spoons/PaperWM.spoon/.git" ]; then
    git -C "$HOME/.hammerspoon/Spoons/PaperWM.spoon" fetch -q origin
else
    git clone -q https://github.com/mogenson/PaperWM.spoon "$HOME/.hammerspoon/Spoons/PaperWM.spoon"
fi
git -C "$HOME/.hammerspoon/Spoons/PaperWM.spoon" checkout -q "$PAPERWM"
if [ ! -e "$HOME/.hammerspoon/init.lua" ]; then
    # yours to add to: nekozame's part is loaded from here
    printf -- '-- nekozame-mac: the shortcuts. add your own below.\ndofile("%s/hammerspoon/init.lua")\n' "$HERE" \
        > "$HOME/.hammerspoon/init.lua"
    ok "~/.hammerspoon/init.lua"
else
    grep -q "nekozame-mac" "$HOME/.hammerspoon/init.lua" && ok "~/.hammerspoon/init.lua" \
        || echo "  · ~/.hammerspoon/init.lua is yours: add  dofile(\"$HERE/hammerspoon/init.lua\")  to it"
fi
# PaperWM needs spaces to stay in order (macOS reorders them by recent use otherwise)
defaults write com.apple.dock mru-spaces -bool false && killall Dock
defaults write org.hammerspoon.Hammerspoon MJShowMenuIconKey -bool false
open -g -a Hammerspoon
echo "  Hammerspoon needs Accessibility: System Settings → Privacy & Security → Accessibility"

step "The bar (SketchyBar), over the macOS menu bar"
place "$HERE/sketchybar" "$HOME/.config/sketchybar"
# the menu bar stays shown and the bar covers it: hidden, it would pop out (and back)
# at the top edge
osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to false' >/dev/null
brew services restart sketchybar >/dev/null && ok "running"

step "cava on the bar"
"$HERE/cava/install.sh"
ok "it reads a copy of what's playing: your audio isn't changed. allow it once when macOS asks"

step "The catshark wallpaper"
swiftc -O -suppress-warnings -o "$HOME/.local/bin/nekozame-wallpaper" "$HERE/wallpaper/main.swift"
# the loop closest to the main screen's shape, in a format macOS plays: prores
# 4444 keeps every pixel of the pixel art
read -r W H < <(osascript -l JavaScript -e 'ObjC.import("AppKit"); var f = $.NSScreen.mainScreen.frame; var s = $.NSScreen.mainScreen.backingScaleFactor; (f.size.width*s) + " " + (f.size.height*s)')
best=$(python3 -c "
r = $W / $H
a = {'21x9': 21/9, '32x9': 32/9, '16x9': 16/9, '16x10': 16/10, '3x2': 3/2, '4x3': 4/3, '5x4': 5/4}
print(min(a, key=lambda k: abs(a[k] - r)))")
VARIANT=$(gum choose --header "Wallpaper: the nekozame logo on it, small, big or none (just the catshark)" --selected=small small big none)
tmp=$(mktemp -d)
fetch "$OS/system_files/usr/share/backgrounds/nekozame/$VARIANT-$best.mkv" "$tmp/loop.mkv"
ffmpeg -v error -y -i "$tmp/loop.mkv" -c:v prores_ks -profile:v 4444 -pix_fmt yuv444p10le -vendor apl0 "$SHARE/wallpaper.mov"
rm -rf "$tmp"
AGENT="$HOME/Library/LaunchAgents/com.nekozame.wallpaper.plist"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nekozame.wallpaper</string>
  <key>ProgramArguments</key><array><string>$HOME/.local/bin/nekozame-wallpaper</string><string>$SHARE/wallpaper.mov</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
PLIST
launchctl bootout "gui/$(id -u)/com.nekozame.wallpaper" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT" && ok "$VARIANT, $best (a ${W%.*}x${H%.*} screen)"

step "The nekozame theme"
mkdir -p "$SHARE/theme"
fetch "$THEME/ghostty/nekozame" "$SHARE/theme/ghostty"
fetch "$THEME/cava/config" "$SHARE/theme/cava"
fetch "$THEME/emacs/nekozame-theme.el" "$SHARE/theme/nekozame-theme.el"
fetch "$THEME/btop/nekozame.theme" "$SHARE/theme/btop.theme"
fetch "$OS/system_files/usr/share/nekozame-os/emacs/banner.png" "$SHARE/theme/banner.png"
mkdir -p "$SHARE/theme/zen" "$SHARE/theme/web"
fetch "$THEME/zen/userChrome.css" "$SHARE/theme/zen/userChrome.css"
fetch "$THEME/zen/userContent.css" "$SHARE/theme/zen/userContent.css"
fetch "$THEME/darkreader/nekozame.json" "$SHARE/theme/web/nekozame-darkreader.json"
fetch "$THEME/improvedtube/nekozame.json" "$SHARE/theme/web/nekozame-improvedtube.json"
place "$SHARE/theme/ghostty" "$HOME/.config/ghostty/themes/nekozame"
# cmd+t: a new window instead of a tab (windows tile; macOS's native tabs don't)
[ -e "$HOME/.config/ghostty/config" ] || printf 'theme = nekozame\nfont-family = Hack Nerd Font\nkeybind = cmd+t=new_window\n' > "$HOME/.config/ghostty/config"
place "$SHARE/theme/cava" "$HOME/.config/cava/config"
place "$SHARE/theme/btop.theme" "$HOME/.config/btop/themes/nekozame.theme"

step "fastfetch, with the bubble logo"
mkdir -p "$SHARE/fastfetch"
fetch "$OS/system_files/usr/share/nekozame-os/fastfetch/logo.png" "$SHARE/fastfetch/logo.png"
fetch "$OS/system_files/usr/share/nekozame-os/fastfetch/logo-color.txt" "$SHARE/fastfetch/logo-color.txt"
sed "s|@SHARE@|$SHARE|g" "$HERE/fastfetch/config.jsonc" > "$SHARE/fastfetch/config.jsonc"
place "$SHARE/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

step "Zen, ready for privacy"
# nekozame's privacy settings, as zen's macOS preferences (it reads its
# policies from there). merged in: zen's other preferences stay
pol=$(mktemp)
fetch "$OS/system_files/usr/share/nekozame-os/zen/policies/policies.json" "$pol"
defaults export app.zen-browser.zen "$pol.old" 2>/dev/null || rm -f "$pol.old"
python3 - "$pol" <<'PY'
import json, os, plistlib, sys
p = sys.argv[1]
prefs = plistlib.load(open(p + ".old", "rb")) if os.path.exists(p + ".old") else {}
prefs.update(json.load(open(p))["policies"])
prefs["EnterprisePoliciesEnabled"] = True
plistlib.dump(prefs, open(p + ".plist", "wb"))
PY
defaults import app.zen-browser.zen "$pol.plist" && rm -f "$pol" "$pol.old" "$pol.plist"
ok "dark reader, ublock origin, privacy badger, libredirect, clearurls, consent-o-matic, duckduckgo, https-only"
# the nekozame look: see-through toolbars, and pages in nekozame (with dark
# reader; github and youtube in their own colours). zen makes its profile on
# its first start: run this again after that if there's none yet
found=""
for prof in "$HOME/Library/Application Support/zen/Profiles"/*/; do
    [ -f "$prof/prefs.js" ] || continue
    found=1
    place "$SHARE/theme/zen/userChrome.css" "$prof/chrome/userChrome.css"
    place "$SHARE/theme/zen/userContent.css" "$prof/chrome/userContent.css"
    for pref in toolkit.legacyUserProfileCustomizations.stylesheets browser.tabs.allow_transparent_browser; do
        grep -qs "\"$pref\"" "$prof/user.js" || echo "user_pref(\"$pref\", true);" >> "$prof/user.js"
    done
done
[ -n "$found" ] || echo "  · open Zen once, then run this again for the nekozame look"
# dark reader and improvedtube only take their settings from an import
cp "$SHARE/theme/web/"*.json "$HOME/Downloads/"
echo "  in Zen, import from ~/Downloads (just once):"
echo "    Dark Reader: Settings → Advanced → Import Settings → nekozame-darkreader.json"
echo "    ImprovedTube (YouTube): Settings → Backup & Reset → Import settings → nekozame-improvedtube.json"

step "Editor: Doom Emacs"
mkdir -p "$HOME/.config/nekozame"
if [ -x "$HOME/.config/emacs/bin/doom" ]; then
    ok "doom emacs"
elif [ -s "$HOME/.config/nekozame/editor" ]; then
    ok "$(cat "$HOME/.config/nekozame/editor")"
else
    DOOM="Doom Emacs (emacs keys)"; EVIL="Doom Emacs with evil mode (vim keys)"; OWN="Another editor"
    choice=$(gum choose --header "Your editor (\$EDITOR):" --selected="$DOOM" "$DOOM" "$EVIL" "$OWN")
    case "$choice" in
        "$OWN")
            pick=$(gum choose --header "Which one?" neovim helix micro nano "something else")
            case "$pick" in
                neovim) brew install neovim; echo nvim > "$HOME/.config/nekozame/editor" ;;
                helix) brew install helix; echo hx > "$HOME/.config/nekozame/editor" ;;
                micro) brew install micro; echo micro > "$HOME/.config/nekozame/editor" ;;
                nano) echo nano > "$HOME/.config/nekozame/editor" ;;
                *) gum input --placeholder "the command" > "$HOME/.config/nekozame/editor" ;;
            esac ;;
        *)
            if [ "$choice" = "$EVIL" ]; then evil=on; else evil=off; fi
            fresh=""; [ -e "$HOME/.config/doom" ] || fresh=1
            git clone -q --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
            "$HOME/.config/emacs/bin/doom" install --force
            if [ -n "$fresh" ]; then
                sed -i '' "s|^(setq doom-theme 'doom-one)|(add-to-list 'custom-theme-load-path \"$SHARE/theme/\")\\
(setq doom-theme 'nekozame)\\
(setq fancy-splash-image \"$SHARE/theme/banner.png\")|" "$HOME/.config/doom/config.el"
                [ "$evil" = on ] || sed -i '' 's/^\( *\)(evil +everywhere)/\1;;(evil +everywhere)/' "$HOME/.config/doom/init.el"
                "$HOME/.config/emacs/bin/doom" sync
            fi
            ok "doom emacs (evil $evil)" ;;
    esac
fi
# the emacs daemon, always running, so emacsclient opens instantly
if [ ! -s "$HOME/.config/nekozame/editor" ] && ! launchctl list | grep -q -E 'emacs'; then
    cat > "$HOME/Library/LaunchAgents/com.nekozame.emacs.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nekozame.emacs</string>
  <key>ProgramArguments</key><array><string>/Applications/Emacs.app/Contents/MacOS/Emacs</string><string>--fg-daemon</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
PLIST
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.nekozame.emacs.plist"
fi
cp "$HERE/shell/nekozame.zsh" "$HOME/.config/nekozame/nekozame.zsh"
if ! grep -q "nekozame/nekozame.zsh" "$HOME/.zshrc" 2>/dev/null; then
    echo '[ -f ~/.config/nekozame/nekozame.zsh ] && source ~/.config/nekozame/nekozame.zsh' >> "$HOME/.zshrc"
fi
ok "\$EDITOR, fastfetch and cava set up in zsh"

step "Tailscale and Moonlight"
ok "installed (open Tailscale to log in)"

step "Music production"
if ask "Set up music production? (DAWs and free plugins)" false; then
    gum choose --no-limit --header "Pick (space), then enter:" \
        "bitwig-studio (proprietary · paid)" "reaper (proprietary · paid · free evaluation)" \
        "lmms (free software)" "surge-xt (free software synth)" "dexed (free software FM synth)" \
        "cardinal (free software modular)" "vcv-rack (free software modular)" \
        "iem-plugin-suite (free software spatial audio)" "blackhole-2ch (free software: route audio between apps)" \
        | while read -r p; do [ -n "$p" ] && { brew install --cask "${p%% *}" || true; }; done
fi

step "Helium (a second browser, optional)"
if ask "Install Helium? It gets the same extensions and settings as Zen" false; then
    # a Helium you installed yourself is used as it is
    [ -d /Applications/Helium.app ] || brew install --cask helium-browser
    # chromium on macOS only takes forced settings from a profile you approve
    python3 "$HERE/helium/profile.py" "$OS/system_files/etc/chromium/policies/managed/nekozame.json" "$SHARE/nekozame-helium.mobileconfig"
    open "$SHARE/nekozame-helium.mobileconfig"
    echo "  approve it in System Settings → General → Device Management (Profiles)"
fi

echo; pink "all set <3"
echo "  Option+Shift+/ shows the shortcuts. log out and back in once for everything."
