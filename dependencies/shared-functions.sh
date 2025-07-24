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
    timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt "$@" -y 2>/dev/null || unlock-apt && fix-apt && timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt "$@" -y 2>/dev/null || unlock-apt
}

safer-apt-fast() {
    timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -yV 2>/dev/null || unlock-apt && fix-apt && timeout -t 900 sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@" -y 2>/dev/null || unlock-apt
}

# Safe tput function that falls back to empty strings if tput fails
safe_tput() {
    if command -v tput >/dev/null 2>&1 && tput "$@" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Export all functions for use in child scripts
export -f run_script_parallel
export -f unlock-apt
export -f fix-apt
export -f safer-apt
export -f safer-apt-fast
export -f safe_tput

# Set up environment variables if not already set
if [[ -z "$DOTFILES_FOLDER" ]]; then
    SOURCE=${BASH_SOURCE[0]}
    while [ -L "$SOURCE" ]; do
        DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
        SOURCE=$(readlink "$SOURCE")
        [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
    done
    export DOTFILES_FOLDER=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
fi
