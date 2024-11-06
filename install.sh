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

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DOTFILES_FOLDER=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
if [[ $DOTFILES_FOLDER != "$HOME/dotfiles" ]] ; then
    # if the current script is not being run from the home directory, we want to move to the home directory.
    rm -rf $HOME/dotfiles
    git clone https://github.com/ayubun/dotfiles.git $HOME/dotfiles
    cd $HOME/dotfiles
    ./install.sh
    exit 0
fi

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

rm -rf $DOTFILES_FOLDER/tmp
mkdir $DOTFILES_FOLDER/tmp


unlock-apt() {
    sudo rm -f /tmp/apt-fast.lock &>/dev/null
    sudo rm -f $HOME/dotfiles/tmp/apt.lock &>/dev/null
    sudo rm -f /var/lib/apt/lists/lock &>/dev/null
    sudo rm -f /var/cache/apt/archives/lock &>/dev/null
    sudo rm -f /var/lib/dpkg/lock* &>/dev/null
}
export -f unlock-apt
fix-apt() {
    sudo apt --fix-broken install -y &>/dev/null
    sudo apt --fix-missing install -y &>/dev/null
    sudo apt install -f -y &>/dev/null
}
export -f fix-apt
safer-apt() {
    timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt "$@" -y 2>/dev/null || unlock-apt && fix-apt && timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt "$@" -y 2>/dev/null || unlock-apt
}
export -f safer-apt
safer-apt-fast() {
    timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -yV 2>/dev/null || unlock-apt && fix-apt && timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -y 2>/dev/null || unlock-apt
}
export -f safer-apt-fast


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

find $DOTFILES_FOLDER/configs -maxdepth 1 -mindepth 1 -type f \( -name ".*" -o -name "personalize" \) -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Symlinking ${UNDERLINE}${file}${RESET}" 
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/configs/$file $HOME/$file
done


# OS-specific programs
if [[ $EXTRAS = true ]] ; then
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs/$OS_PATH $DOTFILES_FOLDER/programs/$OS_PATH/extras -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
else
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs/$OS_PATH -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
fi


# OS-independent programs
if [[ $EXTRAS = true ]] ; then
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs $DOTFILES_FOLDER/programs/extras -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
else
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    find $DOTFILES_FOLDER/programs -maxdepth 1 -mindepth 1 -type f -name "*.sh" | parallel --tty -j+0 --no-notice -I% --max-args 1 . %
fi


rm -rf $DOTFILES_FOLDER/tmp


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

