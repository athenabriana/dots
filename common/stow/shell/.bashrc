# ~/.bashrc — bash interactive-shell wiring (stowed from Dots/common/stow/shell).
#
# POSIX-shared config lives in ~/.config/shell/*.sh and is sourced
# below; only bash-specific code (tool inits, readline keybinds) lives
# in this file.
# shellcheck source=/dev/null

# Re-entry guard: harmless to source twice, but skip the work.
[ -n "${DOTS_BASHRC_RAN:-}" ] && return 0
DOTS_BASHRC_RAN=1

# ── Shared POSIX modules (PATH, EDITOR, aliases, mise shims) ──────────
_dots_modules="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
if [ -d "$_dots_modules" ]; then
    for _f in "$_dots_modules"/*.sh; do
        [ -r "$_f" ] && . "$_f"
    done
    unset _f
fi
unset _dots_modules

# ── Tool inits (bash-specific eval/source) ──────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash --disable-up-arrow)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
if command -v mise >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(mise activate bash)"
fi
command -v fzf >/dev/null 2>&1 && source <(fzf --bash)
command -v carapace >/dev/null 2>&1 && source <(carapace _carapace bash)

# ── Ctrl-P — fzf quick-open: pick a file, open in $VISUAL/$EDITOR ─────
# `[[ $- == *i* ]]` guards: `bind -x` needs readline, so non-interactive
# shells skip the bind.
if [[ $- == *i* ]] && command -v fzf >/dev/null 2>&1; then
    _dots_fzf_quick_open() {
        local file editor
        if command -v rg >/dev/null 2>&1; then
            file=$(rg --files --hidden --follow --glob '!.git' 2>/dev/null \
                   | fzf --height 40% --reverse --prompt 'Open: ') || return
        else
            file=$(find . -type f -not -path '*/.git/*' 2>/dev/null \
                   | fzf --height 40% --reverse --prompt 'Open: ') || return
        fi
        editor="${VISUAL:-${EDITOR:-}}"
        [ -z "$editor" ] && editor='vi'
        eval "$editor \"\$file\""
    }
    bind -x '"\C-p": _dots_fzf_quick_open'
fi

# ── Alt-S — toggle `sudo ` prefix on current line ─────────────────────
if [[ $- == *i* ]]; then
    _dots_toggle_sudo() {
        if [[ "$READLINE_LINE" == sudo\ * ]]; then
            READLINE_LINE="${READLINE_LINE#sudo }"
            READLINE_POINT=$((READLINE_POINT - 5))
            (( READLINE_POINT < 0 )) && READLINE_POINT=0
        else
            READLINE_LINE="sudo $READLINE_LINE"
            READLINE_POINT=$((READLINE_POINT + 5))
        fi
    }
    bind -x '"\eS": _dots_toggle_sudo'
fi

# ── Alt-T — attach/create tmux session (like `t`, but only outside tmux) ─
# Inside tmux, Alt+t is consumed by tmux (new-window). Outside tmux, this
# creates/attaches to a session named after the parent-child dir pair.
if [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
    _dots_tmux_attach_or_create() {
        [[ -z "${TMUX:-}" ]] || return
        t
    }
    bind -x '"\et": _dots_tmux_attach_or_create'
fi

# ── Ctrl-G — fzf git branch picker → checkout ─────────────────────────
if [[ $- == *i* ]] && command -v fzf >/dev/null 2>&1; then
    _dots_fzf_git_checkout() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
        local branch
        branch=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ 2>/dev/null \
                 | sed 's|^origin/||' | awk '!seen[$0]++' \
                 | fzf --height 40% --reverse --prompt 'Checkout: ') || return
        [ -z "$branch" ] && return
        git checkout "$branch"
    }
    bind -x '"\C-g": _dots_fzf_git_checkout'
fi
