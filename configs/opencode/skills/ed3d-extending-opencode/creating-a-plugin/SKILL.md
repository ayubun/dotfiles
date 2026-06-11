---
name: creating-a-plugin
description: Use when creating a new opencode plugin or setting up plugin structure - provides complete file organization, manifest format, and component definitions for commands, agents, skills, hooks, and MCP servers
---

# Creating a Plugin

*Reference note: this skill documents the **upstream Claude-plugin packaging format** used by the `skills-sources` repository that this skill library is generated from. opencode does not install packages in this format — opencode loads skills from `skills.paths` directories and agents from `~/.config/opencode/agents/`, and an "opencode plugin" is a different (JS/TS) mechanism entirely. Keep this as reference for editing the upstream plugin repo. The upstream plugin-root substitution variable is written `${PLUGIN_ROOT}` here.*

## Overview

A **Claude-plugin** packages reusable components (commands, agents, skills, hooks, MCP servers) for distribution. Create a plugin when you have components that work across multiple projects.

**Don't create a plugin for:**
- Project-specific configurations (use project-local config in the project root)
- One-off scripts or commands
- Experimental features still in development

**Plugin storage locations:**
- Development: Anywhere during development, installed via `file:///` path
- Installed: under the upstream harness's user-level or project-level plugin directories (opencode does not install these)

## Quick Start Checklist

Minimal viable plugin:

1. Create directory: `my-plugin/`
2. Create `.claude-plugin/plugin.json` with at minimum:
   ```json
   {
     "name": "my-plugin"
   }
   ```
3. Add components (commands, agents, skills, hooks, or MCP servers)
4. Test locally: `/plugin install file:///absolute/path/to/my-plugin`
5. Reload: `/plugin reload`

## Directory Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json              # Required: plugin manifest
├── commands/                    # Optional: slash commands
│   └── my-command.md
├── agents/                      # Optional: specialized subagents
│   └── my-agent.md
├── skills/                      # Optional: reusable techniques
│   └── my-skill/
│       └── SKILL.md
├── hooks/                       # Optional: event handlers
│   └── hooks.json
├── .mcp.json                    # Optional: MCP server configs
└── README.md                    # Recommended: documentation
```

**Critical:** The `.claude-plugin/` directory with `plugin.json` inside must exist at plugin root.

## Component Reference

| Component | Location | File Format | When to Use |
|-----------|----------|-------------|-------------|
| Commands | `commands/*.md` | Markdown + YAML frontmatter | Custom slash commands for repetitive tasks |
| Agents | `agents/*.md` | Markdown + YAML frontmatter | Specialized subagents for complex workflows |
| Skills | `skills/*/SKILL.md` | Markdown + YAML frontmatter | Reusable techniques and patterns |
| Hooks | `hooks/hooks.json` | JSON | Event handlers (format code, validate, etc.) |
| MCP Servers | `.mcp.json` | JSON | External tool integrations |

## plugin.json Format

**Minimal valid manifest:**
```json
{
  "name": "my-plugin"
}
```

**Complete annotated manifest:**
```json
{
  "name": "my-plugin",                    // Required: kebab-case identifier
  "version": "1.0.0",                     // Recommended: semantic versioning
  "description": "What this plugin does", // Recommended: brief description

  "author": {                             // Optional but recommended
    "name": "Your Name",
    "email": "you@example.com",
    "url": "https://github.com/yourname"
  },

  "homepage": "https://github.com/yourname/my-plugin",
  "repository": "https://github.com/yourname/my-plugin",
  "license": "MIT",
  "keywords": ["productivity", "automation"],

  "commands": [                           // Optional: explicit command paths
    "./commands/cmd1.md",
    "./commands/cmd2.md"
  ],

  "agents": [                             // Optional: explicit agent paths
    "./agents/agent1.md"
  ],

  "hooks": [                              // Optional: inline hooks
    {
      "event": "PostToolUse",
      "matcher": "Edit|Write",
      "command": "npx prettier --write \"$CLAUDE_FILE_PATHS\""
    }
  ],

  "mcpServers": {                         // Optional: inline MCP configs
    "my-server": {
      "command": "${PLUGIN_ROOT}/servers/my-server",
      "args": ["--port", "8080"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

**Key points:**
- `name` is required, everything else is optional
- Use `${PLUGIN_ROOT}` to reference plugin directory
- Commands/agents auto-discovered from `commands/` and `agents/` directories if not listed explicitly
- Skills auto-discovered from `skills/*/SKILL.md` pattern

## Creating Commands

**File location:** `commands/my-command.md` creates `/my-command` slash command

**Nested commands:** `commands/feature/sub-command.md` creates `/plugin-name:feature:sub-command`

**Template:**
```markdown
---
description: Brief description of what this command does
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
argument-hint: "[file-path]"
---

# Command Name

Your command prompt goes here.

You can use:
- $1, $2, etc. for positional arguments
- $ARGUMENTS for all arguments as single string
- @filename to include file contents
- !bash command to execute shell commands

Example implementation instructions...
```

**Frontmatter fields (upstream command format):**
- `description` - Brief description shown in `/help`
- `allowed-tools` - Comma-separated list of upstream tool names: `Read, Grep, Glob, Bash, Edit, Write, TodoWrite, Task`
- `model` - Optional: `haiku`, `sonnet`, or `opus` (defaults to user's setting)
- `argument-hint` - Optional: shown in help text
- `disable-model-invocation` - Optional: `true` to prevent auto-run

**Complete example** (`commands/review-pr.md`):
```markdown
---
description: Review pull request for security and best practices
allowed-tools: Read, Grep, Glob, Bash
model: opus
argument-hint: "[pr-number]"
---

# Pull Request Review

Review pull request #$1 for:

1. Security vulnerabilities
2. Performance issues
3. Best practices compliance
4. Error handling

Steps:
1. Use Bash to run: gh pr diff $1
2. Use Read to examine changed files
3. Use Grep to search for common anti-patterns
4. Provide structured feedback with file:line references

Focus on critical issues first.
```

## Creating Agents

**File location:** `agents/ed3d-code-reviewer.md` creates agent named "ed3d-code-reviewer"

**Template (upstream agent format):**
```markdown
---
name: agent-name
description: When and why to use this agent (critical for auto-delegation)
tools: Read, Edit, Write, Grep, Glob, Bash
model: opus
---

# Agent Name

Detailed instructions and system prompt for this agent.

## Responsibilities
- Task 1
- Task 2

## Tools Available
- Read: File operations
- Grep: Code search
- Bash: Shell commands

## Workflow
1. Step 1
2. Step 2
```

**Frontmatter fields (upstream agent format):**
- `name` - Required: kebab-case identifier
- `description` - Required: Max 1024 chars, used for auto-delegation
- `tools` - Comma-separated list of allowed tools
- `model` - Optional: `haiku`, `sonnet`, or `opus`

(For agents that run under opencode, see the creating-an-agent skill — opencode agents drop `name`/`tools` and use `mode`, full model IDs, and `permission:` blocks instead.)

**Complete example** (`agents/security-auditor.md`):
```markdown
---
name: security-auditor
description: Use when reviewing code for security vulnerabilities, analyzing authentication flows, or checking for common security anti-patterns like SQL injection, XSS, or insecure dependencies
tools: Read, Grep, Glob, Bash
model: opus
---

# Security Auditor Agent

You are a security expert specializing in web application security and secure coding practices.

## Your Responsibilities

1. Identify security vulnerabilities (SQL injection, XSS, CSRF, etc.)
2. Review authentication and authorization logic
3. Check for insecure dependencies
4. Verify input validation and sanitization
5. Review cryptographic implementations

## Workflow

1. **Scan for patterns:** Use Grep to find common vulnerability patterns
2. **Read suspicious code:** Use Read to examine flagged files
3. **Check dependencies:** Use Bash to run security audit tools
4. **Report findings:** Provide severity ratings and remediation steps

## Common Vulnerability Patterns

- SQL injection: String concatenation in queries
- XSS: Unescaped user input in templates
- CSRF: Missing CSRF tokens
- Auth bypass: Missing authorization checks
- Hardcoded secrets: API keys, passwords in code

## Reporting Format

For each finding:
- **Severity:** Critical/High/Medium/Low
- **Location:** `file:line`
- **Issue:** What's vulnerable
- **Impact:** What attacker could do
- **Fix:** How to remediate
```

## Creating Skills

**REQUIRED SUB-SKILL:** Use the writing-skills skill for complete guidance on skill structure, testing, and deployment.

Skills follow a specific structure.

**File location:** `skills/my-skill/SKILL.md`

**Minimal template:**
```markdown
---
name: my-skill-name
description: Use when [specific triggers] - [what it does]
---

# Skill Name

## Overview
Core principle in 1-2 sentences.

## When to Use
- Symptom 1
- Symptom 2
- When NOT to use

## Quick Reference
[Table or bullets for common operations]

## Implementation
[Code examples, patterns]

## Common Mistakes
[What goes wrong + fixes]
```

**Key principles:**
- `name` uses only letters, numbers, hyphens (no special chars)
- `description` starts with "Use when..." in third person
- Keep token-efficient (<500 words if frequently loaded)
- One excellent example beats many mediocre ones
- Use the writing-skills skill for complete guidance

## Creating Hooks

**File location:** `hooks/hooks.json` or inline in `plugin.json`

**Standalone hooks file:**
```json
{
  "hooks": [
    {
      "event": "PreToolUse",
      "matcher": "Bash",
      "command": "echo 'About to run: $CLAUDE_TOOL_NAME'"
    },
    {
      "event": "PostToolUse",
      "matcher": "Edit|Write",
      "command": "npx prettier --write \"$CLAUDE_FILE_PATHS\""
    },
    {
      "event": "SessionStart",
      "matcher": "*",
      "command": "${PLUGIN_ROOT}/scripts/setup.sh"
    }
  ]
}
```

**Hook events:**
- `PreToolUse` - Before tool execution (can block)
- `PostToolUse` - After tool execution
- `UserPromptSubmit` - When user submits prompt
- `Stop` - When Claude finishes responding
- `SessionStart` - Session initialization
- `SessionEnd` - Session cleanup
- `Notification` - On harness notifications
- `SubagentStop` - When subagent completes
- `PreCompact` - Before context compaction

**Matcher patterns:**
- Specific tool: `"Bash"`
- Multiple tools: `"Edit|Write"`
- All tools: `"*"`

**Environment variables:**
- `$CLAUDE_EVENT_TYPE` - Event type
- `$CLAUDE_TOOL_NAME` - Tool being used
- `$CLAUDE_TOOL_INPUT` - Tool input (JSON)
- `$CLAUDE_FILE_PATHS` - Space-separated file paths

## Creating MCP Server Configs

**File location:** `.mcp.json` at plugin root or inline in `plugin.json`

**Standalone .mcp.json:**
```json
{
  "mcpServers": {
    "database-tools": {
      "command": "${PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_URL": "${DB_URL}",
        "API_KEY": "${API_KEY:-default-key}"
      }
    },
    "web-scraper": {
      "command": "npx",
      "args": ["web-mcp-server", "--port", "3000"]
    }
  }
}
```

**Configuration fields:**
- `command` - Executable path or command name
- `args` - Array of arguments
- `env` - Environment variables (supports `${VAR}` or `${VAR:-default}`)

**Special variable:**
- `${PLUGIN_ROOT}` - Resolves to plugin root directory

## Setting Up Dev Marketplace

For local development, create a marketplace to organize your plugins:

**File:** `dev-marketplace/.claude-plugin/marketplace.json`

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "my-dev-marketplace",
  "version": "1.0.0",
  "owner": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "metadata": {
    "description": "Local development marketplace for my plugins",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "my-plugin-one",
      "version": "1.0.0",
      "description": "What this plugin does",
      "source": "./plugins/my-plugin-one",
      "category": "development",
      "author": {
        "name": "Your Name",
        "email": "you@example.com"
      }
    },
    {
      "name": "my-plugin-two",
      "version": "0.1.0",
      "description": "Experimental plugin",
      "source": "./plugins/my-plugin-two",
      "category": "productivity",
      "strict": false
    }
  ]
}
```

**Directory structure:**
```
dev-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    ├── my-plugin-one/
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── commands/
    └── my-plugin-two/
        ├── .claude-plugin/
        │   └── plugin.json
        └── agents/
```

**Install dev marketplace:**
```bash
/plugin marketplace add file:///absolute/path/to/dev-marketplace
/plugin browse
/plugin install my-plugin-one@my-dev-marketplace
```

**Plugin entry fields:**
- `name` - Required: plugin identifier
- `source` - Required: relative path or git URL
- `version` - Recommended: semantic version
- `description` - Recommended: brief description
- `category` - Optional: development, productivity, security, etc.
- `author` - Optional: author details
- `strict` - Optional: default `true` (requires plugin.json), set `false` to use marketplace entry as manifest

**Source formats:**
```json
// Local relative path
"source": "./plugins/my-plugin"

// GitHub repository
"source": {
  "source": "github",
  "repo": "owner/repo"
}

// Git URL
"source": {
  "source": "url",
  "url": "https://gitlab.com/team/plugin.git"
}
```

## Naming Conventions

**Use kebab-case everywhere:**
- Plugin names: `my-awesome-plugin`
- Command names: `review-code`
- Agent names: `security-auditor`
- Skill names: `test-driven-development`

**Filename mapping:**
- `commands/my-command.md` → `/my-command`
- `commands/project/build.md` → `/plugin-name:project:build`
- `agents/ed3d-code-reviewer.md` → agent name `ed3d-code-reviewer`
- `skills/my-skill/SKILL.md` → skill name `my-skill`

## Testing Locally

**Development workflow:**

1. Create plugin structure:
   ```bash
   mkdir -p my-plugin/.claude-plugin
   echo '{"name":"my-plugin"}' > my-plugin/.claude-plugin/plugin.json
   ```

2. Add components (commands, agents, skills)

3. Install locally:
   ```bash
   /plugin install file:///absolute/path/to/my-plugin
   ```

4. Test functionality:
   ```bash
   /my-command arg1 arg2
   # Dispatch your agent on a task
   # Invoke your skill
   ```

5. Iterate:
   - Edit plugin files
   - Run `/plugin reload`
   - Test again

**Using dev marketplace:**

1. Create marketplace structure
2. Add marketplace:
   ```bash
   /plugin marketplace add file:///absolute/path/to/dev-marketplace
   ```
3. Browse and install:
   ```bash
   /plugin browse
   /plugin install my-plugin@my-dev-marketplace
   ```

## Common Mistakes

| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing `.claude-plugin/` | Plugin not recognized | Create `.claude-plugin/plugin.json` at root |
| Invalid plugin.json | Parse error on load | Validate JSON syntax, ensure `name` field exists |
| Wrong tool name | Tool not available in command/agent | Check spelling against the harness's tool list |
| Description too long | Warning or truncation | Keep under 1024 characters total |
| Not using third person | Description sounds wrong | Use "Use when..." not "I will..." |
| Absolute paths in plugin.json | Breaks on other machines | Use relative paths or `${PLUGIN_ROOT}` |
| Forgetting `/plugin reload` | Changes not visible | Run `/plugin reload` after edits |
| Command not found | Slash command doesn't work | Check filename matches expected command, reload plugin |
| Agent not auto-delegated | Agent never gets used | Improve `description` with specific triggers and symptoms |

## Distribution

**For production/team use:**

1. Push plugin to Git repository (GitHub, GitLab, etc.)
2. Create or update team's marketplace repository
3. Add plugin entry to marketplace.json
4. Team members install:
   ```bash
   /plugin marketplace add user-or-org/marketplace-repo
   /plugin install plugin-name@marketplace-name
   ```

**For public distribution:**

Refer to the official upstream documentation for publishing to public marketplaces.

## Reference Links

- Official plugin docs: https://docs.claude.com/en/docs/claude-code/plugins
- Plugin reference: https://docs.claude.com/en/docs/claude-code/plugins-reference
- MCP servers: https://docs.claude.com/en/docs/claude-code/mcp-servers
