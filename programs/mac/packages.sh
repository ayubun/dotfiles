#!/bin/bash

# Brew packages for macOS. Brew handles its own download parallelism and
# dependency resolution, so we just iterate and let it do its thing.

casks=(
  docker
  signal
  telegram
  arc
  ghostty
  cursor
  discord
  discord@canary
  raycast
  spotify
  batfi
)

formulae=(
  kubectl
  nano
  neofetch # TODO: switch off neofetch
  onefetch
  htop
  btop
  gcc
  grpcurl # https://github.com/fullstorydev/grpcurl
  bat
  difftastic
  neovim
  httpie
  ripgrep
  python@3.12
  jesseduffield/lazygit/lazygit
  fd
  tmux
  wireguard-tools
  lsd # https://github.com/lsd-rs/lsd
  python
  pipx
  tlrc # https://github.com/tldr-pages/tlrc
  ncdu
  dive # https://github.com/wagoodman/dive
)

# Formulae that must be compiled from source (no bottles available)
source_formulae=(
  koekeishiya/formulae/skhd
)

# Set environment variables for non-interactive brew operations
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Some cask installs (e.g. Docker) internally call sudo. Ensure passwordless
# sudo is available so the script can run non-interactively.
# If install.sh already set this up, the file exists and this is skipped.
if ! sudo -n true 2>/dev/null; then
  sudo -v
fi
if [[ ! -f /etc/sudoers.d/dotfiles-temp ]]; then
  sudo sh -c "echo '${ORIGINAL_USER:-$USER} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/dotfiles-temp && chmod 440 /etc/sudoers.d/dotfiles-temp"
  trap 'sudo rm -f /etc/sudoers.d/dotfiles-temp 2>/dev/null' EXIT
fi

# Run brew commands as original user on macOS (brew refuses to run as root)
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
  # Write formulae lists to temp files to pass through the sudo -u boundary
  # (casks can be passed inline since --force applies to all of them)
  formulae_file="$DOTFILES_FOLDER/tmp/formulae_$$.tmp"
  source_formulae_file="$DOTFILES_FOLDER/tmp/source_formulae_$$.tmp"
  mkdir -p "$DOTFILES_FOLDER/tmp"
  printf '%s\n' "${formulae[@]}" >"$formulae_file"
  printf '%s\n' "${source_formulae[@]}" >"$source_formulae_file"

  chmod 644 "$formulae_file" "$source_formulae_file"
  chown "$ORIGINAL_USER" "$formulae_file" "$source_formulae_file" 2>/dev/null || true

  echo "Running brew commands as user: $ORIGINAL_USER"

  # Pass cask names as an argument to avoid needing a temp file
  casks_list="${casks[*]}"

  sudo -u "$ORIGINAL_USER" -H bash -c '
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1

    echo "Fetching casks..."
    brew fetch --force --cask '"$casks_list"'

    echo "Fetching formulae..."
    while IFS= read -r pkg; do
      brew fetch --force "$pkg"
    done < "'"$formulae_file"'"

    echo "Installing casks..."
    brew install --cask --force '"$casks_list"'

    echo "Installing formulae..."
    while IFS= read -r pkg; do
      brew install --force-bottle "$pkg"
    done < "'"$formulae_file"'"

    echo "Installing source formulae..."
    while IFS= read -r pkg; do
      brew install "$pkg"
    done < "'"$source_formulae_file"'"

    echo ""
    echo "All done~ (* ・ｖ・)"
  '

  rm -f "$formulae_file" "$source_formulae_file"
else
  echo "Fetching casks..."
  brew fetch --force --cask "${casks[@]}"

  echo "Fetching formulae..."
  for pkg in "${formulae[@]}"; do
    brew fetch --force "$pkg"
  done

  echo "Installing casks..."
  brew install --cask --force "${casks[@]}"

  echo "Installing formulae..."
  for pkg in "${formulae[@]}"; do
    brew install --force-bottle "$pkg"
  done

  echo "Installing source formulae..."
  for pkg in "${source_formulae[@]}"; do
    brew install "$pkg"
  done
fi

# https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
mkdir -p ~/Library/Application\ Support/lazygit
rm -f ~/Library/Application\ Support/lazygit/config.yml
ln -s ~/dotfiles/configs/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
