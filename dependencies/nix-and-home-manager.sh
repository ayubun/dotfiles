#!/bin/bash

# Installs Nix (if missing) and applies the home-manager configuration from
# the flake at ~/dotfiles. This replaces the old per-tool install scripts for
# CLI packages, toolchains, and config symlinks -- see flake.nix and
# nix/home.nix for what it manages.

set -o pipefail

TARGET_USER="${ORIGINAL_USER:-$USER}"
TARGET_HOME="${ORIGINAL_HOME:-$HOME}"

# Run a command as the target (non-root) user when this script is run as root
as_user() {
  if [[ $UID -eq 0 && -n "$TARGET_USER" && "$TARGET_USER" != "root" ]]; then
    sudo -u "$TARGET_USER" -H "$@"
  else
    "$@"
  fi
}

find_nix() {
  # command -v first (covers already-sourced shells), then the two standard
  # profile locations (multi-user daemon layout, single-user layout)
  command -v nix 2>/dev/null && return 0
  for candidate in /nix/var/nix/profiles/default/bin/nix "$TARGET_HOME/.nix-profile/bin/nix"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# ---------- 1. Install Nix if missing ----------
if ! find_nix >/dev/null; then
  echo "Nix not found; installing..."
  installer=$(mktemp)
  curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install -o "$installer" || {
    echo "ERROR: could not download the Nix installer"
    rm -f "$installer"
    exit 1
  }
  if [[ "$OSTYPE" == "darwin"* ]] || [[ -d /run/systemd/system ]]; then
    # Multi-user (daemon) install: macOS and systemd-based Linux. Run as the
    # target user -- the installer escalates internally via sudo (install.sh
    # grants passwordless sudo for the duration of the run).
    as_user sh "$installer" --daemon --yes
  else
    # Single-user install for containers/devboxes without systemd.
    # Pre-create /nix owned by the target user so the installer doesn't
    # need to escalate on its own.
    if [[ $UID -eq 0 && "$TARGET_USER" != "root" && ! -d /nix ]]; then
      mkdir -m 0755 /nix && chown "$TARGET_USER" /nix
    fi
    as_user sh "$installer" --no-daemon --yes
  fi
  rm -f "$installer"
fi

NIX_BIN=$(find_nix) || {
  echo "ERROR: nix still not found after installation"
  exit 1
}
echo "Using nix at: $NIX_BIN"

# ---------- 2. Apply the home-manager configuration ----------
case "$(uname -s)-$(uname -m)" in
Linux-x86_64) SYSTEM=x86_64-linux ;;
Linux-aarch64 | Linux-arm64) SYSTEM=aarch64-linux ;;
Darwin-arm64) SYSTEM=aarch64-darwin ;;
Darwin-x86_64) SYSTEM=x86_64-darwin ;;
*)
  echo "ERROR: unsupported system: $(uname -s)-$(uname -m)"
  exit 1
  ;;
esac

# --impure: flake.nix reads USER/HOME from the environment
# -b hm-backup: move any pre-existing (non-home-manager) files aside instead of failing
HM_ARGS=(switch --flake "$TARGET_HOME/dotfiles#$SYSTEM" --impure -b hm-backup)

# Prefer the home-manager CLI once a first switch has installed it; otherwise
# bootstrap through `nix run`.
HM_BIN="$TARGET_HOME/.nix-profile/bin/home-manager"
if [[ -x "$HM_BIN" ]]; then
  as_user "$HM_BIN" "${HM_ARGS[@]}"
else
  as_user "$NIX_BIN" --extra-experimental-features "nix-command flakes" \
    run github:nix-community/home-manager -- "${HM_ARGS[@]}"
fi
