#!/bin/bash
# Shared by setup and doctor; compatible with macOS Bash 3.2.
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
managed=(
  .zprofile .zshrc
  .config/zsh/env.zsh .config/zsh/aliases.zsh .config/zsh/tools.zsh
  .config/mise/config.toml .config/nvim
)

find_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  command -v brew
}

correct_link() {
  [[ -L "$HOME/$1" && "$(readlink "$HOME/$1")" == "$repo/home/$1" ]]
}

# Refuse to write through symlinked parents (the managed leaf can be a link).
safe_parent() {
  local relative=$1 parent="$HOME" component
  while [[ "$relative" == */* ]]; do
    component=${relative%%/*}
    relative=${relative#*/}
    parent="$parent/$component"
    if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
      printf 'Cannot manage files beneath conflicting parent: %s\n' "$parent" >&2
      return 1
    fi
  done
}
