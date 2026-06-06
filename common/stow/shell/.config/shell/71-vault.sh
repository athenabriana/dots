# 71-vault.sh — `vault` command: run the private vault's justfile from
# anywhere (same pattern as 70-dots.sh). The vault is a private repo
# cloned at ~/vault; inert until it exists.
#
# `vault`         → list recipes
# `vault sync`    → pull, unlock, stow
# `vault save`    → commit everything and push

if command -v just >/dev/null 2>&1 && [ -f "$HOME/vault/justfile" ]; then
    vault() {
        just --justfile "$HOME/vault/justfile" --working-directory "$HOME/vault" "$@"
    }
fi
