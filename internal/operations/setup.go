// Package operations implements setup and read-only diagnostic operations.
package operations

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/DevonPeroutky/dotfiles/internal/config"
)

func Setup(ctx context.Context, repo, home string, install bool, stdout, stderr io.Writer) error {
	for _, relative := range append(config.Managed(), ".config/zsh/secrets.zsh") {
		if err := safeParent(home, relative); err != nil {
			return err
		}
	}
	if err := validateSecrets(home); err != nil {
		return err
	}
	if install {
		if err := installTools(ctx, repo, stdout, stderr); err != nil {
			return err
		}
	}
	if err := migrateSecrets(repo, home, stdout); err != nil {
		return err
	}
	suffix := fmt.Sprintf(".dotfiles-backup.%s.%d", time.Now().Format("20060102-150405"), os.Getpid())
	for _, relative := range config.Managed() {
		if correctLink(repo, home, relative) {
			continue
		}
		destination := filepath.Join(home, relative)
		if err := os.MkdirAll(filepath.Dir(destination), 0700); err != nil {
			return err
		}
		if _, err := os.Lstat(destination); err == nil {
			backup := destination + suffix
			if _, err := os.Lstat(backup); !os.IsNotExist(err) {
				return fmt.Errorf("backup path unavailable: %s", backup)
			}
			if err := os.Rename(destination, backup); err != nil {
				return fmt.Errorf("back up %s: %w", destination, err)
			}
			fmt.Fprintf(stdout, "Backed up %s -> %s\n", destination, backup)
		} else if !os.IsNotExist(err) {
			return fmt.Errorf("inspect %s: %w", destination, err)
		}
		if err := os.Symlink(filepath.Join(repo, "home", relative), destination); err != nil {
			return fmt.Errorf("link %s: %w", destination, err)
		}
		fmt.Fprintf(stdout, "Linked %s\n", destination)
	}
	fmt.Fprintln(stdout, "Setup complete. Open a new login shell, then run dotfiles doctor with the same checkout.")
	return nil
}

func migrateSecrets(repo, home string, stdout io.Writer) error {
	if correctLink(repo, home, ".config/zsh/env.zsh") {
		return nil
	}
	secrets := filepath.Join(home, ".config/zsh/secrets.zsh")
	if _, err := os.Lstat(secrets); err == nil {
		return nil
	} else if !os.IsNotExist(err) {
		return err
	}
	old := filepath.Join(home, ".config/zsh/env.zsh")
	info, err := os.Stat(old)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("inspect %s: %w", old, err)
	}
	if !info.Mode().IsRegular() {
		return nil
	}
	source, err := os.Open(old)
	if err != nil {
		return err
	}
	defer source.Close()
	destination, err := os.OpenFile(secrets, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return err
	}
	if err := destination.Chmod(0600); err != nil {
		destination.Close()
		return fmt.Errorf("set private permissions on %s: %w", secrets, err)
	}
	_, copyErr := io.Copy(destination, source)
	closeErr := destination.Close()
	if copyErr != nil || closeErr != nil {
		return fmt.Errorf("copy %s to %s incomplete; inspect the private file before rerunning: copy=%v close=%v", old, secrets, copyErr, closeErr)
	}
	fmt.Fprintln(stdout, "Preserved old env.zsh as private secrets.zsh (contents not displayed).")
	return nil
}
