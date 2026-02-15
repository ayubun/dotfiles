#!/bin/bash

BOLD=$(safe_tput bold || true)
UNDERLINE=$(safe_tput smul || true)
YELLOW_TEXT=$(safe_tput setaf 3 || true)
BLUE_TEXT=$(safe_tput setaf 4 || true)
RESET=$(safe_tput sgr0 || true)

packages=(
  'build-essential'
  'fail2ban'
  'unzip'
  'manpages-dev'
  'dnsutils'
  # neofetch installed separately below (deprecated upstream, may be unavailable on Ubuntu 24.10+)
  'onefetch'
  'net-tools'
  'htop'
  'btop'
  'nano'
  'bat'
  # 'neovim'
  'httpie'  # https://github.com/httpie/cli?tab=readme-ov-file
  'ripgrep' # https://github.com/BurntSushi/ripgrep
  'fd-find' # https://github.com/sharkdp/fd?tab=readme-ov-file#installation
  # 'tmux'
  # for remote clipboard integration on lvim
  'xsel'
  'xclip'
  #
  # 'lsd' # https://github.com/lsd-rs/lsd
  # ^ this doesnt work pre-ubuntu 23.. see programs/ubuntu/lsd.sh
  'python3-pip'
  'pipx'
  'ncdu'
)
apt_repositories=(
  'ppa:o2sh/onefetch'
  'ppa:neovim-ppa/stable'
  # 'ppa:pi-rho/dev'
)

# Wait to acquire apt lock (only if running under install.sh wrapper)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  while ! {
    set -C
    2>/dev/null >$HOME/dotfiles/tmp/apt.lock
  }; do
    sleep 1
  done
fi

fix-apt

batch_size=10
total_packages=${#packages[@]}

# Clean
# for (( i=0; i<total_packages; i+=batch_size )); do
#     batch=("${packages[@]:i:batch_size}")
#     echo ""
#     echo "${RESET}${YELLOW_TEXT}[${BOLD}Remove Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Removing ${UNDERLINE}${batch[*]}${RESET}"
#     echo ""
#     safer-apt-fast remove "${batch[@]}"
#     echo "${RESET}${YELLOW_TEXT}[${BOLD}Remove Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Done${RESET}"
# done

for repository in ${apt_repositories[@]}; do
  sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y $repository
done

safer-apt-fast update
safer-apt-fast upgrade

for ((i = 0; i < total_packages; i += batch_size)); do
  batch=("${packages[@]:i:batch_size}")
  echo ""
  echo "${RESET}${YELLOW_TEXT}[${BOLD}Install Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Installing ${UNDERLINE}${batch[*]}${RESET}"
  echo ""
  safer-apt-fast install "${batch[@]}"
  echo "${RESET}${YELLOW_TEXT}[${BOLD}Install Batch ${i}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Done${RESET}"
done

# neofetch is deprecated upstream and may not be in repos on Ubuntu 24.10+
# Install separately so a missing package doesn't break the batch
safer-apt-fast install neofetch 2>/dev/null || true

safer-apt-fast autoremove

# Unlock apt lock (only if we acquired it)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  rm -f $HOME/dotfiles/tmp/apt.lock
fi
