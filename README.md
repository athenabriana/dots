<div align="center">

# dots

[![platform](https://img.shields.io/badge/platform-wsl2%20%7C%20ubuntu-111111?style=flat-square)](#)
[![stack](https://img.shields.io/badge/stack-stow%20%2B%20mise%20%2B%20just-111111?style=flat-square)](#)

_one `just sync` from a fresh shell to home._

</div>

bootstrap a fresh machine:

```bash
sudo apt-get install -y git just
git clone git@github.com:athenabriana/dots.git ~/Dots
cd ~/Dots && just sync
```

reconcile anytime, from anywhere, once stowed:

```bash
dots sync
```

upgrade everything (apt + mise + zsh plugins), then sync:

```bash
dots upgrade
```

## layout

| layer            | managed by | where                                          |
| ---------------- | ---------- | ---------------------------------------------- |
| system bootstrap | apt        | `common/packages.txt` + `<plat>/packages.txt`  |
| CLI tools        | mise       | `common/stow/mise/.config/mise/config.toml`    |
| configs          | stow       | `common/stow/` + `wsl/stow/` + `desktop/stow/` |
| zsh plugins      | sheldon    | stowed `plugins.toml`, locked by `sync`        |
| password store   | pass       | separate private repo, cloned by `sync`        |

the platform (`wsl`/`desktop`) is auto-detected, override with `just PLAT=… <recipe>`. `just windows` configures the windows host (font + terminal) from inside WSL.
