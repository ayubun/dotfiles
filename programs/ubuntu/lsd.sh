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
ARCH=$(get_arch)
gh_download "https://github.com/lsd-rs/lsd/releases/download/v${VERSION}/lsd-v${VERSION}-${ARCH}-unknown-linux-gnu.tar.gz" lsd.tar.gz || exit 1
tar -xzf lsd.tar.gz || exit 1
sudo mv -f "lsd-v${VERSION}-${ARCH}-unknown-linux-gnu/lsd" /usr/bin/ || exit 1

cd ../
# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi
