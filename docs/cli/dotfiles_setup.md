## dotfiles setup

Back up conflicts and link configuration from a checkout

### Synopsis

Link the explicitly managed configuration into your home directory. Existing conflicts are backed up. With --install, install Homebrew and mise packages before changing links. Requires Apple Silicon macOS and an existing checkout.

```
dotfiles setup [flags]
```

### Examples

```
  dotfiles setup
  dotfiles setup --install --repo ~/Development/dotfiles
```

### Options

```
  -h, --help          help for setup
      --install       Install declared Homebrew and mise packages before linking
      --repo string   Existing checkout path (defaults to current directory) (default ".")
```

### SEE ALSO

* [dotfiles](dotfiles.md)	 - Manage personal Apple Silicon Mac configuration

