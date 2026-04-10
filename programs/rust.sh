#!/bin/bash

# Source cargo env for the current shell
source "$HOME/.cargo/env" &>/dev/null

# fix ownership of cargo/rustup directories upfront in case a previous run left them root-owned
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.cargo" 2>/dev/null || true
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.rustup" 2>/dev/null || true
fi

# Install standalone rust-analyzer binary (no rustup/cargo required).
# This avoids bugs in toolchain-pinned versions.
install_rust_analyzer() {
    rm -f "$HOME/.local/bin/rust-analyzer"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        RA_TARGET="aarch64-apple-darwin"
    else
        RA_TARGET="x86_64-unknown-linux-gnu"
    fi
    mkdir -p "$HOME/.cargo/bin"
    curl -L "https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-${RA_TARGET}.gz" | gunzip -c - > "$HOME/.cargo/bin/rust-analyzer"
    chmod +x "$HOME/.cargo/bin/rust-analyzer"
}

if [ -f "$HOME/work/.zshrc_aliases" ] && [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "work devbox detected; skipping rust install & toolchain management"
    # Linux devbox manages its own rust toolchain via Nix.
    # Skip rustup management, but use the Nix-provided cargo for tool installs.
    install_rust_analyzer

    if command -v cargo &>/dev/null; then
        cargo install --locked tree-sitter-cli 2>/dev/null || true
        cargo install --locked cargo-subspace --force 2>/dev/null || true
    fi

    # fix ownership after downloads
    if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
        sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.cargo" 2>/dev/null || true
    fi
    exit 0
fi

# --- Non-work computer: full rust install ---

# Clean old rust installation, if present
rustup self uninstall -y &>/dev/null
# Fresh install via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env" &>/dev/null
if [[ "$OSTYPE" == "darwin"* ]]; then
    xcode-select --install &>/dev/null
fi
echo "rust installed~"

# Everything below requires a working rust/cargo installation
if ! command -v rustup &>/dev/null && ! [[ -f "$HOME/.cargo/bin/rustup" ]]; then
    echo "rustup not found, skipping rust toolchain setup"
    exit 0
fi

# set default toolchain to latest nightly
rustup default nightly
rustup update nightly

# packages
rustup component add rust-src

install_rust_analyzer

# fix ownership after downloads/installs
if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.cargo" 2>/dev/null || true
    sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.rustup" 2>/dev/null || true
fi

# tree-sitter CLI -- needed by nvim-treesitter to compile parsers from source.
# Building from source avoids GLIBC mismatch issues with pre-built binaries.
cargo install --locked tree-sitter-cli

# https://github.com/ethowitz/cargo-subspace
# helps keep large cargo projects lazy-loading with rust-analyzer
cargo install --locked cargo-subspace --force
