# ~/.zshrc — silverfox zsh interactive-shell wiring.
#
# Stow package from Dotfiles/shell/.zshrc — to customize, replace the
# symlink with a real file and edit. The skel merge (profile.d) copies
# new defaults from /etc/skel on every login.
#
# POSIX-shared config lives in ~/.config/shell/*.sh and is sourced
# below; only zsh-specific code (compinit, tool inits, ZLE keybinds,
# zsh plugins) lives in this file.

# ── Shared POSIX modules (PATH, EDITOR, NH_HOME_FLAKE, aliases, mise shims) ─
_silverfox_modules="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
if [ -d "$_silverfox_modules" ]; then
    for _f in "$_silverfox_modules"/*.sh; do
        [ -r "$_f" ] && . "$_f"
    done
    unset _f
fi
unset _silverfox_modules

# ── compinit — load completion system before tool inits ────────────────
# atuin, zoxide, mise, fzf, and carapace each emit `compdef …` lines
# from their `init zsh` output. Those run at source-time and need
# `compdef` already defined, which only happens after `compinit` runs.
#
# `-u` skips the security check on group-writable completion dirs
# (rpm-ostree's /usr is read-only and group-owned, which compinit
# otherwise flags interactively). `-d` pins the dump file under
# $XDG_CACHE_HOME so we don't litter $HOME with .zcompdump.
autoload -Uz compinit
compinit -u -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

# ── Tool inits (zsh-specific eval/source) ──────────────────────────────
(( ${+commands[starship]} )) && eval "$(starship init zsh)"
# fzf BEFORE atuin: both bind ^R, last one wins. fzf keeps ^T (file
# picker) and Alt-C (cd); atuin takes ^R (it disables up-arrow itself).
(( ${+commands[fzf]} )) && source <(fzf --zsh)
(( ${+commands[atuin]} )) && eval "$(atuin init zsh --disable-up-arrow)"
(( ${+commands[zoxide]} )) && eval "$(zoxide init zsh)"
if (( ${+commands[mise]} )) && [[ -o interactive ]]; then
    eval "$(mise activate zsh)"
fi
# carapace — 839+ CLI completions; needs compinit (above).
# Must load before zsh-syntax-highlighting (last rule).
(( ${+commands[carapace]} )) && source <(carapace _carapace zsh)

# ── Ctrl-P — VS-Code-style fzf quick-open ──────────────────────────────
# zsh's ZLE (line editor) is the equivalent of bash's readline.
# `zle -N` registers a widget; `bindkey '^P'` binds Ctrl-P.
if (( ${+commands[fzf]} )); then
    _silverfox_fzf_quick_open() {
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
    zle -N _silverfox_fzf_quick_open
    bindkey '^P' _silverfox_fzf_quick_open
fi

# ── Alt-S — toggle `sudo ` prefix on current line ─────────────────────
# BUFFER / CURSOR are zsh's editable-line variables (equivalent of
# bash's READLINE_LINE / READLINE_POINT).
_silverfox_toggle_sudo() {
    if [[ "$BUFFER" == sudo\ * ]]; then
        BUFFER="${BUFFER#sudo }"
        (( CURSOR -= 5 ))
        (( CURSOR < 0 )) && CURSOR=0
    else
        BUFFER="sudo $BUFFER"
        (( CURSOR += 5 ))
    fi
}
zle -N _silverfox_toggle_sudo
bindkey '^[s' _silverfox_toggle_sudo  # ^[ = ESC = Alt prefix; s = lowercase

# ── Ctrl-G — fzf git branch picker → checkout ─────────────────────────
if (( ${+commands[fzf]} )); then
    _silverfox_fzf_git_checkout() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
        local branch
        branch=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ 2>/dev/null \
                 | sed 's|^origin/||' | awk '!seen[$0]++' \
                 | fzf --height 40% --reverse --prompt 'Checkout: ')
        [[ -z "$branch" ]] && return
        git checkout "$branch"
        zle reset-prompt 2>/dev/null
    }
    zle -N _silverfox_fzf_git_checkout
    bindkey '^G' _silverfox_fzf_git_checkout
fi

# ── Alt-T — attach/create tmux session (like `t`, but only outside tmux) ─
# Inside tmux, Alt+t is consumed by tmux (new-window). Outside tmux, this
# creates/attaches to a session named after the parent-child dir pair.
if (( ${+commands[tmux]} )); then
    _silverfox_tmux_attach_or_create() {
        [[ -z "${TMUX:-}" ]] || return
        t
        zle reset-prompt 2>/dev/null
    }
    zle -N _silverfox_tmux_attach_or_create
    bindkey '^[t' _silverfox_tmux_attach_or_create
fi

# ── Plugins via sheldon (MUST load last) ────────────────────────────────
# fzf-tab (Tab → fzf picker over compsys candidates), then
# zsh-autosuggestions (greyed-out history completion; → / End to accept),
# then zsh-syntax-highlighting (invalid commands red, paths blue, …), in
# that order — see ~/.config/sheldon/plugins.toml. syntax-highlighting
# wraps every existing ZLE widget at source time, so sourcing here at the
# end means the Ctrl-P / Alt-S / Ctrl-G widgets above also get colored.
# sheldon comes from mise; plugins are cloned by `dots sync`.

# fzf-tab tuning (zstyles read when the plugin loads below):
zstyle ':completion:*' menu no                     # hand the menu to fzf-tab
zstyle ':completion:*:descriptions' format '[%d]'  # group headers in the picker
# LS_COLORS isn't set by default — dircolors provides it (GNU coreutils;
# silently skipped where absent, e.g. stock macOS).
(( ${+commands[dircolors]} )) && [[ -z $LS_COLORS ]] && eval "$(dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' switch-group '<' '>'           # cycle candidate groups
zstyle ':fzf-tab:*' continuous-trigger '/'         # cd dir/<Tab> keeps drilling down
zstyle ':fzf-tab:*' fzf-pad 4                      # room for the preview border

# Default preview for ANY path candidate: dirs → eza tree, files → bat.
# $realpath is set by fzf-tab for file/dir candidates; empty otherwise,
# so non-path completions fall back to showing the candidate description.
zstyle ':fzf-tab:complete:*:*' fzf-preview \
    'if [[ -d $realpath ]]; then
         eza -T -L2 --color=always --icons=always --group-directories-first "$realpath"
     elif [[ -f $realpath ]]; then
         bat --color=always --style=numbers --line-range=:200 "$realpath" 2>/dev/null \
             || file "$realpath"
     else
         echo "$desc"
     fi'

# Context-specific previews (override the default above):
# git: diff for add/restore targets, log for branches/refs
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
    'git diff --color=always -- "$realpath" | head -200'
zstyle ':fzf-tab:complete:git-(checkout|switch|merge|rebase):*' fzf-preview \
    'case $group in
     *commit*|*branch*|*tag*|*head*) git log --oneline --color=always -20 "$word" 2>/dev/null ;;
     *file*) git diff --color=always -- "$realpath" | head -200 ;;
     *) echo "$desc" ;;
     esac'
# env vars: show the value
zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset):*' fzf-preview \
    'echo "${(P)word}"'
# processes: show the full command line
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
    '[[ $group == *"process"* ]] && ps -p "$word" -o pid,user,etime,args --no-headers 2>/dev/null'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
# systemd: unit status
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
    'SYSTEMD_COLORS=1 systemctl status "$word" 2>/dev/null | head -20'
# man: render the page
zstyle ':fzf-tab:complete:man:*' fzf-preview 'man "$word" 2>/dev/null | col -bx | head -200'

(( ${+commands[sheldon]} )) && eval "$(sheldon source)"
