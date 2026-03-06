
#!/bin/zsh
# .zshenv - Environment variables for ALL zsh instances
# Sourced first for every zsh (interactive, non-interactive, scripts)

# Core environment variables
export DOTFILES_FOLDER=$HOME/dotfiles
export WORK_FOLDER=$HOME/work
export XDG_CONFIG_HOME=$HOME/.config

# Development tools
export VISUAL="nvim"
export EDITOR="nvim"

# Rust/Cargo
. "$HOME/.cargo/env"

if [ -f $HOME/work/.zshenv ]; then
  source ~/work/.zshenv
fi

