#!/bin/bash

# Add local bin and local man directories (if missing)
mkdir $HOME/.local/bin &>/dev/null
mkdir $HOME/.local/man &>/dev/null

# This install script works on both MacOS and Linux, but I moved it to a mac-specific
# installation path in order to move away from multiple package managers on a single OS.

CURRENT_DIR=$(pwd)
cd $HOME/dotfiles/tmp

# Run pre-install scripts (OS-specific cleanups)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
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
elif [[ "$OSTYPE" == "darwin"* ]]; then
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
fi

# Installs Homebrew for MacOS or Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # I cant seem to get around not requiring a password on macOS...
    # Running in NONINTERACTIVE mode breaks the install process :(
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Run post-install scripts
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Post-brew installation script for Linux
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Post-brew installation script for Mac OS
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# We need gnu parallel to run our dotfiles faster (async)
# https://superuser.com/questions/1659206/run-background-async-cmd-with-sync-output
brew install parallel

cd $CURRENT_DIR
