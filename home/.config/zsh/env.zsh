# zsh's unique path array avoids duplicate PATH entries on reload.
typeset -U path PATH
export PNPM_HOME="$HOME/Library/pnpm"
path=("$HOME/.local/bin" "$PNPM_HOME/bin" $path)
export PATH
