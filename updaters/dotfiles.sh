#!/bin/bash

cd ~/dotfiles
if [[ -n "$(git status -s)" ]]; then
  git add --all
  git stash
fi
git pull

