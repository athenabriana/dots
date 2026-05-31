#!/usr/bin/env bash
# detect.sh — print a single platform id to stdout, one of:
#   wsl      Windows Subsystem for Linux (headless; any distro)
#   desktop  Ubuntu/Debian-family desktop (Ubuntu, Zorin, Mint, …)
#   fedora   Fedora / Silverblue            (not yet wired up)
#   macos    macOS                          (not yet wired up)
#   unknown  none of the above
#
# WSL is checked first because a WSL Ubuntu also matches the
# ubuntu/debian branch — but it must NOT pull in the GUI link set.
set -eu

if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null \
   || [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
    echo wsl
    exit 0
fi

case "$(uname -s)" in
    Darwin) echo macos; exit 0 ;;
esac

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
        *" fedora "*|*" rhel "*)        echo fedora;  exit 0 ;;
        *" ubuntu "*|*" debian "*)      echo desktop; exit 0 ;;
    esac
    # Fall back on ID alone for distros that don't set ID_LIKE.
    case "${ID:-}" in
        ubuntu|debian|zorin|linuxmint|pop|elementary) echo desktop; exit 0 ;;
        fedora|silverblue)                            echo fedora;  exit 0 ;;
    esac
fi

echo unknown
