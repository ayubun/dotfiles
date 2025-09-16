#!/bin/bash

if [ -d ~/.tmux/plugins/tpm ]; then
  echo "tmux tpm is already installed~"
  exit 0
fi

sudo rm -rf ~/.tmux/plugins/tpm || true

if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  # Run as original user using sudo -u
  sudo -u "$ORIGINAL_USER" -H bash -c "mkdir -p ~/.tmux/plugins/tpm || true"
  sudo -u "$ORIGINAL_USER" -H bash -c "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
else
  echo "⚠️WARNING: the dotfiles were run as a root user, meaning tpm cannot be installed as non-root. Installing as root..." 
  mkdir -p ~/.tmux/plugins/tpm || true
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

fi

echo ""
echo "tmux tpm is now installed~"

