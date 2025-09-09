#!/bin/sh

CURRENT_DIR=$(pwd)

# lets not run this on my work box .. cuz its specially configured
# however, i still want my default-packages
# so i will run through them and manually install, expecting a pre-existing node version
if [ -f $HOME/work/.zshrc_aliases ]; then
  echo "work computer detected; ignoring node install, but manually installing default packages:"
  packages_array=()
  while IFS= read -r line; do
      packages_array+=("$line")
  done < ~/dotfiles/programs/dependencies/node-default-packages
  for package in "${packages_array[@]}"; do
    if [[ -z "$package" ]]; then
      break
    fi
    echo ""
    echo "now installing package: $package"
    echo ""
    npm install -g ${package}
  done
  echo "all done with manual installs~"
  exit 0
fi
# Clear any current nvm/npm install
sudo rm -rf ~/.nvm ~/.npm
# Install nvm using Git
cd ~/
git clone https://github.com/nvm-sh/nvm.git .nvm
cd ~/.nvm
git checkout v0.40.3
# setup default packages
rm -rf ~/.nvm/default-packages
ln -s ~/dotfiles/programs/dependencies/node-default-packages ~/.nvm/default-packages
# Activate nvm
chmod +x nvm.sh
source nvm.sh
# Activate nvm for current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

cd $CURRENT_DIR

# v22
nvm install 'lts/jod' --reinstall-packages-from=current
# v20
nvm install 'lts/iron' --reinstall-packages-from=current
# v18
nvm install 'lts/hydrogen' --reinstall-packages-from=current
# ensure we use v22 as default
nvm alias default 'lts/jod'
nvm use 'lts/jod'
# Update npm to newer major version
npm install -g npm@latest
