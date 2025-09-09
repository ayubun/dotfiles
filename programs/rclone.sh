#!/bin/bash

which rclone &>/dev/null
if [ $? -eq 0 ]; then
  sudo -v
  curl https://rclone.org/install.sh | sudo bash
else
  echo "rclone is already installed~"
fi
