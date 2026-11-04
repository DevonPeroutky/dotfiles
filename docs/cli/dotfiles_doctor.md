## dotfiles doctor

Check configuration and installed tools without changing files

### Synopsis

Check managed links, Homebrew packages, commands on PATH, fonts, and private secrets permissions. Report all findings and exit nonzero when attention is needed. Requires Apple Silicon macOS and an existing checkout.

```
dotfiles doctor [flags]
```

### Examples

```
  dotfiles doctor
  dotfiles doctor --repo ~/Development/dotfiles
```

### Options

```
  -h, --help          help for doctor
      --repo string   Existing checkout path (defaults to current directory) (default ".")
```

### SEE ALSO

* [dotfiles](dotfiles.md)	 - Manage personal Apple Silicon Mac configuration

