# 35-fzf.sh — global fzf appearance. Every fzf consumer inherits this:
# fzf-tab, the Ctrl-P/Ctrl-G widgets, plain `fzf` pipes.
export FZF_DEFAULT_OPTS="
  --height=60% --layout=reverse --border=rounded --info=inline
  --marker='✓ ' --pointer='▶'
  --preview-window=right:55%:wrap
  --bind=ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up
"
