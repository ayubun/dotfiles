#!/bin/bash

BOLD=$(safe_tput bold || true)
UNDERLINE=$(safe_tput smul || true)
YELLOW_TEXT=$(safe_tput setaf 3 || true)
BLUE_TEXT=$(safe_tput setaf 4 || true)
RESET=$(safe_tput sgr0 || true)

# System-level packages only. Everything user-level (bat, ripgrep, fd,
# lazygit, neovim, lsd, etc.) is managed by home-manager -- see nix/home.nix.
packages=(
  'build-essential'
  'fail2ban'
  'manpages-dev'
  'net-tools'
)

# Wait to acquire apt lock (only if running under install.sh wrapper)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  while ! {
    set -C
    2>/dev/null >$HOME/dotfiles/tmp/apt.lock
  }; do
    sleep 1
  done
fi

fix-apt

safer-apt-fast update
safer-apt-fast upgrade

echo ""
echo "${RESET}${YELLOW_TEXT}[${BOLD}Install${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Installing ${UNDERLINE}${packages[*]}${RESET}"
echo ""
safer-apt-fast install "${packages[@]}"

safer-apt-fast autoremove

# Unlock apt lock (only if we acquired it)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  rm -f $HOME/dotfiles/tmp/apt.lock
fi
