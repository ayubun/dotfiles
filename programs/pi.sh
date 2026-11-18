#!/bin/bash

# The versioned npm prefix avoids read-only system npm installations.

set -euo pipefail

pi_prefix_root() { printf '%s\n' "${PI_PREFIX_ROOT:-$HOME/.local/share/ai-brain/pi}"; }

pi_pinned_version() {
  local pin_file="${1:-$HOME/ai-brain/adapters/pi/pi-version}"
  local version
  version="$(tr -d '[:space:]' <"$pin_file")"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf 'pi.sh: bad pin %s\n' "$version" >&2; return 1; }
  printf '%s\n' "$version"
}

install_pi() {
  local version="$1" root="$2" link="$3"
  local prefix="$root/$version"
  local binary="$prefix/bin/pi"
  if [[ ! -x "$binary" ]] || [[ "$("$binary" --version 2>/dev/null)" != "$version" ]]; then
    rm -rf "$prefix.tmp"
    npm install -g --prefix "$prefix.tmp" "@earendil-works/pi-coding-agent@$version"
    rm -rf "$prefix"
    mv "$prefix.tmp" "$prefix"
  fi
  mkdir -p "$(dirname "$link")"
  [[ "$(readlink "$link" 2>/dev/null)" == "$binary" ]] || ln -sfn "$binary" "$link"
}

# ai-brain.sh runs before pi is installed, so generate again after the binary exists.
link_pi() {
  local reconciler="$1" cli="$2"
  bash "$reconciler"
  [[ -x "$cli" ]] && "$cli" generate || printf 'warning: ai-brain generate did not run; pi skills and agents are linked on the next update\n' >&2
}

main() {
  local version
  version="$(pi_pinned_version)"
  if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
    sudo -u "$ORIGINAL_USER" -H bash "${BASH_SOURCE[0]}"
    return
  fi
  install_pi "$version" "$(pi_prefix_root)" "$HOME/.local/bin/pi"
  link_pi "$HOME/dotfiles/dependencies/reconcile-pi-links.bash" "$HOME/.local/bin/ai-brain"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
