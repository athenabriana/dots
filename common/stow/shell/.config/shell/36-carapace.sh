# 36-carapace.sh — carapace env (POSIX).
#
# Bridges: when carapace has no spec for a command, fall back to
# completions from these engines instead of completing nothing.

export CARAPACE_BRIDGES='zsh,fish,bash'
