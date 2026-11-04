# Homebrew supports both Apple Silicon and Intel Macs.
for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$brew_path" ]]; then
    eval "$("$brew_path" shellenv zsh)"
    break
  fi
done
unset brew_path
