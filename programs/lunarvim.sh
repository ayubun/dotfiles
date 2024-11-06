#!/bin/bash

bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh) -s -- --no-install-dependencies
rm -f ~/.config/lvim/config.lua &>/dev/null
ln -s ~/dotfiles/configs/lvim/config.lua ~/.config/lvim/config.lua

