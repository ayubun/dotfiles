#!/bin/bash

# Brew is a part of the mac dependencies for these dotfiles (so that we can have parallel
# pre-installed). Thus, we can just install brew packages normally here, using GNU parallel
# and brew fetch for async optimization.

packages=(
  # casks
  '--cask docker --force'
  '--cask signal'
  '--cask telegram'
  '--cask arc'
  '--cask ghostty'
  '--cask cursor'
  '--cask discord'
  '--cask discord@canary'
  '--cask raycast'
  '--cask spotify'
  '--cask batfi'
  #
  'kubectl'
  'nano'
  'neofetch' # TODO: switch off neofetch
  'onefetch'
  'htop'
  'btop'
  'gcc'
  'grpcurl' # https://github.com/fullstorydev/grpcurl
  'koekeishiya/formulae/skhd'
  'bat'
  'difftastic'
  'neovim'
  'httpie'
  'ripgrep'
  'python@3.12'
  'jesseduffield/lazygit/lazygit'
  'fd'
  'tmux'
  'wireguard-tools'
  'lsd' # https://github.com/lsd-rs/lsd
  'python'
  'pipx'
  'tlrc' # https://github.com/tldr-pages/tlrc
  'ncdu'
)

# Set environment variables for non-interactive brew operations
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# For some reason, the brew install for docker fails unless we ensure this doesn't exist prior
# rm -rf /Applications/Docker.app

# Run brew commands as original user on macOS (brew refuses to run as root)
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  # Write packages to a temporary file in a more accessible location
  # Use dotfiles/tmp directory instead of system temp to avoid sudo access issues
  packages_file="$DOTFILES_FOLDER/tmp/packages_$$.tmp"
  mkdir -p "$DOTFILES_FOLDER/tmp"
  printf '%s\n' "${packages[@]}" >"$packages_file"

  # Make the file readable by the original user
  chmod 644 "$packages_file"
  chown "$ORIGINAL_USER" "$packages_file" 2>/dev/null || true

  # Run as original user with proper output logging
  echo "Running brew commands as user: $ORIGINAL_USER"
  echo "Fetching packages..."

  sudo -u "$ORIGINAL_USER" -H bash -c "
        eval \"\$(/opt/homebrew/bin/brew shellenv)\"
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_INSTALL_CLEANUP=1
        
        # Read packages from temporary file
        packages_array=()
        while IFS= read -r line; do
            packages_array+=(\"\$line\")
        done < '$packages_file'
        
        echo \"Starting parallel fetch of \${#packages_array[@]} packages...\"
        parallel -j+0 --no-notice --colsep \" \" brew fetch --force ::: \"\${packages_array[@]}\"
        
        echo \"Starting parallel installation of \${#packages_array[@]} packages...\"
        parallel -j 1 --no-notice --colsep \" \" brew install --force-bottle ::: \"\${packages_array[@]}\"

        echo \"\"
        echo \"All done~ (* ・ｖ・)\"
    " 2>&1 | while IFS= read -r line; do
    echo "$line"
  done

  # Clean up temporary file
  rm -f "$packages_file"
else
  parallel -j+0 --no-notice --colsep ' ' brew fetch --quiet --force ::: "${packages[@]}"
  parallel -j 1 --no-notice --colsep ' ' brew install --force-bottle ::: "${packages[@]}"
fi

# https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
rm -f ~/Library/Application\ Support/lazygit/config.yml
ln -s ~/dotfiles/configs/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

