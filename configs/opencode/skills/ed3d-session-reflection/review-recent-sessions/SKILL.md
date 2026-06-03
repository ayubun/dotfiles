---
name: review-recent-sessions
description: Use when the user wants to review their recent Claude Code sessions for patterns — analyzes the last N sessions (default 5) in the current project, dispatching parallel reviewers per session, then synthesizing cross-session findings
---

# Review Recent Sessions

Review multiple recent sessions from the current project directory to identify cross-session patterns.

## Prerequisites

- The `ed3d-extending-claude` plugin must be installed.
- The `ed3d-session-reflection` plugin must be installed (provides the `conversation-reviewer` agent and `reduce-transcript.py` script).
- The current session's transcript path must be available (to determine the project directory).

## Invocation

The user may invoke this as:
- `/review-recent-sessions` — review last 5 sessions
- `/review-recent-sessions 10` — review last 10 sessions

## Steps

### 1. Find the project's session directory

Use the current session's transcript path to determine the project directory. The transcript path looks like:
```
~/.claude/projects/-Users-ed-Development-.../SESSION_ID.jsonl
```

The directory containing it is the project's session directory.

If you cannot determine the project directory, ask the user.

### 2. List recent sessions

Find the most recent JSONL files in the project directory, sorted by modification time, limited to the requested count (default 5).

```bash
ls -t "<project_session_dir>"/*.jsonl | head -<count>
```

Exclude the current session's transcript (the user doesn't want to review the review session itself).

If fewer than 2 sessions are found, tell the user there aren't enough sessions to do a cross-session review and suggest using `/review-session` instead.

### 3. Reduce all transcripts

Create a working directory:
```bash
mkdir -p /tmp/session-review-batch
```

For each session, run the reduction script:
```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/reduce-transcript.py" "<session.jsonl>" "/tmp/session-review-batch/reduced-<N>.txt"
```

This can be done in a single bash command with a loop.

### 4. Dispatch parallel reviewers

For each reduced transcript, dispatch a `conversation-reviewer` agent **in the background**:

<invoke name="Agent">
<parameter name="subagent_type">ed3d-session-reflection:conversation-reviewer</parameter>
<parameter name="description">Review session N of M</parameter>
<parameter name="model">opus</parameter>
<parameter name="run_in_background">true</parameter>
<parameter name="prompt">
Review the reduced Claude Code session transcript.

Transcript path: /tmp/session-review-batch/reduced-N.txt
Write your findings to: /tmp/session-review-batch/findings-N.md

Read the transcript, analyze it, and write your findings following your output format.
</parameter>
</invoke>

Dispatch ALL reviewers in a single message to maximize parallelism. Tell the user you've dispatched N reviewers and are waiting for results.

### 5. Synthesize findings

Once all reviewers complete, dispatch a general-purpose Sonnet agent to synthesize:

<invoke name="Agent">
<parameter name="subagent_type">ed3d-basic-agents:sonnet-general-purpose</parameter>
<parameter name="description">Synthesize session reviews</parameter>
<parameter name="prompt">
You are synthesizing findings from multiple Claude Code session reviews into a cross-session analysis.

Read all findings files in /tmp/session-review-batch/findings-*.md

Produce a synthesis that identifies:

1. **Recurring patterns** — issues that appear across multiple sessions. These are the highest-value findings because they represent systematic problems.

2. **Progression** — is the user getting better or worse at prompting over time? Is the agent handling certain tasks better or worse?

3. **Highest-impact recommendations** — across all sessions, which recommendations would have the biggest effect? Prioritize:
   - CLAUDE.md changes (things the user keeps correcting)
   - Hooks (behaviors that should be enforced automatically)
   - Skills/workflows (multi-step processes that keep being done manually)

4. **Session-specific highlights** — any single-session finding that's particularly noteworthy even if it didn't recur.

Write your synthesis to /tmp/session-review-batch/synthesis.md

Format as Markdown. Be specific — reference which sessions showed which patterns. Be concise — this is a summary, not a repetition of individual findings.
</parameter>
</invoke>

### 6. Present synthesis

Read `/tmp/session-review-batch/synthesis.md` and present the full synthesis to the user.

If any individual session findings are particularly interesting, mention that the user can find per-session details in `/tmp/session-review-batch/findings-N.md`.
