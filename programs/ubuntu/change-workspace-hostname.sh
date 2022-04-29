#!/bin/bash

# For some reason.. coder renames itself to workspace.
# I want my terminal to show milk-tea though because thats
# much cuter.. lol
if grep -q workspace "/etc/hostname"; then
  sudo hostnamectl set-hostname "milk-tea" &>/dev/null
  sudo hostnamectl set-hostname "milk-tea" --pretty&>/dev/null
fi
