#!/bin/zsh

session='ghostty'
# Check if the session already exists
tmux has-session -t $session 2>/dev/null

if [ $? -eq 0 ]; then
  # If the session exists, check to see if it's stale / unresponsive
  # log_file="$HOME/.tmux_monitor/ghostty.log"
  # manager_log="$HOME/.tmux_monitor/manager.log"
  # mkdir -p "$HOME/.tmux_monitor" || true
  # TIMEOUT_SECONDS=300
  #
  # if [ -f "$log_file" ]; then
  #   last_update=$(cat "$log_file")
  #   current_time=$(date +%s)
  #   time_since_update=$((current_time - last_update))
  #
  #   if [ "$time_since_update" -gt "$TIMEOUT_SECONDS" ]; then
  #     echo "$(date +%s) Session '$session' appears frozen. Time since last update: $time_since_update seconds." > $manager_log
  #
  #     # Try to signal the session to refresh
  #     tmux send-keys -t "$session" "echo \$(date +%s) > $log_file" C-m
  #
  #     # Wait a moment and check again
  #     sleep 5
  #     new_update=$(cat "$log_file")
  #
  #     if [ "$new_update" -eq "$last_update" ]; then
  #       echo "$(date +%s) Session '$session' is still unresponsive. Attempting to kill." > $manager_log
  #
  #       # Find the pane with the PID that appears hung
  #       pane_id=$(tmux list-panes -t "$session" -F '#{pane_pid} #{pane_id}' | \
  #           awk '{print $2}' | head -n 1) # Simplistic, finds the first pane
  #
  #       # Kill the stuck pane and respawn it
  #       tmux respawn-pane -k -t "$pane_id"
  #       echo "$(date +%s) Killed and respawned pane $pane_id in session '$session'." > $manager_log
  #     else
  #       echo "$(date +%s) Session '$session' responded to the signal" > $manager_log
  #     fi
  #   fi
  # else
  #   echo "$(date +%s) Log file not found for session '$session'. Skipping." > $manager_log
  # fi
  tmux attach-session -t $session
else
  # If the session doesn't exist, start a new one
  tmux new-session -s $session -d
  tmux attach-session -t $session
fi

exec zsh -l
