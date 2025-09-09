#!/bin/bash

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

# https://github.com/tldr-pages/tlrc/releases
VERSION=1.11.1
mkdir -p tldr/
cd tldr/
# curl -L "https://github.com/tldr-pages/tlrc/releases/download/v${VERSION}/tlrc-v${VERSION}-x86_64-unknown-linux-gnu.tar.gz" | tar xz
curl -L "https://github.com/tldr-pages/tlrc/releases/download/v${VERSION}/tlrc-v${VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar xz
sudo mv -f ./tldr /usr/bin/
cd ../../

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi
