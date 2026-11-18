#!/bin/bash

set -uo pipefail

repo="${AI_BRAIN_REPO:-$HOME/ai-brain}"
workspace="$repo/tools/cli"
bin_dir="$HOME/.local/bin"
state_dir="$HOME/.local/state/ai-brain"
stamp="$state_dir/cli-source.hash"
failed_stamp="$state_dir/cli-source.failed"
os_type="${AI_BRAIN_CLI_OSTYPE:-$OSTYPE}"

warn() { printf 'ai-brain-cli: %s\n' "$*" >&2; }

is_work_devbox() { [[ -f "$HOME/work/.zshrc_aliases" && "$os_type" == linux-gnu* ]]; }

load_cargo() {
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  if is_work_devbox; then
    local profile
    # Cron does not load the Nix profile that provides cargo on work devboxes.
    for profile in "$HOME/.nix-profile/etc/profile.d/nix.sh" \
                   "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" \
                   "/etc/profile.d/nix.sh"; do
      [[ -f "$profile" ]] && source "$profile" 2>/dev/null
    done
  fi
  command -v cargo >/dev/null
}

install_rustup() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path || return 1
  source "$HOME/.cargo/env"
}

ensure_cargo() {
  load_cargo && return 0
  if is_work_devbox; then
    warn "cargo not found; work devboxes get cargo from nix"
    return 1
  fi
  install_rustup && command -v cargo >/dev/null
}

source_hash() {
  (cd "$workspace" && find . -path ./target -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r file; do
    printf '%s %s\n' "$(git hash-object -- "$file")" "$file"
  done) | git hash-object --stdin
}

build_if_stale() {
  [[ -f "$workspace/Cargo.toml" ]] || { warn "missing $workspace/Cargo.toml"; return 1; }
  local hash previous="" failed=""
  hash="$(source_hash)" || return 1
  [[ -f "$stamp" ]] && IFS= read -r previous <"$stamp"
  [[ "$previous" == "$hash" && -x "$bin_dir/ai-brain" ]] && return 0
  [[ -f "$failed_stamp" ]] && IFS= read -r failed <"$failed_stamp"
  if [[ "$failed" == "$hash" ]]; then
    warn "source unchanged since failed build; skipping"
    return 1
  fi
  load_cargo || { warn "cargo not found"; return 1; }
  mkdir -p "$state_dir" || return 1
  # Try offline first, then retry online after any offline build failure.
  cargo build --release --locked --offline --manifest-path "$workspace/Cargo.toml" ||
    cargo build --release --locked --manifest-path "$workspace/Cargo.toml" || {
      printf '%s\n' "$hash" >"$failed_stamp"
      warn "build failed"
      return 1
    }
  mkdir -p "$bin_dir" "$state_dir"
  cp "$workspace/target/release/ai-brain" "$bin_dir/.ai-brain.tmp" && mv -f "$bin_dir/.ai-brain.tmp" "$bin_dir/ai-brain" || return 1
  printf '%s\n' "$hash" >"$stamp" || return 1
  rm -f "$failed_stamp"
}

case "${1:-}" in
  ensure) ensure_cargo && build_if_stale ;;
  build) build_if_stale ;;
  *) echo "usage: ai-brain-cli.bash ensure|build" >&2; exit 2 ;;
esac
