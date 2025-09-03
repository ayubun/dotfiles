#!/bin/zsh

session='love'
tmux has-session -t $session 2>/dev/null

if [ $? -eq 0 ]; then
  tmux attach-session -t $session
else
  tmux new-session -s $session -d
  tmux attach-session -t $session
fi

exec zsh -l
