#!/bin/bash
#
# registers the discord startup sequencer as a login agent (mac only)
#
# generates ~/Library/LaunchAgents/dev.ayu.discord-startup.plist pointing at the
# tracked launcher (programs/mac/discord-startup/launch.sh), which opens discord
# canary first and then stable 30s later. launchd auto-loads agents from that
# dir at each login, so this just has to drop a valid plist once
#
# remember to disable "open discord" inside each client so macos does not also
# auto-launch them (double start)

set -u

DOTFILES="${DOTFILES_FOLDER:-$HOME/dotfiles}"
LABEL="dev.ayu.discord-startup"
LAUNCHER="$DOTFILES/programs/mac/discord-startup/launch.sh"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"

# launchd needs a real launcher on disk; bail loudly rather than half-installing
if [[ ! -f "$LAUNCHER" ]]; then
  echo "discord-startup: launcher missing at $LAUNCHER"
  exit 1
fi
chmod +x "$LAUNCHER"

mkdir -p "$HOME/Library/LaunchAgents"

# generated (not tracked) so it can embed the absolute launcher path -- launchd
# does not expand ~ or $HOME. RunAtLoad fires it at login; no KeepAlive since the
# launcher is a one-shot sequencer that should exit after opening stable
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
    <key>StandardOutPath</key>
    <string>/tmp/discord-startup.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/discord-startup.err.log</string>
</dict>
</plist>
PLIST

# validate before handing it to launchd
if ! plutil -lint "$PLIST_DST" >/dev/null; then
  echo "discord-startup: generated plist failed validation"
  exit 1
fi

# drop any stale copy so a re-run picks up path/label changes. modern launchctl:
# macos deprecated load/unload and they throw "5: input/output error" here. we do
# NOT bootstrap in the installer -- that fires RunAtLoad and would pop discord
# open mid-install. launchd auto-loads the plist from LaunchAgents at next login
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

echo "discord-startup: installed $PLIST_DST"
echo "discord-startup: active at next login -- to start it right now, run:"
echo "  launchctl bootstrap gui/$(id -u) \"$PLIST_DST\""
