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
if mkdir -p "$DOCKER_CLI_PLUGINS" 2>/dev/null; then
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-${ARCH}" -o "$DOCKER_CLI_PLUGINS/docker-compose"
    chmod +x "$DOCKER_CLI_PLUGINS/docker-compose"
else
    # Fallback: install as standalone binary (e.g., older systems without Docker plugin support)
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-${ARCH}" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi
