---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements - dispatches ed3d-code-reviewer subagent, handles retries and timeouts, manages review-fix loop until zero issues
---

# Requesting Code Review

Dispatch ed3d-code-reviewer subagent to catch issues before they cascade.

**Core principle:** Review early, review often. Fix ALL issues before proceeding.

## Session Isolation

**If the calling context provides a SCRATCHPAD_DIR, pass it to ed3d-code-reviewer.**

This prevents collisions when multiple planning/execution sessions run in parallel. The SCRATCHPAD_DIR is a namespaced temp directory (e.g., `/tmp/plan-2025-01-24-feature-a7f3b2/`) that the ed3d-code-reviewer uses for any scratch files.

## Caller is always the top-level orchestrator

This skill is always invoked from the top-level orchestrator session,
never from inside a subagent. Subagents in opencode cannot dispatch
their own subagents — the `task` tool is reserved for the
orchestrator. Both `executing-an-implementation-plan` (single feature)
and `executing-parallel-issue-sweep` (multi-issue) call this skill from
the orchestrator level; the multi-issue case just runs the loop per
issue concurrently — parallel `task` dispatches batched into one
message, advanced by completion notifications.

## When to Request Review

**Mandatory:**
- After each task in plan execution
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## The Review Loop

The review process is a loop: review → fix → re-review → until zero issues.

```
┌──────────────────────────────────────────────────┐
│                                                  │
│   Dispatch ed3d-code-reviewer                         │
│         │                                        │
│         ▼                                        │
│   Issues found? ──No──► Done (proceed)           │
│         │                                        │
│        Yes                                       │
│         │                                        │
│         ▼                                        │
│   Dispatch bug-fixer                             │
│         │                                        │
│         ▼                                        │
│   Re-review with prior issues ◄──────────────────┘
│
└──────────────────────────────────────────────────┘
```

**Exit condition:** Zero issues, or issues accepted per your workflow's policy.

## Step 1: Initial Review

**Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or commit before task
HEAD_SHA=$(git rev-parse HEAD)
```

**Dispatch ed3d-code-reviewer subagent:**

```
task:
  subagent_type: ed3d-code-reviewer
  description: Reviewing [what was implemented]
  prompt: |
    Use the template at [absolute path to code-reviewer.md — shipped with
    this skill; its absolute path is shown in the file list when this
    skill loads]

    WHAT_WAS_IMPLEMENTED: [summary of implementation]
    PLAN_OR_REQUIREMENTS: [task/requirements reference]
    BASE_SHA: [commit before work]
    HEAD_SHA: [current commit]
    DESCRIPTION: [brief summary]
    SCRATCHPAD_DIR: [session-isolated temp dir, or omit if not applicable]
```

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

## Step 2: Handle Reviewer Response

### If Zero Issues
All categories empty → proceed to next task.

### If Any Issues Found
Regardless of category (Critical, Important, or Minor), dispatch bug-fixer:

```
task:
  subagent_type: ed3d-task-bug-fixer
  description: Fixing review issues
  prompt: |
    Fix issues from code review.

    Code reviewer found these issues:
    [list all issues - Critical, Important, and Minor]

    Your job is to:
    1. Understand root cause of each issue
    2. Apply fixes systematically (Critical → Important → Minor)
    3. Verify with tests/build/lint
    4. Commit your fixes
    5. Report back with evidence

    Work from: [directory]

    Fix ALL issues — including every Minor issue. The goal is ZERO issues on re-review.
    Minor issues are not optional. Do not skip them.
```

After fixes, proceed to Step 3.

## Step 3: Re-Review After Fixes

**CRITICAL:** Track prior issues across review cycles.

```
task:
  subagent_type: ed3d-code-reviewer
  description: Re-reviewing after fixes (cycle N)
  prompt: |
    Use the template at [absolute path to code-reviewer.md — shipped with
    this skill; its absolute path is shown in the file list when this
    skill loads]

    WHAT_WAS_IMPLEMENTED: [from bug-fixer's report]
    PLAN_OR_REQUIREMENTS: [original task/requirements]
    BASE_SHA: [commit before this fix cycle]
    HEAD_SHA: [current commit after fixes]
    DESCRIPTION: Re-review after bug fixes (review cycle N)
    SCRATCHPAD_DIR: [session-isolated temp dir, or omit if not applicable]

    PRIOR_ISSUES_TO_VERIFY_FIXED:
    [list all outstanding issues from previous reviews]

    Verify:
    1. Each prior issue listed above is actually resolved
    2. No regressions introduced by the fixes
    3. Any new issues in the changed code

    Report which prior issues are now fixed and which (if any) remain.
```

**Tracking prior issues:**
- When re-reviewer explicitly confirms fixed → remove from list
- When re-reviewer doesn't mention an issue → keep on list (silence ≠ fixed)
- When re-reviewer finds new issues → add to list

Loop back to Step 2 if any issues remain.

## Handling Failures

### Operational Errors
If reviewer reports operational errors (can't run tests, missing scripts):
1. **STOP** - do not continue
2. Report to human
3. When told to continue, re-execute same review

### Timeouts / Empty Response
Usually means context limits. Retry with focused scope:

**First retry:** Narrow to changed files only:
```
FOCUSED REVIEW - Context was too large.

Review ONLY the diff between BASE_SHA and HEAD_SHA.
Focus on: [list only files actually modified]

Skip: broad architectural analysis, unchanged files, tangential concerns.

WHAT_WAS_IMPLEMENTED: [summary]
PLAN_OR_REQUIREMENTS: [reference]
BASE_SHA: [sha]
HEAD_SHA: [sha]
```

**Second retry:** Split into multiple smaller reviews (one per file or logical group).

**Third failure:** Stop and ask human for help.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Zero issues | Proceed |
| Any issues | Fix, re-review (or accept per workflow) |
| Operational error | Stop, report, wait |
| Timeout | Retry with focused scope |
| 3 failed retries | Ask human |

## Red Flags

**Never:**
- Skip review because "it's simple"
- Proceed with ANY unfixed issues (Critical, Important, OR Minor)
- Argue with valid technical feedback without evidence
- Rationalize skipping Minor issues ("they're just style", "we can fix later")

**Minor issues are NOT optional.** The code reviewer flagged them for a reason. Fix all of them. "Minor" means lower severity, not "ignorable."

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification on unclear feedback

## Integration

**Called by:**
- executing-an-implementation-plan (after each task)
- finishing-a-development-branch (final review)
- Ad-hoc when you need a review

**Template location:** `code-reviewer.md` (shipped with this skill; its absolute path is shown in the file list when this skill loads)
