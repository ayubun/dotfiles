#!/bin/bash

RELATIVE_SCRIPT_PATH=updaters/yabai.sh
SCRIPT_PATH=${HOME}/dotfiles/$RELATIVE_SCRIPT_PATH

# Remove any existing entry in the crontab
crontab -l | grep -v $RELATIVE_SCRIPT_PATH  | crontab - &>/dev/null
# Add updateer to crontab
(crontab -l 2>/dev/null; echo "0 13 * * * ${SCRIPT_PATH}") | crontab -
# Run the updater now (will install if missing)
. $SCRIPT_PATH

# Add to the list of sudoers
# echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
