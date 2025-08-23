#!/bin/bash

# Install Zsh if missing (Ubuntu)
sudo apt-get install zsh -y &>/dev/null
# Make it default
sudo chsh -s $(which zsh) &>/dev/null

# # If we already have zsh just continue
# if ! command -v zsh &>/dev/null; then
#     if sudo -n true 2>/dev/null; then           # password-less sudo available
#         sudo apt-get install -y zsh
#     else
#         echo "[ohmyz] Skipping zsh install – sudo not available non-interactively."
#     fi
# fi

# # Only try to change the login shell if we can do it without a prompt
# if [[ "$SHELL" != "$(which zsh)" ]]; then
#     if sudo -n true 2>/dev/null; then
#         sudo chsh -s "$(which zsh)" "$USER"
#     else
#         echo "[ohmyz] Skipping chsh – sudo not available non-interactively."
#     fi
# fi

# Clean up any old (3+ days) backup files
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    find ~/. -mindepth 1 -maxdepth 1 -type f -mtime +6 \
        -regextype egrep -regex '.*\.pre-oh-my-zsh(-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})?$' \
        -delete
elif [[ "$OSTYPE" == "darwin"* ]]; then
    find -E ~/. -mindepth 1 -maxdepth 1 -mtime +6 \
        -regex '.*\.pre-oh-my-zsh(-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})?$' \
        -delete
fi
# Remove any old installation, if present
sudo rm -r $HOME/.oh-my-zsh
# Install Oh My Zsh
export RUNZSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc
# Install Powerlevel10k theme (https://github.com/romkatv/powerlevel10k)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

if ! grep -q "# To customize prompt, run p10k configure or edit ~/.p10k.zsh." ~/.zshrc ; then
    echo "[Error] .zshrc file has been overridden by ohmyz.sh installation. Re-symlinking..."
    rm -f $HOME/.zshrc
    ln -s $HOME/dotfiles/configs/.zshrc $HOME/.zshrc
fi
