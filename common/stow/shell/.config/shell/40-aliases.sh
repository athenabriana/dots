# 40-aliases.sh — eza / bat aliases (POSIX).
#
# Skipped for AI agent shells (see 30-agent-detect.sh). Agents read
# command output as raw strings to feed back into context, so icons /
# ANSI escapes / git decoration / line numbers from eza/bat would
# pollute the parse path. Plain `\ls` / `\cat` (backslash-escaped)
# still hit the GNU coreutils binary regardless.

if [ -z "${DOTS_AGENT_SHELL:-}" ]; then
    if command -v eza >/dev/null 2>&1; then
        alias ls='eza --icons --group-directories-first'
        alias ll='eza --icons --group-directories-first --long --git --header'
        alias la='eza --icons --group-directories-first --long --git --header --all'
        alias tree='eza --icons --tree --level=5 --git-ignore'
    fi
    if command -v bat >/dev/null 2>&1; then
        alias cat='bat --paging=never --style=plain'
        # bare `bat` keeps the full pager + theme + line numbers
    fi
    if command -v claude >/dev/null 2>&1; then
        # Always launch Claude Code with permission prompts bypassed.
        # `\claude` (backslash-escaped) still runs the plain binary.
        alias claude='claude --dangerously-skip-permissions'
    fi
    if command -v tmux >/dev/null 2>&1 && command -v sesh >/dev/null 2>&1 && command -v tv >/dev/null 2>&1; then
        # `t` — tmux session entrypoint.
        #   `t`           → tv picker over the `sesh` channel; picks an
        #                   existing tmux session and connects.
        #   `t <name>`    → create-or-attach session called <name>
        #                   (lowercased). `sesh connect` handles both
        #                   cases natively.
        #   `t .`         → create-or-attach session named after the
        #                   last two path segments of $PWD, lowercased
        #                   (old `t` behavior: keeps two "web" dirs
        #                   distinct via dev-web / work-web).
        # </dev/tty pins stdin to the terminal so tv runs interactively
        # inside `$(...)`. Esc in the picker no-ops cleanly. The picker
        # captures stdout instead of using a tv action to dodge tv
        # 0.15.6's attach_to_tty bug with multiplexer-execute mode.
        t() {
            if [ "$#" -gt 0 ]; then
                if [ "$1" = "." ]; then
                    _t_name="$(basename "$(dirname "$PWD")")-$(basename "$PWD")"
                else
                    _t_name="$1"
                fi
                _t_name="$(printf '%s' "$_t_name" | tr '[:upper:]' '[:lower:]')"
                sesh connect "$_t_name"
                unset _t_name
                return
            fi
            # No sessions yet → skip the empty picker, go straight to
            # the same prompt that ctrl-n triggers inside tv. Same
            # script, same stdout contract: prints the new session
            # name so this wrapper can `sesh connect` in clean context.
            if ! tmux has-session 2>/dev/null; then
                _t_pick="$(sh ~/.config/television/sesh-new.sh </dev/tty)"
                [ -n "$_t_pick" ] && sesh connect "$_t_pick"
                unset _t_pick
                return
            fi
            # Picker mode. ctrl-n / ctrl-d live as `[actions]` inside
            # the `sesh` channel TOML (tv 0.15.6's --expect only
            # accepts one key). On Enter, tv prints the selected
            # session name. On ctrl-n, the action prompts in-place
            # and prints the new session's name to stdout. Either
            # way, the captured value is what `sesh connect` needs.
            # ctrl-d kills inside tv (mode=fork) and prints nothing.
            _t_pick="$(tv sesh </dev/tty)"
            [ -n "$_t_pick" ] && sesh connect "$_t_pick"
            unset _t_pick
        }
    fi
fi
