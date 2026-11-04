if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi
