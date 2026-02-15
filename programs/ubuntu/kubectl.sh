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

ARCH=$(get_arch deb)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

cd "$CURRENT_DIR"

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
    rm -rf "$TMP_DIR"
fi
