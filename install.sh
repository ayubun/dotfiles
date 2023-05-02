#!/bin/bash

# https://unix.stackexchange.com/questions/196603/can-someone-explain-in-detail-what-set-m-does
set -m

EXTRAS=false
VERBOSE=false

while getopts 'ev' flag; do
  case "${flag}" in
    e) EXTRAS=true ;;
    v) VERBOSE=true ;;
  esac
done

rm -rf ./tmp
mkdir ./tmp

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
# TODO: Add a check to verify the install script is being run in the home directory

echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_PATH=ubuntu
    OS_NAME=Ubuntu
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_PATH=mac
    OS_NAME=Mac
else
    echo "Unsupported OS"
    exit 1
fi

# Install dependencies (i.e. GNU parallel)
find $DOTFILES_FOLDER/dependencies -maxdepth 1 -mindepth 1 -type f -name "*.sh" -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dependencies${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}" 
    . $DOTFILES_FOLDER/dependencies/$file
done
find $DOTFILES_FOLDER/dependencies/$OS_PATH -maxdepth 1 -mindepth 1 -type f -name "*.sh" -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME Dependencies${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}" 
    . $DOTFILES_FOLDER/dependencies/$OS_PATH/$file
done

find $DOTFILES_FOLDER/configs -maxdepth 1 -mindepth 1 -type f -name ".*" -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Symlinking ${UNDERLINE}${file}${RESET}" 
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/configs/$file $HOME/$file
done

# OS-Independent programs
if [[ $EXTRAS = true ]] ; then
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs $DOTFILES_FOLDER/programs/extras -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
else
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
fi

# OS-specific programs
if [[ $EXTRAS = true ]] ; then
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs/$OS_PATH $DOTFILES_FOLDER/programs/$OS_PATH/extras -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
else
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs/$OS_PATH -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
fi

rm -rf ./tmp

echo ""
echo ""
echo "${RESET}${GREEN_TEXT}${BOLD}            Installation is complete! (* ^ ω ^)" 
if [[ $EXTRAS = true ]] ; then
    echo ""
    echo "${RESET}${GREEN_TEXT}     ヽ(*・ω・)ﾉ Extra programs have been included"
fi
echo ""
echo "${RESET}${YELLOW_TEXT}  Be sure to install the necessary fonts for Powerlevel10k:"
echo "${RESET}${YELLOW_TEXT}  https://github.com/romkatv/powerlevel10k/blob/master/font.md"
echo "${RESET}"
