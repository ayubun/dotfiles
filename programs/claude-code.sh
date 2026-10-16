#!/bin/bash

curl -fsSL https://claude.ai/install.sh | bash

mkdir -p ~/.claude

status=0
# install.sh children do not inherit brew's PATH, where a fresh mac gets jq
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
settings="$HOME/.claude/settings.json"
dotfiles_settings="$HOME/dotfiles/configs/claude/settings.json"
api_key_helper='zsh ${HOME}/dotfiles/dependencies/claude-api-key.zsh'

as_user() {
  if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
    sudo -u "$ORIGINAL_USER" -H "$@"
  else
    "$@"
  fi
}

has_key=false
as_user zsh -lc '[[ -n "${ANTHROPIC_API_KEY:-}" ]]' && has_key=true

# claude code writes settings.json itself, so keep a merged regular file instead of a symlink into this repo
if ! command -v jq >/dev/null; then
  echo "jq is required to merge $dotfiles_settings into $settings" >&2
  status=1
elif ! merged="$(jq -s --argjson has_key "$has_key" --arg helper "$api_key_helper" '
    (.[0] // {}) * .[1] |
    if $has_key and (.apiKeyHelper == null or .apiKeyHelper == $helper) then .apiKeyHelper = $helper
    elif .apiKeyHelper == $helper then del(.apiKeyHelper)
    else . end
  ' <(if [[ -s "$settings" ]]; then cat "$settings"; else echo '{}'; fi) "$dotfiles_settings")"; then
  echo "failed to merge $dotfiles_settings into $settings" >&2
  status=1
elif ! tmp="$(mktemp "${settings}.XXXXXX")"; then
  status=1
else
  # an existing regular file keeps its owner and mode; a new file starts at 600
  [[ -f "$settings" && ! -L "$settings" ]] && cp -p "$settings" "$tmp"
  [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" ]] && chown "$ORIGINAL_USER" "$tmp"
  if printf '%s\n' "$merged" >"$tmp" && mv -f "$tmp" "$settings"; then
    :
  else
    rm -f "$tmp"
    echo "failed to write $settings" >&2
    status=1
  fi
fi

# claude code is not active, so remove stale skill and agent symlinks
for kind in skills agents; do
  dest="$HOME/.claude/$kind"
  [[ -L "$dest" ]] && rm "$dest"
  [[ -d "$dest" ]] && find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
done

rm -f ~/.claude/CLAUDE.md
ln -s ~/ai-brain/adapters/claude/CLAUDE.md ~/.claude/CLAUDE.md

# nothing reads ~/.claude/AGENTS.md; remove any stale copy
rm -f ~/.claude/AGENTS.md

exit "$status"
