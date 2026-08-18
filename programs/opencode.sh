#!/bin/bash

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://ocx.kdco.dev/install.sh | sh

mkdir -p "$HOME/.config/opencode"

# ai-brain owns the active config, instructions, and skill paths
rm -f "$HOME/.config/opencode/opencode.json"
ln -s "$HOME/ai-brain/adapters/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

# standard global paths remain available for per-machine additions

# aggregate ai-brain agents while preserving real per-machine files
dest="$HOME/.config/opencode/agents"
[[ -L "$dest" ]] && rm "$dest"
mkdir -p "$dest"
find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
shopt -s nullglob
for src in "$HOME/ai-brain/adapters/opencode/agents" "$HOME/ai-brain-discord/agents"; do
  [[ -d "$src" ]] || continue
  for f in "$src"/*.md; do
    name="$(basename "$f")"
    [[ "$name" == "index.md" ]] && continue
    if [[ -e "$dest/$name" && ! -L "$dest/$name" ]]; then
      continue
    fi
    ln -sfn "$f" "$dest/$name"
  done
done
shopt -u nullglob

"$HOME/.local/bin/ocx" init --global --quiet

# canonical plugins resolve dependencies from their real source path
adapter_node_modules="$HOME/ai-brain/adapters/opencode/node_modules"
if [[ -L "$adapter_node_modules" || ! -e "$adapter_node_modules" ]]; then
  ln -sfn "$HOME/.config/opencode/node_modules" "$adapter_node_modules"
fi

dest="$HOME/.config/opencode/plugins"
[[ -L "$dest" ]] && rm "$dest"
mkdir -p "$dest"
find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
shopt -s nullglob
for f in "$HOME/ai-brain/adapters/opencode/plugins"/*.{js,ts}; do
  name="$(basename "$f")"
  if [[ -e "$dest/$name" && ! -L "$dest/$name" ]]; then
    continue
  fi
  ln -sfn "$f" "$dest/$name"
done
shopt -u nullglob

dest="$HOME/.config/opencode/lib"
[[ -L "$dest" ]] && rm "$dest"
mkdir -p "$dest"
find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
shopt -s nullglob
for f in "$HOME/ai-brain/adapters/opencode/lib"/*.{js,ts}; do
  name="$(basename "$f")"
  if [[ -e "$dest/$name" && ! -L "$dest/$name" ]]; then
    continue
  fi
  ln -sfn "$f" "$dest/$name"
done
shopt -u nullglob
