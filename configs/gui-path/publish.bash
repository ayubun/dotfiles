#!/bin/bash
# copies the login shell PATH into launchd so gui apps such as t3 code find user tools; run at login by dev.ayu.gui-path

set -u

CACHE="${XDG_STATE_HOME:-$HOME/.local/state}/gui-path/path"
MARKER="__GUI_PATH__"

# set the cached PATH first, because a cold login shell read can outlast the 5s t3 code probe
if [[ -s "$CACHE" ]]; then
  /bin/launchctl setenv PATH "$(<"$CACHE")"
fi

# start from the launchd default so a rerun does not stack entries on an already published PATH
fresh="$(/usr/bin/env PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/zsh -ilc "print -r -- '$MARKER'\"\$PATH\"" </dev/null 2>/dev/null | sed -n "s/.*$MARKER//p" | tail -n 1)"
if [[ "$fresh" != /* ]]; then
  echo "gui-path: login shell returned no PATH; kept the cached value" >&2
  exit 1
fi

mkdir -p "$(dirname "$CACHE")"
printf '%s\n' "$fresh" >"$CACHE"
/bin/launchctl setenv PATH "$fresh"
