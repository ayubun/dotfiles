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
    # Remove existing rust-analyzer from cargo/bin BEFORE writing the new one.
    # On Linux, rustup uses hardlinks — all proxies (rustup, cargo, rustc,
    # rust-analyzer, etc.) share the same inode.  Writing through the
    # hardlink with `>` would overwrite that shared inode and corrupt
    # every proxy.  Removing first breaks the hardlink so the new
    # standalone binary gets its own inode.
    rm -f "$HOME/.cargo/bin/rust-analyzer"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        RA_TARGET="aarch64-apple-darwin"
    else
        RA_TARGET="x86_64-unknown-linux-gnu"
    fi
    mkdir -p "$HOME/.cargo/bin"
    curl -L "https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-${RA_TARGET}.gz" | gunzip -c - > "$HOME/.cargo/bin/rust-analyzer"
    chmod +x "$HOME/.cargo/bin/rust-analyzer"
}

# Install cargo extensions that are shared across all environments.
install_cargo_extensions() {
    if command -v cargo &>/dev/null; then
        echo "cargo found at $(command -v cargo)"
        # tree-sitter CLI -- needed by nvim-treesitter to compile parsers from source.
        # Building from source avoids GLIBC mismatch issues with pre-built binaries.
        cargo install --locked tree-sitter-cli || true
        # https://github.com/ethowitz/cargo-subspace
        # helps keep large cargo projects lazy-loading with rust-analyzer
        cargo install --locked cargo-subspace --force || true
    else
        echo "WARNING: cargo not found in PATH, skipping cargo extensions"
    fi
}

# Fix ownership of cargo/rustup dirs after installs (root runs can leave them root-owned)
fix_cargo_ownership() {
    if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
        sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.cargo" 2>/dev/null || true
        sudo chown -R "$ORIGINAL_USER:$(id -gn "$ORIGINAL_USER")" "$HOME/.rustup" 2>/dev/null || true
    fi
}

if [ -f "$HOME/work/.zshrc_aliases" ] && [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "** work devbox detected **"
    # Linux devbox manages its own rust toolchain via Nix.
    # Skip rustup management, but use the Nix-provided cargo for tool installs.
    install_rust_analyzer

    # Ensure Nix-provided tools are in PATH (non-interactive shells don't
    # source shell profiles, so cargo from Nix may not be reachable).
    for nix_profile in "$HOME/.nix-profile/etc/profile.d/nix.sh" \
                       "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" \
                       "/etc/profile.d/nix.sh"; do
        [[ -f "$nix_profile" ]] && source "$nix_profile" 2>/dev/null
    done

    install_cargo_extensions
    fix_cargo_ownership
    echo "** work devbox setup complete **"
    exit 0
fi

# --- Non-work computer: full rust install ---

echo "** non-work machine detected **"

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
install_cargo_extensions
fix_cargo_ownership

echo "** non-work setup complete **"

