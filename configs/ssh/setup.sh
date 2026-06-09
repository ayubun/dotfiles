#!/bin/bash
#
# Configures this machine's SSH *client* config so that markdown-preview.nvim and
# `lemonade open <url>` on a remote host open in THIS Mac's browser.
#
# Mac only: the Mac is where the browser (and the `lemonade server`) lives, so it
# is the side that initiates SSH connections and sets up the forwards. The actual
# RemoteForward/LocalForward directives live in configs/ssh/lemonade.conf; here we
# just make sure ~/.ssh/config Includes that file (idempotently, at the top).
#
# NOTE: this file is sourced by install.sh, so avoid `set -e` (it would leak into
# the parent shell) and prefer `return` for early exit.

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
INCLUDE_PATH="~/dotfiles/configs/ssh/lemonade.conf"
INCLUDE_LINE="Include $INCLUDE_PATH"

# Only the Mac (SSH client + browser host) needs the lemonade forwards.
if [[ "$OSTYPE" != darwin* ]]; then
  echo "Not macOS -- skipping lemonade SSH client config"
  return 0 2>/dev/null || exit 0
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if grep -qF "$INCLUDE_PATH" "$SSH_CONFIG"; then
  echo "lemonade SSH Include already present in $SSH_CONFIG"
else
  # Prepend the Include so its Host-* forwards apply to every connection.
  # Overwrite in place (via a temp copy) to preserve the file's 600 perms.
  tmp="$(mktemp)"
  {
    echo "$INCLUDE_LINE"
    echo ""
    cat "$SSH_CONFIG"
  } >"$tmp"
  cat "$tmp" >"$SSH_CONFIG"
  rm -f "$tmp"
  echo "Added '$INCLUDE_LINE' to top of $SSH_CONFIG"
fi
