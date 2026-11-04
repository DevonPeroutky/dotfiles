// Package update replaces the running CLI with the latest published release.
package update

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const (
	latestURL     = "https://api.github.com/repos/DevonPeroutky/dotfiles/releases/latest"
	binaryAsset   = "dotfiles-darwin-arm64"
	maxBinarySize = 128 << 20
)

type release struct {
	Tag        string `json:"tag_name"`
	Draft      bool   `json:"draft"`
	Prerelease bool   `json:"prerelease"`
	Assets     []struct {
		Name string `json:"name"`
		URL  string `json:"browser_download_url"`
	} `json:"assets"`
}

// Run downloads and verifies one release before atomically replacing the executable.
// It does not modify the configuration checkout or persist any updater settings.
func Run(ctx context.Context, current string, stdout io.Writer) error {
	if runtime.GOOS != "darwin" || runtime.GOARCH != "arm64" {
		return fmt.Errorf("self-update requires Apple Silicon macOS")
	}
	client := &http.Client{Timeout: 2 * time.Minute}
	metadata, err := download(ctx, client, latestURL, 1<<20)
	if err != nil {
		return fmt.Errorf("find latest release: %w", err)
	}
	var latest release
	if err := json.Unmarshal(metadata, &latest); err != nil {
		return fmt.Errorf("decode latest release: %w", err)
	}
	if latest.Tag == "" || latest.Draft || latest.Prerelease {
		return fmt.Errorf("GitHub did not return a published stable release")
	}
	if current == latest.Tag {
		fmt.Fprintf(stdout, "Already up to date (%s).\n", current)
		return nil
	}
	assets := make(map[string]string)
	for _, asset := range latest.Assets {
		assets[asset.Name] = asset.URL
	}
	if assets[binaryAsset] == "" || assets["checksums.txt"] == "" {
		return fmt.Errorf("release %s is missing %s or checksums.txt", latest.Tag, binaryAsset)
	}
	checksumData, err := download(ctx, client, assets["checksums.txt"], 64<<10)
	if err != nil {
		return fmt.Errorf("download checksums for %s: %w", latest.Tag, err)
	}
	expected, err := checksum(checksumData)
	if err != nil {
		return err
	}
	executable, err := os.Executable()
	if err != nil {
		return err
	}
	executable, err = filepath.EvalSymlinks(executable)
	if err != nil {
		return fmt.Errorf("resolve installed executable: %w", err)
	}
	file, err := os.CreateTemp(filepath.Dir(executable), ".dotfiles-update-*")
	if err != nil {
		return fmt.Errorf("create replacement beside %s (directory must be writable): %w", executable, err)
	}
	defer os.Remove(file.Name())
	defer file.Close()
	fmt.Fprintf(stdout, "Updating %s -> %s...\n", current, latest.Tag)
	response, err := get(ctx, client, assets[binaryAsset])
	if err != nil {
		return err
	}
	defer response.Body.Close()
	hash := sha256.New()
	size, err := io.Copy(io.MultiWriter(file, hash), io.LimitReader(response.Body, maxBinarySize+1))
	if err != nil {
		return fmt.Errorf("download binary: %w", err)
	}
	if size == 0 || size > maxBinarySize {
		return fmt.Errorf("downloaded binary has an invalid size")
	}
	if hex.EncodeToString(hash.Sum(nil)) != expected {
		return fmt.Errorf("binary checksum mismatch; installed executable was not changed")
	}
	if err := file.Chmod(0755); err != nil {
		return err
	}
	if err := file.Sync(); err != nil {
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	if err := os.Rename(file.Name(), executable); err != nil {
		return fmt.Errorf("replace %s: %w", executable, err)
	}
	fmt.Fprintf(stdout, "Installed %s at %s.\n", latest.Tag, executable)
	return nil
}

func checksum(data []byte) (string, error) {
	expected := ""
	for _, line := range strings.Split(string(data), "\n") {
		fields := strings.Fields(line)
		if len(fields) != 2 || strings.TrimPrefix(fields[1], "*") != binaryAsset {
			continue
		}
		decoded, err := hex.DecodeString(fields[0])
		if err != nil || len(decoded) != sha256.Size || expected != "" {
			return "", fmt.Errorf("invalid or duplicate checksum for %s", binaryAsset)
		}
		expected = hex.EncodeToString(decoded)
	}
	if expected == "" {
		return "", fmt.Errorf("checksums.txt has no SHA-256 checksum for %s", binaryAsset)
	}
	return expected, nil
}
