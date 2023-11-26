#!/bin/bash

sudo ln -Fs $HOME/dotfiles/timeout /usr/bin/timeout || sudo ln -Fs $HOME/dotfiles/timeout /usr/local/bin/timeout &>/dev/null
sudo chmod +x /usr/local/bin/timeout &>/dev/null
