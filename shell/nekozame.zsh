# nekozame-mac, for zsh (setup.sh adds a line sourcing this to ~/.zshrc)

# the editor: doom emacs through its always-running daemon, or the one you picked
if [ -s "$HOME/.config/nekozame/editor" ]; then
    export EDITOR="$(cat "$HOME/.config/nekozame/editor")"
else
    export EDITOR="emacsclient -t -a ''"
fi
export VISUAL="$EDITOR"

# fastfetch: the logo as text with the picture tied to it (kitty-logo), so in tmux
# it stays with its tab. your own logo: NEKOZAME_FETCH_LOGO (a png) and
# NEKOZAME_FETCH_WIDTH (columns). outside ghostty/kitty: the text logo
fastfetch() {
    local logo=${NEKOZAME_FETCH_LOGO:-$HOME/.local/share/nekozame/fastfetch/logo.png} l
    local term=$TERM
    [[ -n $TMUX ]] && term=$(tmux display -p '#{client_termname}' 2>/dev/null)
    if [[ $term == *ghostty* || $term == *kitty* ]] && [[ -f $logo ]] \
        && l=($("$HOME/.local/share/nekozame-mac/bin/kitty-logo" "$logo" ${NEKOZAME_FETCH_WIDTH:-30} 2>/dev/null)); then
        command fastfetch --logo-type file-raw --logo "$l[1]" --logo-width "$l[2]" --logo-height "$l[3]" \
            --logo-padding-top 1 --logo-padding-right 2 "$@"
    else
        command fastfetch --logo-type file-raw --logo "$HOME/.local/share/nekozame/fastfetch/logo-color.txt" \
            --logo-width 34 --logo-height 16 "$@"
    fi
}

# tab titles: the folder at the prompt, the command while it runs (without one,
# ghostty shows its placeholder ghost)
_nekozame_title_dir() { print -Pn "\e]2;%~\a" }
_nekozame_title_cmd() { print -n "\e]2;${1:0:40}\a" }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _nekozame_title_dir
add-zsh-hook preexec _nekozame_title_cmd
