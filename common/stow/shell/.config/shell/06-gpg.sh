# 06-gpg.sh — gpg/pass environment (POSIX).
#
# GPG_TTY: pinentry-curses needs to know which terminal to draw on;
# without it gpg fails with "no tty" in plain terminal sessions.
GPG_TTY=$(tty 2>/dev/null) && export GPG_TTY

# gpg-agent serves SSH too (enable-ssh-support in gpg-agent.conf):
# point ssh at its socket unless something else (an agent forward,
# a desktop keyring) already provided one.
if [ -z "${SSH_AUTH_SOCK:-}" ] && command -v gpgconf >/dev/null 2>&1; then
    SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
    if [ -n "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK
        # gpg-agent auto-starts on gpg use, but ssh-add won't start it;
        # launch only when the socket is missing (keeps startup clean).
        [ -S "$SSH_AUTH_SOCK" ] || gpgconf --launch gpg-agent 2>/dev/null
    fi
fi
