#!/usr/bin/env python3
# pattern: Mixed (unavoidable)
# Reason: CLI entry point — parses args, reads JSON, writes output.
# Pure transformation logic is separated into functions below.
"""
Process opencode session exports into different output formats.

Input is the JSON produced by `opencode export <sessionID>`:
    {info: {...}, messages: [{info: {role, time, ...}, parts: [...]}]}

Usage:
    python3 reduce-transcript.py <export.json> [output]              # reduced text (default)
    python3 reduce-transcript.py <export.json> [output] --markdown   # full Markdown export

Strips bookkeeping (IDs, snapshots, step-start/step-finish, patch records,
token accounting) and retains: role, message text, tool names, tool inputs,
tool results, reasoning, and timestamps.
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Functional Core — pure transformation, no I/O
# ---------------------------------------------------------------------------

SKIP_PART_TYPES = {"step-start", "step-finish", "patch", "snapshot"}

TOOL_RESULT_LIMIT_REDUCED = 2000
REASONING_LIMIT_REDUCED = 1000
TOOL_INPUT_LIMIT_REDUCED = 200
TOOL_RESULT_LIMIT_MARKDOWN = 10000


def _truncate(text, max_len):
    """Truncate text with ellipsis indicator."""
    if len(text) <= max_len:
        return text
    return text[:max_len] + "...[truncated]"


def _summarize_tool_input(tool_input, max_value_len=200):
    """Produce a concise summary of tool input."""
    if isinstance(tool_input, str):
        return _truncate(tool_input, 500)

    if not isinstance(tool_input, dict):
        return str(tool_input)[:500]

    parts = []
    for key, value in tool_input.items():
        if isinstance(value, str) and len(value) > max_value_len:
            parts.append(f"{key}: {_truncate(value, max_value_len)}")
        else:
            parts.append(f"{key}: {value}")

    return "; ".join(parts)


def _stringify(value):
    """Coerce a tool output/error value to a string."""
    if isinstance(value, str):
        return value
    if value is None:
        return ""
    try:
        return json.dumps(value, indent=2)
    except (TypeError, ValueError):
        return str(value)


def extract_blocks(parts):
    """Convert an opencode message's parts into normalized content blocks.

    Returns a list of dicts with 'kind' and 'text' keys, plus optional
    'tool_name' and 'tool_input' for tool blocks.
    """
    if not isinstance(parts, list):
        return []

    blocks = []
    for part in parts:
        if not isinstance(part, dict):
            continue

        part_type = part.get("type", "")
        if part_type in SKIP_PART_TYPES:
            continue

        if part_type == "text":
            text = part.get("text", "")
            if text.strip():
                blocks.append({"kind": "text", "text": text})

        elif part_type == "reasoning":
            text = part.get("text", "")
            if text.strip():
                blocks.append({"kind": "reasoning", "text": text})

        elif part_type == "tool":
            state = part.get("state") or {}
            blocks.append({
                "kind": "tool_use",
                "tool_name": part.get("tool", "unknown"),
                "tool_input": state.get("input", {}),
                "text": "",
            })
            status = state.get("status", "")
            if status == "error":
                error_text = _stringify(state.get("error", "")).strip()
                if error_text:
                    blocks.append({"kind": "tool_error", "text": error_text})
            else:
                output_text = _stringify(state.get("output", "")).strip()
                if output_text:
                    blocks.append({"kind": "tool_result", "text": output_text})

        # Unknown part types are skipped.

    return blocks


def parse_message(message):
    """Parse one entry of messages[] into a normalized structure, or None.

    Returns a dict with keys: role, timestamp_ms, blocks.
    """
    if not isinstance(message, dict):
        return None

    info = message.get("info") or {}
    role = info.get("role", "unknown")
    timestamp_ms = (info.get("time") or {}).get("created")

    blocks = extract_blocks(message.get("parts", []))
    if not blocks:
        return None

    return {"role": role, "timestamp_ms": timestamp_ms, "blocks": blocks}


def _model_string(model):
    """Render a session/message model field (dict or string) as text."""
    if isinstance(model, dict):
        provider = model.get("providerID", "")
        model_id = model.get("id") or model.get("modelID") or ""
        joined = "/".join(p for p in (provider, model_id) if p)
        variant = model.get("variant", "")
        return f"{joined} ({variant})" if variant and joined else joined
    return str(model) if model else ""


def extract_metadata(export):
    """Extract session metadata from the export's top-level info object."""
    info = export.get("info") or {}
    time_info = info.get("time") or {}
    return {
        "session_id": info.get("id", ""),
        "title": info.get("title", ""),
        "directory": info.get("directory", ""),
        "agent": info.get("agent", ""),
        "model": _model_string(info.get("model")),
        "version": info.get("version", ""),
        "created_ms": time_info.get("created"),
        "updated_ms": time_info.get("updated"),
    }


def _format_timestamp_human(epoch_ms):
    """Convert an epoch-milliseconds timestamp to human-readable local-ish text."""
    if not epoch_ms:
        return ""
    try:
        dt = datetime.fromtimestamp(epoch_ms / 1000, tz=timezone.utc)
        return dt.strftime("%b %d, %Y %I:%M %p UTC")
    except (ValueError, OSError, OverflowError, TypeError):
        return str(epoch_ms)


# ---------------------------------------------------------------------------
# Formatters — pure functions producing output strings
# ---------------------------------------------------------------------------

def format_reduced(messages):
    """Format messages as token-efficient reduced text."""
    results = []
    for message in messages:
        entry = parse_message(message)
        if not entry:
            continue

        parts = []
        role = entry["role"]
        ts = _format_timestamp_human(entry["timestamp_ms"])
        ts_suffix = f" ({ts})" if ts else ""

        for block in entry["blocks"]:
            kind = block["kind"]
            if kind == "text":
                parts.append(block["text"])
            elif kind == "tool_use":
                summary = _summarize_tool_input(block["tool_input"], TOOL_INPUT_LIMIT_REDUCED)
                parts.append(f"[tool_use:{block['tool_name']}] {summary}")
            elif kind == "tool_result":
                parts.append(f"[tool_result] {_truncate(block['text'], TOOL_RESULT_LIMIT_REDUCED)}")
            elif kind == "tool_error":
                parts.append(f"[tool_error] {_truncate(block['text'], TOOL_RESULT_LIMIT_REDUCED)}")
            elif kind == "reasoning":
                parts.append(f"[reasoning] {_truncate(block['text'], REASONING_LIMIT_REDUCED)}")

        if parts:
            text = "\n".join(parts)
            results.append(f"[{role}]{ts_suffix}\n{text}")

    return "\n\n---\n\n".join(results)


def format_markdown(metadata, messages):
    """Format the session as a full Markdown document."""
    sections = []

    # Header
    header_parts = ["# Session Transcript", ""]
    title = metadata.get("title", "")
    if title:
        header_parts.append(f"**Title:** {title}")
    session_id = metadata.get("session_id", "")
    if session_id:
        header_parts.append(f"**Session:** `{session_id}`")
    directory = metadata.get("directory", "")
    if directory:
        header_parts.append(f"**Project:** `{directory}`")
    created = metadata.get("created_ms")
    if created:
        header_parts.append(f"**Started:** {_format_timestamp_human(created)}")
    updated = metadata.get("updated_ms")
    if updated:
        header_parts.append(f"**Last updated:** {_format_timestamp_human(updated)}")
    agent = metadata.get("agent", "")
    if agent:
        header_parts.append(f"**Agent:** {agent}")
    model = metadata.get("model", "")
    if model:
        header_parts.append(f"**Model:** {model}")
    version = metadata.get("version", "")
    if version:
        header_parts.append(f"**opencode version:** {version}")
    header_parts.append("")
    header_parts.append("---")
    header_parts.append("")
    sections.append("\n".join(header_parts))

    # Messages
    for message in messages:
        entry = parse_message(message)
        if not entry:
            continue

        role = entry["role"]
        ts = _format_timestamp_human(entry["timestamp_ms"])
        ts_suffix = f" ({ts})" if ts else ""

        msg_parts = []

        if role == "user":
            msg_parts.append(f"**human**{ts_suffix}\n")
        elif role == "assistant":
            msg_parts.append(f"**assistant**{ts_suffix}\n")
        else:
            msg_parts.append(f"**{role}**{ts_suffix}\n")

        for block in entry["blocks"]:
            kind = block["kind"]

            if kind == "text":
                msg_parts.append(block["text"])

            elif kind == "tool_use":
                tool_name = block["tool_name"]
                tool_input = block["tool_input"]
                input_text = _format_tool_input_markdown(tool_input)
                msg_parts.append(f"#### Tool: {tool_name}\n")
                msg_parts.append(input_text)

            elif kind in ("tool_result", "tool_error"):
                label = "Tool Result" if kind == "tool_result" else "Tool Error"
                result_text = block["text"]
                if len(result_text) > 500:
                    msg_parts.append(
                        f"<details>\n<summary>{label}</summary>\n\n"
                        f"```\n{_truncate(result_text, TOOL_RESULT_LIMIT_MARKDOWN)}\n```\n"
                        "</details>"
                    )
                else:
                    msg_parts.append(f"```\n{result_text}\n```")

            elif kind == "reasoning":
                msg_parts.append(
                    "<details>\n<summary>Reasoning</summary>\n\n"
                    f"{block['text']}\n"
                    "</details>"
                )

        if msg_parts:
            sections.append("\n".join(msg_parts))

    return "\n\n---\n\n".join(sections)


def _format_tool_input_markdown(tool_input):
    """Format tool input for Markdown display."""
    if isinstance(tool_input, str):
        return f"```\n{tool_input}\n```"

    if not isinstance(tool_input, dict):
        return f"```\n{tool_input}\n```"

    # Show each field cleanly
    parts = []
    for key, value in tool_input.items():
        if isinstance(value, str) and "\n" in value:
            parts.append(f"**{key}:**\n```\n{value}\n```")
        elif isinstance(value, str) and len(value) > 100:
            parts.append(f"**{key}:** `{_truncate(value, 200)}`")
        else:
            parts.append(f"**{key}:** `{value}`")

    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Imperative Shell — I/O only
# ---------------------------------------------------------------------------

def load_export(path):
    """Read an opencode export JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    if len(sys.argv) < 2:
        print(
            f"Usage: {sys.argv[0]} <export.json> [output] [--markdown]",
            file=sys.stderr,
        )
        sys.exit(1)

    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    use_markdown = "--markdown" in flags

    input_path = Path(args[0])
    if not input_path.exists():
        print(f"error: file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args[1]) if len(args) >= 2 else None

    try:
        export = load_export(input_path)
    except json.JSONDecodeError as e:
        print(f"error: not valid JSON ({e}): {input_path}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(export, dict) or "messages" not in export:
        print(
            f"error: {input_path} does not look like an `opencode export` JSON "
            "(expected an object with 'info' and 'messages')",
            file=sys.stderr,
        )
        sys.exit(1)

    messages = export.get("messages") or []
    metadata = extract_metadata(export)

    if use_markdown:
        output_text = format_markdown(metadata, messages)
    else:
        output_text = format_reduced(messages)

    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output_text, encoding="utf-8")
    else:
        print(output_text)


if __name__ == "__main__":
    main()
