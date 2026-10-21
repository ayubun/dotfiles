#!/bin/bash

# fix ownership of pipx directory -- may be root-owned from a prior run
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    if [[ -d "$HOME/.local/pipx" ]]; then
        sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.local/pipx" &>/dev/null
    fi
fi

# pipx's shared pip vendors its own certifi; keep it current so installs stop trusting the compromised emSign root (needs pip >= 26.2.2)
shared_python="$HOME/.local/share/pipx/shared/bin/python"
[[ -x "$shared_python" ]] && "$shared_python" -m pip install --quiet --upgrade pip

# https://github.com/mhinz/neovim-remote
pipx install neovim-remote
pipx upgrade pynvim 2>/dev/null || pipx install pynvim
pipx install basedpyright
