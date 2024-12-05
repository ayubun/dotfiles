#!/bin/bash

BOLD=`tput bold`
UNDERLINE=`tput smul`
YELLOW_TEXT=`tput setaf 3`
BLUE_TEXT=`tput setaf 4`
RESET=`tput sgr0`

packages=(
    'build-essential'
    'fail2ban'
    'unzip'
    'manpages-dev'
    'dnsutils'
    'neofetch'  # TODO: switch off neofetch
    'onefetch'
    'net-tools'
    'htop'
    'nano'
    'bat'
    'neovim'
    'httpie'  # https://github.com/httpie/cli?tab=readme-ov-file
    'ripgrep'  # https://github.com/BurntSushi/ripgrep
    'fd-find'  # https://github.com/sharkdp/fd?tab=readme-ov-file#installation
    'google-cloud-cli-bigtable-emulator'
)
apt_repositories=(
    'ppa:o2sh/onefetch'
    'ppa:neovim-ppa/unstable'
)

# Wait to acquire apt lock
while ! { set -C; 2>/dev/null >$HOME/dotfiles/tmp/apt.lock; }; do
    sleep 1
done

fix-apt

batch_size=50
total_packages=${#packages[@]}

# Clean
for (( i=0; i<total_packages; i+=batch_size )); do
    batch=("${packages[@]:i:batch_size}")
    echo ""
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Remove Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Removing ${UNDERLINE}${batch[*]}${RESET}"
    echo ""
    safer-apt-fast remove "${batch[@]}"
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Remove Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Done${RESET}"
done

for repository in ${apt_repositories[@]}; do
    sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y $repository
done

safer-apt-fast update
safer-apt-fast upgrade

for (( i=0; i<total_packages; i+=batch_size )); do
    batch=("${packages[@]:i:batch_size}")
    echo ""
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Install Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Installing ${UNDERLINE}${batch[*]}${RESET}"
    echo ""
    safer-apt-fast install "${batch[@]}"
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Install Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Done${RESET}"
done

safer-apt-fast autoremove

# Unlock apt lock
rm -f $HOME/dotfiles/tmp/apt.lock
