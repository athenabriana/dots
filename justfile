# justfile — cross-platform dotfiles bootstrap.
#
# Structure (per-platform subfolders):
#   common/   stow packages + packages.txt applied everywhere
#   wsl/      headless WSL extras (apt)
#   desktop/  Ubuntu-family desktop extras + GUI stow packages (apt)
#   fedora/   stub — not wired up yet
#   macos/    stub — not wired up yet
#
# The platform is auto-detected (lib/detect.sh); override with PLAT=…,
# e.g. `just PLAT=desktop link`. Original Fedora+nix recipes are kept in
# justfile.silverblue.reference.
#
# Usage (or via the `dots` shell command from anywhere):
#   just              # list recipes
#   just platform     # show what was detected
#   just sync         # reconcile everything (apt → link → mise → skills → chsh) — run anytime
#   just link         # stow configs into $HOME

DOTS := justfile_directory()
PLAT := `bash lib/detect.sh`

default:
    @just --list

# Print the detected platform (override with PLAT=…).
platform:
    @echo "{{PLAT}}"

# Reconcile the whole machine to the dotfiles (apt → link → mise → skills → chsh). Idempotent — run anytime.
sync: _apt link _mise _skills
    @just chsh zsh
    @echo ""
    @echo "Synced ({{PLAT}}). Open a new terminal (or 'exec zsh -l') if the shell changed."

# (internal) Install mise tools from config.toml, then prune unused versions.
_mise:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v mise >/dev/null 2>&1; then
        echo "mise not found on PATH — skipping mise tools." >&2
        exit 0
    fi
    echo "mise: installing tools from config.toml…"
    mise install
    echo "mise: pruning unused tool versions…"
    mise prune --yes

# (internal) Install/update agent skills from the skills repo (CLI comes from mise).
_skills:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v skills >/dev/null 2>&1; then
        echo "skills CLI not found on PATH — skipping agent skills." >&2
        exit 0
    fi
    # The CLI has no quiet flag — keep the full log only for failures.
    if out=$(skills add athenabriana/skills -g -a claude-code -s '*' -y 2>&1); then
        n=$(grep -c '✓' <<<"$out" || true)
        echo "skills: $n installed from athenabriana/skills → ~/.claude/skills"
    else
        echo "$out" >&2
        exit 1
    fi

# (internal) Install apt packages: common/packages.txt + <platform>/packages.txt.
_apt:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{PLAT}}" in
        wsl|desktop) ;;
        fedora) echo "fedora install not wired up yet — see justfile.silverblue.reference" >&2; exit 1 ;;
        macos)  echo "macos (brew) install not wired up yet" >&2; exit 1 ;;
        *)      echo "unknown platform — set PLAT=wsl|desktop" >&2; exit 1 ;;
    esac
    files=("{{DOTS}}/common/packages.txt")
    [ -f "{{DOTS}}/{{PLAT}}/packages.txt" ] && files+=("{{DOTS}}/{{PLAT}}/packages.txt")
    pkgs=$(grep -hvE '^\s*(#|$)' "${files[@]}" | sort -u)
    missing=()
    for p in $pkgs; do
        if ! dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed'; then
            missing+=("$p")
        fi
    done
    if [ ${#missing[@]} -eq 0 ]; then
        echo "apt: all packages already installed."
    else
        echo "apt: installing ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi

# Stow common/ + <platform>/ packages into $HOME (backs up real files).
link:
    #!/usr/bin/env bash
    set -euo pipefail
    backup="$HOME/.dots-backup"
    # Each stow root contributes its packages. common always; the
    # detected platform's stow/ dir if it has any packages.
    roots=("{{DOTS}}/common/stow")
    [ -d "{{DOTS}}/{{PLAT}}/stow" ] && roots+=("{{DOTS}}/{{PLAT}}/stow")
    for root in "${roots[@]}"; do
        # Package names = immediate subdirs of the stow root.
        mapfile -t packages < <(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
        [ ${#packages[@]} -eq 0 ] && { echo "link: no packages in $root"; continue; }
        for pkg in "${packages[@]}"; do
            while IFS= read -r -d '' src; do
                rel="${src#"$root/$pkg/"}"
                dst="$HOME/$rel"
                if [ -e "$dst" ] && [ ! -L "$dst" ] && [ ! -d "$dst" ]; then
                    mkdir -p "$(dirname "$backup/$rel")"
                    mv "$dst" "$backup/$rel"
                    echo "backed up $rel → ~/.dots-backup/$rel"
                fi
            done < <(find "$root/$pkg" -type f -print0)
        done
        stow -R --no-folding -d "$root" -t "$HOME" "${packages[@]}"
        echo "stowed from ${root#"{{DOTS}}/"}: ${packages[*]}"
    done
    # SSH wants tight permissions on the key and dir (key lives in common).
    sshd="{{DOTS}}/common/stow/ssh/.ssh"
    if [ -d "$sshd" ]; then
        chmod 700 "$HOME/.ssh" "$sshd" 2>/dev/null || true
        chmod 600 "$sshd/id_ed25519_github" "$sshd/config" 2>/dev/null || true
        chmod 644 "$sshd/id_ed25519_github.pub" "$sshd"/known_hosts* 2>/dev/null || true
        echo "ssh: permissions set."
    fi

# Configure the Windows host: Nerd Font + Windows Terminal (WSL only, via winget).
windows:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{PLAT}}" != "wsl" ]; then
        echo "the 'windows' recipe only applies on WSL (detected: {{PLAT}})." >&2
        exit 1
    fi
    command -v powershell.exe >/dev/null 2>&1 || {
        echo "powershell.exe not reachable — is WSL interop enabled?" >&2; exit 1; }
    ps1="$(wslpath -w "{{DOTS}}/wsl/windows/setup.ps1")"
    echo "running $ps1 (a UAC prompt may appear for the font install)…"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps1"

# Switch login shell (default zsh): just chsh / just chsh bash.
chsh shell="zsh":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{shell}}"
    case "$target" in
        bash|zsh) ;;
        *) echo "Unknown shell: $target (try: bash, zsh)" >&2; exit 1 ;;
    esac
    bin="$(command -v "$target" || true)"
    [ -n "$bin" ] || { echo "$target is not installed (run 'just apt')." >&2; exit 1; }
    current=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current" = "$bin" ]; then
        echo "Already on $target ($bin)."
        exit 0
    fi
    sudo usermod -s "$bin" "$USER"
    echo "Login shell set to $bin. Log out/in, or run 'exec $target -l' now."
