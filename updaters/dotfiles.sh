#!/bin/bash

cd ~/dotfiles
if [[ -z "$(git status -s)" ]]; then
  git add --all
  git stash
fi
git pull

