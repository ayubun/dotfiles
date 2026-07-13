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

LAZYGIT_VERSION=$(gh_latest_version jesseduffield/lazygit) || exit 1
ARCH=$(get_arch)
gh_download "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" lazygit.tar.gz || exit 1
tar xf lazygit.tar.gz lazygit || exit 1
sudo install lazygit /usr/local/bin || exit 1

# https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
rm -f ~/.config/lazygit/config.yml &>/dev/null
if [[ -f ~/dotfiles/configs/lazygit/config.yml ]]; then
ln -s ~/dotfiles/configs/lazygit/config.yml ~/.config/lazygit/config.yml
fi

cd "$CURRENT_DIR"

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
    rm -rf "$TMP_DIR"
fi
