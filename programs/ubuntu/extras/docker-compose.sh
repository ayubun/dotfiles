#!/bin/bash

# This script installs Docker Compose v2 as a Docker CLI plugin.
# Falls back to standalone binary for systems without the Docker plugin directory.
# https://docs.docker.com/compose/install/linux/

COMPOSE_VERSION="v2.32.4"
ARCH=$(get_arch)

# Remove old v1 binaries
sudo rm -f /usr/local/bin/docker-compose
sudo rm -f /usr/bin/docker-compose

# Prefer installing as a Docker CLI plugin (v2 style)
DOCKER_CLI_PLUGINS="${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins"
COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-${ARCH}"
if mkdir -p "$DOCKER_CLI_PLUGINS" 2>/dev/null; then
    gh_download "$COMPOSE_URL" "$DOCKER_CLI_PLUGINS/docker-compose" || exit 1
    chmod +x "$DOCKER_CLI_PLUGINS/docker-compose"
else
    # Fallback: install as standalone binary (e.g., older systems without Docker plugin support)
    # download unprivileged, then place with sudo (gh_download does not sudo)
    COMPOSE_TMP="$(mktemp)"
    gh_download "$COMPOSE_URL" "$COMPOSE_TMP" || exit 1
    sudo install -m 0755 "$COMPOSE_TMP" /usr/local/bin/docker-compose || exit 1
    rm -f "$COMPOSE_TMP"
fi
