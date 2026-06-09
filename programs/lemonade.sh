#!/bin/bash
#
# Installs the `lemonade` remote utility (https://github.com/lemonade-command/lemonade)
# and wires it up so markdown-preview.nvim (and `lemonade open <url>`) on a remote
# host opens in the local Mac's browser, purely over the SSH connection.
#
#   Mac   = where the browser lives -> runs `lemonade server` (via launchd)
#   Linux = the remote you SSH into  -> runs `lemonade open` (client)
#
# The matching SSH port-forwards live in configs/ssh/lemonade.conf, and the
# ~/.ssh/config wiring is added (Mac only) by configs/ssh/setup.sh.

set -u

DOTFILES="${DOTFILES_FOLDER:-$HOME/dotfiles}"
# Sudo-free install dir; ~/.local/bin is prepended to PATH in configs/.zshenv,
# so both the interactive shell and nvim's jobstart() resolve `lemonade` here.
BIN_DIR="$HOME/.local/bin"

# --- 1. Symlink the shared lemonade config to ~/.config/lemonade.toml ----------
# lemonade hardcodes ~/.config/lemonade.toml (HOME-based, not XDG), which is also
# where the launchd server -- with its minimal env -- will look.
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/configs/lemonade.toml" "$HOME/.config/lemonade.toml"
echo "Linked ~/.config/lemonade.toml -> $DOTFILES/configs/lemonade.toml"

# --- 2. Install the lemonade binary (idempotent) -------------------------------
# The official 2016 prebuilt binaries are broken on modern macOS (old Go Mach-O
# binaries crash under Rosetta) and ship no arm64 build at all, so we build from
# source with a throwaway Go toolchain. This yields a native, current (v1.1.2+)
# binary on every platform.
install_lemonade() {
  # ~/.local/bin isn't necessarily on PATH inside install.sh's bash env, so check
  # the install dir directly as well as PATH.
  if [[ -x "$BIN_DIR/lemonade" ]] || command -v lemonade >/dev/null 2>&1; then
    echo "lemonade already installed -- skipping build"
    return 0
  fi

  local os arch
  case "$OSTYPE" in
    darwin*) os=darwin ;;
    linux*)  os=linux ;;
    *) echo "Unsupported OS: $OSTYPE"; return 1 ;;
  esac
  arch="$(get_arch go)" # amd64 | arm64

  # Reuse an existing Go if present, otherwise fetch a throwaway toolchain that we
  # delete once the build is done (keeps the machine clean).
  local go_bin gotmp=""
  if command -v go >/dev/null 2>&1; then
    go_bin="$(command -v go)"
    echo "Using existing Go: $go_bin"
  else
    gotmp="$(mktemp -d)"
    local gover
    gover="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)"
    if [[ -z "$gover" ]]; then
      echo "Could not determine latest Go version"
      rm -rf "$gotmp"
      return 1
    fi
    echo "Fetching throwaway Go toolchain ${gover} (${os}-${arch})..."
    if ! curl -fsSL "https://go.dev/dl/${gover}.${os}-${arch}.tar.gz" | tar xz -C "$gotmp"; then
      echo "Failed to download/extract Go toolchain"
      rm -rf "$gotmp"
      return 1
    fi
    go_bin="$gotmp/go/bin/go"
  fi

  local build
  build="$(mktemp -d)"
  local -a goenv=(
    "GOTOOLCHAIN=local"
    "GOFLAGS=-modcacherw" # keep the module cache writable so cleanup can rm it
    "GOPATH=$build/gopath"
    "GOBIN=$build/bin"
    "GOCACHE=$build/gocache"
  )
  # Only pin GOROOT for the throwaway toolchain; a system Go knows its own.
  [[ -n "$gotmp" ]] && goenv+=("GOROOT=$gotmp/go")

  echo "Building lemonade from source..."
  local rc=0
  if env "${goenv[@]}" "$go_bin" install github.com/lemonade-command/lemonade@latest; then
    mkdir -p "$BIN_DIR"
    install -m 0755 "$build/bin/lemonade" "$BIN_DIR/lemonade"
    echo "Installed lemonade -> $BIN_DIR/lemonade"
  else
    echo "lemonade build failed"
    rc=1
  fi

  # Go marks its module cache read-only; make it writable before removing so a
  # cleanup failure can't mask the build result.
  chmod -R u+w "$build" "$gotmp" 2>/dev/null || true
  rm -rf "$build" "$gotmp" 2>/dev/null || true
  return $rc
}

install_lemonade || exit 1

LEMONADE_BIN="$(command -v lemonade || echo "$BIN_DIR/lemonade")"

# --- 3. Mac only: keep `lemonade server` running via launchd -------------------
# The plist is generated here (rather than tracked) so it can embed an absolute
# path to the per-user binary -- launchd does not expand ~ or $HOME.
if [[ "$OSTYPE" == darwin* ]]; then
  PLIST_DST="$HOME/Library/LaunchAgents/com.lemonade.server.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cat >"$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lemonade.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>${LEMONADE_BIN}</string>
        <string>server</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/lemonade.server.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/lemonade.server.err.log</string>
</dict>
</plist>
PLIST
  # Reload so it picks up any changes and starts immediately.
  launchctl unload "$PLIST_DST" 2>/dev/null || true
  if launchctl load -w "$PLIST_DST"; then
    echo "lemonade server loaded via launchd (allow-listed to loopback, port 2489)"
  else
    echo "WARNING: failed to load lemonade launchd agent"
  fi
fi
