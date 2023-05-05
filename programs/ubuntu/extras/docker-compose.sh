#!/bin/bash

# This script attempts to cleanly install docker-compose on Ubuntu
# https://docs.docker.com/compose/install/

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
