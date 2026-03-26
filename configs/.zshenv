#!/bin/zsh

# .zshenv - Environment variables for ALL zsh instances
# Sourced first for every zsh (interactive, non-interactive, scripts)

# Core environment variables
export DOTFILES_FOLDER=$HOME/dotfiles
export WORK_FOLDER=$HOME/work
export XDG_CONFIG_HOME=$HOME/.config
if [ -d "$WORK_FOLDER" ]; then
  export WORK=true
else
  export WORK=false
fi

# Core aliases - for use in scripts
alias ai-agent="opencode"

# Load any pre-configured functions
if [ -f "$DOTFILES_FOLDER/configs/dependencies/functions.sh" ]; then
  source "$DOTFILES_FOLDER/configs/dependencies/functions.sh"
fi

# PATHs

# opencode
add_to_path "$HOME/.opencode/bin"
# local bin
add_to_path "$HOME/.local/bin"
if $WORK; then
  # discord bin
  add_to_path "$HOME/discord/.local/bin"
fi
# bun
export BUN_INSTALL="$HOME/.bun"
add_to_path "$BUN_INSTALL/bin"
# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# vscode (code)
# if [[ "$OSTYPE" == "darwin"* ]]; then
#   # Add code cmd (only works on mac)
#   add_to_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
# fi


# Development tools
export VISUAL="nvim"
export EDITOR="nvim"
# specifying term to fix ghostty incompatibilities
export TERM=xterm-256color

# Rust/Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

if [ -f $HOME/work/.zshenv ]; then
  source ~/work/.zshenv
fi

