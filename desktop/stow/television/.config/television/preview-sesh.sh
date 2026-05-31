#!/usr/bin/env sh
# tv preview for the silverfox `sesh` cable channel.
#
# sesh sources mix two entry kinds:
#   - tmux session names      (e.g. "silverfox")
#   - zoxide directories      (e.g. "~/Dotfiles", "/var/...")
#
# Branch on what the entry resolves to: existing directory → eza
# tree; otherwise treat as a tmux session and dump its visible
# pane via capture-pane. Anything else just prints "no preview".

target=$1
[ -z "$target" ] && exit 0

# Expand a leading `~` (sesh emits some entries that way). The
# quotes around "~/" in the strip pattern are load-bearing — without
# them dash tilde-expands the pattern itself and the strip becomes
# a no-op.
expanded=$target
case $target in
    "~")    expanded=$HOME ;;
    "~/"*)  expanded=$HOME/${target#"~/"} ;;
esac

if [ -d "$expanded" ]; then
    if command -v eza >/dev/null 2>&1; then
        # --icons=always (not bare --icons) so glyphs render even
        # though eza's stdout is a pipe, not a tty. Same reason
        # --color=always is forced.
        exec eza --tree --level=2 --icons=always --color=always \
                 --group-directories-first "$expanded"
    fi
    exec ls -la --color=always "$expanded"
fi

if tmux has-session -t "$target" 2>/dev/null; then
    exec tmux capture-pane -ep -t "$target"
fi

printf 'no preview\n'
