// Package config describes the files managed by the dotfiles checkout.
package config

import (
	"fmt"
	"os"
	"path/filepath"
)

// Managed returns the explicit destinations beneath the user's home directory.
func Managed() []string {
	return []string{".zprofile", ".zshrc", ".config/zsh/env.zsh", ".config/zsh/aliases.zsh", ".config/zsh/tools.zsh", ".config/mise/config.toml", ".config/nvim"}
}

// Resolve validates a checkout and returns its canonical absolute path.
func Resolve(path string) (string, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	repo, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return "", fmt.Errorf("resolve checkout %s: %w", absolute, err)
	}
	required := []string{"packages/Brewfile"}
	for _, relative := range Managed() {
		required = append(required, filepath.Join("home", relative))
	}
	for _, relative := range required {
		source := filepath.Join(repo, relative)
		info, err := os.Stat(source)
		if err != nil {
			return "", fmt.Errorf("invalid checkout source %s: %w", source, err)
		}
		if relative == "home/.config/nvim" {
			if !info.IsDir() {
				return "", fmt.Errorf("expected directory: %s", source)
			}
		} else if !info.Mode().IsRegular() {
			return "", fmt.Errorf("expected regular file: %s", source)
		}
	}
	return repo, nil
}
