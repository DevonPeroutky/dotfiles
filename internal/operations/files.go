package operations

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func safeParent(home, relative string) error {
	parent := home
	// Include HOME itself so a symlink there cannot bypass parent checks.
	components := strings.Split(filepath.Dir(relative), string(filepath.Separator))
	for i := -1; i < len(components); i++ {
		if i >= 0 {
			parent = filepath.Join(parent, components[i])
		}
		info, err := os.Lstat(parent)
		if os.IsNotExist(err) {
			continue
		}
		if err != nil {
			return fmt.Errorf("inspect parent %s: %w", parent, err)
		}
		if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
			return fmt.Errorf("cannot manage files beneath conflicting parent: %s", parent)
		}
	}
	return nil
}

func correctLink(repo, home, relative string) bool {
	target, err := os.Readlink(filepath.Join(home, relative))
	return err == nil && target == filepath.Join(repo, "home", relative)
}

func validateSecrets(home string) error {
	path := filepath.Join(home, ".config/zsh/secrets.zsh")
	info, err := os.Lstat(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("inspect %s: %w", path, err)
	}
	if !info.Mode().IsRegular() {
		return fmt.Errorf("keep %s as a private regular file, not a symlink or directory", path)
	}
	return nil
}
