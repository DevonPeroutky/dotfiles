// Package cli defines the command interface and its generated documentation.
package cli

import (
	"fmt"
	"os"
	"runtime"

	"github.com/DevonPeroutky/dotfiles/internal/config"
	"github.com/DevonPeroutky/dotfiles/internal/operations"
	"github.com/DevonPeroutky/dotfiles/internal/update"
	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
)

func New(version string) *cobra.Command {
	root := &cobra.Command{Use: "dotfiles", Short: "Manage personal Apple Silicon Mac configuration", Version: version, SilenceUsage: true, SilenceErrors: true, Args: cobra.NoArgs}
	root.RunE = func(cmd *cobra.Command, args []string) error { return cmd.Help() }
	root.CompletionOptions.DisableDefaultCmd = true
	root.InitDefaultVersionFlag()
	var repo string
	var install bool
	setup := &cobra.Command{
		Use: "setup", Short: "Back up conflicts and link configuration from a checkout",
		Long:    "Link the explicitly managed configuration into your home directory. Existing conflicts are backed up. With --install, install Homebrew and mise packages before changing links. Requires Apple Silicon macOS and an existing checkout.",
		Example: "  dotfiles setup\n  dotfiles setup --install --repo ~/Development/dotfiles",
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			checkout, home, err := locations(repo)
			if err != nil {
				return err
			}
			return operations.Setup(cmd.Context(), checkout, home, install, cmd.OutOrStdout(), cmd.ErrOrStderr())
		},
	}
	setup.Flags().StringVar(&repo, "repo", ".", "Existing checkout path (defaults to current directory)")
	setup.Flags().BoolVar(&install, "install", false, "Install declared Homebrew and mise packages before linking")
	var doctorRepo string
	doctor := &cobra.Command{
		Use: "doctor", Short: "Check configuration and installed tools without changing files",
		Long:    "Check managed links, Homebrew packages, commands on PATH, fonts, and private secrets permissions. Report all findings and exit nonzero when attention is needed. Requires Apple Silicon macOS and an existing checkout.",
		Example: "  dotfiles doctor\n  dotfiles doctor --repo ~/Development/dotfiles",
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			checkout, home, err := locations(doctorRepo)
			if err != nil {
				return err
			}
			return operations.Doctor(cmd.Context(), checkout, home, cmd.OutOrStdout(), cmd.ErrOrStderr())
		},
	}
	doctor.Flags().StringVar(&doctorRepo, "repo", ".", "Existing checkout path (defaults to current directory)")
	var output string
	docs := &cobra.Command{Use: "docs", Short: "Generate Markdown command reference", Args: cobra.NoArgs,
		Example: "  dotfiles docs --output docs/cli",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := os.MkdirAll(output, 0755); err != nil {
				return err
			}
			return doc.GenMarkdownTree(root, output)
		},
	}
	docs.Flags().StringVar(&output, "output", "docs/cli", "Directory for generated Markdown")
	selfUpdate := &cobra.Command{
		Use: "self-update", Short: "Install the latest published CLI release",
		Long:    "Download the latest public GitHub release, verify its SHA-256 checksum, and replace this executable. Requires Apple Silicon macOS and a writable installation directory. Does not update the configuration checkout.",
		Example: "  dotfiles self-update",
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return update.Run(cmd.Context(), version, cmd.OutOrStdout())
		},
	}
	root.AddCommand(setup, doctor, docs, selfUpdate)
	root.InitDefaultHelpCmd()
	var disableDates func(*cobra.Command)
	disableDates = func(cmd *cobra.Command) {
		cmd.DisableAutoGenTag = true
		for _, child := range cmd.Commands() {
			disableDates(child)
		}
	}
	disableDates(root)
	return root
}

func locations(path string) (string, string, error) {
	if runtime.GOOS != "darwin" || runtime.GOARCH != "arm64" {
		return "", "", fmt.Errorf("setup and doctor require Apple Silicon macOS")
	}
	repo, err := config.Resolve(path)
	if err != nil {
		return "", "", err
	}
	home, err := os.UserHomeDir()
	return repo, home, err
}
