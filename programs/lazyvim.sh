#!/bin/bash

#### old lunarvim config: ####
# bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh) -s -- --no-install-dependencies
# rm -f ~/.config/lvim/config.lua &>/dev/null
# ln -s ~/dotfiles/configs/lvim/config.lua ~/.config/lvim/config.lua
##############################

# required
rm -rf ~/.config/nvim.bak
mv ~/.config/nvim{,.bak}

# optional but recommended
# note: i'm disabling these so that we don't have to reinstall plugins every
# workspace restart...
# rm -rf ~/.local/share/nvim.bak
# rm -rf ~/.local/state/nvim.bak
# rm -rf ~/.cache/nvim.bak
# mv ~/.local/share/nvim{,.bak}
# mv ~/.local/state/nvim{,.bak}
# mv ~/.cache/nvim{,.bak}

mkdir -p ~/.config/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim

rm -rf ~/.config/nvim/.git

# Clean pre-installed configs & symlink dotfiles
rm -rf ~/.config/nvim/lua
rm -rf ~/.config/nvim/after/ftplugin
rm -rf ~/.config/nvim/ftplugin
mkdir -p ~/.config/nvim/lua
mkdir -p ~/.config/nvim/after/ftplugin
ln -s ~/dotfiles/configs/nvim/config ~/.config/nvim/lua/config
ln -s ~/dotfiles/configs/nvim/plugins ~/.config/nvim/lua/plugins
ln -s ~/dotfiles/configs/nvim/after/ftplugin ~/.config/nvim/after/ftplugin

# Fix ownership so the original user can write to nvim config files
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER" 2>/dev/null || echo staff)" ~/.config/nvim 2>/dev/null || true
fi

