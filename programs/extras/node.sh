#!/bin/sh

CURRENT_DIR=$(pwd)

# Clear any current nvm install
rm -rf ~/.nvm
sudo apt-get remove nodejs &>/dev/null
sudo apt-get remove npm &>/dev/null
# Install nvm using Git
cd ~/
git clone https://github.com/nvm-sh/nvm.git .nvm
cd ~/.nvm
git checkout v0.39.3
# Populate the default packages for node
echo "yarn" > ~/.nvm/default-packages
# Activate nvm
chmod +x nvm.sh
source nvm.sh
# Activate nvm for current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Install node v16 (will also install yarn)
nvm install 'lts/gallium' --reinstall-packages-from=current
# Update npm to newer major version
npm install -g npm@9.6.2

# Return to original dir before cd-ing during script
cd $CURRENT_DIR
