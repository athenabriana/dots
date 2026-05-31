#!/bin/sh
# silverfox tv action — prompt for a new tmux session name.
#
# Invoked by the `sesh` channel under `mode = "execute"`, which exec()s
# this script in tv's place; that gives us /dev/tty cleanly for the
# `read` prompt. We CREATE the session here (detached) and PRINT the
# name on stdout — the attach happens back in the outer `t()` wrapper
# in a fresh process, because mode=execute inherits tv's reopened
# /dev/tty FD and `tmux attach` from inside that FD chain trips tv
# 0.15.6's attach_to_tty bug.

printf 'new session name: ' >&2
IFS= read -r name </dev/tty || exit 0
[ -z "$name" ] && exit 0
name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
tmux new-session -d -s "$name" 2>/dev/null
printf '%s\n' "$name"
