#!/bin/bash

extras_flag=''
verbose='false'

while getopts 'e:v' flag; do
  case "${flag}" in
    e) extras_flag='true' ;;
    v) verbose='true' ;;
  esac
done

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

# if [ "$EUID" -eq 0 ] ; then 
#     echo ""
#     echo "${RESET}${RED_TEXT}${BOLD}[ERROR]${RESET} ${RED_TEXT}${UNDERLINE}Please do not run this script as root!${RESET}"
#     exit 1
# fi

# echo ""
# stty -echo
# printf "Type your password for sudo access: "
# read PASSWORD
# stty echo
# echo "${MOVE_UP}${CLEAR_LINE}\n"


DOTFILES_FOLDER=$HOME/dotfiles

echo ""

find $DOTFILES_FOLDER/configs -maxdepth 1 -mindepth 1 -type f -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Symlinking ${UNDERLINE}${file}${RESET}" 
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/configs/$file $HOME/$file
done

# OS-Independent programs
find $DOTFILES_FOLDER/programs -maxdepth 1 -mindepth 1 -type f -print | \
while read file; do
    file=$(basename ${file})
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
    source $DOTFILES_FOLDER/programs/$file
done
if [ "extras_flag" = true ] ; then
    find $DOTFILES_FOLDER/programs/extras -maxdepth 1 -mindepth 1 -type f -print | \
    while read file; do
        file=$(basename ${file})
        echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}][${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
        source $DOTFILES_FOLDER/programs/$file
    done
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; thfasdfaen
        # Ubuntu programs
        find $DOTFILES_FOLDER/programs/ubuntu -maxdepth 1 -mindepth 1 -type f -print | \
        while read file; do
            file=$(basename ${file})
            echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Ubuntu${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
            source $DOTFILES_FOLDER/programs/ubuntu/$file
        done
        if [ "extras_flag" = true ] ; then
            find $DOTFILES_FOLDER/programs/ubuntu/extras -maxdepth 1 -mindepth 1 -type f -print | \
            while read file; do
                file=$(basename ${file})
                echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Ubuntu${RESET}${YELLOW_TEXT}][${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
                source $DOTFILES_FOLDER/programs/ubuntu/$file
            done
        fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac programs
        find $DOTFILES_FOLDER/programs/mac -maxdepth 1 -mindepth 1 -type f -print | \
        while read file; do
            file=$(basename ${file})
            echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Mac${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
            source $DOTFILES_FOLDER/programs/mac/$file
        done
        if [ "extras_flag" = true ] ; then
            find $DOTFILES_FOLDER/programs/mac/extras -maxdepth 1 -mindepth 1 -type f -print | \
            while read file; do
                file=$(basename ${file})
                echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Mac${RESET}${YELLOW_TEXT}][${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${file}${RESET}\n" 
                source $DOTFILES_FOLDER/programs/mac/$file
            done
        fi
fi

echo ""
echo ""
echo "${RESET}${GREEN_TEXT}${BOLD}            Installation is complete! (* ^ ω ^)" 
if [ "$extras_flag" = true ] ; then
    echo ""
    echo "${RESET}${GREEN_TEXT}     ヽ(*・ω・)ﾉ Extra programs have been included"
fi
echo ""
echo "${RESET}${YELLOW_TEXT}  Be sure to install the necessary fonts for Powerlevel10k:"
echo "${RESET}${YELLOW_TEXT}  https://github.com/romkatv/powerlevel10k/blob/master/font.md"
echo "${RESET}"
