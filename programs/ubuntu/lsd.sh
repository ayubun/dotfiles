#!/bin/bash

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

# https://github.com/lsd-rs/lsd/releases
VERSION=1.2.0
curl -L "https://github.com/lsd-rs/lsd/releases/download/v${VERSION}/lsd-v${VERSION}-x86_64-unknown-linux-gnu.tar.gz" | tar xz
sudo mv -f "lsd-v${VERSION}-x86_64-unknown-linux-gnu/lsd" /usr/bin/

cd ../
# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi
