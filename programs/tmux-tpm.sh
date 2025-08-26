#!/bin/bash

# freshly install tpm
rm -rf ~/.tmux/plugins/tpm || true
mkdir -p ~/.tmux/plugins/tpm || true
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
