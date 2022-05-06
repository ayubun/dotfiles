#!/bin/bash

# Post-brew installation script for Mac OS

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Mac-specific packages
brew install --cask google-cloud-sdk
