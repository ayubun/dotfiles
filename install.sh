#!/bin/bash

DOTFILES_FOLDER=$HOME/dotfiles

find $DOTFILES_FOLDER/config -maxdepth 1 -mindepth 1 -type f -printf "%f\n" | \
while read file; do
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/config/$file $HOME/$file
done

find $DOTFILES_FOLDER/programs/ubuntu -maxdepth 1 -mindepth 1 -type f -printf "%f\n" | \
while read file; do
    source $DOTFILES_FOLDER/programs/ubuntu/$file
done
