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

# tab titles: the folder at the prompt, the command while it runs (without one,
# ghostty shows its placeholder ghost)
_nekozame_title_dir() { print -Pn "\e]2;%~\a" }
_nekozame_title_cmd() { print -n "\e]2;${1:0:40}\a" }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _nekozame_title_dir
add-zsh-hook preexec _nekozame_title_cmd
