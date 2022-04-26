#!/bin/bash

# Pre-installation script for Brew on MacOS

sudo rm -rf /opt/homebrew

sed -i'.sed-backup' '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
rm ~/.zprofile.sed-backup
