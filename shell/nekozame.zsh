# nekozame-mac, for zsh (setup.sh adds a line sourcing this to ~/.zshrc)

# the editor: doom emacs through its always-running daemon, or the one you picked
if [ -s "$HOME/.config/nekozame/editor" ]; then
    export EDITOR="$(cat "$HOME/.config/nekozame/editor")"
else
    export EDITOR="emacsclient -t -a ''"
fi
export VISUAL="$EDITOR"

# fastfetch outside ghostty/kitty: the text logo
if [[ "$TERM" != *ghostty* && "$TERM" != *kitty* ]]; then
    alias fastfetch='fastfetch --logo-type file-raw --logo ~/.local/share/nekozame/fastfetch/logo-color.txt --logo-width 34 --logo-height 16'
fi
