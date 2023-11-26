#!/bin/bash

# Wait to acquire apt lock
while ! { set -C; 2>/dev/null >$HOME/dotfiles/tmp/apt.lock; }; do
    sleep 1
done

fix-apt() {
    sudo dpkg-reconfigure -f noninteractive -plow libpam-modules &>/dev/null
    sudo apt-fast --fix-broken install -y &>/dev/null
    sudo apt-fast --fix-missing install -y &>/dev/null
    sudo apt-fast install -f -y &>/dev/null
}
export -f fix-apt

packages=(
  'docker-ce'
  'docker-ce-cli' 
  'containerd.io'
  'python3.8'
)
apt_repositories=(
  'ppa:deadsnakes/ppa'  # python3.8
)

# Clean
safer-apt-fast remove "${packages[@]}"

# Repository setups
docker_repository_setup() {
  safer-apt-fast install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}
docker_repository_setup
for repository in ${apt_repositories[@]}; do
    sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y $repository
done

safer-apt-fast update
safer-apt-fast upgrade

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
