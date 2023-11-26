#!/bin/bash

safer-apt update
# software-properties-common adds `add-apt-repository` 
safer-apt install software-properties-common
# https://github.com/ilikenwf/apt-fast
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y 'ppa:apt-fast/stable'
safer-apt update
config-apt-fast() {
    sudo rm -f /etc/apt-fast.conf
    sudo ln -s $HOME/dotfiles/configs/packages/apt-fast.conf /etc/apt-fast.conf
}
safer-apt install apt-fast
config-apt-fast

# We need gnu parallel to run our dotfiles faster (async)
# https://superuser.com/questions/1659206/run-background-async-cmd-with-sync-output
safer-apt-fast install parallel
