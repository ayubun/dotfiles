#!/bin/bash

# Pre-installation script for Brew on Linux

sudo rm -rf /home/linuxbrew
sudo rm -rf /opt/homebrew

sed -i '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
sed -i '/eval "$(\/home\/linuxbrew\/.linuxbrew\/bin\/brew shellenv)"/d' ~/.zprofile
