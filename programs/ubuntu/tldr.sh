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
ARCH=$(get_arch)
mkdir -p tldr/
cd tldr/
gh_download "https://github.com/tldr-pages/tlrc/releases/download/v${VERSION}/tlrc-v${VERSION}-${ARCH}-unknown-linux-musl.tar.gz" tlrc.tar.gz || exit 1
tar -xzf tlrc.tar.gz || exit 1
sudo mv -f ./tldr /usr/bin/ || exit 1
cd ../../

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi
