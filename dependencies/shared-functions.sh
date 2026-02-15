#!/bin/bash

# Shared dependencies for dotfiles scripts
# This file contains functions that are used across multiple installation scripts

# Simplified function for parallel execution
run_script_parallel() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    # Create a temporary output file for this script
    local temp_output="/tmp/script_output_$$_$(basename "$script_path").log"
    
    # Completely disable terminal formatting for child scripts
    # This prevents individual scripts from corrupting the terminal
    export TERM=dumb
    export NO_COLOR=1
    export DISABLE_COLORS=1
    
    # Run the script and capture exit code, suppressing all terminal control sequences
    if env TERM=dumb NO_COLOR=1 . "$script_path" >"$temp_output" 2>&1; then
        echo "[OK] $script_name completed successfully"
        rm -f "$temp_output"
        return 0
    else
        local exit_code=$?
        echo "[FAIL] $script_name failed (exit code: $exit_code)"
        echo "$script_path" >> "$FAILURE_LOG" 2>/dev/null || true
        rm -f "$temp_output"
        return 1
    fi
}

# APT lock management functions
unlock-apt() {
    sudo rm -f /tmp/apt-fast.lock &>/dev/null
    sudo rm -f $HOME/dotfiles/tmp/apt.lock &>/dev/null
    sudo rm -f /var/lib/apt/lists/lock &>/dev/null
    sudo rm -f /var/cache/apt/archives/lock &>/dev/null
    sudo rm -f /var/lib/dpkg/lock* &>/dev/null
}

fix-apt() {
    sudo apt --fix-broken install -y &>/dev/null
    sudo apt --fix-missing install -y &>/dev/null
    sudo apt install -f -y &>/dev/null
}

safer-apt() {
    "$HOME/dotfiles/timeout" -t 900 sudo DEBIAN_FRONTEND=noninteractive apt "$@" -y 2>/dev/null || unlock-apt && fix-apt && "$HOME/dotfiles/timeout" -t 900 sudo DEBIAN_FRONTEND=noninteractive apt "$@" -y 2>/dev/null || unlock-apt
}

safer-apt-fast() {
    # If we're capturing logs (CAPTURE_OUTPUT is set), don't redirect to /dev/null
    if [[ -n "$CAPTURE_OUTPUT" ]]; then
        "$HOME/dotfiles/timeout" -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -y || { unlock-apt && fix-apt && "$HOME/dotfiles/timeout" -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -y; } || unlock-apt
    else
        "$HOME/dotfiles/timeout" -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -y 2>/dev/null || unlock-apt && fix-apt && "$HOME/dotfiles/timeout" -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -y 2>/dev/null || unlock-apt
    fi
}

# Safe tput function that falls back to empty strings if tput fails
safe_tput() {
    if command -v tput >/dev/null 2>&1 && tput "$@" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Detect system architecture and output the appropriate string for download URLs.
# Usage: get_arch [format]
#   format: "uname" (default) → x86_64/aarch64
#           "deb"             → amd64/arm64
#           "go"              → amd64/arm64
get_arch() {
    local format="${1:-uname}"
    local machine
    machine=$(uname -m)
    case "$format" in
        deb|go)
            case "$machine" in
                x86_64)  echo "amd64" ;;
                aarch64|arm64) echo "arm64" ;;
                *) echo "$machine" ;;
            esac
            ;;
        *)
            case "$machine" in
                aarch64) echo "aarch64" ;;
                arm64)   echo "aarch64" ;;
                *)       echo "$machine" ;;
            esac
            ;;
    esac
}

# Export all functions for use in child scripts
export -f run_script_parallel
export -f unlock-apt
export -f fix-apt
export -f safer-apt
export -f safer-apt-fast
export -f safe_tput
export -f get_arch

# Set up environment variables if not already set
if [[ -z "$DOTFILES_FOLDER" ]]; then
    export DOTFILES_FOLDER=$HOME/dotfiles
fi
