#!/bin/bash

# Pre-installation script for Brew on MacOS

# Uninstalls homebrew, if present
curl -O https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh
/bin/bash uninstall.sh --force
rm -f uninstall.sh
# Clean any remaining files
sudo rm -rf /opt/homebrew
# Remove .zprofile shellenv lines
sed -i'.sed-backup' '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
rm ~/.zprofile.sed-backup
