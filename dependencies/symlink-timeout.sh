#!/bin/bash

# Only install the shell-based timeout fallback if the system doesn't already have one
if ! command -v timeout &>/dev/null; then
    sudo ln -Fs "$HOME/dotfiles/timeout" /usr/local/bin/timeout &>/dev/null
    sudo chmod +x /usr/local/bin/timeout &>/dev/null
fi
