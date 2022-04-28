#!/bin/bash

# Post-brew installation script for Mac OS

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install some nice thingies
brew install htop
