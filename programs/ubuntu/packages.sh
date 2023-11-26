#!/bin/bash

fix-apt() {
    sudo dpkg-reconfigure -f noninteractive -plow libpam-modules &>/dev/null
    sudo apt-fast --fix-broken install -y &>/dev/null
    sudo apt-fast --fix-missing install -y &>/dev/null
    sudo apt-fast install -f -y &>/dev/null
}
export -f fix-apt

packages=(
    'build-essential'
    'manpages-dev'
    'dnsutils'
    'neofetch'
    'net-tools'
    'htop'
    'nano'
)
apt_repositories=(
)

# Wait to acquire apt lock
while ! { set -C; 2>/dev/null >$HOME/dotfiles/tmp/apt.lock; }; do
    sleep 1
done

# Clean
safer-apt-fast remove "${packages[@]}"

for repository in ${apt_repositories[@]}; do
    sudo add-apt-repository -y $repository
done
safer-apt-fast update
safer-apt-fast upgrade

install_package() {
    if ! safer-apt-fast install $1; then
        fix-apt
        safer-apt-fast install $1
    fi
}
export -f install_package

install_all_packages() {
    ATTEMPTS=0
    while ! timeout -t 600 sudo apt-fast -y install "${packages[@]}"; do
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
safer-apt-fast autoremove

# Unlock apt lock
rm -f $HOME/dotfiles/tmp/apt.lock
