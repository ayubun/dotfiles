#!/bin/bash

if [ -d ~/.tmux/plugins/tpm ]; then
    echo "tmux tpm is already installed~"
else
    # freshly install tpm
    rm -rf ~/.tmux/plugins/tpm || true
    mkdir -p ~/.tmux/plugins/tpm || true
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo ""
    echo "tmux tpm is now installed~"
fi
