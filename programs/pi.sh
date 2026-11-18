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
  local manifest="$prefix/lib/node_modules/@earendil-works/pi-coding-agent/package.json"
  local installed_version=""
  if [[ -f "$manifest" ]]; then
    installed_version="$(node -p 'require(process.argv[1]).version' "$manifest" 2>/dev/null)" || installed_version=""
  fi
  if [[ ! -x "$binary" || "$installed_version" != "$version" ]]; then
    command -v npm >/dev/null 2>&1 || { printf 'pi.sh: npm is required to install pi\n' >&2; return 1; }
    rm -rf "$prefix.tmp"
    npm install -g --prefix "$prefix.tmp" "@earendil-works/pi-coding-agent@$version" || return 1
    rm -rf "$prefix.old"
    if [[ -e "$prefix" ]]; then
      mv "$prefix" "$prefix.old" || return 1
    fi
    if ! mv "$prefix.tmp" "$prefix"; then
      if [[ -e "$prefix.old" ]]; then
        mv "$prefix.old" "$prefix" || return 1
      fi
      return 1
    fi
    rm -rf "$prefix.old"
  fi
  mkdir -p "$(dirname "$link")"
  [[ "$(readlink "$link" 2>/dev/null)" == "$binary" ]] || ln -sfn "$binary" "$link"
}

# ai-brain.sh runs before pi is installed, so generate again after the binary exists.
link_pi() {
  local reconciler="$1" cli="$2"
  bash "$reconciler"
  if [[ ! -x "$cli" ]]; then
    printf 'warning: ai-brain generate did not run; pi skills and agents are linked on the next update\n' >&2
  elif ! "$cli" generate; then
    printf 'warning: ai-brain generate failed; pi skills and agents may be stale\n' >&2
    return 1
  fi
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
