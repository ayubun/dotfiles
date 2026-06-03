#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> dotfiles"
bash "$SCRIPT_DIR/dotfiles.sh"

echo "==> work"
bash "$SCRIPT_DIR/work.sh"
