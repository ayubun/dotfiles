#!/bin/bash

# Brew packages for macOS. Brew handles its own download parallelism and
# dependency resolution, so we just iterate and let it do its thing.

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
)

formulae=(
  kubectl
  nano
  neofetch # TODO: switch off neofetch
  onefetch
  htop
  btop
  gcc
  grpcurl # https://github.com/fullstorydev/grpcurl
  bat
  difftastic
  neovim
  httpie
  ripgrep
  python@3.12
  jesseduffield/lazygit/lazygit
  fd
  wireguard-tools
  lsd # https://github.com/lsd-rs/lsd
  python
  pipx
  tlrc # https://github.com/tldr-pages/tlrc
  ncdu
  dive # https://github.com/wagoodman/dive
  cloudflared
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

echo "Fetching formulae..."
for pkg in "${formulae[@]}"; do
  brew fetch --force "$pkg"
done

echo "Installing casks..."
brew install --cask --force "${casks[@]}"

echo "Installing formulae..."
for pkg in "${formulae[@]}"; do
  brew install --force-bottle "$pkg"
done

echo "Installing source formulae..."
for pkg in "${source_formulae[@]}"; do
  brew install "$pkg"
done

echo ""
echo "All done~ (* ・ｖ・)"

# https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
mkdir -p ~/Library/Application\ Support/lazygit
rm -f ~/Library/Application\ Support/lazygit/config.yml
ln -s ~/dotfiles/configs/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
