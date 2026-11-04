package operations

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
)

const brew = "/opt/homebrew/bin/brew"

func run(ctx context.Context, stdout, stderr io.Writer, directory string, env []string, executable string, args ...string) error {
	cmd := exec.CommandContext(ctx, executable, args...)
	cmd.Dir, cmd.Env = directory, env
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, stdout, stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%s %v: %w", executable, args, err)
	}
	return nil
}

func installTools(ctx context.Context, repo string, stdout, stderr io.Writer) error {
	if _, err := os.Stat(brew); err != nil {
		return fmt.Errorf("install Apple Silicon Homebrew first: https://brew.sh (%w)", err)
	}
	env := append(os.Environ(), "PATH=/opt/homebrew/bin:/opt/homebrew/sbin:"+os.Getenv("PATH"))
	if err := run(ctx, stdout, stderr, repo, env, brew, "bundle", "install", "--file="+filepath.Join(repo, "packages/Brewfile"), "--no-upgrade"); err != nil {
		return err
	}
	miseConfig := filepath.Join(repo, "home/.config/mise/config.toml")
	env = append(env, "MISE_GLOBAL_CONFIG_FILE="+miseConfig)
	for _, args := range [][]string{{"trust", miseConfig}, {"install"}} {
		if err := run(ctx, stdout, stderr, "/private/tmp", env, "/opt/homebrew/bin/mise", args...); err != nil {
			return err
		}
	}
	return nil
}
