# brewenv.sh — put brew on PATH in non-login shells (no-op if absent).
#
# Sourced by justfile recipes, which run in fresh shells where the
# interactive hook (common/stow/shell/.config/shell/04-brew.sh) hasn't
# loaded.
if ! command -v brew >/dev/null 2>&1; then
    for _b in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$_b" ]; then
            eval "$("$_b" shellenv)"
            break
        fi
    done
    unset _b
fi
