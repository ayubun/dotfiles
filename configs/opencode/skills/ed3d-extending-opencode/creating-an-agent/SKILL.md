---
name: creating-an-agent
description: Use when creating specialized subagents for opencode or the task tool - covers description writing for auto-delegation, tool selection, prompt structure, and testing agents
---

# Creating an Agent

**REQUIRED BACKGROUND:** Read the writing-opencode-directives skill for foundational guidance on token efficiency, compliance techniques, and directive structure. This skill focuses on agent-specific patterns.

## What is an Agent?

An **agent** is a specialized assistant instance with:
- Its own model and tool permissions
- Specific responsibilities (code review, security audit, research)
- A focused system prompt

Agents are defined as Markdown files in an agents directory (`~/.config/opencode/agents/` for the user) and dispatched via the `task` tool. The filename (minus `.md`) is the agent's name.

## When to Create an Agent

**Create when:**
- Task requires specialized expertise
- Workflow benefits from tool restrictions
- You want consistent behavior across invocations
- Task is complex enough to warrant context isolation

**Don't create for:**
- Simple, one-off tasks
- Tasks the main agent handles well
- Purely conversational interactions

## Agent File Structure

```
agents/
  my-agent.md
```

**Template:**
```markdown
---
description: Use when [specific triggers] - [what agent does]
mode: subagent
model: anthropic/claude-sonnet-4-6
---

# Agent Name

[Agent system prompt - who they are, what they do]

## Responsibilities
- Task 1
- Task 2

## Workflow
1. Step 1
2. Step 2
```

There is no `name` field — the filename is the identifier. `mode: subagent` makes the agent dispatchable via the `task` tool (rather than a primary agent you switch to).

## Description: The Critical Field

The `description` field determines when the main agent auto-delegates to your agent. It's searched when matching tasks to available agents.

### Writing Effective Descriptions

**Format:** "Use when [specific triggers/symptoms] - [what the agent does]"

**Write in third person.** Injected into system prompt.

```yaml
# Bad: vague, no triggers
description: Helps with code

# Bad: first person
description: I review code for security issues

# Good: specific triggers + action
description: Use when reviewing code for security vulnerabilities, analyzing authentication flows, or checking for common security anti-patterns like SQL injection, XSS, or insecure dependencies
```

**Include:**
- Specific symptoms that trigger use
- Domain keywords (security, performance, testing)
- File types or patterns if relevant
- Actions the agent performs

**Length:** Be specific, not verbose. A few sentences at most.

## Tools and Permissions

Agents get the standard opencode toolset by default:

| Tool | What the agent uses it for |
|------|----------------------------|
| `read` | Reading files, analyzing code |
| `grep` | Searching code patterns |
| `glob` | Finding files by pattern |
| `edit` | Modifying existing files |
| `write` | Creating new files |
| `bash` | Running commands, git, tests |
| `todowrite` | Tracking multi-step workflows |
| `task` | Spawning sub-agents |
| `webfetch` / `websearch` | Research tasks |

**Principle:** Restrict what the agent doesn't need. Fewer capabilities = more focused behavior. Express restrictions as a `permission:` block in frontmatter (the deprecated `tools:` list should not be used):

```yaml
# Read-only agent (e.g. a reviewer)
permission:
  edit: deny

# Agent that must ask before running shell commands
permission:
  bash: ask
```

**Example restrictions:**
- Code reviewer: `edit: deny` (no write access)
- Implementor: default permissions (full access)
- Researcher: `edit: deny`, relies on `read`/`webfetch`/`websearch`

## Agent Prompt Structure

### Role Definition

Start with who the agent is:
```markdown
You are a security expert specializing in web application security and secure coding practices.
```

### Responsibilities

Explicit, numbered list:
```markdown
## Your Responsibilities

1. Identify security vulnerabilities
2. Review authentication logic
3. Check for insecure dependencies
4. Report findings with severity ratings
```

### Workflow

Step-by-step process:
```markdown
## Workflow

1. **Scan:** Use `grep` to find common vulnerability patterns
2. **Analyze:** Use `read` to examine flagged files
3. **Verify:** Use `bash` to run security audit tools
4. **Report:** Provide structured findings
```

### Output Format

Define expected structure:
```markdown
## Reporting Format

For each finding:
- **Severity:** Critical/High/Medium/Low
- **Location:** `file:line`
- **Issue:** What's vulnerable
- **Impact:** What attacker could do
- **Fix:** How to remediate
```

### Constraints

What the agent should NOT do:
```markdown
## Constraints

- Report findings only; do not modify code
- Ask for clarification if scope is unclear
- Escalate to human for ambiguous security decisions
```

## Model Selection

| Model | Use For |
|-------|---------|
| `anthropic/claude-haiku-4-5` | Simple tasks, fast iteration, high volume |
| `anthropic/claude-sonnet-4-6` | Balanced capability/cost, most tasks |
| `anthropic/claude-opus-4-8` | Complex reasoning, critical decisions, code review |

Specify in frontmatter:
```yaml
model: anthropic/claude-opus-4-8
```

## Testing Agents

### 1. Baseline Test

Run the task WITHOUT the agent. Document:
- What went wrong
- What was missing
- How long it took

### 2. Agent Test

Run with agent. Verify:
- Agent is auto-delegated (description triggers correctly)
- Workflow is followed
- Output matches expected format
- Permission restrictions are respected

### 3. Edge Case Testing

Test with:
- Ambiguous inputs
- Missing context
- Large/complex inputs
- Tasks outside scope (should refuse gracefully)

### 4. Iteration

If agent fails:
1. Identify root cause (description? workflow? constraints?)
2. Update agent definition
3. Re-test

## Common Patterns

### Code Reviewer

```markdown
---
description: Use when reviewing code changes, pull requests, or verifying implementation quality - analyzes for bugs, style issues, and best practices
mode: subagent
model: anthropic/claude-opus-4-8
permission:
  edit: deny
---

# Code Reviewer

You are a senior engineer reviewing code for correctness, readability, and maintainability.

## Responsibilities
1. Identify bugs and edge cases
2. Check error handling
3. Verify naming and style consistency
4. Suggest improvements

## Workflow
1. Read the changed files
2. Analyze for issues
3. Provide structured feedback

## Output Format
For each issue:
- **File:Line:** location
- **Severity:** Critical/Major/Minor
- **Issue:** description
- **Suggestion:** how to fix
```

### Research Agent

```markdown
---
description: Use when gathering information from the web, investigating APIs, or synthesizing documentation from multiple sources
mode: subagent
model: anthropic/claude-sonnet-4-6
permission:
  edit: deny
---

# Research Agent

You are a research specialist gathering and synthesizing information.

## Responsibilities
1. Search for relevant sources
2. Extract key information
3. Synthesize findings
4. Cite sources

## Workflow
1. `websearch` for relevant sources
2. `webfetch` promising results
3. Extract and organize findings
4. Return structured synthesis with citations
```

### Implementor Agent

```markdown
---
description: Use when implementing specific tasks from plans - writes code, runs tests, commits changes following TDD workflow
mode: subagent
model: anthropic/claude-sonnet-4-6
---

# Task Implementor

You implement tasks following TDD principles.

## Responsibilities
1. Write failing test first
2. Implement minimal code to pass
3. Refactor if needed
4. Commit with descriptive message

## Constraints
- Never write implementation before test
- Run tests after each change
- Commit atomic, working changes only
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Vague description | Include specific triggers and symptoms |
| Unrestricted permissions | Add `permission:` block (e.g. `edit: deny`) when the agent shouldn't modify files |
| No workflow | Add step-by-step process |
| No output format | Define expected structure |
| First-person description | Write in third person |
| Overly broad scope | Narrow to specific responsibility |
| No testing | Test auto-delegation and output quality |

## Checklist

- [ ] Description starts with "Use when...", third person
- [ ] Description includes specific triggers/symptoms
- [ ] `mode: subagent` set
- [ ] Permissions restricted where the role calls for it
- [ ] Model appropriate for task complexity
- [ ] Responsibilities clearly listed
- [ ] Workflow is step-by-step
- [ ] Output format defined
- [ ] Constraints/limitations stated
- [ ] Tested for auto-delegation
- [ ] Tested for output quality
