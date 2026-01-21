#!/bin/bash

if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  # downgrade to original user
  su - $ORIGINAL_USER
else
  echo "⚠️WARNING: the dotfiles were run as a root user, meaning pipx cannot install programs as non-root. Installing as root..." 
fi

# ensure that the user and group of pipx is actually of the original user .. (otherwise this causes issues..)
sudo chown -R $(id -u):$(id -g) ~/.local/pipx &>/dev/null

# https://github.com/mhinz/neovim-remote
pipx install neovim-remote
pipx install pynvim --upgrade
pipx install basedpyright

