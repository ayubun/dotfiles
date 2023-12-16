#!/bin/bash

# Brew is a part of the mac dependencies for these dotfiles (so that we can have parallel
# pre-installed). Thus, we can just install brew packages normally here, using GNU parallel
# and brew fetch for async optimization.

packages=(
    'kubectl'
    'nano'
    'neofetch'
    'htop'
    'gcc'
    '--cask docker'
    'grpcurl'  # https://github.com/fullstorydev/grpcurl
    '--cask signal'
    '--cask telegram'
    '--cask arc'
)

# For some reason, the brew install for docker fails unless we ensure this doesn't exist prior
rm -rf /Applications/Docker.app
parallel -j+0 --no-notice --colsep ' ' brew fetch --quiet --force ::: "${packages[@]}"
parallel -j 1 --no-notice --colsep ' ' brew install ::: "${packages[@]}"
