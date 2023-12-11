#!/bin/bash

packages=(
    'build-essential'
    'manpages-dev'
    'dnsutils'
    'neofetch'
    'net-tools'
    'htop'
    'nano'
    'google-cloud-sdk-gke-gcloud-auth-plugin'  # weeeee
)
apt_repositories=(
)

# Wait to acquire apt lock
while ! { set -C; 2>/dev/null >$HOME/dotfiles/tmp/apt.lock; }; do
    sleep 1
done

fix-apt

# Clean
safer-apt-fast remove "${packages[@]}"

for repository in ${apt_repositories[@]}; do
    sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y $repository
done
safer-apt-fast update
safer-apt-fast upgrade
safer-apt-fast install "${packages[@]}"
safer-apt-fast autoremove

# Unlock apt lock
rm -f $HOME/dotfiles/tmp/apt.lock
