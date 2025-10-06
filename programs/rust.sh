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

# packages

rustup component add rust-src
# https://github.com/ethowitz/cargo-subspace
# helps keep large cargo projects lazy-loading with rust-analyzer
cargo install --locked cargo-subspace --force

