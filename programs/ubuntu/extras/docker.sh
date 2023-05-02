#!/bin/bash

# This script attempts to cleanly install docker and docker-compose on Ubuntu
# Sources: https://docs.docker.com/engine/install/ubuntu/
# https://docs.docker.com/compose/install/

# ======
# DOCKER
# ======

# Remove any old files
sudo apt-fast remove docker docker-engine docker.io containerd runc -y
# Stable repository setup
sudo apt-fast update -y
sudo apt-fast autoremove -y
sudo apt-fast install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Install Docker Engine
sudo apt-fast update -y
sudo apt-fast install docker-ce docker-ce-cli containerd.io -y

# ==============
# DOCKER COMPOSE
# ==============

# Remove any old files
sudo rm -f /usr/local/bin/docker-compose
sudo rm -f /usr/bin/docker-compose
# Download
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
