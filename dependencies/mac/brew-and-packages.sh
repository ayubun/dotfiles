#!/bin/bash

# Add local bin and local man directories (if missing)
mkdir $HOME/.local/bin &>/dev/null
mkdir $HOME/.local/man &>/dev/null

# This install script works on both MacOS and Linux, but I moved it to a mac-specific
# installation path in order to move away from multiple package managers on a single OS.

CURRENT_DIR=$(pwd)

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
    TMP_DIR="$HOME/dotfiles/tmp"
    mkdir -p "$TMP_DIR" &>/dev/null
else
    TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"

# # Run pre-install scripts (OS-specific cleanups)
# if [[ "$OSTYPE" == "linux-gnu"* ]]; then
#     # Pre-installation script for Brew on Linux

#     # Uninstalls homebrew, if present
#     curl -O https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh
#     NONINTERACTIVE=1 /bin/bash uninstall.sh --force
#     rm -f uninstall.sh
#     # Clean any remaining files
#     sudo rm -rf /home/linuxbrew
#     sudo rm -rf /opt/homebrew
#     # Remove .zprofile shellenv lines
#     sed -i '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
#     sed -i '/eval "$(\/home\/linuxbrew\/.linuxbrew\/bin\/brew shellenv)"/d' ~/.zprofile
# elif [[ "$OSTYPE" == "darwin"* ]]; then
#     # Pre-installation script for Brew on MacOS

#     # Uninstalls homebrew, if present
#     curl -O https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh
#     /bin/bash uninstall.sh --force
#     rm -f uninstall.sh
#     # Clean any remaining files
#     sudo rm -rf /opt/homebrew
#     # Remove .zprofile shellenv lines
#     sed -i'.sed-backup' '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
#     rm ~/.zprofile.sed-backup
# fi

# Installs Homebrew for MacOS or Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Homebrew refuses to run as root, so we need to run as the original user
    # Use NONINTERACTIVE mode and run as original user
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
        # Run as original user using sudo -u
        sudo -u "$ORIGINAL_USER" -H bash -c "NONINTERACTIVE=1 CI=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        echo "Error: Cannot install Homebrew - original user information not available"
        exit 1
    fi
fi

# Run post-install scripts
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Post-brew installation script for Linux
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Post-brew installation script for Mac OS - run as original user
    if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
        # Add to original user's .zprofile and evaluate for this session
        sudo -u "$ORIGINAL_USER" bash -c 'echo '\''eval "$(/opt/homebrew/bin/brew shellenv)"'\'' >> '"$ORIGINAL_HOME"'/.zprofile'
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# We need gnu parallel to run our dotfiles faster (async)
# https://superuser.com/questions/1659206/run-background-async-cmd-with-sync-output
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

if [[ "$OSTYPE" == "darwin"* ]] && [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    # Run brew as original user on macOS
    sudo -u "$ORIGINAL_USER" -H bash -c 'eval "$(/opt/homebrew/bin/brew shellenv)" && brew install --force-bottle parallel'
else
    # Run normally on Linux (where brew can run as root)
    brew install --force-bottle parallel
fi

cd "$CURRENT_DIR"

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
    rm -rf "$TMP_DIR"
fi
