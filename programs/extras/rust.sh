#!/bin/bash

# Clean old rust installation, if present
rustup self uninstall -y &>/dev/null
# Fresh install via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Configure current shell
source $HOME/.cargo/env &>/dev/null
if [[ "$OSTYPE" == "darwin"* ]]; then
    xcode-select --install &>/dev/null
fi
