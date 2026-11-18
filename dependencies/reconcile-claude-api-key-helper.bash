#!/bin/bash

# Claude Code ranks apiKeyHelper above a subscription login, so the dotfiles helper stays only while T3 claudeAgent is in api-key mode.

set -uo pipefail

settings="$HOME/.claude/settings.json"
helper='zsh ${HOME}/dotfiles/dependencies/claude-api-key.zsh'
cli="$HOME/.local/bin/ai-brain"
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
# claude-code.sh creates ~/.claude; machines without Claude Code get no settings file
[[ -d "$HOME/.claude" ]] || exit 0

mode=api-key
if [[ -x "$cli" ]]; then
  mode="$("$cli" secrets provider-mode claudeAgent)"
  case $? in
    0) ;;
    # Exit 3 means the config does not manage claudeAgent, so the helper keeps its behavior from before T3.
    3) mode=api-key ;;
    *)
      printf 'reconcile-claude-api-key-helper: cannot read the claudeAgent mode; %s is unchanged\n' "$settings" >&2
      exit 1
      ;;
  esac
fi

want=false
if [[ "$mode" == api-key ]] && zsh -lc '[[ -n "${ANTHROPIC_API_KEY:-}" ]]' </dev/null >/dev/null 2>&1; then
  want=true
fi

if ! command -v jq >/dev/null; then
  printf 'reconcile-claude-api-key-helper: jq is required to update %s\n' "$settings" >&2
  exit 1
fi

if [[ -s "$settings" ]]; then
  current="$(jq -c . "$settings")" || {
    printf 'reconcile-claude-api-key-helper: %s is not valid JSON; it is unchanged\n' "$settings" >&2
    exit 1
  }
else
  [[ "$want" == true ]] || exit 0
  current='{}'
fi

existing="$(jq -r '.apiKeyHelper // ""' <<<"$current")"
if [[ "$mode" == subscription && -n "$existing" && "$existing" != "$helper" ]]; then
  printf 'reconcile-claude-api-key-helper: warning: a custom apiKeyHelper in %s outranks the claude subscription login\n' "$settings" >&2
fi

next="$(jq -c --argjson want "$want" --arg helper "$helper" '
  if $want and (.apiKeyHelper == null or .apiKeyHelper == $helper) then .apiKeyHelper = $helper
  elif (.apiKeyHelper == $helper) then del(.apiKeyHelper)
  else . end
' <<<"$current")" || exit 1
[[ "$next" == "$current" && -s "$settings" ]] && exit 0

mkdir -p "${settings%/*}"
tmp="$(mktemp "${settings}.XXXXXX")" || exit 1
# an existing regular file keeps its owner and mode; a new file starts at 600
[[ -f "$settings" && ! -L "$settings" ]] && cp -p "$settings" "$tmp"
if jq . <<<"$next" >"$tmp" && mv -f "$tmp" "$settings"; then
  exit 0
fi
rm -f "$tmp"
printf 'reconcile-claude-api-key-helper: failed to write %s\n' "$settings" >&2
exit 1
