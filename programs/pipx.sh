#!/bin/bash

# Function to run pipx commands as the original user if available
run_pipx() {
    if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
        # Run as the original user with their home directory
        sudo -u "$ORIGINAL_USER" -H pipx "$@"
    else
        echo "⚠️ WARNING: Running pipx as root"
        pipx "$@"
    fi
}

# fix ownership of pipx directory
# this can be created by root on accident (probably due to my own bad code lol)
# if that happens, all future pipx attempts fail, so we have to fix it first
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    ORIGINAL_HOME=$(eval echo ~$ORIGINAL_USER)
    if [[ -d "$ORIGINAL_HOME/.local/pipx" ]]; then
        sudo chown -R "$ORIGINAL_USER:$(id -gn $ORIGINAL_USER)" "$ORIGINAL_HOME/.local/pipx" &>/dev/null
    fi
else
    if [[ -d ~/.local/pipx ]]; then
        sudo chown -R $(id -u):$(id -g) ~/.local/pipx &>/dev/null
    fi
fi

# https://github.com/mhinz/neovim-remote
run_pipx install neovim-remote
run_pipx install pynvim --upgrade
run_pipx install basedpyright

