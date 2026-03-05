#!/bin/bash

cd ~/work
if [[ -n "$(git status -s)" ]]; then
  git add --all
  git stash
fi
git pull

