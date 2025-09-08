#!/bin/sh

CURRENT_DIR=$(pwd)

# Clear any current nvm install
rm -rf ~/.nvm
sudo apt-fast remove nodejs &>/dev/null
sudo apt-fast remove npm &>/dev/null
# Install nvm using Git
cd ~/
git clone https://github.com/nvm-sh/nvm.git .nvm
cd ~/.nvm
git checkout v0.40.1
# Populate the default packages for node
echo "yarn" >~/.nvm/default-packages
# Activate nvm
chmod +x nvm.sh
source nvm.sh
# Activate nvm for current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install node v18 (will also install yarn)
nvm install 'lts/hydrogen' --reinstall-packages-from=current
# Install node v20
nvm install 'lts/iron' --reinstall-packages-from=current
# Update npm to newer major version
npm install -g npm@11.4.2

# Return to original dir before cd-ing during script
cd $CURRENT_DIR

# install npm packages
. ~/dotfiles/programs/dependencies/npm-packages.sh

