# 10-editor.sh — EDITOR/VISUAL (POSIX).
#
# WSL has no GUI Zed/flatpak, so pick the best available editor. `code
# --wait` (VS Code's WSL remote) blocks until the buffer closes — what
# git commit, sudoedit, mise edit, crontab -e, less's `v` key, etc. all
# need; nvim/vim block natively. First match wins.

if command -v code >/dev/null 2>&1; then
    export EDITOR='code --wait'
    export VISUAL='code --wait'
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
    export VISUAL='nvim'
elif command -v vim >/dev/null 2>&1; then
    export EDITOR='vim'
    export VISUAL='vim'
fi
