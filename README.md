<div align="center">

# dots

[![platform](https://img.shields.io/badge/platform-wsl2%20%7C%20ubuntu-111111?style=flat-square)](#)
[![stack](https://img.shields.io/badge/stack-brew%20%2B%20mise%20%2B%20stow-111111?style=flat-square)](#)

_one `just sync` from a fresh shell to home._

</div>

bootstrap a fresh machine:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"   # brew (standalone)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
curl https://mise.run | sh                                                                        # mise (standalone)
brew install just                                                                                 # to run the justfile
git clone git@github.com:athenabriana/dots.git ~/Dots
cd ~/Dots && just sync
```

reconcile anytime, from anywhere, once stowed:

```bash
dots sync
```

upgrade everything (brew + mise + zsh plugins), then sync:

```bash
dots upgrade
```

## layout

| layer            | managed by | where                                          |
| ---------------- | ---------- | ---------------------------------------------- |
| system layer     | brew       | `common/Brewfile` + `<plat>/Brewfile`          |
| CLI tools        | mise       | `common/stow/mise/.config/mise/config.toml`    |
| configs          | stow       | `common/stow/` + `wsl/stow/` + `desktop/stow/` |
| zsh plugins      | sheldon    | stowed `plugins.toml`, locked by `sync`        |

the platform (`wsl`/`desktop`) is auto-detected, override with `just PLAT=… <recipe>`. `just windows` configures the windows host (font + terminal) from inside WSL.
