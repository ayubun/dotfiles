#!/bin/bash

if [ -d ~/.tmux/plugins/tpm ]; then
  echo "tmux tpm is already installed~"
  exit 0
fi

mkdir -p ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo ""
echo "tmux tpm is now installed~"
