#!/bin/bash

# Decrypts the age-encrypted API keys from ai-brain for this machine (sync), or changes them (edit).
# Never prints key values. Runs under macOS bash 3.2 and from cron.

set -eo pipefail

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

repo="$HOME/ai-brain"
encrypted_rel="secrets/api-keys.env.age"
encrypted="$repo/$encrypted_rel"
recipients="$repo/secrets/recipients.txt"
store="${XDG_CONFIG_HOME:-$HOME/.config}/ai-brain-keys"
identity="$store/age-key.txt"
decrypted="$store/api-keys.env"
refresh_pending="$store/.refresh-pending"
lock="$store/.lock"
# every line is sourced by every zsh, so allow only single-quoted exports of credential-named variables
line_pattern="^(#.*|export [A-Z][A-Z0-9_]*_(API_KEY|TOKEN|SECRET|KEY)='[^']*')?\$"

die() {
  echo "ai-brain-secrets: $*" >&2
  exit 1
}

has_valid_format() {
  local status=0
  grep -Evq "$line_pattern" "$1" || status=$?
  # grep exits 1 only when every line matched; 2 is a read error
  [[ $status -eq 1 ]]
}

refresh_tool_copies() {
  local status=0
  command -v zsh >/dev/null || return 0
  if [[ -x "$HOME/.local/bin/codex" ]]; then
    zsh -lc 'zsh "$HOME/dotfiles/dependencies/sync-codex-auth.zsh"' || status=1
  fi
  if command -v opencode >/dev/null || [[ -x "$HOME/.opencode/bin/opencode" ]]; then
    zsh -lc 'zsh "$HOME/dotfiles/dependencies/sync-opencode-auth.zsh"' || status=1
  fi
  return "$status"
}

acquire_lock() {
  local attempt holder
  for attempt in $(seq 1 60); do
    if mkdir "$lock" 2>/dev/null; then
      echo "$$" >"$lock/pid"
      return 0
    fi
    holder="$(cat "$lock/pid" 2>/dev/null || true)"
    # a lock whose owner died would otherwise block every later sync
    if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then
      rm -rf "$lock"
      continue
    fi
    sleep 1
  done
  die "another sync still holds $lock"
}

sync_secrets() {
  [[ -f "$identity" && -f "$encrypted" ]] || return 0
  command -v age >/dev/null || die "age is not installed"
  umask 077
  mkdir -p "$store"
  chmod 700 "$store"
  acquire_lock
  tmp="$(mktemp "$store/.sync.XXXXXX")"
  trap 'rm -f "$tmp"; rm -rf "$lock"' EXIT
  age -d -i "$identity" -o "$tmp" "$encrypted" || die "failed to decrypt $encrypted"
  has_valid_format "$tmp" || die "$encrypted has a line that is not blank, a comment, or an allowed export"
  if [[ -f "$decrypted" ]] && cmp -s "$tmp" "$decrypted"; then
    rm -f "$tmp"
  else
    # the marker survives a failed refresh, so the next hook run retries it
    : >"$refresh_pending"
    mv -f "$tmp" "$decrypted"
  fi
  if [[ -f "$refresh_pending" ]]; then
    refresh_tool_copies || return 1
    rm -f "$refresh_pending"
  fi
}

open_editor() {
  local editor="${VISUAL:-${EDITOR:-vi}}"
  # vim-family editors would otherwise write swap, undo, and backup copies of the plaintext
  case "$(basename "${editor%% *}")" in
    nvim | vim | vi) $editor --clean -n -i NONE -c 'setlocal noundofile nobackup nowritebackup' "$1" ;;
    *) $editor "$1" ;;
  esac
}

encrypted_blob() {
  git -C "$repo" rev-parse -q --verify "HEAD:$encrypted_rel" 2>/dev/null || true
}

edit_secrets() {
  [[ -f "$identity" ]] || die "this machine has no age identity; enroll it first"
  [[ -f "$recipients" ]] || die "missing $recipients"
  command -v age >/dev/null || die "age is not installed"
  umask 077
  git -C "$repo" pull --ff-only -q || die "failed to update $repo"
  [[ -z "$(git -C "$repo" rev-list '@{u}..HEAD' 2>/dev/null)" ]] || die "$repo has unpushed commits; push or drop them first"
  start_blob="$(encrypted_blob)"

  if [[ -d /dev/shm ]]; then
    work="$(mktemp -d /dev/shm/ai-brain-secrets.XXXXXX)"
  else
    work="$(mktemp -d)"
  fi
  staged="$repo/secrets/.api-keys.env.age.$$"
  trap 'rm -rf "$work"; rm -f "$staged"' EXIT
  chmod 700 "$work"
  plain="$work/api-keys.env"
  if [[ -f "$encrypted" ]]; then
    age -d -i "$identity" -o "$plain" "$encrypted" || die "failed to decrypt $encrypted"
  else
    : >"$plain"
  fi
  cp "$plain" "$work/before"

  open_editor "$plain"
  while ! has_valid_format "$plain"; do
    echo "every line must be blank, a comment, or export NAME='value' where NAME ends in _API_KEY, _TOKEN, _SECRET, or _KEY (no single quotes in values)" >&2
    read -r -p "edit again? [Y/n] " answer
    case "$answer" in [nN]*) die "nothing was saved" ;; esac
    open_editor "$plain"
  done
  if cmp -s "$plain" "$work/before"; then
    echo "no changes"
    return 0
  fi

  git -C "$repo" pull --ff-only -q || die "failed to update $repo; nothing was saved"
  [[ "$(encrypted_blob)" == "$start_blob" ]] || die "the keys changed on another machine while you edited; rerun edit. nothing was saved"
  # stage inside the repo so the rename is atomic for a concurrent sync
  age -a -R "$recipients" -o "$staged" "$plain"
  chmod 644 "$staged"
  mv -f "$staged" "$encrypted"
  git -C "$repo" add -- "$encrypted_rel"
  git -C "$repo" commit -q -m "update encrypted api keys" -- "$encrypted_rel"
  # the repo updater may fast-forward between the check above and the commit
  if [[ "$(git -C "$repo" rev-parse -q --verify "HEAD~1:$encrypted_rel" 2>/dev/null || true)" != "$start_blob" ]]; then
    git -C "$repo" reset -q --keep HEAD~1
    die "the keys changed on another machine while you edited; rerun edit. nothing was saved"
  fi
  if ! git -C "$repo" push -q; then
    git -C "$repo" reset -q --keep HEAD~1
    die "the push failed, so the change was undone locally; rerun edit"
  fi
  echo "pushed. other machines pick it up within a few minutes; run 'exec zsh' to load it here"
  bash "${BASH_SOURCE[0]}" sync || echo "ai-brain-secrets: the local sync failed; run: ai-brain-secrets sync" >&2
}

case "${1:-}" in
  sync) sync_secrets ;;
  edit) edit_secrets ;;
  *)
    echo "usage: ai-brain-secrets sync|edit" >&2
    exit 2
    ;;
esac
