#!/bin/bash

CURRENT_DIR=$(pwd)

# Create temp directory - prefer dotfiles/tmp if available, fallback to system tmp
if [[ -d "$HOME/dotfiles" ]]; then
    TMP_DIR="$HOME/dotfiles/tmp"
    mkdir -p "$TMP_DIR" &>/dev/null
else
    TMP_DIR=$(mktemp -d)
fi

cd "$TMP_DIR"


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

# rc-guarded so a failure still falls through to the apt-lock release below
# (a bare exit would leave the lock held and deadlock later apt scripts)
rc=0
DIVE_VERSION=$(gh_latest_version wagoodman/dive) || rc=1
if [[ $rc -eq 0 ]]; then
  ARCH=$(get_arch deb)
  DIVE_DEB="dive_${DIVE_VERSION}_linux_${ARCH}.deb"
  gh_download "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/${DIVE_DEB}" "$DIVE_DEB" \
    && safer-apt-fast install "./${DIVE_DEB}" || rc=1
fi


cd "$CURRENT_DIR"

# Unlock apt lock (only if we acquired it)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  rm -f $HOME/dotfiles/tmp/apt.lock
fi

# Clean up if we used system tmp
if [[ "$TMP_DIR" != "$HOME/dotfiles/tmp" ]]; then
    rm -rf "$TMP_DIR"
fi

exit $rc

