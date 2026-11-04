"""Exercise setup without changing the real home or installing anything."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SetupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles test ")
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name)
        self.repo = base / "checkout with spaces"
        self.home = base / "home"
        self.home.mkdir()
        for name in ("scripts", "home", "packages"):
            shutil.copytree(ROOT / name, self.repo / name)
        self.env = dict(os.environ, HOME=str(self.home))

    def setup(self, *args, succeeds=True):
        result = subprocess.run(
            ["/bin/bash", str(self.repo / "scripts/setup"), *args],
            env=self.env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, succeeds, result.stdout + result.stderr)
        return result

    def test_fresh_home_and_repeat(self):
        self.setup()
        self.assertEqual((self.home / ".config/nvim").resolve(),
                         (self.repo / "home/.config/nvim").resolve())
        self.assertTrue((self.home / ".zshrc").is_symlink())
        self.assertFalse((self.home / ".config/zsh/secrets.zsh").exists())
        self.setup()
        self.assertEqual(list(self.home.rglob("*.dotfiles-backup.*")), [])

    def test_existing_config_and_secret_migration(self):
        zsh = self.home / ".config/zsh"
        zsh.mkdir(parents=True)
        private_content = "export TEST_CREDENTIAL=placeholder-for-test\n"
        (zsh / "env.zsh").write_text(private_content)
        old_nvim = self.home / ".config/nvim"
        old_nvim.mkdir()
        (old_nvim / "keep-me").write_text("existing editor")
        result = self.setup()
        self.assertNotIn(private_content.strip(), result.stdout + result.stderr)
        secrets = zsh / "secrets.zsh"
        self.assertEqual(secrets.read_text(), private_content)
        self.assertEqual(secrets.stat().st_mode & 0o777, 0o600)
        self.assertFalse(secrets.is_symlink())
        self.assertEqual(next(zsh.glob("env.zsh.dotfiles-backup.*")).read_text(), private_content)
        backup = next(old_nvim.parent.glob("nvim.dotfiles-backup.*"))
        self.assertEqual((backup / "keep-me").read_text(), "existing editor")
        self.setup()
        self.assertEqual(secrets.read_text(), private_content)

    def test_existing_secrets_are_preserved(self):
        zsh = self.home / ".config/zsh"
        zsh.mkdir(parents=True)
        (zsh / "env.zsh").write_text("old environment")
        (zsh / "secrets.zsh").write_text("existing secrets")
        self.setup()
        self.assertEqual((zsh / "secrets.zsh").read_text(), "existing secrets")
        self.assertEqual(next(zsh.glob("env.zsh.dotfiles-backup.*")).read_text(), "old environment")

    def test_symlinked_parent_is_refused_before_any_links(self):
        outside = self.home.parent / "outside"
        outside.mkdir()
        (self.home / ".config").symlink_to(outside)
        self.setup(succeeds=False)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((self.home / ".zprofile").exists())

    def test_dangling_leaf_link_is_backed_up(self):
        (self.home / ".zshrc").symlink_to(self.home / "missing")
        self.setup()
        backup = next(self.home.glob(".zshrc.dotfiles-backup.*"))
        self.assertTrue(backup.is_symlink())
        self.assertEqual(os.readlink(backup), str(self.home / "missing"))

    def test_symlinked_secrets_are_refused(self):
        zsh = self.home / ".config/zsh"
        zsh.mkdir(parents=True)
        (zsh / "secrets.zsh").symlink_to(self.repo / "private")
        self.setup(succeeds=False)
        self.assertFalse((self.home / ".zshrc").exists())

    def test_invalid_arguments_do_not_link(self):
        self.setup("--unknown", succeeds=False)
        self.setup("--install", "extra", succeeds=False)
        self.assertFalse((self.home / ".zshrc").exists())

    def test_install_failure_stops_before_linking(self):
        # Override discovery in the temporary copy, never invoking real Homebrew.
        import shlex
        stub = self.repo / "fake-brew"
        stub.write_text('#!/bin/bash\nif [[ "$1" == shellenv ]]; then exit 0; fi\nexit 31\n')
        stub.chmod(0o755)
        common = self.repo / "scripts/common.sh"
        with common.open("a") as stream:
            stream.write('\nfind_brew() { printf "%s\\n" ' + shlex.quote(str(stub)) + '; }\n')
        self.setup("--install", succeeds=False)
        self.assertFalse((self.home / ".zshrc").exists())

    def test_install_uses_declared_tools_before_linking(self):
        import shlex
        binaries = self.repo / "fake-bin"
        binaries.mkdir()
        brew = binaries / "brew"
        brew.write_text(
            '#!/bin/bash\n'
            'if [[ "$1" == shellenv ]]; then\n'
            '  printf "export PATH=%s:$PATH\\n" "$(printf %q "$(dirname "$0")")"\n'
            'else\n'
            '  [[ "$1" == bundle && "$2" == install ]] || exit 3\n'
            '  [[ ! -L "$HOME/.zshrc" ]] || exit 4\n'
            'fi\n'
        )
        mise = binaries / "mise"
        mise.write_text(
            '#!/bin/bash\n'
            '[[ -f "$MISE_GLOBAL_CONFIG_FILE" && ! -L "$HOME/.zshrc" ]] || exit 4\n'
            'printf "%s\\n" "$1" >> "$HOME/mise-calls"\n'
        )
        brew.chmod(0o755)
        mise.chmod(0o755)
        common = self.repo / "scripts/common.sh"
        with common.open("a") as stream:
            stream.write('\nfind_brew() { printf "%s\\n" ' + shlex.quote(str(brew)) + '; }\n')
        self.setup("--install")
        self.assertEqual((self.home / "mise-calls").read_text(), "trust\ninstall\n")
        self.assertTrue((self.home / ".zshrc").is_symlink())

    def test_environment_paths_are_home_relative_and_unique(self):
        script = 'source "$1"; source "$1"; print -l -- $path'
        result = subprocess.run(
            ["zsh", "-f", "-c", script, "test", str(self.repo / "home/.config/zsh/env.zsh")],
            env=self.env, capture_output=True, text=True, check=True,
        )
        paths = result.stdout.splitlines()
        self.assertEqual(paths.count(str(self.home / ".local/bin")), 1)
        self.assertEqual(paths.count(str(self.home / "Library/pnpm/bin")), 1)

    def test_doctor_checks_installation_without_requiring_upgrades(self):
        import shlex
        stub = self.repo / "fake-brew"
        stub.write_text(
            '#!/bin/bash\n'
            '[[ "$*" == *"--no-upgrade"* && "$*" == *"--verbose"* ]]\n'
        )
        stub.chmod(0o755)
        common = self.repo / "scripts/common.sh"
        with common.open("a") as stream:
            stream.write('\nfind_brew() { printf "%s\\n" ' + shlex.quote(str(stub)) + '; }\n')
        result = subprocess.run(
            ["/bin/bash", str(self.repo / "scripts/doctor")],
            env=self.env, capture_output=True, text=True,
        )
        # Other checks may fail in a fresh temporary home, but installed packages
        # must not be reported missing just because newer releases exist.
        self.assertNotIn("Brewfile packages missing", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
