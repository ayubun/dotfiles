#!/bin/bash

# Official apt repo per https://github.com/cli/cli/blob/trunk/docs/install_linux.md

KEYRING=/etc/apt/keyrings/githubcli-archive-keyring.gpg
SOURCE_LIST=/etc/apt/sources.list.d/github-cli.list
PIN_FILE=/etc/apt/preferences.d/github-cli
REPO_URL=https://cli.github.com/packages

tmpdir=$(mktemp -d)
have_lock=0
cleanup() {
  rm -rf "$tmpdir"
  [[ $have_lock -eq 1 ]] && rm -f "$HOME/dotfiles/tmp/apt.lock"
}
trap cleanup EXIT

# Wait to acquire apt lock (only if running under install.sh wrapper)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  while ! {
    set -C
    2>/dev/null >$HOME/dotfiles/tmp/apt.lock && have_lock=1
  }; do
    sleep 1
  done
fi

recover-apt

# True when the installed gh came from the official repo and is still its current version.
installed_current_from_repo() {
  apt-cache policy gh 2>/dev/null | grep -A1 '^ \*\*\*' | grep -q "$REPO_URL"
}

# Install a file only when its content differs, so healthy reruns write nothing.
install_if_changed() {
  local src=$1 dst=$2
  cmp -s "$src" "$dst" && return 1
  sudo mkdir -p -m 755 "$(dirname "$dst")"
  sudo install -m 644 "$src" "$dst" || exit 1
  return 0
}

changed=0

if ! curl -fsSL -o "$tmpdir/key" "${REPO_URL}/githubcli-archive-keyring.gpg" || [[ ! -s "$tmpdir/key" ]]; then
  if [[ -s "$KEYRING" ]] && installed_current_from_repo; then
    echo "could not refresh the GitHub CLI signing key; keeping the installed gh"
    exit 0
  fi
  echo "could not download the GitHub CLI signing key"
  exit 1
fi
install_if_changed "$tmpdir/key" "$KEYRING" && changed=1

# Another active source for the same repo would conflict on signed-by, so defer to it.
if grep -lsE "^[^#]*${REPO_URL}" /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources \
  | grep -qvxF "$SOURCE_LIST"; then
  echo "another apt source already provides ${REPO_URL}; leaving it alone"
  if [[ -e "$SOURCE_LIST" ]]; then
    sudo rm -f "$SOURCE_LIST" && changed=1
  fi
else
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] ${REPO_URL} stable main" >|"$tmpdir/list"
  install_if_changed "$tmpdir/list" "$SOURCE_LIST" && changed=1
fi

# Ubuntu Pro pins ESM at 510, which would otherwise win with its broken 2.45 build.
printf 'Package: gh\nPin: origin cli.github.com\nPin-Priority: 600\n' >|"$tmpdir/pin"
install_if_changed "$tmpdir/pin" "$PIN_FILE"

if [[ $changed -eq 1 ]] || ! apt-cache policy gh 2>/dev/null | grep -q "$REPO_URL"; then
  safer-apt-fast update
fi
installed_current_from_repo || safer-apt-fast install gh

# Check the installed state directly instead of trusting the apt exit code.
if ! installed_current_from_repo; then
  echo "gh is not installed from ${REPO_URL}"
  exit 1
fi
