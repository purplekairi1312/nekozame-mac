#!/bin/bash
# nekozame-mac's fonts, asked by setup.sh (run it again any time): all Nerd Fonts, from
# Homebrew, installed when picked. macOS's own interface font can't be changed, so the
# interface font is the bar's (SketchyBar's labels; its icons stay Hack, which they need);
# the code font is Ghostty's. nekozame os asks the same (nekozame-fonts), with the same pictures.
set -euo pipefail
OS=https://raw.githubusercontent.com/purplekairi1312/nekozame-os/main
STATE="$HOME/.config/nekozame/fonts"
PICTURES="$HOME/.local/share/nekozame/fonts"
KITTY="$(cd "$(dirname "$0")/.." && pwd)/bin/kitty-logo"

pink() { gum style --foreground "#ffc0e5" --bold "$*"; }
ok() { echo "  ✓ $*"; }
picture() {  # picture FILE: in the terminal where it draws pictures, or where it is
    local rows
    if [ -x "$KITTY" ] && "$KITTY" --probe 2>/dev/null && rows=$("$KITTY" "$1" 60 2>/dev/null | cut -d" " -f1) && [ -f "$rows" ]; then
        cat "$rows"; echo
    else
        echo "  Picture of each font: $1"
    fi
}
cask_of() {  # the Homebrew cask for a font
    case "$1" in
        opendyslexic) echo font-opendyslexic-nerd-font ;; jetbrains) echo font-jetbrains-mono-nerd-font ;;
        firacode) echo font-fira-code-nerd-font ;; hack) echo font-hack-nerd-font ;;
    esac
}
code_family() {
    case "$1" in
        jetbrains) echo "JetBrainsMono Nerd Font Mono" ;; firacode) echo "FiraCode Nerd Font Mono" ;;
        hack) echo "Hack Nerd Font Mono" ;; opendyslexic) echo "OpenDyslexicM Nerd Font Mono" ;;
    esac
}

mkdir -p "$PICTURES"
for p in interface code; do
    curl -fsSL -o "$PICTURES/$p.png" "$OS/system_files/usr/share/nekozame-os/fonts/$p.png" 2>/dev/null || true
done
now_ui=system now_code=jetbrains
[ -f "$STATE" ] && . <(grep -E '^(interface|code)=[a-z]+$' "$STATE" | sed 's/^interface=/now_ui=/; s/^code=/now_code=/')

echo; pink "▸ The bar's font (macOS's own can't be changed)"
picture "$PICTURES/interface.png"
SYS="System's own (recommended)"; OD="OpenDyslexic"
[ "$now_ui" = opendyslexic ] && sel="$OD" || sel="$SYS"
pick=$(gum choose --header "Which font for the bar?" --selected="$sel" "$SYS" "$OD") || exit 0
ui=system; [ "$pick" = "$OD" ] && ui=opendyslexic

echo; pink "▸ The code font: Ghostty"
picture "$PICTURES/code.png"
JB="JetBrains Mono (recommended)"; FC="FiraCode"; HK="Hack"; ODM="OpenDyslexic Mono"
case "$now_code" in firacode) sel="$FC" ;; hack) sel="$HK" ;; opendyslexic) sel="$ODM" ;; *) sel="$JB" ;; esac
pick=$(gum choose --header "Which font for code?" --selected="$sel" "$JB" "$FC" "$HK" "$ODM") || exit 0
case "$pick" in "$FC") code=firacode ;; "$HK") code=hack ;; "$ODM") code=opendyslexic ;; *) code=jetbrains ;; esac

for f in $(printf '%s\n' "$code" "$([ "$ui" = system ] || echo "$ui")" hack | sort -u); do
    brew list --cask "$(cask_of "$f")" >/dev/null 2>&1 || brew install --cask "$(cask_of "$f")"
done
# ghostty: its font-family line, the rest of its config as it was (backed up once)
g="$HOME/.config/ghostty/config" family="$(code_family "$code")"
mkdir -p "$(dirname "$g")"
if [ -f "$g" ]; then
    [ -f "$g.before-nekozame-fonts" ] || cp "$g" "$g.before-nekozame-fonts"
    if grep -q '^font-family' "$g"; then
        sed -i '' "s|^font-family.*|font-family = \"$family\"|" "$g"
    else
        printf 'font-family = "%s"\n' "$family" >> "$g"
    fi
else
    printf 'font-family = "%s"\n' "$family" > "$g"
fi
mkdir -p "$(dirname "$STATE")" && printf 'interface=%s\ncode=%s\n' "$ui" "$code" > "$STATE"
sketchybar --reload >/dev/null 2>&1 || true
ok "the bar: $( [ "$ui" = system ] && echo "Hack, as before" || echo "OpenDyslexic" ); Ghostty: $family (open windows: once reopened)"
