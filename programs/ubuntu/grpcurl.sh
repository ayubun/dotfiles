#!/bin/bash

CURRENT_DIR=$(pwd)

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
    TMP_DIR="$HOME/dotfiles/tmp"
    mkdir -p "$TMP_DIR" &>/dev/null
else
    TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

# https://github.com/fullstorydev/grpcurl
VERSION=1.8.7
mkdir grpcurl  # Temp dir for this binary
curl -L "https://github.com/fullstorydev/grpcurl/releases/download/v${VERSION}/grpcurl_${VERSION}_linux_x86_64.tar.gz" | tar xz -C grpcurl
sudo mv -f grpcurl/grpcurl /usr/bin/
sudo rm -rf grpcurl  # Remove temp dir

cd "$CURRENT_DIR"

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
    rm -rf "$TMP_DIR"
fi