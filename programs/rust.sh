#!/bin/bash


if [ -f $HOME/work/.zshrc_aliases ]; then
  echo "work computer detected; ignoring rust install"
else
  # Clean old rust installation, if present
  rustup self uninstall -y &>/dev/null
  # Fresh install via rustup
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # Configure current shell
  source $HOME/.cargo/env &>/dev/null
  if [[ "$OSTYPE" == "darwin"* ]]; then
      xcode-select --install &>/dev/null
  fi
  echo "rust installed~"
fi

# clean up old standalone rust-analyzer location
rm -f ~/.local/bin/rust-analyzer

# set default toolchain to latest nightly
rustup default nightly
rustup update nightly

# packages
rustup component add rust-src

# install latest standalone rust-analyzer (avoids bugs in toolchain-pinned versions)
if [[ "$OSTYPE" == "darwin"* ]]; then
  RA_TARGET="aarch64-apple-darwin"
else
  RA_TARGET="x86_64-unknown-linux-gnu"
fi
curl -L "https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-${RA_TARGET}.gz" | gunzip -c - > ~/.cargo/bin/rust-analyzer
chmod +x ~/.cargo/bin/rust-analyzer

# https://github.com/ethowitz/cargo-subspace
# helps keep large cargo projects lazy-loading with rust-analyzer
cargo install --locked cargo-subspace --force

