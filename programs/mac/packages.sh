#!/bin/bash

# Brew handles macOS GUI apps (casks) and the odd source-built formula only.
# All CLI formulae (bat, ripgrep, lazygit, neovim, etc.) are managed by
# home-manager -- see nix/home.nix.

casks=(
  docker
  signal
  telegram
  ghostty
  cursor
  discord
  discord@canary
  discord@ptb
  raycast
  spotify
  batfi
  steam
  nikitabobko/tap/aerospace
)

# Formulae that must be compiled from source (no bottles available)
source_formulae=(
  koekeishiya/formulae/skhd
)

# Set environment variables for non-interactive brew operations
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Some cask installs (e.g. Docker) internally call sudo. Ensure passwordless
# sudo is available so the script can run non-interactively.
# If install.sh already set this up, the file exists and this is skipped.
if ! sudo -n true 2>/dev/null; then
  sudo -v
fi
if [[ ! -f /etc/sudoers.d/dotfiles-temp ]]; then
  sudo sh -c "echo '${ORIGINAL_USER:-$USER} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/dotfiles-temp && chmod 440 /etc/sudoers.d/dotfiles-temp"
  trap 'sudo rm -f /etc/sudoers.d/dotfiles-temp 2>/dev/null' EXIT
fi

# Ensure brew is on PATH for this session
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

echo "Fetching casks..."
brew fetch --force --cask "${casks[@]}"

echo "Installing casks..."
brew install --cask --force "${casks[@]}"

echo "Installing source formulae..."
for pkg in "${source_formulae[@]}"; do
  brew install "$pkg"
done

echo ""
echo "All done~ (* ・ｖ・)"
