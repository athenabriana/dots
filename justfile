# justfile — cross-platform dotfiles bootstrap.
#
# Structure (per-platform subfolders):
#   common/   stow packages + Brewfile applied everywhere
#   wsl/      headless WSL extras
#   desktop/  Ubuntu-family desktop extras (Brewfile + GUI stow packages)
# The system layer comes from brew (see common/Brewfile); fedora/macos
# detection exists (lib/detect.sh) and brew covers them too.
#
# The platform is auto-detected (lib/detect.sh); override with PLAT=…,
# e.g. `just PLAT=desktop link`.
#
# Usage (or via the `dots` shell command from anywhere):
#   just              # list recipes
#   just platform     # show what was detected
#   just sync         # reconcile everything — run anytime
#   just upgrade      # upgrade everything (brew + mise + zsh plugins), then sync
#   just link         # stow configs into $HOME

DOTS := justfile_directory()
PLAT := `bash lib/detect.sh`

default:
    @just --list

# Print the detected platform (override with PLAT=…).
platform:
    @echo "{{PLAT}}"

# Reconcile the whole machine to the dotfiles (pull → brew → link → mise → sheldon → skills → tmux plugins → pass → chsh). Idempotent — run anytime.
sync: _pull _brew link _mise _sheldon _skills _tmux-plugins _pass
    @just chsh zsh
    @echo ""
    @echo "Synced ({{PLAT}}). Open a new terminal (or 'exec zsh -l') if the shell changed."

# Upgrade everything to latest (brew + mise self-update/tools + zsh plugins), then sync.
upgrade: _pull _brew-upgrade _mise-upgrade _sheldon-upgrade sync

# (internal) Fast-forward the dotfiles repo. Skips the pull if the tree
# is dirty or the branch diverged — never stashes/merges.
_pull:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{DOTS}}"
    if [ -n "$(git status --porcelain)" ]; then
        echo "pull: working tree dirty — skipping git pull." >&2
        exit 0
    fi
    before=$(git rev-parse HEAD)
    git pull --ff-only --quiet || echo "pull: cannot fast-forward (branch diverged?) — skipping." >&2
    after=$(git rev-parse HEAD)
    if [ "$before" != "$after" ]; then
        echo "pull: updated $(git rev-parse --short "$before") → $(git rev-parse --short "$after")"
        # just already parsed the old justfile for this run; if the pull
        # changed it, the rest of this run would use stale recipes.
        if ! git diff --quiet "$before" "$after" -- justfile; then
            echo "pull: the justfile itself changed — re-run the command to use the new recipes." >&2
            exit 1
        fi
    fi

# (internal) Install zsh plugins per sheldon's plugins.toml (no-op if current).
_sheldon:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{DOTS}}/lib/brewenv.sh"
    if ! command -v sheldon >/dev/null 2>&1; then
        echo "sheldon not found on PATH — skipping zsh plugins." >&2
        exit 0
    fi
    echo "sheldon: locking zsh plugins…"
    sheldon lock

# (internal) Bump zsh plugins to latest upstream.
_sheldon-upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{DOTS}}/lib/brewenv.sh"
    if ! command -v sheldon >/dev/null 2>&1; then
        echo "sheldon not found on PATH — skipping zsh plugin upgrade." >&2
        exit 0
    fi
    echo "sheldon: updating zsh plugins…"
    sheldon lock --update

# (internal) Update brew itself, then upgrade all formulae.
_brew-upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{DOTS}}/lib/brewenv.sh"
    if ! command -v brew >/dev/null 2>&1; then
        echo "brew not found — skipping brew upgrade." >&2
        exit 0
    fi
    echo "brew: updating…"
    brew update --quiet
    echo "brew: upgrading formulae…"
    brew upgrade

# (internal) Upgrade mise tools (re-resolves latest/lts within pins).
# The mise binary itself comes from brew — _brew-upgrade covers it.
_mise-upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{DOTS}}/lib/brewenv.sh"
    if ! command -v mise >/dev/null 2>&1; then
        echo "mise not found on PATH — skipping mise upgrade." >&2
        exit 0
    fi
    echo "mise: upgrading tools…"
    mise upgrade

# (internal) Install mise tools from config.toml, then prune unused versions.
_mise:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{DOTS}}/lib/brewenv.sh"
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

# (internal) Clone tmux session-persistence plugins (desktop only; see tmux.conf).
_tmux-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    [ "{{PLAT}}" = "desktop" ] || exit 0
    dir="$HOME/.tmux/plugins"
    for repo in tmux-resurrect tmux-continuum; do
        name="${repo#tmux-}"
        if [ ! -d "$dir/$name/.git" ]; then
            echo "tmux: cloning $repo…"
            git clone --quiet --depth 1 "https://github.com/tmux-plugins/$repo" "$dir/$name"
        fi
    done

# (internal) Sync the password store: clone the private repo on first run,
# fast-forward after. Skips gracefully until the repo/SSH key exists.
_pass:
    #!/usr/bin/env bash
    set -euo pipefail
    # stow creates ~/.gnupg with the default umask; gpg refuses to trust it.
    [ -d "$HOME/.gnupg" ] && chmod 700 "$HOME/.gnupg"
    store="$HOME/.password-store"
    if [ -d "$store/.git" ]; then
        git -C "$store" pull --ff-only --quiet \
            || echo "pass: cannot fast-forward store — skipping." >&2
    elif [ ! -e "$store" ]; then
        if git clone --quiet git@github.com:athenabriana/pass.git "$store" 2>/dev/null; then
            echo "pass: cloned password store → ~/.password-store"
        else
            echo "pass: store repo not reachable (not created yet, or no SSH key) — skipping." >&2
        fi
    fi

# (internal) Install system packages: common/Brewfile + <platform>/Brewfile.
_brew:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{DOTS}}/lib/brewenv.sh"
    if ! command -v brew >/dev/null 2>&1; then
        # Assumes curl/git/procps/file on the host (Ubuntu/WSL ships them).
        echo "brew: not found — installing Homebrew…"
        # NONINTERACTIVE makes the installer check sudo with -n (no prompt),
        # so cache the credentials first.
        sudo -v
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        source "{{DOTS}}/lib/brewenv.sh"
    fi
    files=("{{DOTS}}/common/Brewfile")
    [ -f "{{DOTS}}/{{PLAT}}/Brewfile" ] && files+=("{{DOTS}}/{{PLAT}}/Brewfile")
    for f in "${files[@]}"; do
        rel="${f#"{{DOTS}}/"}"
        if brew bundle check --file "$f" >/dev/null 2>&1; then
            echo "brew: $rel already satisfied."
        else
            echo "brew: bundling $rel…"
            brew bundle --file "$f"
        fi
    done

# Stow common/ + <platform>/ packages into $HOME (backs up real files).
link:
    #!/usr/bin/env bash
    set -euo pipefail
    # brew's stow (2.4.x); the recipe still works with any stow on PATH.
    source "{{DOTS}}/lib/brewenv.sh"
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
    source "{{DOTS}}/lib/brewenv.sh"
    target="{{shell}}"
    case "$target" in
        bash|zsh) ;;
        *) echo "Unknown shell: $target (try: bash, zsh)" >&2; exit 1 ;;
    esac
    bin="$(command -v "$target" || true)"
    [ -n "$bin" ] || { echo "$target is not installed (run 'just sync')." >&2; exit 1; }
    current=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current" = "$bin" ]; then
        echo "Already on $target ($bin)."
        exit 0
    fi
    # login tooling (chsh, some PAM setups) only accepts shells listed here
    if ! grep -qx "$bin" /etc/shells; then
        echo "$bin" | sudo tee -a /etc/shells >/dev/null
        echo "added $bin to /etc/shells"
    fi
    sudo usermod -s "$bin" "$USER"
    echo "Login shell set to $bin. Log out/in, or run 'exec $target -l' now."
