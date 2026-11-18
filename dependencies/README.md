# Dependencies Directory

This directory contains essential setup scripts that **must** be run before other installation scripts can function properly. Dependencies are automatically executed by both `install.sh` and `with-deps` to ensure a consistent, properly configured environment.

`reconcile-pi-links.bash` links the pi adapter settings, models, and extensions into the agent directory and keeps machine-local additions.

`reconcile-claude-api-key-helper.bash` adds the Claude Code `apiKeyHelper` to `~/.claude/settings.json` while the T3 claudeAgent instance is in `api-key` mode and removes it in `subscription` mode.

`sync-codex-auth.zsh` logs codex in with `OPENAI_API_KEY`, except while `ai-brain secrets provider-mode codex` prints `subscription`; then it leaves the ChatGPT login in place.
