<div align="center">

# dots

[![Platform](https://img.shields.io/badge/platform-wsl2%20%7C%20ubuntu-111111?style=flat-square)](#)
[![Stack](https://img.shields.io/badge/stack-stow%20%2B%20mise%20%2B%20just-111111?style=flat-square)](#)

_One `just sync` from a fresh shell to home._

</div>

Bootstrap a fresh machine:

```bash
sudo apt-get install -y git just
git clone git@github.com:athenabriana/dots.git ~/Dots
cd ~/Dots && just sync
```

Reconcile anytime (from anywhere, once stowed):

```bash
dots sync
```

Upgrade everything (apt + mise + zsh plugins), then sync:

```bash
dots upgrade
```

## Layout

| Layer            | Managed by | Where                                    |
| ---------------- | ---------- | ---------------------------------------- |
| System bootstrap | apt        | `common/packages.txt` + `<plat>/packages.txt` |
| CLI tools        | mise       | `common/stow/mise/.config/mise/config.toml` |
| Configs          | stow       | `common/stow/` + `wsl/stow/` + `desktop/stow/` |
| zsh plugins      | sheldon    | stowed `plugins.toml`, locked by `sync`  |
| Password store   | pass       | separate private repo, cloned by `sync`  |

The platform (`wsl`/`desktop`) is auto-detected; override with `just PLAT=… <recipe>`. `just windows` configures the Windows host (font + terminal) from inside WSL.
