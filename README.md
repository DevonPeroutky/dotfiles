# Mac dotfiles

Shell, Neovim, and Neovide configuration shared across Macs. Configuration lives
in `home/`, mirroring its destination beneath your home directory. Setup creates
absolute symlinks into this checkout; keep it where you want it to live.

## Set up a Mac

Only Apple Silicon macOS is supported. Install Apple's Command Line Tools
(`xcode-select --install`) and [Homebrew](https://brew.sh/) first.

Install the CLI once per Mac. These commands download the latest stable
executable from [GitHub Releases](https://github.com/DevonPeroutky/dotfiles/releases),
verify its checksum, and install it at `~/.local/bin/dotfiles`. Go is not required:

```sh
mkdir -p ~/.local/bin

(
  set -e
  install_dir=$(mktemp -d)
  trap 'rm -rf "$install_dir"' EXIT
  cd "$install_dir"
  base="https://github.com/DevonPeroutky/dotfiles/releases/latest/download"
  curl -fLO "$base/dotfiles-darwin-arm64"
  curl -fLO "$base/checksums.txt"
  shasum -a 256 -c checksums.txt
  install -m 755 dotfiles-darwin-arm64 "$HOME/.local/bin/dotfiles"
)

export PATH="$HOME/.local/bin:$PATH"
dotfiles --version
```

The CLI needs an existing checkout; it does not download configuration or remember
its location. Clone this repo where you want it to stay, then run:

```sh
mkdir -p ~/Development
git clone https://github.com/DevonPeroutky/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
dotfiles setup --install
```

If you already cloned the repo, use that checkout instead. Once setup completes,
reload your login shell:

```sh
exec zsh -l
```

Then check the installation from the checkout:

```sh
dotfiles doctor
```

Doctor may report that secrets are not configured on a new Mac. Follow the
private-file instructions below if you need credentials.

Commands use the current directory as the checkout by default. From elsewhere,
pass `--repo ~/Development/dotfiles` to setup or doctor. Setup adds `~/.local/bin`
to your shell's PATH, so the command remains available in new shells.

For future CLI versions, run just:

```sh
dotfiles self-update
```

You do not need to repeat the download and installation block. Configuration
updates are separate: run `git pull --ff-only` in the checkout.

`--install` installs the Brewfile packages without upgrading existing packages,
then installs the Node LTS and pnpm versions declared in mise. Homebrew owns
applications and system tools, including uv; mise owns Node and pnpm. Versions
float deliberately: this reproduces configuration, rather than freezing the
entire machine. See [mise's global configuration documentation](https://mise.jdx.dev/configuration).

Run `dotfiles setup` to link configuration without installing tools. Both modes
can be run repeatedly. Installation failures stop setup before links are changed.
Setup doesn't uninstall old tools, remove old package-manager installations,
change macOS preferences, or configure other terminal apps.

Neovim's existing LazyVim configuration and plugin lockfile are preserved.
Its first launch installs plugins through lazy.nvim. Neovide uses the same editor
configuration, with its GUI settings in `lua/config/neovide.lua` beneath the
Neovim config. Monaco comes with macOS; the Brewfile installs Inconsolata Nerd Font.

On Macs, Neovim uses the active developer tools' `MacOSX.sdk` for native builds
unless `SDKROOT` is already set. This avoids selecting an incompatible newer SDK
installed alongside the active toolchain, including when launching Neovide from
Finder. No macOS version is hardcoded.

## Existing configuration and private files

Setup backs up each conflicting file, directory, or symlink beside its original
location with a `.dotfiles-backup.<timestamp>.<pid>` suffix. A whole existing
Neovim directory is backed up before its replacement is linked. Review and remove
backups yourself when satisfied; old shell backups may contain secrets.

When an existing unmanaged `~/.config/zsh/env.zsh` is present, setup first copies
it to `~/.config/zsh/secrets.zsh` with mode 600, unless a secrets file already
exists. Contents are never printed. If secrets already exist, the old environment
file is still backed up; reconcile its values manually. A legacy env file can
include ordinary environment settings too; review and separate them later.

For a new Mac, create the private file yourself:

```sh
cp examples/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

Edit it locally with your credentials. Do not put real values into example files.
Optional machine-specific settings go in `~/.config/zsh/local.zsh`; an example is
provided. Neither private file is linked into the repo. Secret and local filenames
are also ignored by Git as a secondary safeguard.

Setup refuses symlinked parent directories, such as a symlink for `~/.config` or
`~/.config/zsh`, and symlinked secrets files. Resolve these manually before running
setup so it cannot write through them into another directory or checkout.

## Everyday use

- `.zprofile` loads Homebrew from `/opt/homebrew`, the Apple Silicon installation path.
- `.zshrc` loads shared `env.zsh`, optional `local.zsh`, optional `secrets.zsh`,
  `aliases.zsh`, then `tools.zsh` for mise and WorkTrunk initialization.
- Edit linked configuration normally, then review and commit changes in this repo.
- In Neovim or Neovide, press `<Space>gW` (Space, g, Shift+W) to search existing
  worktrees and press Enter to switch. The picker shows Branch, Status, Commit,
  and Message headings and preserves unsaved buffers. Use `:WorktreeSwitch` for
  the same picker. Its configuration is in `home/.config/nvim/lua/plugins/worktrunk.lua`.
- Add system tools to `packages/Brewfile` and runtimes to the mise config; rerun
  `dotfiles setup --install` to install them.
- Keep personal utility scripts in `home/.local/bin/` when needed, and explicitly
  add their paths to the explicit list in `internal/config/config.go`.
- After moving this checkout, rerun setup to replace the old absolute symlinks.
- `dotfiles doctor` reports missing packages, commands, fonts, private-file setup,
  and incorrect links. It makes no changes and exits nonzero for unresolved checks.
  A missing secrets file is a reminder; it is optional if no tools need credentials.

The setup manages only explicitly listed destinations. It does not sweep an
entire home directory into Git. New configuration files must be added to the
managed list. The existing `~/.local/bin/env` is no longer needed by this shell
configuration; its PATH behavior is part of the tracked `env.zsh`.

## CLI development and documentation

Install Go matching `go.mod`, then build locally:

```sh
go build -o /tmp/dotfiles ./cmd/dotfiles
/tmp/dotfiles --help
/tmp/dotfiles setup --help
/tmp/dotfiles docs --output docs/cli
```

The [command reference](docs/cli/dotfiles.md) is generated from the same Cobra
command definitions as `--help`. Regenerate and commit it when commands change.
The CLI has no saved settings, checkout registry, or background updates.

Before committing, check formatting, build, and inspect changed shell syntax:

```sh
gofmt -l cmd internal
go vet ./...
go build -o /tmp/dotfiles ./cmd/dotfiles
for file in home/.zshrc home/.zprofile home/.config/zsh/*.zsh; do zsh -n "$file" || break; done
```

There is no automated test suite. Manually check filesystem changes using a
disposable `HOME` and checkout (including paths with spaces), never your real home.
Check repeat runs, conflict backups, private-file migration, and unsafe-parent
refusal. Doctor should report findings without changing configuration. Package
installation is a separate manual check on a Mac you intend to provision.

## Releases and updates

CLI checks run on pushes to `main` that change `cmd/`, `internal/`, Go module
files, generated CLI documentation, or workflow files. They check formatting,
run vet, verify generated documentation, and cross-compile the Apple Silicon
executable on Ubuntu. Configuration-only changes do not trigger CLI checks.
There is no automated test suite or Mac runner.

After pushing your changes and checking that CI passed, publish a release:

```sh
git tag v0.1.0
git push origin v0.1.0
```

Use a new stable version tag for each release. The release workflow repeats the
checks, builds the binary, and uploads it with `checksums.txt` to a draft release
before publishing it. Tags containing a hyphen (such as `v0.0.1-dev`) publish
prereleases; stable tags publish as latest. Self-update skips prereleases.
Tag pushes always run the release workflow;
GitHub does not apply path filters to tags. Release versions come from the tag;
local builds report `dev`. Releases are unsigned. If publishing fails and leaves
a draft release, inspect or delete that draft before rerunning the workflow.

On each Mac, update the installed CLI explicitly:

```sh
dotfiles --version
dotfiles self-update
dotfiles --version
```

Self-update needs no Go installation or checkout. It selects GitHub's latest
published stable release, downloads that release's Apple Silicon executable and
checksum, verifies SHA-256, then replaces the running executable using a rename
from a temporary file in the same directory. Download or verification failures
leave the installed executable unchanged; temporary downloads are removed.
The installation directory must be writable. Symlinked executables update their
resolved target. An already-current release does nothing; a local `dev` build
is replaced by the published release. GitHub's latest release is authoritative,
so selecting an older release as latest also selects it for self-update.

Releases must be publicly accessible; private repositories and authenticated
downloads are not supported. Before the first release exists, self-update
reports a download error. To get self-update into an older installed binary,
rebuild it or repeat the download instructions above once.

Updating the CLI does not update your configuration checkout. Run
`git pull --ff-only` there to bring in shell and editor changes, then rerun setup
if managed links changed or `setup --install` if package declarations changed.
