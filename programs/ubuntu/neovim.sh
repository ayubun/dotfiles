#!/bin/bash


# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

rm -rf ./nvim-linux-x86_64.tar.gz

sudo curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | sudo tar -xz
# mv -f ./nvim-linux-x86_64/bin/nvim /usr/local/bin
sudo mv -f ./nvim-linux-x86_64/bin/nvim /usr/local/bin
sudo mv -f ./nvim-linux-x86_64/lib/nvim /usr/local/lib
sudo mv -f ./nvim-linux-x86_64/share/nvim /usr/local/share

# Set ownership to original user if available
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  sudo chown -R "$ORIGINAL_USER:$ORIGINAL_USER" /usr/local/bin/nvim
  sudo chown -R "$ORIGINAL_USER:$ORIGINAL_USER" /usr/local/lib/nvim
  sudo chown -R "$ORIGINAL_USER:$ORIGINAL_USER" /usr/local/share/nvim
fi

echo ""
echo "neovim is now installed~"

cd ..

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  rm -rf "$TMP_DIR"
fi

