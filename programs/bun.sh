#!/bin/bash

# Fix ownership in case a previous root-based install left these root-owned
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.bun" 2>/dev/null || true

curl -fsSL https://bun.sh/install | bash
