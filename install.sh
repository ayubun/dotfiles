#!/bin/bash

# https://unix.stackexchange.com/questions/196603/can-someone-explain-in-detail-what-set-m-does
# Note: Job control can cause SIGTTOU issues with background processes writing to terminal
# set -m

EXTRAS=false
VERBOSE=false

while getopts 'ev' flag; do
  case "${flag}" in
    e) EXTRAS=true ;;
    v) VERBOSE=true ;;
  esac
done

SELF="${BASH_SOURCE[0]}"
[[ $SELF == */* ]] || SELF="./$SELF"
SELF="$(cd "${SELF%/*}" && pwd -P)/${SELF##*/}"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:${SELF%/*}:$PATH"

auto_su() {
    [[ $UID == 0 ]] || exec sudo -p "$PROGRAM must be run as root. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"
}

# Safe tput function that falls back to empty strings if tput fails
safe_tput() {
    if command -v tput >/dev/null 2>&1 && tput "$@" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 0 to 7 = black, red, green, yellow, blue, magenta, cyan, white
# Use safe tput with fallbacks
MOVE_UP=$(safe_tput cuu 1 || echo "")
CLEAR_LINE=$(safe_tput el 1 || echo "")
BOLD=$(safe_tput bold || echo "")
UNDERLINE=$(safe_tput smul || echo "")
RED_TEXT=$(safe_tput setaf 1 || echo "")
GREEN_TEXT=$(safe_tput setaf 2 || echo "")
YELLOW_TEXT=$(safe_tput setaf 3 || echo "")
BLUE_TEXT=$(safe_tput setaf 4 || echo "")
MAGENTA_TEXT=$(safe_tput setaf 5 || echo "")
CYAN_TEXT=$(safe_tput setaf 6 || echo "")
WHITE_TEXT=$(safe_tput setaf 7 || echo "")
DIM_TEXT=$(safe_tput dim || echo "")
RESET=$(safe_tput sgr0 || echo "")

# If tput is completely broken, disable all formatting
if ! safe_tput cols >/dev/null 2>&1; then
    echo "Warning: Terminal formatting disabled due to tput issues"
    MOVE_UP=""
    CLEAR_LINE=""
    BOLD=""
    UNDERLINE=""
    RED_TEXT=""
    GREEN_TEXT=""
    YELLOW_TEXT=""
    BLUE_TEXT=""
    MAGENTA_TEXT=""
    CYAN_TEXT=""
    WHITE_TEXT=""
    DIM_TEXT=""
    RESET=""
fi

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DOTFILES_FOLDER=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
if [[ $DOTFILES_FOLDER != "$HOME/dotfiles" ]] ; then
    # if the current script is not being run from the home directory, we want to move to the home directory.
    rm -rf $HOME/dotfiles
    git clone https://github.com/ayubun/dotfiles.git $HOME/dotfiles
    cd $HOME/dotfiles
    ./install.sh
    exit 0
fi

echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_PATH=ubuntu
    OS_NAME=Ubuntu
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_PATH=mac
    OS_NAME=Mac
else
    echo "Unsupported OS"
    exit 1
fi

rm -rf $DOTFILES_FOLDER/tmp
mkdir $DOTFILES_FOLDER/tmp

# Initialize failure tracking
FAILURE_LOG="$DOTFILES_FOLDER/tmp/failed_scripts.log"
PROMPTED_LOG="$DOTFILES_FOLDER/tmp/prompted_scripts.log"
touch "$FAILURE_LOG"
touch "$PROMPTED_LOG"

# Load shared dependencies
source "$DOTFILES_FOLDER/dependencies/shared-functions.sh"

# Function to safely run a script and track failures
safe_run_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    local script_type="${2:-Script}"
    
    if [[ $VERBOSE = true ]] ; then
        echo "${RESET}${YELLOW_TEXT}[${BOLD}${script_type}${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running ${UNDERLINE}${script_name}${RESET}" 
    fi
    
    # Run the script and capture exit code
    local temp_output=$(mktemp)
    if . "$script_path" >"$temp_output" 2>&1; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    # Some scripts may return non-zero but still succeed (like mkdir for existing dirs)
    # Check if this is a "soft failure" by looking for specific patterns
    local is_soft_failure=false
    if [[ $exit_code -ne 0 ]]; then
        # Check for common soft failure patterns
        if grep -qi "file exists\|already exists\|directory exists" "$temp_output" 2>/dev/null; then
            is_soft_failure=true
        elif [[ "$script_name" =~ (create-dirs|mkdir) ]]; then
            is_soft_failure=true
        fi
    fi
    
    if [[ $exit_code -eq 0 ]] || [[ $is_soft_failure == true ]]; then
        if [[ $VERBOSE = true ]] ; then
            echo "${RESET}${GREEN_TEXT}[${BOLD}✓${RESET}${GREEN_TEXT}] ${script_name} completed successfully${RESET}"
        fi
        rm -f "$temp_output"
        return 0
    else
        echo "${RESET}${RED_TEXT}[${BOLD}✗${RESET}${RED_TEXT}] ${script_name} failed${RESET}"
        if [[ $VERBOSE = true ]] && [[ -s "$temp_output" ]]; then
            echo "${RESET}${RED_TEXT}Error output: $(cat "$temp_output")${RESET}"
        fi
        echo "$script_path" >> "$FAILURE_LOG"
        rm -f "$temp_output"
        return 1
    fi
}

# Function to show spinning animation while a script runs
show_spinner() {
    local pid=$1
    local script_name="$2"
    local script_path="$3"
    local log_file="$4"
    local timeout_seconds="${5:-300}"  # Default 5 minute timeout
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local elapsed=0
    
    # Get relative path from dotfiles folder
    local rel_path=${script_path#$DOTFILES_FOLDER/}
    local dir_path=$(dirname "$rel_path")
    
    local last_shown_content=""
    local spinner_shown=false
    local header_shown=false
    local timed_out=false
    
    while kill -0 $pid 2>/dev/null; do
        # Check for timeout
        if [[ $elapsed -ge $timeout_seconds ]]; then
            timed_out=true
            break
        fi
        
        # Get last 25 lines from log
        if [[ -f "$log_file" && -s "$log_file" ]]; then
            local current_content=$(tail -n 25 "$log_file" 2>/dev/null)
            
            # Only update if content changed
            if [[ "$current_content" != "$last_shown_content" ]]; then
                # Show header only when we first have content
                if [[ $header_shown == false ]]; then
                    # Clear spinner if shown before displaying header
                    if [[ $spinner_shown == true ]]; then
                        printf "\r\033[K"
                        spinner_shown=false
                    fi
                    printf "${RESET}${MAGENTA_TEXT}--- Captured stdout ---${RESET}\n\n"
                    header_shown=true
                fi
                
                # Clear spinner if shown (for subsequent updates)
                if [[ $spinner_shown == true ]]; then
                    printf "\r\033[K"
                    spinner_shown=false
                fi
                
                # Clear previous content and show new
                if [[ -n "$last_shown_content" ]]; then
                    # Count lines to clear (last content + empty line)
                    local lines_to_clear=$(echo -n "$last_shown_content" | grep -c $'\n')
                    lines_to_clear=$((lines_to_clear + 1))
                    for ((j=0; j<lines_to_clear; j++)); do
                        printf "\033[1A\033[2K"
                    done
                    # Small delay to ensure clearing completes
                    sleep 0.01
                fi
                
                # Show current content
                printf "${DIM_TEXT}%s${RESET}\n" "$current_content"
                last_shown_content="$current_content"
            fi
        fi
        
        # Show spinner with timeout indicator
        local timeout_indicator=""
        if [[ $elapsed -gt 30 ]]; then
            timeout_indicator=" ${DIM_TEXT}(${elapsed}s)${RESET}"
        fi
        
        if [[ $spinner_shown == false ]]; then
            printf "\n${RESET}${CYAN_TEXT}[${BOLD}Running${RESET}${CYAN_TEXT}]${RESET} ${BLUE_TEXT}${UNDERLINE}${script_name}${RESET} ${YELLOW_TEXT}(${dir_path})${RESET} ${BLUE_TEXT}${spin:$i:1}${RESET}${timeout_indicator}"
            spinner_shown=true
        else
            printf "\r${RESET}${CYAN_TEXT}[${BOLD}Running${RESET}${CYAN_TEXT}]${RESET} ${BLUE_TEXT}${UNDERLINE}${script_name}${RESET} ${YELLOW_TEXT}(${dir_path})${RESET} ${BLUE_TEXT}${spin:$i:1}${RESET}${timeout_indicator}"
        fi
        
        i=$(( (i+1) % ${#spin} ))
        elapsed=$((elapsed + 1))
        sleep 1
    done
    
    # Handle timeout case
    if [[ $timed_out == true ]]; then
        # Clear spinner and content
        if [[ $spinner_shown == true ]]; then
            printf "\r\033[K"
        fi
        if [[ -n "$last_shown_content" ]]; then
            local lines_to_clear=$(echo -n "$last_shown_content" | grep -c $'\n')
            lines_to_clear=$((lines_to_clear + 1))
            for ((j=0; j<lines_to_clear; j++)); do
                printf "\033[1A\033[2K"
            done
        fi
        if [[ $header_shown == true ]]; then
            printf "\033[1A\033[2K"
            printf "\033[1A\033[2K"
        fi
        
        # Properly terminate the background process and its children
        # Send SIGTERM first, then SIGKILL if needed
        pkill -P $pid 2>/dev/null || true
        kill -TERM $pid 2>/dev/null || true
        sleep 0.5
        kill -KILL $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
        
        # Show timeout message and prompt for interactive mode
        printf "${RESET}${YELLOW_TEXT}[${BOLD}${WHITE_TEXT}⏰${RESET}${YELLOW_TEXT}]${RESET} ${BOLD}${YELLOW_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${dir_path})${RESET} ${YELLOW_TEXT}timed out - likely needs input${RESET}\n"
        printf "${RESET}${CYAN_TEXT}[${BOLD}Interactive${RESET}${CYAN_TEXT}]${RESET} Running ${BOLD}${script_name}${RESET} interactively...\n"
        
        # Log that this script required prompting
        echo "$script_path" >> "$PROMPTED_LOG" 2>/dev/null || true
        
        # Return special code to indicate timeout
        return 2
    fi
    
    # Clear spinner and last content, show completion
    if [[ $spinner_shown == true ]]; then
        printf "\r\033[K"
    fi
    if [[ -n "$last_shown_content" ]]; then
        local lines_to_clear=$(echo -n "$last_shown_content" | grep -c $'\n')
        lines_to_clear=$((lines_to_clear + 1))
        for ((j=0; j<lines_to_clear; j++)); do
            printf "\033[1A\033[2K"
        done
    fi
    
    # Also clear the header line if it was shown
    if [[ $header_shown == true ]]; then
        # Clear 2 lines: header + blank line below
        printf "\033[1A\033[2K"
        printf "\033[1A\033[2K"
    fi
    
    # Show completion message
    printf "${RESET}${GREEN_TEXT}[${BOLD}${WHITE_TEXT}✓${RESET}${GREEN_TEXT}]${RESET} ${BOLD}${GREEN_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${dir_path})${RESET} ${GREEN_TEXT}completed successfully!${RESET}\n"
    return 0
}

# Install dependencies (i.e. GNU parallel)
echo "${RESET}${YELLOW_TEXT}[${BOLD}Dependencies${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Installing dependencies...${RESET}"

find $DOTFILES_FOLDER/dependencies -maxdepth 1 -mindepth 1 -type f -name "*.sh" -print | \
while read file; do
    script_name=$(basename "$file")
    script_log="/tmp/dep_output_$$_$(basename "$file").log"
    
    # Try running non-interactively first
    # Disable job control and redirect properly to avoid SIGTTOU
    ( set +m; exec env NO_COLOR=1 bash "$file" ) > "$script_log" 2>&1 &
    script_pid=$!
    show_spinner $script_pid "$script_name" "$file" "$script_log" 120  # 2 minute timeout for deps
    spinner_result=$?
    
    if [[ $spinner_result -eq 2 ]]; then
        # Script timed out, run interactively
        bash "$file"
        exit_code=$?
    else
        # Capture exit code properly before || true
        wait $script_pid
        exit_code=$?
        # Suppress any wait errors
        wait $script_pid 2>/dev/null || true
    fi
    
    if [[ $exit_code -ne 0 ]]; then
        printf "\033[1A\033[2K"
        script_dir=$(dirname "${file#$DOTFILES_FOLDER/}")
        printf "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}\n"
        echo "$file" >> "$FAILURE_LOG" 2>/dev/null || true
    fi
    
    rm -f "$script_log" 2>/dev/null
done

if [ -d "$DOTFILES_FOLDER/dependencies/$OS_PATH" ]; then
    find $DOTFILES_FOLDER/dependencies/$OS_PATH -maxdepth 1 -mindepth 1 -type f -name "*.sh" -print | \
    while read file; do
        script_name=$(basename "$file")
        script_log="/tmp/dep_output_$$_$(basename "$file").log"
        
        # Try running non-interactively first
        ( set +m; exec env NO_COLOR=1 bash "$file" ) > "$script_log" 2>&1 &
        script_pid=$!
        show_spinner $script_pid "$script_name" "$file" "$script_log" 120
        spinner_result=$?
        
        if [[ $spinner_result -eq 2 ]]; then
            # Script timed out, run interactively
            bash "$file"
            exit_code=$?
        else
            # Capture exit code properly before || true
            wait $script_pid
            exit_code=$?
            # Suppress any wait errors
            wait $script_pid 2>/dev/null || true
        fi
        
        if [[ $exit_code -ne 0 ]]; then
            printf "\033[1A\033[2K"
            script_dir=$(dirname "${file#$DOTFILES_FOLDER/}")
            printf "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}\n"
            echo "$file" >> "$FAILURE_LOG" 2>/dev/null || true
        fi
        
        rm -f "$script_log" 2>/dev/null
    done
fi

find $DOTFILES_FOLDER/configs -maxdepth 1 -mindepth 1 -type f \( -name ".*" -o -name "personalize" \) -print | \
while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Symlinking ${UNDERLINE}${file}${RESET}" 
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/configs/$file $HOME/$file
done

# Symlink ghostty config for mac
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "${RESET}${YELLOW_TEXT}[${BOLD}Ghostty${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Configuring default Ghostty config${RESET}" 
  rm -rf ${HOME}/.config/ghostty/config
  ln -s $DOTFILES_FOLDER/configs/ghostty/config ${HOME}/.config/ghostty/config
fi

echo "${RESET}${YELLOW_TEXT}[${BOLD}SSH${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Configuring default SSH configs${RESET}" 
# Configure default SSH stuffs
. $DOTFILES_FOLDER/configs/ssh/setup.sh

# OS-specific programs with better error handling
if [[ $EXTRAS = true ]] ; then
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    
    # Use simpler sequential execution with background processes for reliability
    shopt -s nullglob  # Make globs that don't match return empty instead of literal
    for script in $DOTFILES_FOLDER/programs/$OS_PATH/*.sh $DOTFILES_FOLDER/programs/$OS_PATH/extras/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            
            # Run script in background with spinner
            script_log="/tmp/script_output_$$_$(basename "$script").log"
            ( set +m; exec env NO_COLOR=1 bash "$script" ) > "$script_log" 2>&1 &
            script_pid=$!
            show_spinner $script_pid "$script_name" "$script" "$script_log" 300  # 5 minute timeout
            spinner_result=$?
            
            if [[ $spinner_result -eq 2 ]]; then
                # Script timed out, run interactively
                bash "$script"
                exit_code=$?
            else
                # Capture exit code properly before || true
                wait $script_pid
                exit_code=$?
                # Suppress any wait errors
                wait $script_pid 2>/dev/null || true
            fi
            
            if [[ $exit_code -ne 0 ]]; then
                # Override the success message for failures
                printf "\033[1A\033[2K"  # Clear last line
                script_dir=$(dirname "${script#$DOTFILES_FOLDER/}")
                printf "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}\n"
                echo "$script" >> "$FAILURE_LOG" 2>/dev/null || true
            fi
            
            # Clean up log file
            rm -f "$script_log" 2>/dev/null
        fi
    done
    shopt -u nullglob  # Reset nullglob
else
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    
    shopt -s nullglob
    for script in $DOTFILES_FOLDER/programs/$OS_PATH/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            
            script_log="/tmp/script_output_$$_$(basename "$script").log"
            ( set +m; exec env NO_COLOR=1 bash "$script" ) > "$script_log" 2>&1 &
            script_pid=$!
            show_spinner $script_pid "$script_name" "$script" "$script_log" 300
            spinner_result=$?
            
            if [[ $spinner_result -eq 2 ]]; then
                # Script timed out, run interactively
                bash "$script"
                exit_code=$?
            else
                # Capture exit code properly before || true
                wait $script_pid
                exit_code=$?
                # Suppress any wait errors
                wait $script_pid 2>/dev/null || true
            fi
            
            if [[ $exit_code -ne 0 ]]; then
                printf "\033[1A\033[2K"
                script_dir=$(dirname "${script#$DOTFILES_FOLDER/}")
                printf "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}\n"
                echo "$script" >> "$FAILURE_LOG" 2>/dev/null || true
            fi
            
            rm -f "$script_log" 2>/dev/null
        fi
    done
    shopt -u nullglob
fi


# OS-independent programs
if [[ $EXTRAS = true ]] ; then
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    
    shopt -s nullglob
    for script in $DOTFILES_FOLDER/programs/*.sh $DOTFILES_FOLDER/programs/extras/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            
            script_log="/tmp/script_output_$$_$(basename "$script").log"
            ( set +m; exec env NO_COLOR=1 bash "$script" ) > "$script_log" 2>&1 &
            script_pid=$!
            show_spinner $script_pid "$script_name" "$script" "$script_log" 300
            spinner_result=$?
            
            if [[ $spinner_result -eq 2 ]]; then
                # Script timed out, run interactively
                bash "$script"
                exit_code=$?
            else
                # Capture exit code properly before || true
                wait $script_pid
                exit_code=$?
                # Suppress any wait errors
                wait $script_pid 2>/dev/null || true
            fi
            
            if [[ $exit_code -ne 0 ]]; then
                printf "\033[1A\033[2K"
                script_dir=$(dirname "${script#$DOTFILES_FOLDER/}")
                printf "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}\n"
                echo "$script" >> "$FAILURE_LOG" 2>/dev/null || true
            fi
            
            rm -f "$script_log" 2>/dev/null
        fi
    done
    shopt -u nullglob
else
    echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n" 
    
    shopt -s nullglob
    for script in $DOTFILES_FOLDER/programs/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            
            script_log="/tmp/script_output_$$_$(basename "$script").log"
            ( set +m; exec env NO_COLOR=1 bash "$script" ) > "$script_log" 2>&1 &
            script_pid=$!
            show_spinner $script_pid "$script_name" "$script" "$script_log" 300
            spinner_result=$?
            
            if [[ $spinner_result -eq 2 ]]; then
                # Script timed out, run interactively
                bash "$script"
                exit_code=$?
            else
                # Capture exit code properly before || true
                wait $script_pid
                exit_code=$?
                # Suppress any wait errors
                wait $script_pid 2>/dev/null || true
            fi
            
            if [[ $exit_code -ne 0 ]]; then
                printf "\033[1A\033[2K"
                script_dir=$(dirname "${script#$DOTFILES_FOLDER/}")
                printf "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}\n"
                echo "$script" >> "$FAILURE_LOG" 2>/dev/null || true
            fi
            
            rm -f "$script_log" 2>/dev/null
        fi
    done
    shopt -u nullglob
fi

# Display failed scripts summary
echo ""
echo ""

# Show failed scripts
if [[ -s "$FAILURE_LOG" ]]; then
    echo "${RESET}${RED_TEXT}${BOLD}⚠️  WARNING: The following scripts failed to install:${RESET}"
    echo ""
    while IFS= read -r failed_script; do
        script_name=$(basename "$failed_script")
        echo "${RESET}${RED_TEXT}${BOLD}    ✗ ${script_name}${RESET} ${RED_TEXT}(${failed_script})${RESET}"
    done < "$FAILURE_LOG"
    echo ""
    echo "${RESET}${YELLOW_TEXT}You may want to check these scripts manually and re-run them if needed.${RESET}"
    echo ""
fi

# Show scripts that required prompting
if [[ -s "$PROMPTED_LOG" ]]; then
    echo "${RESET}${YELLOW_TEXT}${BOLD}📝 INFO: The following scripts required interactive input:${RESET}"
    echo ""
    while IFS= read -r prompted_script; do
        script_name=$(basename "$prompted_script")
        echo "${RESET}${YELLOW_TEXT}${BOLD}    ⏰ ${script_name}${RESET} ${YELLOW_TEXT}(${prompted_script})${RESET}"
    done < "$PROMPTED_LOG"
    echo ""
    echo "${RESET}${CYAN_TEXT}These scripts may benefit from being made non-interactive for automation.${RESET}"
    echo ""
fi

# Overall summary
if [[ ! -s "$FAILURE_LOG" && ! -s "$PROMPTED_LOG" ]]; then
    echo "${RESET}${GREEN_TEXT}${BOLD}🎉 All scripts completed successfully without prompting!${RESET}"
    echo ""
elif [[ ! -s "$FAILURE_LOG" ]]; then
    echo "${RESET}${GREEN_TEXT}${BOLD}✅ All scripts completed successfully!${RESET}"
    echo ""
fi

rm -rf $DOTFILES_FOLDER/tmp

echo ""
echo ""
echo "${RESET}${GREEN_TEXT}${BOLD}            Installation is complete! (* ^ ω ^)${RESET}" 
if [[ $EXTRAS = true ]] ; then
    echo ""
    echo "${RESET}${GREEN_TEXT}     ヽ(*・ω・)ﾉ Extra programs have been included${RESET}"
fi
echo ""
echo "${RESET}${YELLOW_TEXT}  Be sure to install the necessary fonts for Powerlevel10k:"
echo "${RESET}${YELLOW_TEXT}  https://github.com/romkatv/powerlevel10k/blob/master/font.md${RESET}"
echo "${RESET}"

