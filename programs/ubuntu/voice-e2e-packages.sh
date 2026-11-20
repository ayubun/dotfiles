#!/bin/bash

# The coder root disk resets on restart, so reinstall the voice-e2e host packages each boot from the ai-brain-discord list.
USER_HOME="${ORIGINAL_HOME:-$HOME}"
REPO="$USER_HOME/ai-brain-discord"
SCRIPT="$REPO/skills/testing-voice-call-end-to-end/host-packages.sh"
if [[ ! -d "$REPO" ]]; then
  echo "skipping voice-e2e packages: $REPO is not cloned"
  exit 0
fi
if [[ ! -f "$SCRIPT" ]]; then
  echo "voice-e2e packages: $SCRIPT is missing" >&2
  exit 1
fi

# Wait to acquire apt lock (only if running under install.sh wrapper)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  while ! {
    set -C
    2>/dev/null >$HOME/dotfiles/tmp/apt.lock
  }; do
    sleep 1
  done
fi

recover-apt

# rc-guarded so a failure still falls through to the apt-lock release below
rc=0
bash "$SCRIPT" || rc=1

# Unlock apt lock (only if we acquired it)
if [[ -d "$HOME/dotfiles/tmp" ]]; then
  rm -f $HOME/dotfiles/tmp/apt.lock
fi

exit $rc
