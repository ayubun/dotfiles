#!/bin/bash

sudo apt update -y &>/dev/null
sudo apt install -y build-essential libevent-dev ncurses-dev 2>/dev/null
sudo apt autoremove -y automake 2>/dev/null
sudo apt install -y automake pkg-config autoconf bison 2>/dev/null

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"
# sudo rm -rf ./tmux &/dev/null

if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  # Run as original user using sudo -u
  #
  sudo -u "$ORIGINAL_USER" -H bash -c "git clone https://github.com/tmux/tmux.git"
  cd tmux

  sudo -u "$ORIGINAL_USER" -H bash -c "sh autogen.sh"
  sudo -u "$ORIGINAL_USER" -H bash -c "./configure && make"
else
  echo "⚠️WARNING: the dotfiles were run as a root user, meaning tmux cannot be installed as non-root. Installing as root..." 

  git clone https://github.com/tmux/tmux.git
  cd tmux
  sh autogen.sh
  ./configure && make
fi

sudo mv -f ./tmux /usr/bin/

echo "tmux has been installed~"

# mkdir -p ./tmux
# cd ./tmux
#
# TMUX_VERSION="3.5a"
# wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
# tar -xzf tmux-${TMUX_VERSION}.tar.gz
# cd tmux-${TMUX_VERSION}
#
# ./configure
# make
# sudo make install

cd ../../

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  sudo rm -rf "$TMP_DIR"
fi

