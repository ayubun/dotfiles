#!/bin/bash

sudo apt update -y
# software-properties-common adds `add-apt-repository` 
sudo apt install software-properties-common -y
# https://github.com/ilikenwf/apt-fast
sudo add-apt-repository -y 'ppa:apt-fast/stable'
sudo apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y apt-fast

# Apply new config
DOTFILES_FOLDER=$HOME/dotfiles
rm -f /etc/apt-fast.conf
ln -s $DOTFILES_FOLDER/configs/packages/apt-fast.conf /etc/apt-fast.conf

# We need gnu parallel to run our dotfiles faster (async)
# https://superuser.com/questions/1659206/run-background-async-cmd-with-sync-output
sudo apt-fast install parallel -y
