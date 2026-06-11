# Migrate Claude Code skills/agents → opencode

You are an LLM agent asked to (re)generate opencode skills and agents from the
Claude Code source in this repo. This file is the spec. It replaces the old
`updaters/skills.sh` (awk/sed) converter, which only rewrote frontmatter and
could not port skill **bodies** (tool references) to opencode tooling.

**When to run:** after the `skills-sources` submodule is bumped, or whenever the
source changes and the opencode output needs to be regenerated.

**Invocation prompt (what the human gives you):** "Re-run the opencode migration
per `configs/opencode/CLAUDE-TO-OPENCODE.md`." You then execute the whole flow
below autonomously.

---

## 0. Operating principles

- **Do not trust hardcoded values in this doc that describe opencode itself**
  (allowed frontmatter keys, tool names, model IDs, task-tool parameters,
  session-export shape). opencode changes. Section 1 tells you how to
  **re-derive** each one from the installed opencode + live model list. The
  literals quoted elsewhere are "last known good" defaults — verify them, and
  if reality differs, follow reality and update this doc.
- **The mapping rules (Claude→opencode concept translation) ARE the contract.**
  Apply them uniformly so re-runs are *semantically idempotent*:
  - **Deterministic, must not vary between runs:** identifier renames,
    frontmatter transforms, tool-name mappings, file/dir layout, the
    `generated-by` marker.
  - **May vary in wording, must not vary in meaning:** connective prose around
    a transformed construct (e.g. how you reword a sentence after deleting a
    parameter).
- **Wipe + regenerate** the managed output each run (Section 4). Don't try to
  diff-patch in place.
- Work is parallelizable. Converting 40+ skills is best done by dispatching
  several subagents, each handed THIS doc + a batch of plugin dirs + the agent
  inventory (§1.6). You (orchestrator) own Sections 1, 4, 8, 9, 10.

---

## 1. Re-derive volatile facts BEFORE converting

Run these and use the results as ground truth for this run. Record what you
found at the top of your run summary, and hand the results to every converter
subagent so they don't re-derive independently (and inconsistently).

1. **Skill frontmatter schema opencode actually reads.** opencode is lenient:
   it reads `name` (required, string), `description` (string), `slash` (bool)
   and ignores unknown keys. Verify against the installed binary or
   <https://opencode.ai/docs/skills>:
   `strings "$(command -v opencode)" | grep -i "SKILL.md"` near the skill
   loader. Practical rule: emit only `name`, `description`, `slash`.
2. **Agent frontmatter schema + options.** Read <https://opencode.ai/docs/agents>
   or `$defs/AgentConfig` in <https://opencode.ai/config.json>. Last known
   accepted keys: `description, mode, model, variant, temperature, top_p,
   prompt, tools (deprecated — do not emit), disable, hidden, options, color,
   steps, permission` + provider passthrough (e.g. `reasoningEffort`).
3. **Model IDs.** `opencode models`. Resolve Claude shortnames to the
   **newest stable canonical alias**: highest version number, **no** `-fast`,
   no date-stamp suffix, no `-latest`. (Bare names like `claude-opus-4` pass
   schema validation but fail at dispatch; date-stamped and `-fast` variants
   are not the canonical alias.) Last known good:
   - `opus`   → `anthropic/claude-opus-4-8`
   - `sonnet` → `anthropic/claude-sonnet-4-6`
   - `haiku`  → `anthropic/claude-haiku-4-5`
4. **Tool names + the task tool's parameters.** opencode tools are lowercase:
   `read, write, edit, glob, grep, list, bash, task, todowrite, webfetch,
   websearch, skill, question`. Confirm the `task` tool's parameters
   (last known: `description, prompt, subagent_type, task_id`). Note what is
   NOT there: **no per-call `model`, no `run_in_background`.** Parallelism is
   intrinsic: dispatch multiple `task` calls in one message; completion is
   notified — no polling/sleeping.
5. **Session store surface** (needed for ed3d-session-reflection, §5f):
   - `opencode session list` — human-readable table; session IDs match
     `ses_[A-Za-z0-9]+`; lists sessions for the current project.
   - `opencode export <sessionID>` — JSON to stdout. Last known shape:
     `{info: {id, directory, title, time, ...}, messages: [{info: {role, ...},
     parts: [{type: "text"|"tool"|"reasoning"|"step-start"|"step-finish"|...}]}]}`.
   - Re-derive by exporting one real (non-active) session and inspecting keys.
     Do not export the currently-running session — it can truncate mid-write.
6. **Subagent inventory.** Enumerate `plugins/*/agents/*.md` in the source,
   apply the §5a renames, then prepend **`ed3d-`** to every agent name (e.g.
   `code-reviewer` → `ed3d-code-reviewer`). The prefix marks provenance and
   prevents collisions with personal agents in `~/work/opencode/agents` (e.g.
   the generated `ed3d-code-reviewer` vs the personal `reviewer` used by the
   personal `code-review` skill — ed3d skills must dispatch ed3d agents, never
   the personal ones, and vice versa). Every `subagent_type` you emit must be
   on this prefixed list or be a built-in (`general`, `explore`). Hand this
   list to every converter subagent.

---

## 2. Source layout (read-only)

```
configs/dependencies/skills-sources/
  plugins/<plugin>/
    skills/<skill>/SKILL.md      → convert (+ aux files per §5e)
    agents/<agent>.md            → convert (skip .keep)
    scripts/  _docs/             → plugin-level shared resources (§5e)
    hooks/  commands/            → IGNORE (out of scope)
    LICENSE* README* CLAUDE.md   → IGNORE
  .claude-plugin/marketplace.json → IGNORE
```

`ed3d-session-reflection` additionally gets the bespoke §5f treatment.

---

## 3. Destinations (managed output — opencode only)

```
configs/opencode/
  skills/<renamed-plugin>/<renamed-skill>/SKILL.md   # plugin-grouped
  agents/<renamed-agent>.md                          # flat
```

**Do NOT emit Claude Code copies** (`configs/claude/skills`,
`configs/claude/agents`). That path is retired (§9). Hand-authored personal
skills/agents live in `~/work/opencode/{skills,agents}` and are **out of scope**
for this migration — never write there.

---

## 4. Idempotency protocol

1. Ensure source looks right: `configs/dependencies/skills-sources/plugins`
   exists (else `git submodule update --init --recursive`).
2. Wipe managed subtrees only:
   - `configs/opencode/skills/`: remove every `ed3d-*` plugin dir. **Preserve**
     any non-`ed3d-*` dir.
   - `configs/opencode/agents/`: remove every `*.md` whose frontmatter contains
     the `# generated-by: migrate-to-opencode` marker (§6). **Preserve** files
     without the marker. (If a file has no marker but `git log` shows it was
     created by a previous migration commit, treat it as generated.)
3. Regenerate everything from source per Sections 5–7.
4. Verify per Section 8. Commit.

---

## 5. SKILL conversion rules

For each `plugins/<plugin>/skills/<skill>/SKILL.md`:

### 5a. Names / renames
Apply identifier renames to BOTH the plugin dir and skill dir (and anywhere the
identifier appears in any converted text):
- `extending-claude` → `extending-opencode`
- `writing-claude-md-files` → `writing-agents-md-files`
- `writing-claude-directives` → `writing-opencode-directives`
- `project-claude-librarian` → `project-opencode-librarian`

Output dir: `configs/opencode/skills/<renamed-plugin>/<renamed-skill>/`.

### 5b. Frontmatter
Emit exactly this, in this order:
1. `name: <renamed-skill-folder>` (opencode requires `name` == folder)
2. `description: <source description>` — required (hard error if missing),
   **with the §5c text replacements applied** (it is text like any other; e.g.
   "Claude Code sessions" → "opencode sessions"). Do not otherwise reword it.
3. `slash: true` — if and only if the source has `user-invocable: true`.

Drop every other key (`user-invocable` itself, `tags`, `polytoken`,
`disable-model-invocation`, `allowed-tools`, etc.).

### 5c. Body text replacements
- `CLAUDE.md` → `AGENTS.md`; `CLAUDE_MD_TESTING` → `AGENTS_MD_TESTING`
- `Claude Code` / `claude code` / `claude-code` → `opencode`
- `~/.claude/skills/` → `~/.config/opencode/skills/`
- the four identifier renames from §5a
- Rename aux files whose names contain `CLAUDE_MD` → `AGENTS_MD`.
- Drop "(or TodoWrite in older Claude Code versions)"-style asides entirely.
- Leave generic prose uses of "Claude" that mean the model/assistant (e.g.
  "Claude tends to...") — only rewrite tool/product/path/identifier references.
- **Tautology cleanup:** if a replacement collapses a contrast into nonsense
  (e.g. "use `Grep` instead of `grep`" → "use `grep` instead of `grep`"),
  reword to preserve the contrast: "use the `grep` tool, not shell
  `grep`/`rg` via bash".

### 5d. Body semantic tool mapping  ← the part the old script could not do
Apply the §7 table. The high-frequency cases:

- **Subagent dispatch blocks.** Claude bodies contain XML-ish examples:
  ```
  <invoke name="Agent">
  <parameter name="subagent_type">ed3d-<plugin>:<agent></parameter>
  <parameter name="model">opus</parameter>
  <parameter name="run_in_background">true</parameter>
  <parameter name="description">...</parameter>
  <parameter name="prompt">...</parameter>
  </invoke>
  ```
  Convert to the **canonical task-call block** (fenced, YAML-ish — this exact
  shape, so re-runs are uniform):
  ````
  ```
  task:
    subagent_type: <bare-agent-name>
    description: <short description>
    prompt: |
      <prompt text>
  ```
  ````
  with: namespace stripped (`ed3d-<plugin>:<agent>` → `<agent>`), the `model`
  parameter **deleted** (see §7 for the rule), `run_in_background` **deleted**.
  If surrounding prose says "in the background", reword to "dispatch all of
  them in a single message so they run in parallel; react to completion
  notifications — do not poll or sleep."
- **Task-tracker calls.** `TaskCreate` / `TaskUpdate` / `TaskList` / `TaskRead`
  / `TodoWrite` → the `todowrite` tool: a flat list of
  `{content, status, priority}`. Drop dependency semantics (`addBlockedBy`);
  express ordering by list order and prose ("after X completes"). Keep the
  status lifecycle `pending → in_progress → completed`.
- **`${CLAUDE_PLUGIN_ROOT}/<x>`** → see §5e/§5f.

### 5e. Auxiliary files & shared plugin resources
- Copy everything in the skill dir except `SKILL.md` verbatim, then apply §5c
  replacements + renames to `.md`/`.txt` files.
- **Plugin-level shared resources** (`<plugin>/scripts/*`, `<plugin>/_docs/*`)
  that a skill references (via `${CLAUDE_PLUGIN_ROOT}` or by name): copy the
  file **into each referencing skill's own dir** (e.g.
  `<skill>/scripts/reduce-transcript.py`). Self-containment matters: when
  opencode loads a skill it lists the files in that skill's dir with absolute
  paths, which is how the agent finds them at runtime. Rewrite references to
  `scripts/<name>` / `<name>` + add the note "(shipped with this skill; its
  absolute path is shown in the file list when this skill loads)". Never emit
  CWD-relative `../` paths in runnable commands.

### 5f. ed3d-session-reflection — bespoke port (Claude session store → opencode)

These skills/agents read Claude's `~/.claude/projects/<munged-cwd>/*.jsonl`
transcripts. opencode has no JSONL files; sessions live in a SQLite store
surfaced via the CLI (§1.5). Port functionally, not textually:

- **Find sessions** (replaces "ls the project transcript dir"):
  `opencode session list` (current project; newest first; IDs `ses_…`). To
  exclude/identify the *current* session, note it's the most recently updated
  one and its title matches the running conversation — when ambiguous, ask.
- **Get a transcript** (replaces reading a `.jsonl`):
  `opencode export <sessionID> > /tmp/…/session-<n>.json` (do not export the
  active session).
- **`scripts/reduce-transcript.py`** must be rewritten to parse the opencode
  export shape (re-derive per §1.5) instead of Claude JSONL: walk
  `messages[]`, keep `info.role`, text parts, tool-call names/args summaries,
  truncate long outputs — same reduction *intent* as the source script.
- **`export-session-as-markdown`**: same input change; output stays
  GitHub-flavored Markdown (metadata header from `info`, collapsible tool
  results, reasoning blocks).
- Frontmatter/text/tool mapping rules (§5a–5e) still apply on top.
- Verify the port by actually running the rewritten script against one real
  exported session and eyeballing the output.

---

## 6. AGENT conversion rules

For each `plugins/<plugin>/agents/<agent>.md` with a `description`
(warn + skip if missing):

- Output: `configs/opencode/agents/ed3d-<renamed-agent>.md` (flat; §5a renames,
  then the `ed3d-` prefix per §1.6 — filename is the agent name).
- Frontmatter — emit in this canonical order:
  1. `# generated-by: migrate-to-opencode` — **required**, first line inside
     the frontmatter block (YAML comment). §4's wipe keys off it.
  2. `description:` (with §5c replacements applied)
  3. `mode: subagent` (unless source sets a mode)
  4. `model:` resolved per §1.3
  5. `color:` mapped, else omit: `cyan|blue→info`, `green→success`,
     `yellow→warning`, `red→error`, `orange→accent`, `purple|pink→secondary`.
     (This mapping is a convention of this doc — verify only that the target
     values are still in opencode's color enum.)
  6. any other accepted keys (§1.2) carried from source
- **Drop** `name` (filename is the identifier) and `tools` (deprecated). If the
  source `tools:` list clearly restricted the agent (e.g. read-only), express
  the intent as a `permission:` block (e.g. `edit: deny`) instead.
- Body: §5c text replacements + §5d semantic mapping (agents dispatch
  subagents too).

---

## 7. Canonical mapping table (Claude Code → opencode)

| Claude Code | opencode | Notes |
|---|---|---|
| `<invoke name="Agent">` / `name="Task"` | canonical `task:` block (§5d) | |
| `subagent_type: ed3d-<plugin>:<name>` | `subagent_type: ed3d-<name>` | flatten the plugin namespace to the flat `ed3d-` prefix (§1.6); name must be in the inventory |
| `subagent_type: general-purpose` (bare) | `subagent_type: general` | built-in. Only the **bare** token maps; `ed3d-{opus,sonnet,haiku}-general-purpose` are real agent names — keep them |
| per-call `<parameter name="model">X` | *(delete)* | no per-call model in opencode. If the dispatched agent is `ed3d-<X>-general-purpose`-style, the model is already pinned by that agent. If a domain agent (e.g. `ed3d-conversation-reviewer`) carried a per-call model, ensure that agent's own `model:` matches the intent; flag in the run summary if it can't |
| `run_in_background: true` | *(delete)* | parallel `task` calls in one message; completion is notified; keep "don't poll/sleep" prose |
| `TaskCreate/TaskUpdate/TaskList/TaskRead/TodoWrite` | `todowrite` | flat `{content,status,priority}`; drop `addBlockedBy`; keep lifecycle + ordering |
| `WebFetch` / `WebSearch` / `Skill` / `Read/Write/Edit/Glob/Grep/Bash/Task/List/Question` | lowercase tool names | only when the token denotes the tool; "List to yourself…" (verb) stays prose. Apply §5c tautology cleanup on collisions |
| `${CLAUDE_PLUGIN_ROOT}/<x>` | per-skill copy (§5e) | no env var in opencode |
| `~/.claude/skills/` | `~/.config/opencode/skills/` | |
| `~/.claude/projects/…*.jsonl` (session transcripts) | `opencode session list` + `opencode export <id>` (§5f) | functional port, not textual |
| `CLAUDE.md` | `AGENTS.md` | |
| "plugin must be installed" framing | "the `<name>` skill/agent must be available" | opencode loads from paths, not installed plugins |

**Rows added by past runs** (encountered in the wild; apply the same way):

| Claude Code | opencode | Notes |
|---|---|---|
| `AskUserQuestion` | `question` tool | |
| namespaced **skill** refs (`ed3d-<plugin>:<skill>`, `superpowers:<skill>`) | bare skill name | frame as "the `<name>` skill" |
| `@`-mention agents (`@ed3d-<p>:<a>`, `@agent-<ns>:<a>`) | "the `<name>` agent" prose | no @-mention syntax in opencode skill bodies |
| other `~/.claude/<x>` paths (`worktrees/`, user-level `CLAUDE.md`) | `~/.config/opencode/<x>` analog (`worktrees/`, `AGENTS.md`) | generalize the path rule |
| `/clear` | `/new` | verified TUI alias |
| plugin slash commands (`/ed3d-<plugin>:<cmd> args`) | paste-message "Use the `<skill>` skill with `<args>`" | commands are out of scope (§2) |
| Enter/Exit plan mode | write the plan + `question`-tool approval gate | plan mode is a user-switched primary agent, not programmatic |
| hook names in prose (`PreToolUse`/`PostToolUse`) | plugin hooks `tool.execute.before`/`tool.execute.after` or permission rules | `SessionStart` context-injection has no equivalent — replace the flow, don't fake the hook |
| plugin-bundled `.mcp.json` server refs | the `mcp` block of `opencode.json` | MCP **tool names** (`browser_*` etc.) stay untouched |
| CLAUDE.md-vs-AGENTS.md dual-format machinery | collapse to AGENTS.md-only | companion-file logic is unrepresentable under §8's CLAUDE.md ban |
| "subagents cannot dispatch their own subagents" claims | emit `permission: { task: deny }` on that agent | makes the ported claim true (it's permission-gated in opencode, not structural) |
| `/rewind` / checkpoints UI | `/undo` / `/redo` | |
| docs *documenting* the upstream Claude-plugin format | keep as upstream reference + italic preamble; `${CLAUDE_PLUGIN_ROOT}` → `${PLUGIN_ROOT}` + note | applies to creating-a-plugin, maintaining-a-marketplace |
| source encoding artifacts (U+FFFD/U+FFFC, mangled box-drawing) | repair to intended glyphs | "may vary in wording, not meaning" covers this |
| source frontmatter `name` ≠ folder | folder name wins | §5b; has occurred upstream (e.g. `functional-core-imperative-shell`, `using-basic-agents`) |

If you encounter a Claude-ism not in either table, resolve it against the live
opencode tool/agent surface (§1) and **add a row here** before finishing.

---

## 8. Verification (must pass before commit)

Run over `configs/opencode/skills` and `configs/opencode/agents`:

1. **No leftover Claude-isms** — each of these must return zero hits:
   ```
   grep -rnE 'ed3d-[a-z-]+:' .                  # namespaced subagent_types
   grep -rnE 'subagent_type:\s*general-purpose\b' .   # bare general-purpose
   grep -rnE 'TaskCreate|TaskUpdate|TaskList|TaskRead' .
   grep -rnE 'run_in_background|model_override|job_block' .
   grep -rnE 'CLAUDE\.md|Claude Code|CLAUDE_PLUGIN_ROOT' .
   grep -rnE '~/\.claude/' .
   grep -rniE 'user-invocable' .
   grep -rnE 'AskUserQuestion|TodoWrite|addBlockedBy|@agent-|<invoke ' .
   grep -rnE '\.jsonl' .        # session transcripts must use opencode export
   ```
   (`ed3d-{opus,sonnet,haiku}-general-purpose` as subagent_type / filenames are
   legitimate and will not match the bare-token pattern above. Known sanctioned
   exceptions: upstream tool names inside the explicitly-framed
   "upstream Claude-plugin packaging format" reference sections of
   `creating-a-plugin` / `maintaining-a-marketplace`; and the aux template
   FILE `code-reviewer.md` inside `requesting-code-review` — an on-disk
   filename, not an agent reference.)
   Additionally: every generated agent file must be named `ed3d-*.md`, and
   every `subagent_type` emitted by an ed3d skill must be `ed3d-*` or a
   built-in — never a personal (`~/work/opencode/agents`) agent.
2. **name == folder** for every `SKILL.md`; `description` present; `slash`
   only where source had `user-invocable: true`.
3. **Every agent** has the `generated-by` marker, `description`,
   `mode: subagent`, and a `model` present in `opencode models`.
4. **Every emitted `subagent_type`** is in the §1.6 inventory or a built-in.
5. **Session-reflection smoke test (§5f):** run the rewritten
   `reduce-transcript.py` against a real `opencode export` of a non-active
   session; it must produce a sane reduction.
6. **Load test:** restart/start opencode and confirm no `ConfigInvalidError`,
   no duplicate-skill warnings, and expected counts of skills/agents.

---

## 9. Wiring (do once; verify each run)

- **Skill paths** — `configs/opencode/opencode.json` `skills.paths` must
  include `~/dotfiles/configs/opencode/skills` and `~/work/opencode/skills`.
- **Agents** — opencode has no agent-paths config. `programs/opencode.sh`
  builds `~/.config/opencode/agents/` as symlinks aggregated from
  `~/dotfiles/configs/opencode/agents` and `~/work/opencode/agents`. Re-run
  its agent-linking block after generating (or symlink new agents manually).
- **Claude Code emission is retired** — `programs/claude-code.sh` must NOT
  symlink skills/agents into `~/.claude/` anymore, and any stale
  `~/.claude/skills/*` / `~/.claude/agents/*` symlinks should be removed so
  opencode's external `~/.claude/skills` scan finds nothing (no double-load).
  `updaters/skills.sh` is retired in favor of this doc.
- After everything: **restart opencode** (skills/agents load once at startup).

---

## 10. Validate THESE instructions (self-check)

Before declaring done, dispatch a **fresh** subagent that has not seen your
analysis. Give it only this file + one untouched source skill dir, and ask it
to produce the opencode output. If it has to guess or gets a transform wrong,
this doc is missing context — fix the doc, not just the output. Repeat for one
agent file. This keeps the doc sufficient as the real source of truth.
