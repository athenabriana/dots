# 70-dots.sh — `dots` command: run the dotfiles justfile from anywhere.
#
# `dots`            → list recipes
# `dots sync`       → reconcile everything (run anytime)
# `dots upgrade`    → upgrade everything (apt + mise), then sync
# `dots link` / `dots windows` / `dots platform` …
#
# --justfile pins the recipe file and --working-directory pins the cwd
# so relative bits in the justfile (lib/detect.sh) resolve no matter
# where you call `dots` from. Inert if `just` isn't installed yet.

if command -v just >/dev/null 2>&1; then
    dots() {
        just --justfile "$HOME/Dots/justfile" --working-directory "$HOME/Dots" "$@"
    }
fi
