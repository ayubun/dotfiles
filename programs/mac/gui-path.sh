#!/bin/bash
# installs dev.ayu.gui-path, a login agent that runs configs/gui-path/publish.bash (mac only)

set -u

DOTFILES="${DOTFILES_FOLDER:-$HOME/dotfiles}"
LABEL="dev.ayu.gui-path"
LAUNCHER="$DOTFILES/configs/gui-path/publish.bash"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

if [[ ! -f "$LAUNCHER" ]]; then
  echo "gui-path: launcher missing at $LAUNCHER"
  exit 1
fi
# the heredoc below writes the path into xml unescaped
if [[ "$LAUNCHER" == *[\&\<\>]* ]]; then
  echo "gui-path: launcher path contains xml special characters: $LAUNCHER"
  exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents"

# launchd does not expand ~ or $HOME, so the plist embeds absolute paths
cat >"$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${LAUNCHER}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/gui-path.err.log</string>
</dict>
</plist>
PLIST

if ! plutil -lint "$PLIST_DST" >/dev/null; then
  echo "gui-path: generated plist failed validation"
  exit 1
fi

# unlike discord-startup, running now is harmless, so load the agent to publish the PATH immediately
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
if ! launchctl bootstrap "$DOMAIN" "$PLIST_DST" && ! launchctl kickstart -k "$DOMAIN/$LABEL"; then
  echo "gui-path: could not start the agent now; it loads at next login"
  exit 0
fi

echo "gui-path: installed $PLIST_DST"
