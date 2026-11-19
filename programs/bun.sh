#!/bin/bash

# Fix ownership in case a previous root-based install left these root-owned
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.bun" 2>/dev/null || true

# configs/.zshenv already puts bun on PATH; with bun visible the installer skips appending to ~/.zshrc
export PATH="${BUN_INSTALL:-$HOME/.bun}/bin:$PATH"
curl -fsSL https://bun.sh/install | bash
