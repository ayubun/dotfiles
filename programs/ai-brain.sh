#!/bin/bash

set -u

as_user=()
if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
  as_user=(sudo -u "$ORIGINAL_USER" -H)
fi

ensure_repo() {
  local name="$1"
  local path="$2"
  local required="$3"
  local remote="git@github.com:ayubun/${name}.git"

  if [[ -d "$path/.git" ]]; then
    if [[ -z "$(${as_user[@]+"${as_user[@]}"} git -C "$path" status --porcelain)" ]]; then
      ${as_user[@]+"${as_user[@]}"} git -C "$path" pull --ff-only || printf 'warning: failed to update %s\n' "$name" >&2
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

  if ! ${as_user[@]+"${as_user[@]}"} git clone "$remote" "$path"; then
    printf 'warning: failed to clone %s\n' "$name" >&2
    $required && return 1
  fi
}

ensure_repo "ai-brain" "$HOME/ai-brain" true || exit 1
personal_only_marker="${AI_BRAIN_PERSONAL_ONLY_MARKER:-$HOME/.config/ai-brain/personal-only}"
if [[ ! -e "$personal_only_marker" ]]; then
  ensure_repo "ai-brain-discord" "$HOME/ai-brain-discord" false
fi

work_link="$HOME/ai-brain/work"
work_target="../ai-brain-discord"
if [[ -L "$work_link" ]]; then
  [[ "$(readlink "$work_link")" == "$work_target" ]] || ${as_user[@]+"${as_user[@]}"} ln -sfn "$work_target" "$work_link"
elif [[ ! -e "$work_link" ]]; then
  ${as_user[@]+"${as_user[@]}"} ln -s "$work_target" "$work_link"
else
  printf 'warning: refusing to replace non-symlink path %s\n' "$work_link" >&2
fi

# runs before programs/rust.sh, so the helper installs a toolchain when the machine has none
${as_user[@]+"${as_user[@]}"} bash "$HOME/dotfiles/dependencies/ai-brain-cli.bash" ensure || printf 'warning: failed to build the ai-brain cli\n' >&2
if [[ -x "$HOME/.local/bin/ai-brain" ]]; then
  ${as_user[@]+"${as_user[@]}"} "$HOME/.local/bin/ai-brain" secrets sync || printf 'warning: failed to sync ai-brain secrets\n' >&2
  ${as_user[@]+"${as_user[@]}"} "$HOME/.local/bin/ai-brain" generate || printf 'warning: failed to run ai-brain generate\n' >&2
else
  printf 'warning: the ai-brain cli is not installed; skipping the secrets sync\n' >&2
fi
