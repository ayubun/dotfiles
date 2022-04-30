#!/bin/bash

# Post-brew installation script for Linux

echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.zprofile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
