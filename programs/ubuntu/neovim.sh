#!/bin/bash


# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

ARCH=$(get_arch)
rm -rf ./nvim-linux-${ARCH}.tar.gz

curl -L "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz" | tar -xz
sudo mv -f ./nvim-linux-${ARCH}/bin/nvim /usr/local/bin
sudo mv -f ./nvim-linux-${ARCH}/lib/nvim /usr/local/lib
sudo mv -f ./nvim-linux-${ARCH}/share/nvim /usr/local/share

# Ensure all users can read and execute
sudo chmod 755 /usr/local/bin/nvim
sudo chmod -R a+rX /usr/local/lib/nvim /usr/local/share/nvim

echo ""
echo "neovim is now installed~"

cd ..

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi
