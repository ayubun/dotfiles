---
name: review-recent-sessions
description: Use when the user wants to review their recent opencode sessions for patterns — analyzes the last N sessions (default 5) in the current project, dispatching parallel reviewers per session, then synthesizing cross-session findings
---

# Review Recent Sessions

Review multiple recent sessions from the current project to identify cross-session patterns.

## Prerequisites

- The `opencode` CLI must be available on PATH (provides `opencode session list` and `opencode export`).
- The `ed3d-conversation-reviewer` agent and the `writing-opencode-directives` skill must be available (the reviewer loads that skill).
- This skill ships `scripts/reduce-transcript.py` (its absolute path is shown in the file list when this skill loads).

## Invocation

The user may ask to:
- review recent sessions — default to the last 5
- review the last N sessions — use their N

## Steps

### 1. List recent sessions

List the current project's sessions (newest first):

```bash
opencode session list
```

Session IDs match `ses_[A-Za-z0-9]+`.

Exclude the current session (the user doesn't want to review the review session itself): it is the most recently updated one and its title matches the running conversation — ask the user if it's ambiguous. **Never export the active session** — a session still being written can truncate mid-write. Take the requested count (default 5) from the remaining sessions.

If fewer than 2 sessions remain, tell the user there aren't enough sessions to do a cross-session review and suggest the `review-session` skill instead.

### 2. Export and reduce all transcripts

Create a working directory, then for each selected session export it and run `scripts/reduce-transcript.py` (shipped with this skill; its absolute path is shown in the file list when this skill loads):

```bash
mkdir -p /tmp/session-review-batch
opencode export <sessionID-N> > /tmp/session-review-batch/session-N.json
python3 scripts/reduce-transcript.py /tmp/session-review-batch/session-N.json /tmp/session-review-batch/reduced-N.txt
```

This can be done in a single bash command with a loop over the selected session IDs.

### 3. Dispatch parallel reviewers

For each reduced transcript, dispatch a `ed3d-conversation-reviewer` agent:

```
task:
  subagent_type: ed3d-conversation-reviewer
  description: Review session N of M
  prompt: |
    Review the reduced opencode session transcript.

    Transcript path: /tmp/session-review-batch/reduced-N.txt
    Write your findings to: /tmp/session-review-batch/findings-N.md

    Read the transcript, analyze it, and write your findings following your output format.
```

Dispatch ALL reviewers in a single message so they run in parallel; react to completion notifications — do not poll or sleep. Tell the user you've dispatched N reviewers and are waiting for results.

### 4. Synthesize findings

Once all reviewers complete, dispatch a general-purpose Sonnet agent to synthesize:

```
task:
  subagent_type: ed3d-sonnet-general-purpose
  description: Synthesize session reviews
  prompt: |
    You are synthesizing findings from multiple opencode session reviews into a cross-session analysis.

    Read all findings files in /tmp/session-review-batch/findings-*.md

    Produce a synthesis that identifies:

    1. **Recurring patterns** — issues that appear across multiple sessions. These are the highest-value findings because they represent systematic problems.

    2. **Progression** — is the user getting better or worse at prompting over time? Is the agent handling certain tasks better or worse?

    3. **Highest-impact recommendations** — across all sessions, which recommendations would have the biggest effect? Prioritize:
       - AGENTS.md changes (things the user keeps correcting)
       - Plugin hooks or permission rules (behaviors that should be enforced automatically)
       - Skills/workflows (multi-step processes that keep being done manually)

    4. **Session-specific highlights** — any single-session finding that's particularly noteworthy even if it didn't recur.

    Write your synthesis to /tmp/session-review-batch/synthesis.md

    Format as Markdown. Be specific — reference which sessions showed which patterns. Be concise — this is a summary, not a repetition of individual findings.
```

### 5. Present synthesis

Read `/tmp/session-review-batch/synthesis.md` and present the full synthesis to the user.

If any individual session findings are particularly interesting, mention that the user can find per-session details in `/tmp/session-review-batch/findings-N.md`.
