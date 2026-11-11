#!/bin/bash

# Root runs the recorder so it can read every process and the kernel log; the unit lives on the ephemeral root disk, so reinstall each boot.
command -v systemctl >/dev/null 2>&1 || exit 0

USER_NAME="${ORIGINAL_USER:-$USER}"
USER_HOME="${ORIGINAL_HOME:-$HOME}"
SCRIPT="$USER_HOME/dotfiles/configs/memwatch/memwatch.bash"
OUT_DIR="$USER_HOME/.local/state/memwatch"

sudo -u "$USER_NAME" mkdir -p "$OUT_DIR" || exit 1

UNIT=$(
  cat <<EOF
[Unit]
Description=Persistent memory pressure and OOM recorder
After=local-fs.target

[Service]
Environment=MEMWATCH_DIR=$OUT_DIR
ExecStart=/bin/bash $SCRIPT
Restart=always
RestartSec=5
OOMScoreAdjust=-1000
Nice=10
MemoryMax=128M

[Install]
WantedBy=multi-user.target
EOF
)

if [[ "$(cat /etc/systemd/system/memwatch.service 2>/dev/null)" != "$UNIT" ]]; then
  printf '%s\n' "$UNIT" | sudo tee /etc/systemd/system/memwatch.service >/dev/null || exit 1
  sudo systemctl daemon-reload || exit 1
fi
sudo systemctl enable --now memwatch.service || exit 1
