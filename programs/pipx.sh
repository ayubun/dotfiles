#!/bin/bash

# fix ownership of pipx directory -- may be root-owned from a prior run
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    if [[ -d "$HOME/.local/pipx" ]]; then
        sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.local/pipx" &>/dev/null
    fi
fi

# https://github.com/mhinz/neovim-remote
pipx install neovim-remote
pipx upgrade pynvim 2>/dev/null || pipx install pynvim
pipx install basedpyright
