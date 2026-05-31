# 25-zoxide.sh — zoxide env (POSIX).
#
# Fedora Atomic / Silverblue has /home as a symlink to /var/home. Without
# resolving symlinks, `cd ~/foo` and `cd /var/home/<user>/foo` produce
# two zoxide entries for the same directory. Setting this canonicalizes
# the path before zoxide records it.

export _ZO_RESOLVE_SYMLINKS=1
