# Nix / home-manager layer

CLI packages, language toolchains, and dotfile symlinks are managed
declaratively by [home-manager](https://github.com/nix-community/home-manager)
via the flake at the repo root (`flake.nix` + `nix/home.nix`). This replaced
the per-tool bash installers (nvm, rustup, starship, the GitHub-release
downloaders for lazygit/neovim/lsd/dive/grpcurl/kubectl/tldr, the tmux source
build, and the user-level apt/brew package lists).

What deliberately stays bash:

- macOS GUI apps (brew casks) and skhd: `programs/mac/packages.sh`
- macOS `defaults write` settings: `programs/mac/system-settings.sh`
- system-level apt packages (build-essential, fail2ban): `programs/ubuntu/packages.sh`
- oh-my-zsh/p10k, LazyVim starter, tmux TPM: `programs/ohmyz.sh`, `programs/lazyvim.sh`, `programs/tmux-tpm.sh`
- fast self-updating tools: `programs/claude-code.sh`, `programs/opencode.sh`
- ssh config, cron auto-updater: unchanged in `install.sh`

## Bootstrap

`./install.sh` handles everything: `dependencies/nix-and-home-manager.sh`
installs Nix if missing (multi-user on macOS/systemd Linux, single-user on
containers/devboxes without systemd) and applies the flake.

To run just the Nix step by hand:

```sh
./with-deps dependencies/nix-and-home-manager.sh
# or directly:
home-manager switch --flake ~/dotfiles#x86_64-linux --impure -b hm-backup
```

`--impure` is required: the flake reads `$USER`/`$HOME` so the same config
works across machines with different usernames. The flake attribute is the
system name (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`,
`aarch64-darwin`); the bootstrap script picks it via `uname`.

## Day-to-day

```sh
# apply config changes (after editing nix/home.nix)
home-manager switch --flake ~/dotfiles#<system> --impure

# update all packages (then commit the new flake.lock)
nix flake update ~/dotfiles

# something broke? roll back
home-manager generations   # list
/nix/store/...-home-manager-generation/activate   # activate an older one

# try an older node without installing it
nix shell nixpkgs#nodejs_20
```

`flake.lock` pins the exact version of every package; every machine that
pulls the repo converges on identical software. **Commit `flake.lock` after
the first successful switch** (it is generated on first run) and after every
`nix flake update`.

## Migrating an existing machine

1. Pull this repo and run `./install.sh` as usual.
2. home-manager backs up any pre-existing files it now owns as `*.hm-backup`
   (the old symlinks pointed at the same repo files, so the backups are
   safe to delete).
3. Optional cleanup of now-redundant installs: `~/.nvm`, `~/.rustup`,
   `rustup`-managed toolchains, `~/.bun`, pipx venvs, and on the Mac the old
   brew formulae (`brew leaves` will show them; casks are unaffected).
   Nothing breaks if you leave them -- `~/.local/bin` and brew still sit in
   front of the nix profile on PATH for anything self-updating.

## Known trade-offs

- `cargo-subspace` was installed by the old `rust.sh` and is not in nixpkgs;
  install with `cargo install --locked cargo-subspace` if needed.
- Only one node major (currently 22) is on PATH; the old nvm setup kept
  18/20/22 installed side by side. Use `nix shell nixpkgs#nodejs_20` per
  invocation or add more majors to `home.packages`.
- The work devbox provides its own rust toolchain; per-project `nix develop`
  / direnv environments take PATH precedence over the home profile, so the
  toolchains coexist.
