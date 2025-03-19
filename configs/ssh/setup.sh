#!/bin/bash

set -e

SSH_CONFIG_PATH="$HOME/.ssh/config"

NEW_HOST_BLOCK="Host *
  RemoteForward 2224 /tmp/ghostty-clipboard-socket"

# Check if config file exists
if [[ ! -f "$SSH_CONFIG_PATH" ]]; then
    echo "SSH config file not found at $SSH_CONFIG_PATH"
    echo "Creating a new one..."
    mkdir -p "$(dirname "$SSH_CONFIG_PATH")"
    touch "$SSH_CONFIG_PATH"
fi

# Create a temporary file for the new config
temp_file=$(mktemp)

# Check if Host * block exists
if grep -q "^[[:space:]]*Host[[:space:]]*\*" "$SSH_CONFIG_PATH"; then
    # Extract the Host * block
    start_line=$(grep -n "^[[:space:]]*Host[[:space:]]*\*" "$SSH_CONFIG_PATH" | head -1 | cut -d: -f1)
    
    # Find the end of the block (next Host entry or end of file)
    next_host=$(tail -n +$((start_line + 1)) "$SSH_CONFIG_PATH" | grep -n "^[[:space:]]*Host[[:space:]]" | head -1)
    
    # Initialize the new config file
    > "$temp_file"
    
    # Add content before the Host * block if it's not at the beginning
    if [ "$start_line" -gt 1 ]; then
        head -n $((start_line - 1)) "$SSH_CONFIG_PATH" > "$temp_file"
    fi
    
    # Add our new Host * block
    echo "$NEW_HOST_BLOCK" >> "$temp_file"
    
    if [[ -n "$next_host" ]]; then
        # Calculate end line number
        next_host_rel_line=$(echo "$next_host" | cut -d: -f1)
        end_line=$((start_line + next_host_rel_line - 1))
        
        # Add content after the Host * block
        tail -n +$((end_line + 1)) "$SSH_CONFIG_PATH" >> "$temp_file"
    fi
else
    # No Host * block exists, add one at the beginning
    echo "$NEW_HOST_BLOCK" > "$temp_file"
    echo "" >> "$temp_file"
    cat "$SSH_CONFIG_PATH" >> "$temp_file"
fi

# Replace the original file with our new one
mv "$temp_file" "$SSH_CONFIG_PATH"

