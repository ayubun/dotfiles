#!/bin/bash

# Wait to acquire apt lock (only if running under install.sh wrapper)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
while ! { set -C; 2>/dev/null >$HOME/dotfiles/tmp/apt.lock; }; do
    sleep 1
done
fi

packages=(
  'docker-ce'
  'docker-ce-cli' 
  'containerd.io'
  'python3.12'
)
apt_repositories=(
  'ppa:deadsnakes/ppa'  # python3.8
)

fix-apt

# Clean
# safer-apt-fast remove "${packages[@]}"

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
safer-apt-fast install "${packages[@]}"
safer-apt-fast autoremove

# Unlock apt lock (only if we acquired it)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
rm -f $HOME/dotfiles/tmp/apt.lock
fi
