#!/bin/bash

curl -sS https://starship.rs/install.sh | sh -s -- -y

mkdir -p ~/.config

rm -f ~/.config/starship.toml
ln -s ~/dotfiles/configs/dotconfig/starship.toml ~/.config/starship.toml

