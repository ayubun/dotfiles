---
name: prompt-security-hardening
description: Use when writing skills, CLAUDE.md files, agent prompts, or any directives that involve shell commands, environment variables, API credentials, file creation, or git operations - prevents secrets leakage into LLM context, unsafe shell patterns, and credential exposure
user-invocable: false
---

# Prompt Security Hardening

Your context window is sent to an API provider. Every secret that enters your context is a secret leaked to a third party. This skill defines the security boundaries you operate within.

## 1. Never Read Secret Values Into Context

When you need to verify an environment variable exists, check its existence without reading its value. The value should never appear in your context window, terminal output, or logs.

```bash
# SAFE: check existence without reading value
if [ -z "${STRIPE_SECRET_KEY+x}" ]; then
  echo "STRIPE_SECRET_KEY is not set"
else
  echo "STRIPE_SECRET_KEY is set"
fi

# SAFE: bash 4.2+ (macOS with brew bash, most Linux)
[[ -v STRIPE_SECRET_KEY ]] && echo "set" || echo "not set"

# SAFE: direnv / .envrc-aware check
[[ -v DATABASE_URL ]] && echo "DATABASE_URL is set" || echo "DATABASE_URL is not set"
```

```bash
# DANGEROUS: reads the value into context
echo $STRIPE_SECRET_KEY
printenv STRIPE_SECRET_KEY
echo "Key is: ${STRIPE_SECRET_KEY}"
echo "Preview: ${STRIPE_SECRET_KEY:0:8}..."    # partial values still leak
echo "Length: ${#STRIPE_SECRET_KEY}"            # length leaks entropy info
set | grep STRIPE_SECRET_KEY                    # shows the value
export | grep STRIPE_SECRET_KEY                 # shows the value
env | grep STRIPE_SECRET_KEY                    # shows the value
env | grep -q '^VAR='                           # -q is safe for existence check,
                                                # but omitting -q leaks the value
```

**Partial values and lengths are also leaks.** An 8-character prefix of a Stripe key narrows the search space enormously. The length of a secret confirms its format. Reveal nothing.

Grepping shell config files (`~/.zshrc`, `~/.bashrc`, `~/.envrc`) for a variable name will show the full export line including the value. Check for the variable name's presence without showing the line content:

```bash
# SAFE: check if the variable is configured in shell config (shows nothing about value)
grep -qc 'ANTHROPIC_API_KEY' ~/.zshrc && echo "found in .zshrc" || echo "not in .zshrc"

# DANGEROUS: shows the full export line, including the secret value
grep 'ANTHROPIC_API_KEY' ~/.zshrc
grep -n 'ANTHROPIC_API_KEY' ~/.zshrc
```

## 2. Never Hardcode Secrets in Generated Code or Directives

When writing skills, agents, or CLAUDE.md files that include code examples, use environment variable references. When generating code for users, always reference environment variables or secret managers.

```python
# SAFE
stripe.api_key = os.environ["STRIPE_SECRET_KEY"]

# DANGEROUS: reproduces training data patterns
stripe.api_key = "sk_live_..."
stripe.api_key = "sk_test_..."  # test keys are still keys
```

```yaml
# SAFE: docker-compose referencing env vars
environment:
  DATABASE_URL: ${DATABASE_URL}

# DANGEROUS: inline credentials
environment:
  DATABASE_URL: postgresql://admin:password123@db:5432/myapp
```

Placeholder values like `changeme`, `your-api-key-here`, `replace-me`, or `postgres://user:password@localhost/db` are not acceptable. They train developers to put real values in the same location, and they appear as false positives in secret scanners, desensitizing teams to alerts. Use empty values (`STRIPE_SECRET_KEY=`) or environment variable references as the primary pattern.

For `.env.example` or template files that get committed:

```bash
# SAFE: empty values in committed templates
STRIPE_SECRET_KEY=
DATABASE_URL=
JWT_SECRET=

# DANGEROUS: fake credentials that normalize the pattern
STRIPE_SECRET_KEY=sk_test_your_key_here
DATABASE_URL=postgres://user:password@localhost:5432/myapp
JWT_SECRET=change-this-to-something-secure
```

## 3. Set Restrictive File Permissions on Sensitive Files

When creating files that contain or will contain secrets (`.env`, `.envrc`, config files, key files), set restrictive permissions immediately.

```bash
# Create with restrictive permissions from the start
touch .env && chmod 600 .env
# Then populate the file

# SSH keys require restrictive permissions to function
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Application secret files
chmod 600 /etc/myapp/secrets.conf
```

Default file creation mode (typically 644) makes files world-readable. SSH will refuse to use a key with open permissions, but `.env` files and config files have no such guardrail.

## 4. Verify .gitignore Before Creating Secret-Bearing Files

Before creating `.env`, `.envrc`, or any file that will contain secrets, verify the gitignore rules will exclude it. If they won't, add the rule first.

```bash
# SAFE: check first, then create
git check-ignore -v .env || echo ".env" >> .gitignore
touch .env && chmod 600 .env

# Also check for .envrc (direnv)
git check-ignore -v .envrc || echo ".envrc" >> .gitignore
```

This applies to any file that will hold credentials: `.env`, `.envrc`, `secrets.conf`, `credentials.json`, key files, MCP configuration with embedded tokens.

## 5. Keep Secrets Out of URLs and Process-Visible Arguments

Tokens in URLs get logged in server access logs, proxy logs, and browser history. Tokens in command-line arguments are visible to other users via `ps aux`.

```bash
# SAFE: token in header, not URL
curl -H "Authorization: Bearer ${API_TOKEN}" https://api.example.com/data

# DANGEROUS: token in URL query parameter (logged in server logs)
curl "https://api.example.com/data?api_key=${API_TOKEN}"
```

For git operations, avoid embedding tokens in clone URLs:

```bash
# DANGEROUS: token in URL, persists in .git/config and shell history
git clone "https://${GITHUB_TOKEN}@github.com/org/repo.git"

# SAFER: use credential helper or environment-based auth
GIT_ASKPASS=$(mktemp) && chmod 700 "$GIT_ASKPASS"
printf '#!/bin/sh\necho "${GITHUB_TOKEN}"' > "$GIT_ASKPASS"
GIT_ASKPASS="$GIT_ASKPASS" git clone https://github.com/org/repo.git
rm "$GIT_ASKPASS"

# SAFER: configure credential helper
git config --global credential.helper store
echo "https://oauth2:${GITHUB_TOKEN}@github.com" | git credential-store store
git clone https://github.com/org/repo.git
```

When a token must be passed as an argument and there is no header/stdin alternative, use process substitution to limit exposure:

```bash
# Reduces exposure window via process substitution
curl -H @<(echo "Authorization: Bearer ${API_TOKEN}") https://api.example.com/data
```

## 6. Sanitize External Input in Shell Commands

When constructing shell commands from file contents, tool results, or user-provided values, always quote variables and validate input.

```bash
# DANGEROUS: unquoted variable, metacharacter injection
FILENAME=$(some_tool_output)
cat $FILENAME

# SAFE: quoted
cat "$FILENAME"

# DANGEROUS: user input interpolated into command
USER_INPUT="$1"
find . -name $USER_INPUT

# SAFE: quoted and validated
USER_INPUT="$1"
if [[ ! "$USER_INPUT" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Invalid input" >&2
  exit 1
fi
find . -name "$USER_INPUT"
```

For SQL in shell scripts, use parameterized queries:

```bash
# DANGEROUS: string interpolation
psql -c "SELECT * FROM users WHERE name = '$USERNAME'"

# SAFE: psql variable binding
psql --variable="username=$USERNAME" -c "SELECT * FROM users WHERE name = :'username'"
```

## 7. Guard Against Context Contamination From Files

When you read a file, its contents enter your context window and are sent to the API provider. Before reading any file, evaluate whether it might contain secrets.

Files likely to contain secrets — read with extreme caution or avoid entirely:
- `.env`, `.envrc`, `*.env.*`
- `credentials.json`, `secrets.*`, `*-key.pem`
- MCP configuration files with `env` blocks
- Docker `.env` files
- `~/.aws/credentials`, `~/.netrc`, `~/.npmrc` with tokens

When debugging configuration issues, check file existence and structure without reading secret values:

```bash
# SAFE: check structure without reading values
wc -l .env                           # line count
grep -c '=' .env                     # count of key=value pairs
grep '^[A-Z_]*=' .env | cut -d= -f1 # list keys only, not values
stat .env                            # file metadata
```

## Applying This Skill to Directives

When writing skills, CLAUDE.md files, or agent prompts:

1. **Code examples** in directives must use environment variable references, not placeholder secrets
2. **Shell examples** that check configuration must use existence checks, not value reads
3. **Workflow steps** involving credentials must specify the safe pattern explicitly — if you leave it to default behavior, the unsafe pattern will be used inconsistently
4. **File creation steps** must include permission setting and gitignore verification
5. **Never instruct an agent to read a secrets file** to verify its contents — instruct it to verify structure or key names only

## Quick Reference

| Need | Safe Pattern | Dangerous Pattern |
|------|-------------|-------------------|
| Check env var exists | `[ -z "${VAR+x}" ]` or `[[ -v VAR ]]` | `echo $VAR`, `printenv VAR` |
| Use credential in code | `os.environ["KEY"]` | `key = "sk_live_..."` |
| Create secret file | `touch f && chmod 600 f` | `echo "secret" > f` (644) |
| Pre-commit safety | `git check-ignore -v .env` | Create `.env` and hope |
| API authentication | `-H "Authorization: Bearer $TOKEN"` | `?api_key=$TOKEN` in URL |
| Git clone with token | Credential helper or GIT_ASKPASS | `https://token@github.com` |
| Verify file config | `grep '^KEY=' f \| cut -d= -f1` | `cat f` or `source f` |
| Shell variable use | `"$VAR"` (quoted) | `$VAR` (unquoted) |
