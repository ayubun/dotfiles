---
name: executing-parallel-issue-sweep
description: Use when the user asks to address multiple independent issues (bugs OR feature tickets) in parallel - dispatches one opus implementor per issue in the background, then drives each issue's review/fix/PR loop independently as completions land, so issues iterate at their own pace instead of waiting at phase boundaries. Not for single issues or for issues that should land as one PR.
user-invocable: false
---

# Executing a Parallel Issue Sweep

Run a coordinated sweep of several independent issues in one session.
Each issue gets its own worktree, branch, and opus-powered implementor
subagent. The orchestrator dispatches implementors in the background,
then drives each issue's review/fix/PR pipeline independently as
subagent completions arrive.

**Core principle:** Orchestrator-async pipeline. Subagents in this
Claude Code harness cannot dispatch their own subagents — the
dispatch tool is reserved for the top-level orchestrator. To get
true per-issue parallelism without nested dispatch, the orchestrator
uses `run_in_background: true` on every subagent it dispatches and
reacts to completion notifications, immediately advancing each
issue's pipeline as its current step finishes.

**Why this shape:** A naive wave-based design ("dispatch all
implementors, wait, dispatch all reviewers, wait, ...") forces issue
A's cycle 3 to wait for issue B's cycle 1 at every phase boundary.
Background dispatch + per-issue state tracking lets A and B advance at
their own paces.

**Required reading before applying this skill:**
- `using-git-worktrees` — worktree setup conventions
- `requesting-code-review` — the review-fix-rereview loop (the
  orchestrator runs this per-issue, not nested)
- `verification-before-completion` — gate semantics

## When to use

- User points at a backlog / project board / issue list and asks to
  "fix these" or "ship these" together.
- Items are mostly independent (different files / surfaces / subsystems).
- Each item is small-to-medium scope.
- Sweep size roughly 3–8 issues. Larger sweeps fill orchestrator context
  fast; checkpoint with the operator between batches.

## When NOT to use

- Single issue. Use `executing-an-implementation-plan` or just do the
  work.
- Items that should land as ONE PR (a coherent refactor sweep). That's
  one feature, not a sweep.
- Items with hard dependencies between them (A blocks B blocks C). Use
  sequential execution with a real implementation plan.
- Items where the right answer is "design first." Don't fanout to
  implementation when the design isn't pinned down.

## The architecture: orchestrator-async pipeline

```
Orchestrator
  │
  ├── dispatch task-issue-implementor #A   (background)
  ├── dispatch task-issue-implementor #B   (background)
  ├── dispatch task-issue-implementor #C   (background)
  │
  │   (completion of #A's implementor arrives)
  │
  ├── dispatch code-reviewer #A            (background)
  │   (completion of #B's implementor arrives)
  ├── dispatch code-reviewer #B            (background)
  │   (completion of #A's reviewer arrives — clean)
  ├── push #A; open draft PR #A
  │   (completion of #B's reviewer arrives — issues found)
  ├── dispatch task-bug-fixer #B           (background)
  │   (completion of #C's implementor arrives)
  ├── dispatch code-reviewer #C            (background)
  │   (completion of #B's bug-fixer arrives)
  ├── dispatch code-reviewer #B (cycle 2)  (background)
  └── ... and so on, until every issue is at "done"
```

Every dispatch is `run_in_background: true`. The orchestrator does NOT
poll or sleep — the harness notifies on completion. The orchestrator's
job between notifications is: track per-issue state, print the result
of the just-completed subagent (for operator transparency), and decide
what to dispatch next for that issue.

## Per-issue state machine

```
implementing → reviewing → done            (cycle 1 clean)
implementing → reviewing → fixing → reviewing → done   (cycle 2 clean)
implementing → reviewing → fixing → reviewing → fixing → reviewing → done   (cycle 3)
                                                            ↓
                                                       three-strike
                                                       escalation
```

Track state in `TaskCreate` / `TaskUpdate` per issue. One task per
issue, status field reflects current phase, metadata holds the latest
agent ID and BASE_SHA/HEAD_SHA so the next dispatch knows what to do.

**Three-strike rule:** If the same issues persist after three review
cycles on one issue, STOP that issue's pipeline and escalate to the
operator. Don't auto-dispatch cycle 4. Other issues continue.

## The process

### 1. Pre-flight — DO NOT FANOUT YET

#### 1a. Verify the input set

- If the user pointed at a label/tag (e.g. "all the bugs"), confirm
  that label actually exists. Don't infer.
- For each candidate, fetch the body / read the description. Don't
  trust the title alone.
- For each one, decide: in scope for this sweep? Some candidates will be:
  - Already fixed (verify against current state of the repo).
  - Too large / needs design.
  - Environmental (only reproduces on a setup the operator can't drive).
  - Duplicates of each other.

Use `AskUserQuestion` to lock the final set with the operator before
fanout.

#### 1b. Look for shared root causes

Two items with similar symptom wording often share a root cause.
Investigate the simplest one first and gate the related ones on its
outcome. Don't spawn implementors for issues that might be duplicates.

#### 1c. Identify shared-resource conflicts

Some work needs exclusive access to a resource: docker compose stack
with fixed container names, host ports, shared databases, the user's
running services. **If two items both need the same exclusive
resource, they cannot truly parallelize.** Either:
- Sequence them in waves (don't dispatch the second implementor until
  the first is done with the resource).
- Or instruct their implementor prompts to skip the conflicting
  verification step, and the orchestrator runs that verification
  serially at the end.

#### 1d. Confirm with the operator

Surface concretely:
- Final list of issues in scope
- Any items requiring operator-side verification (e.g. Safari testing
  on a Mac the cloud workstation can't drive)
- PR strategy (default: one draft PR per item)

Don't fanout until the operator confirms.

### 2. Worktree setup

One worktree per item. Convention:

```
.worktrees/<prefix>-<id>-<short-slug>/    # e.g. bug-251-write-outputs
branch: claude/<prefix>-<id>-<short-slug>
```

Create all worktrees in parallel (multiple Bash calls in one message).

### 3. Per-issue task tracking

Create one task per issue via `TaskCreate`. Metadata schema:

```
subject:   "Issue #N: <short title>"
status:    pending → in_progress (implementing) → in_progress (reviewing) → ...
metadata:
  issue_num: 251
  worktree:  /abs/path/.worktrees/bug-251-write-outputs
  branch:    claude/bug-251-write-outputs
  base_sha:  <sha at branch creation>
  phase:     implementing | reviewing | fixing | done | escalated
  cycle:     1..3
  agent_id:  <id of currently-running subagent for this issue>
  pending_findings: <reviewer output the bug-fixer needs>
```

Update on every state transition. After compaction, the task list is
the orchestrator's only memory of which issue is at which step.

### 4. Initial dispatch: implementors in background

For each issue, dispatch `ed3d-plan-and-execute:task-issue-implementor`
with `run_in_background: true`. **All dispatches in one message** so
they start concurrently.

Dispatch prompt template (per-issue context only — the agent's own
system prompt handles workflow defaults):

```
## Worktree
Operate in: <absolute worktree path>
Branch: <branch name>

## Issue
Issue: #<n> <title>
Repo: <owner/repo>

<full issue body / reproducer pasted inline>

## Verified root cause (if orchestrator pre-investigated)
<paste findings, OR omit so the agent investigates>

## Out of scope
- <files NOT to touch>
- <constraints>
- <project conventions worth surfacing: arrow-function style, no
  PR-context comments in code, etc.>

## Shared-resource note (if applicable)
Other issues in this sweep also need <resource>. Skip <verification
step>; the orchestrator will run it serially at the end.
```

Mark the task as `in_progress` with `metadata.phase = "implementing"`
and `metadata.agent_id = <id from dispatch return>`.

### 5. Drive the pipeline on completion

When a subagent completes, the harness notifies. Per the harness rules:
**do NOT sleep or poll** — react to notifications only.

For each completion notification:

1. Look up which issue/phase the completed agent belongs to (use
   `TaskList` + metadata).
2. **Print the agent's full response to the operator.** This is
   non-negotiable — without this the operator loses real-time
   visibility into their codebase.
3. Decide the next dispatch based on `phase`:

```
phase == "implementing"  →  dispatch code-reviewer (background)
                            update task: phase=reviewing, cycle=1

phase == "reviewing"  →
    if zero issues:
        push branch
        open draft PR (use smite-pr or repo equivalent)
        update task: phase=done
    elif cycle == 3:
        escalate (do not auto-dispatch cycle 4)
        update task: phase=escalated, surface to operator
    else:
        dispatch task-bug-fixer with findings (background)
        update task: phase=fixing, pending_findings=<verbatim>

phase == "fixing"  →  dispatch code-reviewer with PRIOR_ISSUES (background)
                      update task: phase=reviewing, cycle += 1
```

Each dispatch is `run_in_background: true`. Return to waiting.

### 6. Push and draft PR

When an issue reaches `phase=done`:
- `git push -u origin <branch>` (orchestrator runs, not subagent — the
  agent has bash, but the orchestrator owns the "this is ready" gate)
- Open a draft PR via the repo's PR-creation workflow. Look for a
  `smite-pr` skill or equivalent first; otherwise `gh pr create
  --draft`. The PR body should `Closes #<n>` so merge auto-closes the
  issue.

Title and body must be self-contained — the reader has no context
about the sweep.

### 7. Synthesis when all issues are done or escalated

Final summary to the operator:

```
| Issue | PR    | Cycles | Status     | Operator action          |
|-------|-------|--------|------------|--------------------------|
| #181  | #288  | 1      | done       | none                     |
| #144  | #289  | 2      | done       | spot-check in Safari     |
| #251  | #290  | 3      | done       | none                     |
| #158  | #291  | 3      | done       | none                     |
| #213  | —     | —      | escalated  | need decision on scope   |
```

## Why nested dispatch was abandoned

An earlier draft of this skill had each issue-owner subagent dispatch
its own code-reviewer + bug-fixer subagents. Empirical testing
confirmed that subagents in this Claude Code harness do NOT have
access to the `Task` / `Agent` dispatch tool — the tool is reserved
for the top-level orchestrator, presumably to keep the context tree
shallow and bounded.

The orchestrator-async pipeline is the workaround. It achieves
per-issue independence (the goal of the nested design) without
requiring nested dispatch (which doesn't exist).

Side benefit: the orchestrator sees every subagent's full output as
it lands, so the human-transparency rule is preserved in real time
rather than reconstructed from a final cycle log.

## Common rationalizations and what they really mean

| Rationalization | Reality |
|---|---|
| "I'll dispatch all implementors, wait for ALL, then all reviewers" | That's wave-based. Slowest implementor gates the whole sweep. Use background dispatch + completion-driven advancement instead. |
| "I'll poll the agent IDs every 30 seconds to check status" | No. The harness notifies on completion. Polling burns context and breaks the cache-warm window. |
| "I'll skip the per-issue task tracking for small sweeps" | After 4+ in-flight issues you will lose track. The task list is the orchestrator's memory. |
| "I'll fix the issues myself instead of dispatching the bug-fixer" | The bug-fixer is fresh-context. You have orchestrator-context contamination. Dispatch it. |
| "I'll just print a summary of the agent's output to save context" | Operator transparency requires verbatim. Summarize at the END, not mid-flight. |
| "Three-strike fired but I think I see the fix — let me try cycle 4" | No. Three-strike is the architecture-question signal. Escalate. |

## Anti-patterns

| Anti-pattern | Why it bites |
|---|---|
| Foreground dispatch of implementors (no background) | Loses parallelism; you can only have one implementor running at a time |
| Polling for agent status | Wastes context; harness already notifies on completion |
| Summarizing subagent output instead of printing verbatim | Operator loses visibility; can't catch missed issues |
| Skipping per-issue TaskCreate | After 5+ in-flight issues, you forget which is at which phase |
| Auto-pushing non-draft PRs | Removes the operator's merge gate |
| Same-resource parallelism without coordination | Container-name collisions break verification |
| Fixing review issues yourself instead of dispatching bug-fixer | Mixes orchestrator concerns with fix concerns; loses fresh-context advantage |

## Quick reference

| Phase | Who does the work | Tool |
|---|---|---|
| 1. Pre-flight (scope, conflicts, confirm) | Orchestrator | AskUserQuestion |
| 2. Worktrees | Orchestrator | Bash (parallel) |
| 3. Task tracking | Orchestrator | TaskCreate, TaskUpdate |
| 4. Initial implementor dispatch | Orchestrator (`run_in_background`) | Agent → task-issue-implementor (opus) |
| 5a. Implementor completion → reviewer | Orchestrator (`run_in_background`) | Agent → code-reviewer |
| 5b. Reviewer completion → bug-fixer | Orchestrator (`run_in_background`) | Agent → task-bug-fixer |
| 5c. Reviewer completion (clean) → push + PR | Orchestrator | Bash + smite-pr (or gh pr create) |
| 6. Synthesis | Orchestrator | (text output) |

## When this fails

If the orchestrator's context fills before the sweep finishes — typically
on sweeps larger than ~6 issues with 2+ cycles each — checkpoint with
the operator. The task list + the PR list (for already-completed issues)
is enough state to resume in a fresh session.

If specific issues escalate via three-strike, surface them prominently
in the final report. Don't bury the escalations beneath the successes.

If an implementor returns "I couldn't reproduce the bug" — that's not a
failure of the workflow; it's a real signal that the bug may already be
fixed, the reproducer is wrong, or the operator needs to clarify scope.
Surface and ask, don't ship a no-op PR.
