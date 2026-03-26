#!/bin/bash

# Source cargo env for the current shell
source "$HOME/.cargo/env" &>/dev/null

# Helper to run commands as the original (non-root) user
run_as_user() {
    if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
        sudo -u "$ORIGINAL_USER" -H bash -c "source \$HOME/.cargo/env &>/dev/null && $1"
    else
        eval "$1"
    fi
}

# fix ownership of cargo/rustup directories upfront in case a previous run left them root-owned
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.cargo" 2>/dev/null || true
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.rustup" 2>/dev/null || true
fi

if [ -f "$HOME/work/.zshrc_aliases" ]; then
  echo "work computer detected; ignoring rust install"
else
  # Clean old rust installation, if present
  run_as_user "rustup self uninstall -y &>/dev/null"
  # Fresh install via rustup
  run_as_user "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
  source "$HOME/.cargo/env" &>/dev/null
  if [[ "$OSTYPE" == "darwin"* ]]; then
      xcode-select --install &>/dev/null
  fi
  echo "rust installed~"
fi

# Everything below requires a working rust/cargo installation
if ! command -v rustup &>/dev/null && ! [[ -f "$HOME/.cargo/bin/rustup" ]]; then
  echo "rustup not found, skipping rust toolchain setup"
  exit 0
fi

# clean up old standalone rust-analyzer location
rm -f "$HOME/.local/bin/rust-analyzer"

# set default toolchain to latest nightly
run_as_user "rustup default nightly"
run_as_user "rustup update nightly"

# packages
run_as_user "rustup component add rust-src"

# install latest standalone rust-analyzer (avoids bugs in toolchain-pinned versions)
if [[ "$OSTYPE" == "darwin"* ]]; then
  RA_TARGET="aarch64-apple-darwin"
else
  RA_TARGET="x86_64-unknown-linux-gnu"
fi
mkdir -p "$HOME/.cargo/bin"
curl -L "https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-${RA_TARGET}.gz" | gunzip -c - > "$HOME/.cargo/bin/rust-analyzer"
chmod +x "$HOME/.cargo/bin/rust-analyzer"

# fix ownership again after downloads/installs that ran as root (e.g. rust-analyzer curl)
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.cargo" 2>/dev/null || true
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.rustup" 2>/dev/null || true
fi

# https://github.com/ethowitz/cargo-subspace
# helps keep large cargo projects lazy-loading with rust-analyzer
run_as_user "cargo install --locked cargo-subspace --force"
