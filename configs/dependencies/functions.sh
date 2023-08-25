#!/bin/bash

# Function to add something to the $PATH if it does not already exist
add_to_path() {
    # Check if the path is not already in the PATH variable
    if ! echo "$PATH" | grep -E -q "(^|:)$1($|:)"; then
        PATH="$PATH:$1"
    fi
}

add_discord_bin_to_usr_local_bin() {
    # If $1 (arg 1) is not non-zero
    if [ ! -n "$1" ]; then
        echo "add_discord_bin_to_usr_local_bin function called with no args!"
        return
    fi
    OLD_BIN_NAME=$1
    NEW_BIN_NAME=$1
    if [ -n "$2" ]; then
        NEW_BIN_NAME=$2
    fi
    # Check if the path is not already in the PATH variable
    if ! echo "$PATH" | grep -E -q "(^|:)$OLD_BIN_NAME($|:)"; then
        if [ ! -f $HOME/discord/.local/bin/$OLD_BIN_NAME ]; then
            echo "~/discord/.local/bin/$OLD_BIN_NAME not found! Please clone the Discord repo in the home directory."
        elif [ -e "/usr/local/bin/$NEW_BIN_NAME" ] | [ -L "/usr/local/bin/$NEW_BIN_NAME" ]; then
            symlink="/usr/local/bin/$NEW_BIN_NAME"
            if [ -L "$symlink" ]; then
                # Get the target file of the symlink
                target_file=$(readlink -f "$symlink")
                
                # Extract just the file names from both paths
                symlink_filename=$(basename "$target_file")
                
                # Compare the two file names
                if [[ $symlink_filename == $OLD_BIN_NAME ]]; then
                    echo "$symlink symlink exists and points to ~/discord/.local/bin/$OLD_BIN_NAME!"
                else
                    OLD_BIN_SYMLINK_POINTER="$target_file"
                    OLD_BIN_NEW_SYMLINK="/usr/local/bin/$OLD_BIN_NAME-old"
                    NEW_SYMLINK_POINTER="$HOME/discord/.local/bin/$OLD_BIN_NAME"
                    echo "WARNING: $symlink symlink already exists but doesn't point to $NEW_SYMLINK_POINTER!"
                    echo "         (Currently points to $target_file)"
                    echo "         Symlinking $OLD_BIN_SYMLINK_POINTER to $OLD_BIN_NEW_SYMLINK and"
                    echo "         Symlinking $NEW_SYMLINK_POINTER to $symlink"
                    ln -Fs $OLD_BIN_SYMLINK_POINTER $OLD_BIN_NEW_SYMLINK
                    # Preserve old symlink with "symlinkname"-old
                    mv $symlink $OLD_BIN_NEW_SYMLINK
                    # Create new symlink desired
                    ln -Fs $NEW_SYMLINK_POINTER $symlink
                fi
            elif [ $OLD_BIN_NAME != $NEW_BIN_NAME ]; then
                echo "WARNING: $symlink *FILE* already exists!"
            fi
        else
            ln -s $HOME/discord/.local/bin/$OLD_BIN_NAME /usr/local/bin/$NEW_BIN_NAME
        fi
    else
        # Debug
        echo "The ~/discord/.local/bin/$OLD_BIN_NAME script is already accesible via the user path!"
    fi
}
