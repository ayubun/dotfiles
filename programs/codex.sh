#!/bin/bash

set -eo pipefail

case "$(uname -s)" in
  Linux) platform=unknown-linux-musl ;;
  Darwin) platform=apple-darwin ;;
  *)
    echo "unsupported os for codex: $(uname -s)" >&2
    exit 1
    ;;
esac
target="codex-$(get_arch)-${platform}"
codex="$HOME/.local/bin/codex"

as_user() {
  if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
    sudo -u "$ORIGINAL_USER" -H "$@"
  else
    "$@"
  fi
}

latest="$(curl -fsSI https://github.com/openai/codex/releases/latest | sed -nE 's#^[Ll]ocation:.*/tag/rust-v([^[:space:]]+).*#\1#p' | tr -d '\r' || true)"
# codex creates ~/.codex state on any run, so a root rerun must not probe it as root
installed="$(as_user "$codex" --version 2>/dev/null | awk '{print $2}' || true)"

if [[ -z "$installed" || ( -n "$latest" && "$installed" != "$latest" ) ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  curl -fsSL --retry 3 --retry-delay 2 -o "$tmp_dir/codex.tar.gz" \
    "https://github.com/openai/codex/releases/latest/download/${target}.tar.gz"
  tar -xzf "$tmp_dir/codex.tar.gz" -C "$tmp_dir" "$target"
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$tmp_dir/$target" "$codex"
fi

if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
  chown "$ORIGINAL_USER" "$HOME/.local" "$HOME/.local/bin" "$codex"
fi
as_user zsh -lc 'zsh "$HOME/dotfiles/dependencies/sync-codex-auth.zsh"'
