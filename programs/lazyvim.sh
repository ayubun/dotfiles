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
rm -rf ~/.local/share/nvim.bak
rm -rf ~/.local/state/nvim.bak
rm -rf ~/.cache/nvim.bak
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter ~/.config/nvim

rm -rf ~/.config/nvim/.git

# TODO: Setup config step
# rm -f ~/.config/nvim/config.lua &>/dev/null
# ln -s ~/dotfiles/configs/nvim/config.lua ~/.config/nvim/config.lua

