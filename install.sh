#!/bin/sh

DOTFILES_FOLDER=$HOME/dotfiles

find $DOTFILES_FOLDER/config -maxdepth 1 -mindepth 1 -type f -printf "%f\n" | \
while read file; do
    ln -s $DOTFILES_FOLDER/config/$file $HOME/$file
done
