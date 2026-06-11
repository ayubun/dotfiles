---
name: export-session-as-markdown
description: Use when the user wants to export an opencode session transcript as a readable Markdown file — converts a specified session (or the most recent non-active one) into GitHub-flavored Markdown with metadata header, collapsible tool results, and reasoning blocks
---

# Export Session as Markdown

Export an opencode session transcript to a human-readable GitHub-flavored Markdown file.

## Prerequisites

- The `opencode` CLI must be available on PATH (provides `opencode session list` and `opencode export`).
- This skill ships `scripts/reduce-transcript.py` (its absolute path is shown in the file list when this skill loads).

## Invocation

The user may ask to:
- export "this session" or the most recent session — pick the most recent **non-active** session, or ask which one (see step 1)
- export a specific session — identified by session ID (`ses_…`) or by title
- export to a specific output path

## Steps

### 1. Determine the session to export

List the current project's sessions:

```bash
opencode session list
```

Session IDs match `ses_[A-Za-z0-9]+`.

**Never export the active session** — a session still being written can truncate mid-write. The active session is the most recently updated one (its title matches the running conversation).

- If the user named a session (by ID or title), use that one.
- If the user asked for "this session" or didn't specify: take the most recent non-active session, or ask the user which session they want if it's ambiguous.

### 2. Determine the output path

If the user gave an output path, use it. Otherwise, default to the current working directory with a descriptive filename:

```
session-transcript-YYYY-MM-DD.md
```

If a file with that name already exists, append a counter: `session-transcript-YYYY-MM-DD-2.md`.

### 3. Export and convert

Export the session to JSON, then run `scripts/reduce-transcript.py` (shipped with this skill; its absolute path is shown in the file list when this skill loads) with the `--markdown` flag:

```bash
opencode export <sessionID> > /tmp/session-export.json
python3 scripts/reduce-transcript.py /tmp/session-export.json "<output_path>" --markdown
```

### 4. Report the result

Tell the user where the file was written and its size. Example:

```
Exported session transcript to ./session-transcript-2026-03-20.md (346 KB)
```

Clean up the intermediate `/tmp/session-export.json` afterwards.
