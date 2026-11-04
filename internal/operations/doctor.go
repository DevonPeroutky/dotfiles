package operations

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/DevonPeroutky/dotfiles/internal/config"
)

func Doctor(ctx context.Context, repo, home string, stdout, stderr io.Writer) error {
	failures := 0
	missing := func(message string) { fmt.Fprintln(stdout, "CHECK:", message); failures++ }
	for _, relative := range config.Managed() {
		if err := safeParent(home, relative); err != nil {
			missing(err.Error())
		} else if !correctLink(repo, home, relative) {
			missing(fmt.Sprintf("Incorrect or missing link: %s (run dotfiles setup with this checkout)", filepath.Join(home, relative)))
		}
	}
	if _, err := os.Stat(brew); err != nil {
		missing("Apple Silicon Homebrew is missing; install it from https://brew.sh")
	} else {
		env := append(os.Environ(), "HOMEBREW_NO_AUTO_UPDATE=1")
		if err := run(ctx, stdout, stderr, repo, env, brew, "bundle", "check", "--no-upgrade", "--verbose", "--file="+filepath.Join(repo, "packages/Brewfile")); err != nil {
			missing("Brewfile package check failed; run dotfiles setup --install with this checkout: " + err.Error())
		}
	}
	for _, tool := range []string{"git", "fzf", "fd", "wget", "mise", "nvim", "wt", "codex", "neovide", "uv", "node", "pnpm"} {
		if _, err := exec.LookPath(tool); err != nil {
			missing("Command not on PATH: " + tool + " (open a new login shell after setup)")
		}
	}
	if !nerdFontInstalled(home) {
		missing("Inconsolata Nerd Font missing; run dotfiles setup --install with this checkout")
	}
	if _, err := os.Stat("/System/Library/Fonts/Monaco.ttf"); err != nil {
		missing("Monaco font not found in /System/Library/Fonts")
	}
	if err := safeParent(home, ".config/zsh/secrets.zsh"); err != nil {
		missing(err.Error())
	} else if err := validateSecrets(home); err != nil {
		missing(err.Error())
	} else {
		info, err := os.Stat(filepath.Join(home, ".config/zsh/secrets.zsh"))
		if os.IsNotExist(err) {
			missing("Secrets not configured; optional if no tools need credentials. Copy examples/secrets.zsh.example if needed")
		} else if err != nil {
			missing(err.Error())
		} else if info.Mode().Perm() != 0600 {
			missing("Set private permissions: chmod 600 ~/.config/zsh/secrets.zsh")
		}
	}
	if failures > 0 {
		return fmt.Errorf("%d check(s) need attention. No configuration files were changed", failures)
	}
	fmt.Fprintln(stdout, "All checks passed.")
	return nil
}

func nerdFontInstalled(home string) bool {
	found := false
	for _, directory := range []string{filepath.Join(home, "Library/Fonts"), "/Library/Fonts"} {
		_ = filepath.WalkDir(directory, func(path string, entry fs.DirEntry, err error) error {
			if err == nil && !entry.IsDir() {
				name := strings.ToLower(entry.Name())
				if strings.Contains(name, "inconsolata") && strings.Contains(name, "nerd") {
					found = true
				}
			}
			return nil
		})
	}
	return found
}
