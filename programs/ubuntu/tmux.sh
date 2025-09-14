#!/bin/bash

sudo apt update -y &>/dev/null
sudo apt install -y build-essential libevent-dev ncurses-dev &>/dev/null

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"
rm -rf ./tmux &/dev/null
mkdir -p ./tmux
cd ./tmux

TMUX_VERSION="3.5a"
wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
tar -xzf tmux-${TMUX_VERSION}.tar.gz
cd tmux-${TMUX_VERSION}

./configure
make
sudo make install

cd ../../

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi

