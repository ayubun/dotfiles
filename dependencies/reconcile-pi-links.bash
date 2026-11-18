#!/bin/bash

# Keep machine-local files and foreign links while converging managed pi links.

set -euo pipefail

PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
AI_BRAIN_PI_ADAPTER_ROOT="${AI_BRAIN_PI_ADAPTER_ROOT:-$HOME/ai-brain/adapters/pi}"

[[ -d "$AI_BRAIN_PI_ADAPTER_ROOT" ]] || exit 0
[[ -n "${PI_CODING_AGENT_DIR:-}" || -x "$HOME/.local/bin/pi" ]] || exit 0

shopt -s nullglob

reconcile_sources() {
  link_file "$AI_BRAIN_PI_ADAPTER_ROOT/settings.json" "$PI_AGENT_DIR/settings.json"
  link_file "$AI_BRAIN_PI_ADAPTER_ROOT/models.json" "$PI_AGENT_DIR/models.json"

  [[ -d "$AI_BRAIN_PI_ADAPTER_ROOT/extensions" ]] || return 0
  prepare_dest "$PI_AGENT_DIR/extensions"
  local src name wanted=""
  for src in "$AI_BRAIN_PI_ADAPTER_ROOT/extensions"/*.ts; do
    name="$(basename "$src")"
    wanted+="$name"$'\n'
    link_file "$src" "$PI_AGENT_DIR/extensions/$name"
  done
  prune_stale "$PI_AGENT_DIR/extensions" "$wanted"
  prepare_dest "$PI_AGENT_DIR/extensions/subagent"
  link_file "$AI_BRAIN_PI_ADAPTER_ROOT/subagent-config.json" "$PI_AGENT_DIR/extensions/subagent/config.json"
}

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

prune_stale() {
  local dest="$1"
  local wanted="$2"
  local link target

  for link in "$dest"/*.ts; do
    [[ -L "$link" ]] || continue
    grep -Fqx -- "$(basename "$link")" <<<"$wanted" && continue
    target="$(readlink "$link")"
    case "$target" in
      "$HOME/ai-brain/"*|"$HOME/ai-brain-discord/"*|"$AI_BRAIN_PI_ADAPTER_ROOT"/*) rm -f "$link" ;;
    esac
  done
}

mkdir -p "$PI_AGENT_DIR"
reconcile_sources
