#!/bin/bash

set -euo pipefail

CATPPUCCIN_TMUX_VERSION="${CATPPUCCIN_TMUX_VERSION:-v2.3.0}"
CATPPUCCIN_TMUX_REPOSITORY="https://github.com/catppuccin/tmux.git"
CATPPUCCIN_TMUX_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/catppuccin/tmux"
TPM_PATH="$HOME/.tmux/plugins/tpm"

if [[ ! "$CATPPUCCIN_TMUX_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "invalid catppuccin tmux version: $CATPPUCCIN_TMUX_VERSION" >&2
  exit 1
fi

if [[ -d "$TPM_PATH/.git" ]]; then
  echo "tmux tpm is already installed~"
elif [[ -e "$TPM_PATH" ]]; then
  echo "cannot install tmux tpm over existing path: $TPM_PATH" >&2
  exit 1
else
  mkdir -p "$(dirname "$TPM_PATH")"
  git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
  echo "tmux tpm is now installed~"
fi

if [[ -d "$CATPPUCCIN_TMUX_PATH/.git" ]]; then
  if [[ "$(git -C "$CATPPUCCIN_TMUX_PATH" remote get-url origin)" != "$CATPPUCCIN_TMUX_REPOSITORY" ]]; then
    echo "unexpected catppuccin tmux origin: $CATPPUCCIN_TMUX_PATH" >&2
    exit 1
  fi
  if [[ -n "$(git -C "$CATPPUCCIN_TMUX_PATH" status --porcelain)" ]]; then
    echo "catppuccin tmux checkout has local changes: $CATPPUCCIN_TMUX_PATH" >&2
    exit 1
  fi

  git -C "$CATPPUCCIN_TMUX_PATH" fetch --depth 1 origin tag "$CATPPUCCIN_TMUX_VERSION"
  git -C "$CATPPUCCIN_TMUX_PATH" checkout --detach "$CATPPUCCIN_TMUX_VERSION"
elif [[ -e "$CATPPUCCIN_TMUX_PATH" ]]; then
  echo "cannot install catppuccin tmux over existing path: $CATPPUCCIN_TMUX_PATH" >&2
  exit 1
else
  mkdir -p "$(dirname "$CATPPUCCIN_TMUX_PATH")"
  git clone --branch "$CATPPUCCIN_TMUX_VERSION" --depth 1 \
    "$CATPPUCCIN_TMUX_REPOSITORY" "$CATPPUCCIN_TMUX_PATH"
fi

echo ""
echo "catppuccin tmux $CATPPUCCIN_TMUX_VERSION is installed~"
