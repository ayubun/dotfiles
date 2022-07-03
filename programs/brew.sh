#!/bin/bash

DOTFILES_FOLDER=$HOME/dotfiles

# Run pre-install scripts (OS-specific cleanups)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    source $DOTFILES_FOLDER/programs/ubuntu/pre-install/brew.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    source $DOTFILES_FOLDER/programs/mac/pre-install/brew.sh
fi
# Installs Homebrew for MacOS and Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # I cant seem to get around not requiring a password on macOS...
    # Running in NONINTERACTIVE mode breaks the install process :(
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Run post-install scripts
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    source $DOTFILES_FOLDER/programs/ubuntu/post-install/brew.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    source $DOTFILES_FOLDER/programs/mac/post-install/brew.sh
fi
# Packages! :3
brew install gcc
brew install htop
brew install neofetch
brew install nano
brew install kubectl
