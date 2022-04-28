#!/bin/bash

# Pre-installation script for Brew on Linux

# Uninstalls homebrew, if present
curl -O https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh
NONINTERACTIVE=1 /bin/bash uninstall.sh --force
rm -f uninstall.sh
# Clean any remaining files
sudo rm -rf /home/linuxbrew
sudo rm -rf /opt/homebrew
# Remove .zprofile shellenv lines
sed -i '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
sed -i '/eval "$(\/home\/linuxbrew\/.linuxbrew\/bin\/brew shellenv)"/d' ~/.zprofile
