---
name: gsd:autopilot
description: Run GSD in continuous loop mode until milestone complete (Ralph Wiggum style)
argument-hint: "[--max-iterations N] [--phase-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - SlashCommand
---

<objective>
Execute GSD in a continuous loop until the current milestone is complete or an escape condition is hit.

Inspired by the Ralph Wiggum Loop: each iteration gets fresh context, progress accumulates in files, and the loop continues until verifiable completion.

**Key behaviors:**
- Forces YOLO mode internally (no confirmation prompts)
- Tracks iteration count in STATE.md
- Detects stuck loops (same position for N iterations)
- Supports BLOCKED sentinel for manual escape
- Fresh subagent context per phase execution
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/autopilot.md
</execution_context>

<process>
**Follow the autopilot workflow** from `@~/.claude/get-shit-done/workflows/autopilot.md`.

The workflow handles all loop logic including:

1. Argument parsing (--max-iterations, --phase-only)
2. STATE.md position detection
3. Route to appropriate action (plan/execute/transition)
4. Execute action with forced YOLO mode
5. Update iteration tracking
6. Loop back or exit based on conditions

**Escape conditions:**
- Milestone complete
- Max iterations reached
- BLOCKED sentinel in STATE.md
- Stuck detection (same position for 3+ iterations)
- Critical error during execution
</process>
