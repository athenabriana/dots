# 25-zoxide.sh — zoxide env (POSIX).
#
# Canonicalize paths before zoxide records them, so a symlinked $HOME
# (e.g. /home → /var/home) doesn't create duplicate entries.

export _ZO_RESOLVE_SYMLINKS=1
