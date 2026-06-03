# 35-fzf.sh — fzf env (POSIX). Every fzf consumer inherits
# FZF_DEFAULT_OPTS: fzf-tab, the Ctrl-P/Ctrl-G widgets, plain `fzf`.

export FZF_DEFAULT_OPTS="
  --height=60% --layout=reverse --border=rounded --info=inline
  --marker='✓ ' --pointer='▶'
  --preview-window=right:55%:wrap
  --bind=ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up
  --bind=ctrl-/:toggle-preview
"

# .gitignore-aware file source for bare `fzf` and ^T (same listing the
# Ctrl-P widget uses).
if command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Previews: ^T files → bat; Alt-C dirs → eza tree.
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'eza -T -L2 --color=always --icons=always --group-directories-first {} 2>/dev/null || ls {}'"
