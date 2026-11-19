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

load_pi_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    set +u
    source "$NVM_DIR/nvm.sh" --no-use || true
    nvm use default >/dev/null 2>&1 || true
    set -u
  fi
}

ensure_pi_node() {
  command -v node >/dev/null 2>&1 || load_pi_nvm
  command -v node >/dev/null 2>&1 || { printf 'pi.sh: node is required to install pi; install Node or configure the nvm default\n' >&2; return 1; }
}

write_pi_launcher() {
  local launcher="$1" binary="$2" node="$3" content
  printf -v content '#!/bin/bash\nnode=%q\nif [[ ! -x "$node" ]]; then\n  node="$(command -v node)" || {\n    printf "%%s\\n" %q >&2\n    exit 127\n  }\nfi\nexport PATH="${PATH:+$PATH:}"%q\nexec "$node" %q "$@"\n' \
    "$node" "pi: pinned node $node is missing; rerun ~/dotfiles/programs/pi.sh" "$(dirname "$node")" "$binary"
  if ! cmp -s "$launcher" <(printf '%s' "$content"); then
    printf '%s' "$content" >"$launcher.tmp" || return 1
    chmod +x "$launcher.tmp" || return 1
    mv "$launcher.tmp" "$launcher" || return 1
  fi
}

refresh_pi_launcher() {
  local link="$HOME/.local/bin/pi" binary launcher
  [[ -L "$link" ]] || return 0
  binary="$(readlink "$link")"
  case "$binary" in
    "$(pi_prefix_root)"/*/bin/pi|"$(pi_prefix_root)"/*/bin/pi-launcher) ;;
    *) return 0 ;;
  esac
  binary="$(dirname "$binary")/pi"
  [[ -x "$binary" ]] || return 0
  ensure_pi_node || return 1
  launcher="${binary}-launcher"
  write_pi_launcher "$launcher" "$binary" "$(command -v node)" || return 1
  [[ "$(readlink "$link")" == "$launcher" ]] || ln -sfn "$launcher" "$link"
}

install_pi() {
  local version="$1" root="$2" link="$3"
  local prefix="$root/$version"
  local binary="$prefix/bin/pi"
  local launcher="$prefix/bin/pi-launcher" node
  local manifest="$prefix/lib/node_modules/@earendil-works/pi-coding-agent/package.json"
  local installed_version=""
  ensure_pi_node || return 1
  node="$(command -v node)"
  if [[ -f "$manifest" ]]; then
    installed_version="$(node -p 'require(process.argv[1]).version' "$manifest" 2>/dev/null)" || installed_version=""
  fi
  if [[ ! -x "$binary" || "$installed_version" != "$version" ]]; then
    command -v npm >/dev/null 2>&1 || load_pi_nvm
    command -v npm >/dev/null 2>&1 || { printf 'pi.sh: npm is required to install pi; install npm or configure the nvm default\n' >&2; return 1; }
    node="$(command -v node)"
    rm -rf "$prefix.tmp"
    npm install -g --prefix "$prefix.tmp" "@earendil-works/pi-coding-agent@$version" || return 1
    write_pi_launcher "$prefix.tmp/bin/pi-launcher" "$binary" "$node" || return 1
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
  write_pi_launcher "$launcher" "$binary" "$node" || return 1
  mkdir -p "$(dirname "$link")"
  [[ "$(readlink "$link" 2>/dev/null)" == "$launcher" ]] || ln -sfn "$launcher" "$link"
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
  if [[ "${1:-}" == --refresh-launcher ]]; then
    refresh_pi_launcher
    return
  fi
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
