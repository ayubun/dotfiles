#!/bin/bash

fix-apt() {
    ALREADY_FIXING=false
    while ! { set -C; 2>/dev/null >$HOME/dotfiles/tmp/apt-fix.lock; }; do
        ALREADY_FIXING=true
        sleep 1
    done
    if [[ $ALREADY_FIXING == true ]]; then
        rm -f $HOME/dotfiles/tmp/apt-fix.lock
        return 0
    fi
    sudo apt-fast --fix-broken install -y &>/dev/null
    sudo apt-fast --fix-missing install -y &>/dev/null
    sudo apt-fast install -f -y &>/dev/null
    rm -f $HOME/dotfiles/tmp/apt-fix.lock
}
export -f fix-apt

packages=(
    'build-essential'
    'manpages-dev'
    'dnsutils'
    'neofetch'
    'google-cloud-sdk-pubsub-emulator'  # discord
    'net-tools'
    'htop'
    'nano'
    'python3.8'
)
apt_repositories=(
    'ppa:deadsnakes/ppa'  # python3.8
)

# Clean
sudo apt-fast -y remove "${packages[@]}"

for repository in ${apt_repositories[@]}; do
    sudo add-apt-repository -y $repository
done
sudo apt-fast update -y
sudo apt-fast upgrade -y

install_package() {
    if ! sudo apt-fast -y install $1; then
        fix-apt
        sudo apt-fast -y install $1
    fi
}
export -f install_package

install_all_packages() {
    ATTEMPTS=0
    while ! sudo apt-fast -y install "${packages[@]}"; do
        ATTEMPTS=$ATTEMPTS+1
        if [[ $ATTEMPTS > 4 ]]; then
            echo "Max apt install attempts reached"
            exit 1
        fi
        fix-apt
    done
}
export -f install_all_packages

install_all_packages
sudo apt-fast autoremove -y
