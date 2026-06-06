# 04-brew.sh — Homebrew on PATH (POSIX).
#
# Loads before 05-mise-shims.sh so the mise shims land ahead of brew in
# PATH — mise wins for anything both manage.
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
    for _b in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$_b" ]; then
            eval "$("$_b" shellenv)"
            break
        fi
    done
    unset _b
fi
