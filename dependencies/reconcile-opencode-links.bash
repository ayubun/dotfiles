#!/bin/bash

# Aggregates ai-brain opencode agents, plugins, and lib files into
# ~/.config/opencode as symlinks. Converges instead of rebuilding: links that
# already point at the right file are left alone, replacements are atomic, and
# only stale links into the ai-brain repositories are pruned. A real file at a
# wanted name is a per-machine override and wins. Links at other names that
# point outside the ai-brain repositories are per-machine additions and stay.
# Safe unattended: no sudo, no network.

set -euo pipefail

config_root="$HOME/.config/opencode"
adapter_root="$HOME/ai-brain/adapters/opencode"

[[ -d "$config_root" && -d "$adapter_root" ]] || exit 0

shopt -s nullglob

# A non-symlink destination directory is required; a leftover directory
# symlink from an older install is replaced by a real directory.
prepare_dest() {
  local dest="$1"
  [[ -L "$dest" ]] && rm "$dest"
  mkdir -p "$dest"
}

link_file() {
  local src="$1"
  local link="$2"
  local tmp="$link.reconcile.$$"

  if [[ -L "$link" ]]; then
    [[ "$(readlink "$link")" == "$src" ]] && return 0
  elif [[ -e "$link" ]]; then
    return 0
  fi
  # mv follows a symlink to a directory and would move the temp link inside it
  if [[ -d "$link" ]]; then
    ln -sfn "$src" "$link"
  else
    ln -sfn "$src" "$tmp"
    mv -f "$tmp" "$link"
  fi
}

# Removes managed links whose target is no longer in the desired set.
prune_stale() {
  local dest="$1"
  local wanted="$2"
  local link target

  for link in "$dest"/*; do
    [[ -L "$link" ]] || continue
    grep -Fqx -- "$(basename "$link")" <<<"$wanted" && continue
    target="$(readlink "$link")"
    case "$target" in
      "$HOME/ai-brain/"*|"$HOME/ai-brain-discord/"*) rm -f "$link" ;;
    esac
  done
}

reconcile() {
  local dest="$1"
  shift
  local wanted="" f name

  prepare_dest "$dest"
  for f in "$@"; do
    name="$(basename "$f")"
    [[ "$name" == "index.md" ]] && continue
    grep -Fqx -- "$name" <<<"$wanted" && continue
    wanted+="$name"$'\n'
    link_file "$f" "$dest/$name"
  done
  prune_stale "$dest" "$wanted"
}

# First source wins for a duplicate agent name, so discord overrides ai-brain.
agent_sources=()
for src in "$HOME/ai-brain-discord/agents" "$adapter_root/agents"; do
  [[ -d "$src" ]] || continue
  agent_sources+=("$src"/*.md)
done
# A cloned discord repo whose agents/ is transiently missing must not prune its agents.
if [[ -d "$adapter_root/agents" ]] && ! [[ -d "$HOME/ai-brain-discord" && ! -d "$HOME/ai-brain-discord/agents" ]]; then
  reconcile "$config_root/agents" ${agent_sources[@]+"${agent_sources[@]}"}
fi

# Canonical plugins resolve dependencies from their real source path. The link
# lives on an ignored path inside ai-brain, so it is not a repository edit.
adapter_node_modules="$adapter_root/node_modules"
if [[ -L "$adapter_node_modules" || ! -e "$adapter_node_modules" ]]; then
  [[ "$(readlink "$adapter_node_modules" 2>/dev/null)" == "$config_root/node_modules" ]] ||
    ln -sfn "$config_root/node_modules" "$adapter_node_modules"
fi

# Plugins already registered through the opencode.json plugin array must not
# also auto-load from this directory.
json_registered="$(grep -o 'adapters/opencode/plugins/[^"]*' "$adapter_root/opencode.json" | sed 's#.*/##' || true)"
plugin_sources=()
for f in "$adapter_root/plugins"/*.{js,ts}; do
  grep -Fqx -- "$(basename "$f")" <<<"$json_registered" && continue
  plugin_sources+=("$f")
done
# A missing source directory (for example mid-rebase) must not prune a category.
[[ -d "$adapter_root/plugins" ]] && reconcile "$config_root/plugins" ${plugin_sources[@]+"${plugin_sources[@]}"}
[[ -d "$adapter_root/lib" ]] && reconcile "$config_root/lib" "$adapter_root/lib"/*.{js,ts}
exit 0
