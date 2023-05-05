#!/bin/bash

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
sudo apt-fast -y install "${packages[@]}"
