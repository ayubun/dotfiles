#!/bin/bash

DOTFILES_FOLDER=$HOME/dotfiles

# Installs Homebrew for MacOS and Linux
echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Run post-install scripts
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    source $DOTFILES_FOLDER/programs/ubuntu/post-install/brew.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    source $DOTFILES_FOLDER/programs/mac/post-install/brew.sh
fi
