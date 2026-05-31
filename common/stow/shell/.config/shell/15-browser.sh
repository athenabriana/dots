# 15-browser.sh — open URLs in the host browser on WSL (POSIX).
#
# `winopen` (shipped in wsl/stow/winopen, a wslu-free opener) hands a
# URL/file to the Windows host via PowerShell Start-Process. Setting
# BROWSER makes tools that respect it — gcloud/gh/claude auth flows,
# vite/next "open browser", python -m webbrowser — pop the link on the
# Windows side instead of failing in a headless WSL. Guarded by
# command -v, so it's inert wherever winopen isn't present (non-WSL).

if command -v winopen >/dev/null 2>&1; then
    export BROWSER=winopen
fi
