# 45-title.sh — set terminal window title to cwd on each prompt.
#
# Emits OSC 2 (xterm "set window title") with `~` collapsed for $HOME
# so ghostty's tab label reflects what directory the shell is in
# instead of the generic "Ghostty" default.
#
# When running inside tmux, this OSC is consumed by tmux (pane title)
# and the outer ghostty title comes from `set-titles-string` in
# tmux.conf instead ("tmux · <session> · <window>"). So the two
# behaviors don't conflict: tmux owns the title when attached; the
# shell owns it otherwise.

if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook
    _silverfox_set_title() { print -Pn '\e]2;%~\a'; }
    add-zsh-hook precmd _silverfox_set_title
elif [ -n "${BASH_VERSION:-}" ]; then
    case "${PROMPT_COMMAND:-}" in
        *_silverfox_set_title*) ;;
        *)
            _silverfox_set_title() {
                printf '\e]2;%s\a' "${PWD/#$HOME/~}"
            }
            PROMPT_COMMAND='_silverfox_set_title;'"${PROMPT_COMMAND:-}"
            ;;
    esac
fi
