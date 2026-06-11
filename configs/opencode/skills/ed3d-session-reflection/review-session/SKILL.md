---
name: review-session
description: Use when the user wants to review an opencode session for quality — analyzes a specified session (or the most recent non-active one) for prompting effectiveness, agent performance, and environment gaps, producing actionable recommendations
---

# Review Session

Review a single opencode session transcript for quality and produce actionable findings.

## Prerequisites

- The `opencode` CLI must be available on PATH (provides `opencode session list` and `opencode export`).
- The `ed3d-conversation-reviewer` agent and the `writing-opencode-directives` skill must be available (the reviewer loads that skill).
- This skill ships `scripts/reduce-transcript.py` (its absolute path is shown in the file list when this skill loads).

## Invocation

The user may ask to:
- review "this session" or the most recent session — pick the most recent **non-active** session, or ask which one (see step 1)
- review a specific session — identified by session ID (`ses_…`) or by title

## Steps

### 1. Determine the session to review

List the current project's sessions:

```bash
opencode session list
```

Session IDs match `ses_[A-Za-z0-9]+`.

**Never export the active session** — a session still being written can truncate mid-write. The active session is the most recently updated one (its title matches the running conversation).

- If the user named a session (by ID or title), use that one.
- If the user asked for "this session" or didn't specify: take the most recent non-active session, or ask the user which session they want if it's ambiguous.

### 2. Export and reduce the transcript

Export the session, then run `scripts/reduce-transcript.py` (shipped with this skill; its absolute path is shown in the file list when this skill loads) to produce a token-efficient version:

```bash
mkdir -p /tmp/session-review
opencode export <sessionID> > /tmp/session-review/session.json
python3 scripts/reduce-transcript.py /tmp/session-review/session.json /tmp/session-review/reduced.txt
```

Tell the user you're reducing the transcript for analysis.

### 3. Dispatch the reviewer

Create a temporary output path for findings:
```
/tmp/session-review/findings.md
```

Dispatch the `ed3d-conversation-reviewer` agent with:

```
task:
  subagent_type: ed3d-conversation-reviewer
  description: Review session transcript
  prompt: |
    Review the reduced opencode session transcript.

    Transcript path: /tmp/session-review/reduced.txt
    Write your findings to: /tmp/session-review/findings.md

    Read the transcript, analyze it, and write your findings following your output format.
```

### 4. Present findings

Once the reviewer completes, read `/tmp/session-review/findings.md` and present the findings to the user.

Present the full findings — do not summarize or truncate. The reviewer has already calibrated the length to be proportional to what's interesting.
