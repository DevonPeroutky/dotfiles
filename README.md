# Mac dotfiles

Shell, Neovim, and Neovide configuration shared across Macs. Configuration lives
in `home/`, mirroring its destination beneath your home directory. Setup creates
absolute symlinks into this checkout; keep it where you want it to live.

## Set up a Mac

Install Apple's Command Line Tools (`xcode-select --install`) and
[Homebrew](https://brew.sh/) first. Then clone this repo anywhere and run:

```sh
git clone git@github.com:DevonPeroutky/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
./scripts/setup --install
exec zsh -l
./scripts/doctor
```

`--install` installs the Brewfile packages without upgrading existing packages,
then installs the Node LTS and pnpm versions declared in mise. Homebrew owns
applications and system tools, including uv; mise owns Node and pnpm. Versions
float deliberately: this reproduces configuration, rather than freezing the
entire machine. See [mise's global configuration documentation](https://mise.jdx.dev/configuration).

Run `./scripts/setup` to link configuration without installing tools. Both modes
can be run repeatedly. Installation failures stop setup before links are changed.
Setup doesn't uninstall old tools, remove old package-manager installations,
change macOS preferences, or configure other terminal apps.

Neovim's existing LazyVim configuration and plugin lockfile are preserved.
Its first launch installs plugins through lazy.nvim. Neovide uses the same editor
configuration, with its GUI settings in `lua/config/neovide.lua` beneath the
Neovim config. Monaco comes with macOS; the Brewfile installs Inconsolata Nerd Font.

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

- `.zprofile` finds Homebrew at the Apple Silicon or Intel installation path.
- `.zshrc` loads shared `env.zsh`, optional `local.zsh`, optional `secrets.zsh`,
  `aliases.zsh`, then `tools.zsh` for mise and WorkTrunk initialization.
- Edit linked configuration normally, then review and commit changes in this repo.
- Add system tools to `packages/Brewfile` and runtimes to the mise config; rerun
  `./scripts/setup --install` to install them.
- Keep personal utility scripts in `home/.local/bin/` when needed, and explicitly
  add their paths to the `managed` array in `scripts/common.sh`.
- After moving this checkout, rerun setup to replace the old absolute symlinks.
- `./scripts/doctor` reports missing packages, commands, fonts, private-file setup,
  and incorrect links. It makes no changes and exits nonzero for unresolved checks.
  A missing secrets file is a reminder; it is optional if no tools need credentials.

The setup manages only explicitly listed destinations. It does not sweep an
entire home directory into Git. New configuration files must be added to the
managed list. The existing `~/.local/bin/env` is no longer needed by this shell
configuration; its PATH behavior is part of the tracked `env.zsh`.

## Verify changes

```sh
for file in scripts/*; do bash -n "$file" || break; done
for file in home/.zshrc home/.zprofile home/.config/zsh/*.zsh; do zsh -n "$file" || break; done
python3 -m unittest discover -s tests -v
```

Integration tests use temporary homes and a checkout path containing spaces. They
do not install packages or touch your actual home directory. Python is only needed
to run tests; setup and doctor use the Bash shipped with macOS.
