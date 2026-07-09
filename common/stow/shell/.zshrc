# ~/.zshrc — zsh interactive-shell wiring (stowed from Dots/common/stow/shell).
#
# POSIX-shared config lives in ~/.config/shell/*.sh and is sourced
# below; only zsh-specific code (compinit, tool inits, ZLE keybinds,
# zsh plugins) lives in this file.

# ── Shared POSIX modules (PATH, EDITOR, aliases, mise shims) ──────────
_dots_modules="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
if [ -d "$_dots_modules" ]; then
    for _f in "$_dots_modules"/*.sh; do
        [ -r "$_f" ] && . "$_f"
    done
    unset _f
fi
unset _dots_modules

# ── History — zsh's own file feeds zsh-autosuggestions; atuin owns ^R ──
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[ -d "${HISTFILE:h}" ] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks

# ── compinit — must run before the tool inits below: their `init zsh`
# output emits `compdef …` lines that need compinit loaded. `-u` skips
# the group-writable-dir security prompt; `-d` keeps .zcompdump out of
# $HOME. Full $fpath scan at most once a day; -C trusts the dump after.
autoload -Uz compinit
_dots_zdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
if [[ -n $_dots_zdump(#qN.mh-24) ]]; then
    compinit -C -u -d "$_dots_zdump"
else
    mkdir -p "${_dots_zdump:h}"
    compinit -u -d "$_dots_zdump"
fi
unset _dots_zdump

# ── Tool inits (zsh-specific eval/source) ──────────────────────────────
# Each `tool init zsh` emits a static script, but spawning the tool to
# get it costs ~50-100ms; at ~8 tools that dominates startup. Cache the
# output and re-source it; regenerate when the binary is newer than the
# cache (brew/mise upgrade) or when an extra dep file (--dep) changed.
_dots_eval_cached() {
    local dep=""
    [[ "$1" == --dep ]] && { dep="$2"; shift 2; }
    local cmd="$1"; shift
    (( ${+commands[$cmd]} )) || return 0
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init-${cmd}.zsh"
    if [[ ! -s $cache || $cache -ot ${commands[$cmd]} ]] \
       || [[ -n $dep && $cache -ot $dep ]]; then
        mkdir -p "${cache:h}"
        "$cmd" "$@" >| "$cache" 2>/dev/null
        zcompile "$cache" 2>/dev/null
    fi
    source "$cache"
}

_dots_eval_cached starship init zsh
# fzf BEFORE atuin: both bind ^R, last one wins. fzf keeps ^T (file
# picker) and Alt-C (cd); atuin takes ^R (it disables up-arrow itself).
_dots_eval_cached fzf --zsh
_dots_eval_cached atuin init zsh --disable-up-arrow
_dots_eval_cached zoxide init zsh
# mise activate is lazy — see the end of this file (needs zsh-defer,
# which sheldon loads).
# carapace — 839+ CLI completions; needs compinit (above).
# Must load before zsh-syntax-highlighting (last rule).
_dots_eval_cached carapace _carapace zsh

# ── Ctrl-P — fzf quick-open: pick a file, open in $VISUAL/$EDITOR ─────
if (( ${+commands[fzf]} )); then
    _dots_fzf_quick_open() {
        local file editor
        if (( ${+commands[rg]} )); then
            file=$(rg --files --hidden --follow --glob '!.git' 2>/dev/null \
                   | fzf --height 40% --reverse --prompt 'Open: ')
        else
            file=$(find . -type f -not -path '*/.git/*' 2>/dev/null \
                   | fzf --height 40% --reverse --prompt 'Open: ')
        fi
        [[ -z "$file" ]] && return
        editor="${VISUAL:-${EDITOR:-vi}}"
        eval "$editor \"\$file\""
        zle reset-prompt 2>/dev/null
    }
    zle -N _dots_fzf_quick_open
    bindkey '^P' _dots_fzf_quick_open
fi

# ── Alt-S — toggle `sudo ` prefix on current line ─────────────────────
_dots_toggle_sudo() {
    if [[ "$BUFFER" == sudo\ * ]]; then
        BUFFER="${BUFFER#sudo }"
        (( CURSOR -= 5 ))
        (( CURSOR < 0 )) && CURSOR=0
    else
        BUFFER="sudo $BUFFER"
        (( CURSOR += 5 ))
    fi
}
zle -N _dots_toggle_sudo
bindkey '^[s' _dots_toggle_sudo

# ── Ctrl-G — fzf git branch picker → checkout ─────────────────────────
if (( ${+commands[fzf]} )); then
    _dots_fzf_git_checkout() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
        local branch
        branch=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ 2>/dev/null \
                 | sed 's|^origin/||' | awk '!seen[$0]++' \
                 | fzf --height 40% --reverse --prompt 'Checkout: ')
        [[ -z "$branch" ]] && return
        git checkout "$branch"
        zle reset-prompt 2>/dev/null
    }
    zle -N _dots_fzf_git_checkout
    bindkey '^G' _dots_fzf_git_checkout
fi

# ── Alt-T — attach/create tmux session (like `t`, but only outside tmux) ─
# Inside tmux, Alt+t is consumed by tmux (new-window). Outside tmux, this
# creates/attaches to a session named after the parent-child dir pair.
if (( ${+commands[tmux]} )); then
    _dots_tmux_attach_or_create() {
        [[ -z "${TMUX:-}" ]] || return
        t
        zle reset-prompt 2>/dev/null
    }
    zle -N _dots_tmux_attach_or_create
    bindkey '^[t' _dots_tmux_attach_or_create
fi

# ── Native completion — zsh's own compsys menu, tuned so it isn't crude ──
zstyle ':completion:*' menu select                 # arrow-navigable menu
# case-insensitive + substring: `dow`→Downloads, `loads`→Downloads.
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format '[%d]'  # group headers
zstyle ':completion:*' group-name ''               # group candidates by type
# LS_COLORS isn't set by default — dircolors provides it (GNU coreutils;
# silently skipped where absent, e.g. stock macOS).
(( ${+commands[dircolors]} )) && [[ -z $LS_COLORS ]] && eval "$(dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' rehash true                 # notice newly-installed binaries
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
setopt COMPLETE_IN_WORD ALWAYS_TO_END              # complete mid-word; cursor to end

# fzf's shell integration (loaded above) grabs Tab for its own fuzzy
# completer; take Tab back for the native menu. fzf keeps ^T (files) and
# Alt-C (cd); ^R is atuin. This also drops fzf's `**<Tab>` trigger.
bindkey '^I' expand-or-complete

# ── Plugins via sheldon (MUST load last) ────────────────────────────────
# Order lives in ~/.config/sheldon/plugins.toml: zsh-autosuggestions, then
# zsh-syntax-highlighting — the latter wraps every ZLE widget that exists at
# source time, so loading at the end covers the widgets defined above. Both
# are deferred to after the first prompt. Plugins are cloned by `dots sync`.

# --dep: `sheldon source` output changes when plugins.toml does, not
# only when the binary does.
_dots_eval_cached --dep "${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml" \
    sheldon source

# ── mise — lazy activate ───────────────────────────────────────────────
# hook-env execs the mise binary (~90ms). Two cuts: zsh-defer moves the
# activation off the first-prompt path, and dropping _mise_hook from
# precmd_functions makes the env refresh on cd (chpwd) instead of every
# prompt. The mise() wrapper from activate still re-runs the hook after
# `mise use`, so nothing needs a manual refresh; `cd .` covers edge cases.
_dots_mise_lazy() {
    _dots_eval_cached mise activate zsh
    precmd_functions=(${precmd_functions:#_mise_hook})
    _mise_hook  # apply env for the directory the shell started in
}
if (( ${+functions[zsh-defer]} )); then
    zsh-defer _dots_mise_lazy
else
    _dots_mise_lazy
fi
