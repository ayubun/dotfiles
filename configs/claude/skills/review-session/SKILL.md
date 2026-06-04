---
name: review-session
description: Use when the user wants to review a Claude Code session for quality — analyzes the current session (or a specified transcript path) for prompting effectiveness, agent performance, and environment gaps, producing actionable recommendations
---

# Review Session

Review a single Claude Code session transcript for quality and produce actionable findings.

## Prerequisites

- The `ed3d-extending-claude` plugin must be installed.
- The `ed3d-session-reflection` plugin must be installed (provides the `conversation-reviewer` agent and `reduce-transcript.py` script).
- The current session's transcript path must be available (injected by the SessionStart hook). If it is not available, ask the user for the transcript path.

## Invocation

The user may invoke this as:
- `/review-session` — review the current session
- `/review-session /path/to/transcript.jsonl` — review a specific transcript

If no argument is provided, use the current session's transcript path (from the SessionStart hook context injection).

## Steps

### 1. Determine the transcript path

If an argument was provided, use it as the transcript path. Otherwise, use the current session's transcript path from the SessionStart hook injection.

If you cannot determine the transcript path, tell the user:
```
I don't know the current session's transcript path.
Either provide a path: /review-session /path/to/session.jsonl
Or ensure the ed3d-session-reflection SessionStart hook is active.
```

### 2. Reduce the transcript

Run the reduction script to produce a token-efficient version:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/reduce-transcript.py" "<transcript_path>" "/tmp/session-review/reduced.txt"
```

Tell the user you're reducing the transcript for analysis.

### 3. Dispatch the reviewer

Create a temporary output path for findings:
```
/tmp/session-review/findings.md
```

Dispatch the `conversation-reviewer` agent with:

<invoke name="Agent">
<parameter name="subagent_type">ed3d-session-reflection:conversation-reviewer</parameter>
<parameter name="description">Review session transcript</parameter>
<parameter name="model">opus</parameter>
<parameter name="prompt">
Review the reduced Claude Code session transcript.

Transcript path: /tmp/session-review/reduced.txt
Write your findings to: /tmp/session-review/findings.md

Read the transcript, analyze it, and write your findings following your output format.
</parameter>
</invoke>

### 4. Present findings

Once the reviewer completes, read `/tmp/session-review/findings.md` and present the findings to the user.

Present the full findings — do not summarize or truncate. The reviewer has already calibrated the length to be proportional to what's interesting.
