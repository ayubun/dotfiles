#!/bin/bash

set -u

ensure_repo() {
  local name="$1"
  local path="$2"
  local required="$3"
  local remote="git@github.com:ayubun/${name}.git"

  if [[ -d "$path/.git" ]]; then
    if [[ -z "$(git -C "$path" status --porcelain)" ]]; then
      git -C "$path" pull --ff-only || printf 'warning: failed to update %s\n' "$name" >&2
    else
      printf 'warning: leaving dirty %s clone unchanged\n' "$name" >&2
    fi
    return 0
  fi

  if [[ -e "$path" ]]; then
    printf 'warning: refusing to replace non-repository path %s\n' "$path" >&2
    $required && return 1
    return 0
  fi

  if ! git clone "$remote" "$path"; then
    printf 'warning: failed to clone %s\n' "$name" >&2
    $required && return 1
  fi
}

ensure_repo "ai-brain" "$HOME/ai-brain" true || exit 1
ensure_repo "ai-brain-discord" "$HOME/ai-brain-discord" false

work_link="$HOME/ai-brain/work"
work_target="../ai-brain-discord"
if [[ -L "$work_link" ]]; then
  [[ "$(readlink "$work_link")" == "$work_target" ]] || ln -sfn "$work_target" "$work_link"
elif [[ ! -e "$work_link" ]]; then
  ln -s "$work_target" "$work_link"
else
  printf 'warning: refusing to replace non-symlink path %s\n' "$work_link" >&2
fi
