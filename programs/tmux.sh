#!/bin/bash

# OS-agnostic tmux installer. Builds tmux from source at a pinned version so
# both macOS and Ubuntu boxes end up on the exact same release (apt and brew
# both lag/race the upstream and drift apart otherwise).

set -e

TMUX_VERSION="3.5a"
CONFIGURE_FLAGS=()

# ---------- OS-specific build deps & install path ----------
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  sudo apt update -y &>/dev/null
  sudo apt install -y build-essential libevent-dev ncurses-dev 2>/dev/null
  sudo apt autoremove -y automake 2>/dev/null
  sudo apt install -y automake pkg-config autoconf bison 2>/dev/null

  INSTALL_PATH="/usr/bin"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Make sure brew is on PATH (install.sh exports it, but allow standalone runs)
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

  # Xcode CLT supplies gcc/make. Brew handles the rest. utf8proc is required
  # on macOS because the system Unicode support is poor; tmux's configure
  # refuses to proceed without an explicit choice.
  brew install libevent ncurses automake pkg-config autoconf bison utf8proc 2>/dev/null || true

  # Brew's bison is keg-only; tmux's autogen.sh needs a modern bison on PATH
  # (macOS ships bison 2.3, which is too old).
  if BISON_PREFIX=$(brew --prefix bison 2>/dev/null); then
    export PATH="$BISON_PREFIX/bin:$PATH"
  fi

  # If a brew-installed tmux already exists, remove it so it doesn't shadow the
  # one we're about to build (brew lives at /opt/homebrew/bin which is earlier
  # on PATH than /usr/local/bin).
  if brew list tmux &>/dev/null; then
    brew uninstall --ignore-dependencies tmux 2>/dev/null || true
  fi

  CONFIGURE_FLAGS+=(--enable-utf8proc)
  INSTALL_PATH="/usr/local/bin"
  sudo mkdir -p "$INSTALL_PATH"
else
  echo "Unsupported OS for tmux install: $OSTYPE"
  exit 1
fi

# ---------- Fetch & build ----------
# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
  TMP_DIR="$HOME/dotfiles/tmp"
  mkdir -p "$TMP_DIR" &>/dev/null
else
  TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"
# Clear any leftover clone so `git clone` doesn't fail on re-runs
rm -rf ./tmux

git clone https://github.com/tmux/tmux.git
cd tmux
git fetch --tags
git checkout "$TMUX_VERSION"
sh autogen.sh
./configure "${CONFIGURE_FLAGS[@]}"
make

sudo mv -f ./tmux "$INSTALL_PATH/"

echo "tmux $TMUX_VERSION installed to $INSTALL_PATH/tmux"

cd /

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
  sudo rm -rf "$TMP_DIR"
fi
