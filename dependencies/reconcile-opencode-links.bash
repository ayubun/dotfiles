#!/bin/bash

# Aggregates the ai-brain opencode config, agents, plugins, and lib files into
# ~/.config/opencode as symlinks. Handles both adapter shapes: OpenCode 1
# (opencode.json, plugin files, a plugin array) and OpenCode 2 (opencode.jsonc,
# plugin files and directories, no plugin array). OPENCODE_CONFIG_ROOT and
# AI_BRAIN_ADAPTER_ROOT override the roots for a parallel install. Converges instead of rebuilding: links that
# already point at the right file are left alone, replacements are atomic, and
# only stale links into the ai-brain repositories are pruned. A real file at a
# wanted name is a per-machine override and wins. Links at other names that
# point outside the ai-brain repositories are per-machine additions and stay.
# Safe unattended: no sudo, no network.

set -euo pipefail

config_root="${OPENCODE_CONFIG_ROOT:-$HOME/.config/opencode}"
adapter_root="${AI_BRAIN_ADAPTER_ROOT:-$HOME/ai-brain/adapters/opencode}"

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
      "$HOME/ai-brain/"*|"$HOME/ai-brain-discord/"*|"$adapter_root"/*) rm -f "$link" ;;
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

# Exactly one global config link: the adapter's opencode.jsonc (OpenCode 2) or
# opencode.json (OpenCode 1). The other name is pruned when it points into ai-brain.
for config_name in opencode.jsonc opencode.json; do
  if [[ -f "$adapter_root/$config_name" ]]; then
    link_file "$adapter_root/$config_name" "$config_root/$config_name"
  elif [[ -L "$config_root/$config_name" ]]; then
    case "$(readlink "$config_root/$config_name")" in
      "$HOME/ai-brain/"*|"$adapter_root"/*) rm -f "$config_root/$config_name" ;;
    esac
  fi
done

# An OpenCode 1 adapter resolves @opencode-ai/plugin from the config root's
# node_modules. An OpenCode 2 adapter owns its package.json and node_modules.
adapter_node_modules="$adapter_root/node_modules"
if [[ ! -f "$adapter_root/package.json" ]]; then
  if [[ -L "$adapter_node_modules" || ! -e "$adapter_node_modules" ]]; then
    [[ "$(readlink "$adapter_node_modules" 2>/dev/null)" == "$config_root/node_modules" ]] ||
      ln -sfn "$config_root/node_modules" "$adapter_node_modules"
  fi
elif [[ -L "$adapter_node_modules" ]]; then
  rm -f "$adapter_node_modules"
fi

# OpenCode 1 only: plugins registered through the opencode.json plugin array
# must not also auto-load from this directory.
json_registered=""
if [[ -f "$adapter_root/opencode.json" ]]; then
  json_registered="$(grep -o 'adapters/opencode/plugins/[^"]*' "$adapter_root/opencode.json" | sed 's#.*/##' || true)"
fi
plugin_sources=()
for f in "$adapter_root/plugins"/*.{js,ts} "$adapter_root/plugins"/*/; do
  f="${f%/}"
  grep -Fqx -- "$(basename "$f")" <<<"$json_registered" && continue
  plugin_sources+=("$f")
done
# A missing source directory (for example mid-rebase) must not prune a category.
[[ -d "$adapter_root/plugins" ]] && reconcile "$config_root/plugins" ${plugin_sources[@]+"${plugin_sources[@]}"}
[[ -d "$adapter_root/lib" ]] && reconcile "$config_root/lib" "$adapter_root/lib"/*.{js,ts}
exit 0
