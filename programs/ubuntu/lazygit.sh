#!/bin/bash

CURRENT_DIR=$(pwd)
mkdir $HOME/dotfiles/tmp &>/dev/null
cd $HOME/dotfiles/tmp

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# https://github.com/jesseduffield/lazygit/issues/2187#issuecomment-1259243646
rm -f ~/.config/lazygit/config.yml &>/dev/null
ln -s ~/dotfiles/configs/lazygit/config.yml ~/.config/lazygit/config.yml

cd $CURRENT_DIR
