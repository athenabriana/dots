# 60-tmux.sh — auto-launch the `t` session picker on interactive shell
# entry so a forgotten `t` never leaves a ghostty tab outside tmux
# (which would void the resurrect/continuum persistence guarantee).
#
# With t()'s no-session-yet branch (see 40-aliases.sh), the very
# first ghostty tab goes straight to "new session name:" instead of
# an empty picker. Subsequent tabs land on the picker; Esc on the
# picker (or empty prompt on the no-session branch) returns to a raw
# shell — that's the escape hatch when you actually want a one-off
# command outside tmux.
#
# Guards (any one true ⇒ skip auto-launch):
#   $TMUX                  already inside tmux (recursion would loop)
#   $ZELLIJ                legacy zellij child
#   $SSH_TTY               SSH session — let remote own multiplexing
#   $DOTS_AGENT_SHELL claude / cursor / etc. (see 30-agent-detect.sh)
#   $DOTS_NO_TMUX     manual one-off opt-out for this shell
#   $TERM = "dumb"         non-interactive context (eshell, etc.)
#   stdin or stdout not a TTY (script / pipe context)
#
# No `exec`: when `t` returns (Esc, empty prompt, or post-detach), we
# fall back into the interactive shell instead of closing the tab.

if [ -z "${TMUX:-}" ] \
    && [ -z "${ZELLIJ:-}" ] \
    && [ -z "${SSH_TTY:-}" ] \
    && [ -z "${DOTS_AGENT_SHELL:-}" ] \
    && [ -z "${DOTS_NO_TMUX:-}" ] \
    && [ "${TERM:-}" != "dumb" ] \
    && [ -t 0 ] && [ -t 1 ] \
    && command -v t >/dev/null 2>&1; then
    t
fi
