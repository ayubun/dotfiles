#!/bin/bash


# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  # Run as original user using sudo -u
  sudo -u "$ORIGINAL_USER" -H bash -c "curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | tar -xz"
else
  echo "⚠️WARNING: the dotfiles were run as a root user, meaning tpm cannot be installed as non-root. Installing as root..." 
  curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | tar -xz
fi

# mv -f ./nvim-linux-x86_64/bin/nvim /usr/local/bin
mv -f ./nvim-linux-x86_64/bin/nvim /usr/local/bin
mv -f ./nvim-linux-x86_64/lib/nvim /usr/local/lib
mv -f ./nvim-linux-x86_64/share/nvim /usr/local/share

echo ""
echo "neovim is now installed~"

cd ..

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi

