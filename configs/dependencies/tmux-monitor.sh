#!/bin/bash

if [[ "$TMUX_SESSION_NAME" != "ghostty" ]]; then
  # we only want to run this script for our ghostty tmux sesh
  return 0
fi

# Configuration
log_file="$HOME/.tmux_monitor/ghostty.log"

if [ -f "$log_file" ]; then
  line_count=$(grep -c . "$log_file")
  if [[ line_count > 100 ]]; then
    rm -rf $log_file
  fi
fi

mkdir -p ~/.tmux_monitor
echo \$(date +%s) > $log_file

