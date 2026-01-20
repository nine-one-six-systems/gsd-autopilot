<purpose>
Execute GSD in a continuous autonomous loop until milestone complete.

Inspired by the Ralph Wiggum Loop pattern: each iteration gets fresh context, progress accumulates on disk (STATE.md, SUMMARY.md files), and the loop continues until verifiable completion or an escape condition.

"The technique is deterministically bad in an undeterministic world. It's better to fail predictably than succeed unpredictably." — Geoffrey Huntley
</purpose>

<core_principle>
**Persistence + self-correction beats single-shot perfection.**

Each iteration:
1. Reads STATE.md to know current position
2. Determines what action is needed
3. Executes that action (plan/execute/transition)
4. Updates iteration tracking
5. Loops back until done or blocked

Progress accumulates in files. Failures get thrown away. Fresh context per major action.
</core_principle>

<process>

<step name="parse_arguments">
Parse command arguments and read config:

```bash
# Read defaults from config.json
MAX_ITERATIONS=$(cat .planning/config.json 2>/dev/null | grep -o '"max_iterations"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' || echo "50")
COST_LIMIT=$(cat .planning/config.json 2>/dev/null | grep -o '"cost_limit"[[:space:]]*:[[:space:]]*[0-9.]*\|null' | grep -o '[0-9.]*\|null' | head -1 || echo "null")
AUTO_CONTINUE=$(cat .planning/config.json 2>/dev/null | grep -o '"auto_continue"[[:space:]]*:[[:space:]]*[^,}]*' | grep -o 'true\|false' || echo "true")
UNATTENDED=$(cat .planning/config.json 2>/dev/null | grep -o '"unattended"[[:space:]]*:[[:space:]]*[^,}]*' | grep -o 'true\|false' || echo "false")
PHASE_ONLY=false
GOAL_FILE=""

# Parse command-line arguments (override config)
for arg in "$@"; do
  case $arg in
    --max-iterations=*)
      MAX_ITERATIONS="${arg#*=}"
      ;;
    --max-iterations)
      shift
      MAX_ITERATIONS="$1"
      ;;
    --phase-only)
      PHASE_ONLY=true
      AUTO_CONTINUE=false
      ;;
    --unattended)
      UNATTENDED=true
      ;;
    --goal=*)
      GOAL_FILE="${arg#*=}"
      ;;
  esac
done

# Convert cost_limit to number if not null
if [ "$COST_LIMIT" = "null" ] || [ -z "$COST_LIMIT" ]; then
  COST_LIMIT=""
fi
```

**Arguments:**
- `--max-iterations N` — Stop after N iterations (default: from config or 50)
- `--phase-only` — Stop after current phase completes (overrides auto_continue)
- `--unattended` — Auto-approve human verification prompts (no manual UAT)
- `--goal=FILE` — Read additional success criteria from file (optional)

**Config options:**
- `autopilot.max_iterations` — Default max iterations (default: 50)
- `autopilot.cost_limit` — Maximum cost in USD (null = no limit)
- `autopilot.auto_continue` — Auto-transition to next phase (default: true)
- `autopilot.unattended` — Auto-approve human verification prompts (default: false)

Store values for use throughout workflow.
</step>

<step name="verify_project">
Verify GSD project exists:

```bash
if [ ! -f .planning/STATE.md ]; then
  echo "No GSD project found. Run /gsd:new-project first."
  exit 1
fi

if [ ! -f .planning/ROADMAP.md ]; then
  echo "No ROADMAP.md found. Project may be between milestones."
  echo "Run /gsd:new-milestone to start a new milestone."
  exit 1
fi
```

If verification fails, exit with clear message.
</step>

<step name="initialize_tracking">
Initialize or read iteration tracking from STATE.md:

```bash
# Check for existing autopilot section
if grep -q "## Autopilot Status" .planning/STATE.md; then
  # Read existing iteration count
  CURRENT_ITERATION=$(grep "Iteration:" .planning/STATE.md | grep -oE '[0-9]+' | head -1)
  LAST_POSITION=$(grep "Last position:" .planning/STATE.md | cut -d: -f2- | xargs)
  STUCK_COUNT=$(grep "Stuck count:" .planning/STATE.md | grep -oE '[0-9]+' | head -1 || echo 0)
else
  # Initialize tracking
  CURRENT_ITERATION=0
  LAST_POSITION=""
  STUCK_COUNT=0
fi
```

**Tracking fields:**
- `Iteration` — Current loop count
- `Last position` — Previous phase/plan position (for stuck detection)
- `Stuck count` — Consecutive iterations at same position
- `Started` — When autopilot began
- `Max iterations` — Configured limit
</step>

<step name="check_escape_conditions">
Before each iteration, check escape conditions:

**1. Check for BLOCKED sentinel:**

```bash
if grep -q "^BLOCKED:" .planning/STATE.md; then
  BLOCK_REASON=$(grep "^BLOCKED:" .planning/STATE.md | cut -d: -f2-)
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  AUTOPILOT STOPPED — BLOCKED                         ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  echo "Reason: $BLOCK_REASON"
  echo ""
  echo "To resume: Remove 'BLOCKED:' line from STATE.md and run /gsd:autopilot"
  exit 1
fi
```

**2. Check iteration limit:**

```bash
if [ "$CURRENT_ITERATION" -ge "$MAX_ITERATIONS" ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  AUTOPILOT STOPPED — MAX ITERATIONS                  ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  echo "Completed $CURRENT_ITERATION iterations without finishing milestone."
  echo "Increase limit with: /gsd:autopilot --max-iterations=100"
  echo "Or update config.json: autopilot.max_iterations"
  exit 1
fi
```

**3. Check cost limit (if configured):**

```bash
if [ -n "$COST_LIMIT" ] && [ "$COST_LIMIT" != "null" ]; then
  # TODO: Implement cost tracking
  # CURRENT_COST=$(calculate_cost_from_iterations)
  # if [ "$(echo "$CURRENT_COST >= $COST_LIMIT" | bc)" -eq 1 ]; then
  #   echo "Cost limit reached: $CURRENT_COST >= $COST_LIMIT"
  #   exit 1
  # fi
  # For now, cost_limit is a placeholder for future implementation
fi
```

**4. Check stuck detection:**

```bash
CURRENT_POSITION=$(grep "^Phase:" .planning/STATE.md | head -1)
CURRENT_POSITION="$CURRENT_POSITION | $(grep "^Plan:" .planning/STATE.md | head -1)"

if [ "$CURRENT_POSITION" = "$LAST_POSITION" ]; then
  STUCK_COUNT=$((STUCK_COUNT + 1))
  if [ "$STUCK_COUNT" -ge 3 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  AUTOPILOT STOPPED — STUCK                           ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "Position unchanged for $STUCK_COUNT iterations:"
    echo "$CURRENT_POSITION"
    echo ""
    echo "Possible causes:"
    echo "- Plan execution failing repeatedly"
    echo "- Verification blocking progress"
    echo "- Missing dependencies"
    echo ""
    echo "Review STATE.md and recent SUMMARY.md files for issues."
    exit 1
  fi
else
  STUCK_COUNT=0
fi
```

If any escape condition triggers, exit with informative message.
</step>

<step name="determine_action">
Read STATE.md and ROADMAP.md to determine what action is needed:

```bash
# Read current state
cat .planning/STATE.md
cat .planning/ROADMAP.md
```

**Parse current position:**

From STATE.md, extract:
- Current phase number (X of Y)
- Current plan number (A of B)
- Status (Ready to plan / In progress / Phase complete / etc.)

**Determine action based on state:**

| State | Action |
|-------|--------|
| No plans exist for phase | PLAN |
| Plans exist, not all executed | EXECUTE |
| All plans executed, verification needed | VERIFY |
| Phase complete, more phases remain | TRANSITION |
| All phases complete | COMPLETE_MILESTONE |

**Route logic:**

```bash
# Get current phase directory
PHASE_NUM=$(grep "^Phase:" .planning/STATE.md | grep -oE '[0-9]+' | head -1)
PADDED_PHASE=$(printf "%02d" $PHASE_NUM)
PHASE_DIR=$(ls -d .planning/phases/${PADDED_PHASE}-* .planning/phases/${PHASE_NUM}-* 2>/dev/null | head -1)

# Count plans and summaries
PLAN_COUNT=$(ls -1 "$PHASE_DIR"/*-PLAN.md 2>/dev/null | wc -l | tr -d ' ')
SUMMARY_COUNT=$(ls -1 "$PHASE_DIR"/*-SUMMARY.md 2>/dev/null | wc -l | tr -d ' ')
VERIFICATION_EXISTS=$(ls -1 "$PHASE_DIR"/*-VERIFICATION.md 2>/dev/null | wc -l | tr -d ' ')

if [ "$PLAN_COUNT" -eq 0 ]; then
  ACTION="PLAN"
elif [ "$SUMMARY_COUNT" -lt "$PLAN_COUNT" ]; then
  ACTION="EXECUTE"
elif [ "$VERIFICATION_EXISTS" -eq 0 ]; then
  ACTION="VERIFY"
else
  # Check if more phases remain
  TOTAL_PHASES=$(grep -c "^### Phase\|^- \[.\] \*\*Phase" .planning/ROADMAP.md || echo 0)
  if [ "$PHASE_NUM" -lt "$TOTAL_PHASES" ]; then
    ACTION="TRANSITION"
  else
    ACTION="COMPLETE_MILESTONE"
  fi
fi
```

Store `$ACTION` for execution step.
</step>

<step name="execute_action">
Execute the determined action with forced YOLO mode.

**Before executing:** Increment iteration and update tracking in STATE.md.

```bash
CURRENT_ITERATION=$((CURRENT_ITERATION + 1))
```

Update STATE.md autopilot section:

```markdown
## Autopilot Status

Mode: Active
Iteration: {CURRENT_ITERATION} of {MAX_ITERATIONS}
Started: {timestamp if iteration 1}
Last position: {CURRENT_POSITION}
Stuck count: {STUCK_COUNT}
Current action: {ACTION}
Unattended: {UNATTENDED}
```

**If `UNATTENDED=true`:** Human verification prompts will be auto-approved. The execute-phase workflow checks for this marker and skips UAT prompts.

**Execute based on action:**

**ACTION = PLAN:**

```
echo "═══════════════════════════════════════════════════════"
echo "  Iteration $CURRENT_ITERATION: Planning Phase $PHASE_NUM"
echo "═══════════════════════════════════════════════════════"
```

Invoke plan-phase workflow with forced YOLO:
- Read `.planning/config.json`
- Temporarily override mode to "yolo" if not already
- Execute planning subagents
- Plans are created in phase directory

After completion, loop back to determine_action.

**ACTION = EXECUTE:**

```
echo "═══════════════════════════════════════════════════════"
echo "  Iteration $CURRENT_ITERATION: Executing Phase $PHASE_NUM"
echo "═══════════════════════════════════════════════════════"
```

Invoke execute-phase workflow:
- Forces YOLO mode internally
- Subagents get fresh 200k context
- Each plan executed, SUMMARY.md created
- Verification runs after completion

After completion, loop back to determine_action.

**ACTION = VERIFY:**

```
echo "═══════════════════════════════════════════════════════"
echo "  Iteration $CURRENT_ITERATION: Verifying Phase $PHASE_NUM"
echo "═══════════════════════════════════════════════════════"
```

Phase was executed but verification is missing. Re-run verification:
- Spawn gsd-verifier
- Create VERIFICATION.md
- If gaps found, next iteration will need gap planning

**ACTION = TRANSITION:**

Check `--phase-only` flag or `auto_continue` config:

```bash
if [ "$PHASE_ONLY" = "true" ] || [ "$AUTO_CONTINUE" = "false" ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  AUTOPILOT STOPPED — PHASE COMPLETE                  ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  echo "Phase $PHASE_NUM complete. --phase-only flag set."
  echo "Run /gsd:autopilot to continue to next phase."
  exit 0
fi
```

If not phase-only, transition to next phase:

```
echo "═══════════════════════════════════════════════════════"
echo "  Iteration $CURRENT_ITERATION: Transitioning to Phase $((PHASE_NUM + 1))"
echo "═══════════════════════════════════════════════════════"
```

- Mark current phase complete in ROADMAP.md
- Update STATE.md position to next phase
- Loop back to determine_action (will route to PLAN for new phase)

**ACTION = COMPLETE_MILESTONE:**

```
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  🎉 AUTOPILOT COMPLETE — MILESTONE FINISHED          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "All phases complete after $CURRENT_ITERATION iterations."
echo ""
echo "Next steps:"
echo "  /gsd:complete-milestone — Archive and tag release"
echo "  /gsd:new-milestone — Start next milestone"
```

Clear autopilot tracking from STATE.md and exit successfully.
</step>

<step name="loop_continuation">
After each action completes, continue the loop:

```
# Update last position for stuck detection
LAST_POSITION="$CURRENT_POSITION"

# Brief pause to prevent runaway (optional, can be removed)
sleep 2

# Loop back to check_escape_conditions
```

The loop continues until an escape condition is met:
- Milestone complete (success)
- BLOCKED sentinel found
- Max iterations reached
- Stuck detection triggered
- Critical error during execution
</step>

</process>

<state_tracking>
**Autopilot tracking in STATE.md:**

Autopilot adds a section to STATE.md to track loop state:

```markdown
## Autopilot Status

Mode: Active
Iteration: 7 of 50
Started: 2025-01-20T10:30:00Z
Last position: Phase: 3 of 5 | Plan: 2 of 3
Stuck count: 0
Current action: EXECUTE
Unattended: true
```

**When autopilot completes or is stopped:**

```markdown
## Autopilot Status

Mode: Inactive
Last run: 2025-01-20T14:45:00Z
Result: Milestone complete (12 iterations)
```

This enables:
- Resuming autopilot after context reset
- Debugging why autopilot stopped
- Tracking iteration history
- Execute-phase can check `Unattended:` to auto-approve UAT
</state_tracking>

<escape_valves>
**Manual escape:**

Add `BLOCKED: reason` to STATE.md to stop autopilot:

```markdown
BLOCKED: Need API credentials before continuing
```

Autopilot checks for this sentinel at the start of each iteration.

**Automatic escapes:**

1. **Max iterations** — Prevents runaway cost
2. **Stuck detection** — Same position for 3+ iterations
3. **Milestone complete** — Natural successful exit
4. **Missing project** — Can't find STATE.md or ROADMAP.md

**Cost awareness:**

Each iteration may spawn multiple subagents. Monitor API usage:
- Quick phases: 2-3 iterations (plan + execute + verify)
- Complex phases: 5-10 iterations (research + multiple plans + fixes)
- Typical milestone: 20-40 iterations
</escape_valves>

<success_criteria>
Autopilot succeeds when:
- [ ] All phases in milestone complete
- [ ] All verifications pass
- [ ] COMPLETE_MILESTONE action reached
- [ ] Clean exit with success message

Autopilot stops (not failure) when:
- [ ] BLOCKED sentinel found
- [ ] Max iterations reached
- [ ] Stuck detection triggered
- [ ] --phase-only flag and phase complete
</success_criteria>

<integration_with_ralph>
**Using autopilot with external loop (full Ralph mode):**

For even more autonomy, wrap autopilot in a bash loop:

```bash
#!/bin/bash
# ralph-gsd.sh - External loop with fresh Claude context per milestone

while :; do
  echo "Starting GSD autopilot..."
  echo "/gsd:autopilot --max-iterations=30" | claude --dangerously-skip-permissions
  
  # Check if milestone complete
  if grep -q "Result: Milestone complete" .planning/STATE.md; then
    echo "Milestone complete!"
    
    # Optionally start next milestone automatically
    # echo "/gsd:new-milestone" | claude --dangerously-skip-permissions
    break
  fi
  
  # Check for blocked state
  if grep -q "^BLOCKED:" .planning/STATE.md; then
    echo "Blocked - human intervention needed"
    break
  fi
  
  sleep 10
done
```

This gives you:
- Fresh Claude context per autopilot run
- Survives context window limits
- Multiple milestones in sequence
- True "set and forget" operation
</integration_with_ralph>
