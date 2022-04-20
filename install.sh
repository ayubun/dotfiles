#!/bin/bash


# 0 to 7 = black, red, green, yellow, blue, magenta, cyan, white
MOVE_UP=`tput cuu 1`
CLEAR_LINE=`tput el 1`
BOLD=`tput bold`
UNDERLINE=`tput smul`
RED_TEXT=`tput setaf 1`
GREEN_TEXT=`tput setaf 2`
YELLOW_TEXT=`tput setaf 3`
BLUE_TEXT=`tput setaf 4`
MAGENTA_TEXT=`tput setaf 5`
CYAN_TEXT=`tput setaf 6`
WHITE_TEXT=`tput setaf 7`
RESET=`tput sgr0`


DOTFILES_FOLDER=$HOME/dotfiles

echo ""

find $DOTFILES_FOLDER/config -maxdepth 1 -mindepth 1 -type f -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Symlinking ${UNDERLINE}${file}${RESET}" 
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/config/$file $HOME/$file
done

# OS-Independent programs
find $DOTFILES_FOLDER/programs -maxdepth 1 -mindepth 1 -type f -print | \
while read file; do
    file=$(basename ${file})
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
    source $DOTFILES_FOLDER/programs/$file
done

echo "$OSTYPE"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Ubuntu programs
        find $DOTFILES_FOLDER/programs/ubuntu -maxdepth 1 -mindepth 1 -type f -print | \
        while read file; do
            file=$(basename ${file})
            echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Ubuntu${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
            source $DOTFILES_FOLDER/programs/ubuntu/$file
        done
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac programs
        find $DOTFILES_FOLDER/programs/mac -maxdepth 1 -mindepth 1 -type f -print | \
        while read file; do
            file=$(basename ${file})
            echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Mac${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
            source $DOTFILES_FOLDER/programs/mac/$file
        done
fi

echo ""
echo ""
echo "${RESET}${GREEN_TEXT}${BOLD}Installation is complete! (* ^ ω ^)" 
echo ""
