#!/bin/bash

# Install Zsh if missing (Ubuntu)
sudo apt-get install zsh -y &>/dev/null
# Make it default
sudo chsh -s $(which zsh) &>/dev/null

# Clean up any old (3+ days) backup files
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    find ~/. -mindepth 1 -maxdepth 1 -type f -mtime +2 \
        -regextype egrep -regex '.*\.pre-oh-my-zsh(-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})?$' \
        -delete
elif [[ "$OSTYPE" == "darwin"* ]]; then
    find -E ~/. -mindepth 1 -maxdepth 1 -mtime +2 \
        -regex '.*\.pre-oh-my-zsh(-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})?$' \
        -delete
fi
# Remove any old installation, if present
rm -r $HOME/.oh-my-zsh
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Install Powerlevel10k theme (https://github.com/romkatv/powerlevel10k)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# Edit the config to set the ZSH_THEME to powerlevel10k
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sed -i 's/^ZSH_THEME=".*"$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OS sed seems to require a backup, so we will just rm it after
    sed -i'.sed-backup' -e 's/^ZSH_THEME=".*"$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    rm ~/.zshrc.sed-backup
fi

cat <<EOF >> ~/.zshrc

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Run neofetch on terminal login! (just looks kinda cool :3)
echo ""
neofetch
echo ""

EOF
