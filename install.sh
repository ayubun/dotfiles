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

# Capture original user information before escalating to root
if [[ $UID != 0 ]]; then
  export ORIGINAL_USER="$USER"
  export ORIGINAL_UID="$UID"
  export ORIGINAL_HOME="$HOME"
  export SUDO_USER="$USER"
else
  # If already root, try to get original user from environment
  export ORIGINAL_USER="${SUDO_USER:-root}"
  export ORIGINAL_UID="${SUDO_UID:-0}"
  export ORIGINAL_HOME="${SUDO_USER:+$(eval echo ~$SUDO_USER)}"
  [[ -z "$ORIGINAL_HOME" ]] && export ORIGINAL_HOME="$HOME"
fi


auto_su() {
  [[ $UID == 0 ]] || exec sudo -p "Dotfiles must be run as root. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"

  # override home with original home
  export HOME="$ORIGINAL_HOME"
}

auto_su

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
  DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DOTFILES_FOLDER=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
if [[ "$DOTFILES_FOLDER" != "$HOME/dotfiles" ]]; then
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Non-Home Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Ensuring dotfiles are installed in ~/dotfiles...${RESET}"
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

# clean up temp files from prev runs
rm -rf $DOTFILES_FOLDER/tmp || true
mkdir $DOTFILES_FOLDER/tmp || true
rm -rf $DOTFILES_FOLDER/logs || true
mkdir $DOTFILES_FOLDER/logs || true

# Initialize failure tracking
FAILURE_LOG="$DOTFILES_FOLDER/tmp/failed_scripts.log"
touch "$FAILURE_LOG"

# Load shared dependencies
source "$DOTFILES_FOLDER/dependencies/shared-functions.sh"

# Function to run a script with proper error tracking and persistent logging
# this will consume status codes and always return 0
run_script() {
  local script_path="$1"
  local script_name=$(basename "$script_path")
  local script_dir=$(dirname "${script_path#$DOTFILES_FOLDER/}")

  # Calculate persistent log file path: tmp/logs/script_path/script_name.log
  local relative_path="${script_path#$DOTFILES_FOLDER/}"
  local log_dir="$DOTFILES_FOLDER/logs/$(dirname "$relative_path")"
  local log_name="${script_name}.log"
  local log_file="$log_dir/$log_name"

  # Create log directory structure
  mkdir -p "$log_dir"

  echo "${RESET}${CYAN_TEXT}[${BOLD}Running${RESET}${CYAN_TEXT}]${RESET} ${BLUE_TEXT}${UNDERLINE}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET}"

  # Capture start time (cross-platform compatible)
  local start_time
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use seconds only (BSD date doesn't support nanoseconds)
    start_time=$(date +%s)
  else
    # Linux: Use GNU date with millisecond precision
    start_time=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))
  fi

  # Add header to log file
  {
    echo "========== Script Execution Log =========="
    echo "$script_path"
    echo ""
    echo "Started $(date)"
  } >"$log_file"

  # Run the script and capture exit code and output
  local temp_output=$(mktemp)
  export CAPTURE_OUTPUT=1
  export DOTFILES_FOLDER="$DOTFILES_FOLDER" # Ensure DOTFILES_FOLDER is available to child process

  # Export original user information for child scripts
  export ORIGINAL_USER="$ORIGINAL_USER"
  export ORIGINAL_UID="$ORIGINAL_UID"
  export ORIGINAL_HOME="$ORIGINAL_HOME"

  # Set global environment variables for non-interactive operations
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  export DEBIAN_FRONTEND=noninteractive
  if bash "$script_path" >"$temp_output" 2>&1; then
    local exit_code=0
  else
    local exit_code=$?
  fi
  unset CAPTURE_OUTPUT

  # Calculate execution duration (cross-platform compatible)
  local end_time
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use seconds only (BSD date doesn't support nanoseconds)
    end_time=$(date +%s)
  else
    # Linux: Use GNU date with millisecond precision
    end_time=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))
  fi

  # Ensure we have valid numbers and calculate duration safely
  start_time=$((10#${start_time:-0}))
  end_time=$((10#${end_time:-0}))

  # Calculate duration based on platform precision
  local duration_ms
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Duration in seconds, convert to ms for display consistency
    duration_ms=$(((end_time - start_time) * 1000))
  else
    # Linux: Duration already in milliseconds
    duration_ms=$((end_time - start_time))
  fi

  # Format duration: ms if < 1s, seconds with 2 decimals if >= 1s
  local duration_display
  if [[ $duration_ms -lt 1000 ]]; then
    duration_display="${duration_ms}ms"
  else
    local seconds=$((duration_ms / 1000))
    local millis=$((duration_ms % 1000))
    duration_display=$(printf "%d.%02d" "$seconds" "$((millis / 10))")s
  fi

  {
    echo "Finished in $duration_display"
    echo ""
  } >>"$log_file"

  # Some scripts may return non-zero but still succeed (like mkdir for existing dirs)
  # Check if this is a "soft failure" by looking for specific patterns
  local is_soft_failure=false
  # if [[ $exit_code -ne 0 ]]; then
  #     # Check for common soft failure patterns
  #     if grep -qi "file exists\|already exists\|directory exists" "$temp_output" 2>/dev/null; then
  #         is_soft_failure=true
  #     elif [[ "$script_name" =~ (create-dirs|mkdir) ]]; then
  #         is_soft_failure=true
  #     fi
  # fi

  if [[ $exit_code -eq 0 ]] || [[ $is_soft_failure == true ]]; then
    echo "${RESET}${GREEN_TEXT}[${BOLD}${WHITE_TEXT}✓${RESET}${GREEN_TEXT}]${RESET} ${BOLD}${GREEN_TEXT}${script_name}${RESET} ${GREEN_TEXT}completed successfully!${RESET}"
    echo "Exit Code: $exit_code (SUCCESS)" >>"$log_file"
  else
    echo "${RESET}${RED_TEXT}[${BOLD}${WHITE_TEXT}✗${RESET}${RED_TEXT}]${RESET} ${BOLD}${RED_TEXT}${script_name}${RESET} ${YELLOW_TEXT}(${script_dir})${RESET} ${RED_TEXT}failed!${RESET}"
    if [[ $VERBOSE = true ]] && [[ -s "$temp_output" ]]; then
      echo "${RESET}${RED_TEXT}Error output: $(cat "$temp_output")${RESET}"
    fi
    echo "Exit Code: $exit_code (FAILED)" >>"$log_file"
    echo "$script_path" >>"$FAILURE_LOG" 2>/dev/null || true
  fi

  {
    echo "=========================================="
    echo ""
  } >>"$log_file"

  # Copy output to persistent log
  cat "$temp_output" >>"$log_file"
  rm -f "$temp_output"

  {
    echo ""
    echo "=========================================="
  } >>"$log_file"
}

# Install dependencies (i.e. GNU parallel)
echo -e "${RESET}${YELLOW_TEXT}[${BOLD}Dependencies${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Installing dependencies...${RESET}\n"

find $DOTFILES_FOLDER/dependencies -maxdepth 1 -mindepth 1 -type f -name "*.sh" -print |
  while read file; do
    run_script "$file"
  done

if [ -d "$DOTFILES_FOLDER/dependencies/$OS_PATH" ]; then
  find $DOTFILES_FOLDER/dependencies/$OS_PATH -maxdepth 1 -mindepth 1 -type f -name "*.sh" -print |
    while read file; do
      run_script "$file"
    done
fi

echo ""

# for non-mac, we want all the remote servers to auto update
if ! [[ "$OSTYPE" == "darwin"* ]]; then
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Crontab${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Configuring dotfiles auto-updater${RESET}"
  RELATIVE_SCRIPT_PATH=updaters/dotfiles.sh
  SCRIPT_PATH=${HOME}/dotfiles/$RELATIVE_SCRIPT_PATH

  if [[ -n "$ORIGINAL_USER" && "$ORIGINAL_USER" != "root" ]]; then
      # Run as original user using sudo -u
      sudo -u "$ORIGINAL_USER" -H bash -c "crontab -l | grep -v $RELATIVE_SCRIPT_PATH  | crontab - &>/dev/null"
      sudo -u "$ORIGINAL_USER" -H bash -c "(crontab -l 2>/dev/null; echo \"*/5 * * * * ${SCRIPT_PATH}\") | crontab -"
      # maybe could replace with this oneline?: (crontab -l ; echo "0 * * * * your_command") | sort - | uniq - | crontab -
  else
      echo "${RESET}${RED_TEXT}${BOLD}⚠️WARNING: Because install.sh was run as a root user (no original user), the auto-updater cron will be added to the root crontab${RESET}"
      # Remove any existing entry in the crontab
      sudo crontab -l | grep -v $RELATIVE_SCRIPT_PATH  | sudo crontab - &>/dev/null
      # Add updater to crontab
      (sudo crontab -l 2>/dev/null; echo "*/5 * * * * ${SCRIPT_PATH}") | sudo crontab -
  fi

fi

echo ""

find $DOTFILES_FOLDER/configs -maxdepth 1 -mindepth 1 -type f \( -name ".*" -o -name "personalize" \) -print |
  while read file; do
    file=$(basename ${file})
    echo "${RESET}${YELLOW_TEXT}[${BOLD}Dotfiles${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Symlinking ${UNDERLINE}${file}${RESET}"
    rm -rf $HOME/$file
    ln -s $DOTFILES_FOLDER/configs/$file $HOME/$file
  done

# Symlink ghostty config for mac
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Ghostty${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Configuring default Ghostty config${RESET}"
  rm -rf ${HOME}/.config/ghostty/config
  ln -s $DOTFILES_FOLDER/configs/ghostty/config ${HOME}/.config/ghostty/config
fi

# applying keuboard settings for for mac
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}Mac Keyboard Setup${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Configuring long keypress behaviour${RESET}"
  defaults write -g ApplePressAndHoldEnabled -bool false
  # make the repeat speed the fastest possible
  defaults write -g KeyRepeat -int 3
  # adjust the repeat start speed
  # defaults write -g InitialKeyRepeat -int 10
fi

echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}SSH${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Configuring default SSH configs${RESET}"
# Configure default SSH stuffs
. $DOTFILES_FOLDER/configs/ssh/setup.sh

# OS-specific programs with better error handling
if [[ $EXTRAS = true ]]; then
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n"

  shopt -s nullglob # Make globs that don't match return empty instead of literal
  for script in $DOTFILES_FOLDER/programs/$OS_PATH/*.sh $DOTFILES_FOLDER/programs/$OS_PATH/extras/*.sh; do
    if [[ -f "$script" ]]; then
      run_script "$script"
    fi
  done
  shopt -u nullglob # Reset nullglob
else
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}$OS_NAME${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n"

  shopt -s nullglob
  for script in $DOTFILES_FOLDER/programs/$OS_PATH/*.sh; do
    if [[ -f "$script" ]]; then
      run_script "$script"
    fi
  done
  shopt -u nullglob
fi

# OS-independent programs
if [[ $EXTRAS = true ]]; then
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}] [${BOLD}Extras${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n"

  shopt -s nullglob
  for script in $DOTFILES_FOLDER/programs/*.sh $DOTFILES_FOLDER/programs/extras/*.sh; do
    if [[ -f "$script" ]]; then
      run_script "$script"
    fi
  done
  shopt -u nullglob
else
  echo -e "\n${RESET}${YELLOW_TEXT}[${BOLD}OS-Independent${RESET}${YELLOW_TEXT}]${RESET}${BOLD}${BLUE_TEXT} Running scripts...${RESET}\n"

  shopt -s nullglob
  for script in $DOTFILES_FOLDER/programs/*.sh; do
    if [[ -f "$script" ]]; then
      run_script "$script"
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
  done <"$FAILURE_LOG"
  echo ""
  echo "${RESET}${YELLOW_TEXT}You may want to check these scripts manually and re-run them if needed.${RESET}"
  echo ""
fi

# Overall summary
if [[ ! -s "$FAILURE_LOG" ]]; then
  echo "${RESET}${GREEN_TEXT}${BOLD}🎉 All scripts completed successfully!${RESET}"
  echo ""
fi

# Show log information
echo "${RESET}${CYAN_TEXT}${BOLD}📁 Script execution logs have been saved to:${RESET}"
echo "${RESET}${CYAN_TEXT}   $DOTFILES_FOLDER/logs/${RESET}"
echo ""

# Clean up temporary files
rm -f "$FAILURE_LOG" 2>/dev/null || true
rm -rf $DOTFILES_FOLDER/tmp || true

echo ""
echo ""
echo "${RESET}${GREEN_TEXT}${BOLD}            Installation is complete! (* ^ ω ^)${RESET}"
if [[ $EXTRAS = true ]]; then
  echo ""
  echo "${RESET}${GREEN_TEXT}     ヽ(*・ω・)ﾉ Extra programs have been included${RESET}"
fi
echo ""
echo "${RESET}${YELLOW_TEXT}  Be sure to install the necessary fonts for Powerlevel10k:"
echo "${RESET}${YELLOW_TEXT}  https://github.com/romkatv/powerlevel10k/blob/master/font.md${RESET}"
echo ""
echo "${RESET}${YELLOW_TEXT}      To change the current shell to zsh, run 'exec zsh -l'"
echo "${RESET}"
