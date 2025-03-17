#!/bin/bash

# Brew is a part of the mac dependencies for these dotfiles (so that we can have parallel
# pre-installed). Thus, we can just install brew packages normally here, using GNU parallel
# and brew fetch for async optimization.

packages=(
    # casks
    '--cask docker'
    '--cask signal'
    '--cask telegram'
    '--cask arc'
    '--cask ghostty'
    '--cask cursor'
    '--cask discord'
    '--cask discord@canary'
    '--cask raycast'
    '--cask spotify'
    #
    'kubectl'
    'nano'
    'neofetch'  # TODO: switch off neofetch
    'onefetch'
    'htop'
    'gcc'
    'grpcurl'  # https://github.com/fullstorydev/grpcurl
    'koekeishiya/formulae/skhd'
    'bat'
    'difftastic'
    'neovim'
    'httpie'
    'ripgrep'
    'python@3.12'
    'jesseduffield/lazygit/lazygit'
    'fd'
    'tmux'
)

# For some reason, the brew install for docker fails unless we ensure this doesn't exist prior
rm -rf /Applications/Docker.app
parallel -j+0 --no-notice --colsep ' ' brew fetch --quiet --force ::: "${packages[@]}"
parallel -j 1 --no-notice --colsep ' ' brew install ::: "${packages[@]}"

# https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
rm -f ~/Library/Application\ Support/lazygit/config.yml
ln -s ~/dotfiles/configs/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

