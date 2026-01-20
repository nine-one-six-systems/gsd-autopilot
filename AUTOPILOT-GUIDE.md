# GSD Autopilot Guide

Complete guide to installing and using GSD Autopilot with the `--unattended` flag for fully autonomous milestone execution.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Using Autopilot](#using-autopilot)
- [Configuration](#configuration)
- [What Gets Auto-Approved](#what-gets-auto-approved)
- [Updating Your Fork](#updating-your-fork)
- [Troubleshooting](#troubleshooting)
- [Example Workflows](#example-workflows)

---

## Installation

### Step 1: Clone and Build

On any machine where you want to use GSD with autopilot:

```bash
# Clone your fork
git clone https://github.com/nine-one-six-systems/gsd-autopilot.git
cd gsd-autopilot

# Install dependencies
npm install

# Build the hooks (required!)
npm run build:hooks
```

### Step 2: Install to Your Project

**Option A: Global Installation** (available in all projects)
```bash
node bin/install.js --global
```

**Option B: Local Installation** (specific project only)
```bash
cd /path/to/your/project
node /path/to/gsd-autopilot/bin/install.js --local
```

### Step 3: Initialize GSD in Your Project

```bash
cd /path/to/your/project

# Start a new GSD project
/gsd:new-project

# Or if you already have a project, just verify it exists
ls .planning/STATE.md
```

---

## Quick Start

**Run autopilot with auto-approval:**
```bash
/gsd:autopilot --unattended
```

This will:
- Run continuously until milestone complete
- Auto-approve all human verification prompts
- Skip UAT prompts (like "Did you get a chance to see the badges...")
- Log auto-approvals to VERIFICATION.md for review later

---

## Using Autopilot

### One-Time Autonomous Run

```bash
/gsd:autopilot --unattended
```

This will:
- Run continuously until milestone complete
- Auto-approve all human verification prompts
- Skip UAT prompts (like "Did you get a chance to see the badges...")
- Log auto-approvals to VERIFICATION.md for review later

### Always Autonomous (Set in Config)

Edit `.planning/config.json` in your project:

```json
{
  "autopilot": {
    "unattended": true,
    "max_iterations": 50,
    "auto_continue": true
  }
}
```

Then just run:
```bash
/gsd:autopilot
```

### Other Useful Flags

```bash
# Stop after current phase (useful for testing)
/gsd:autopilot --phase-only --unattended

# Limit iterations (safety net)
/gsd:autopilot --max-iterations=30 --unattended

# Combine flags
/gsd:autopilot --max-iterations=100 --unattended --phase-only
```

---

## Configuration

### Config File Location

`.planning/config.json` in your project root.

### Available Options

```json
{
  "autopilot": {
    "unattended": false,        // Auto-approve UAT prompts (default: false)
    "max_iterations": 50,        // Maximum iterations before stopping (default: 50)
    "cost_limit": null,          // Maximum cost in USD (null = no limit)
    "auto_continue": true        // Auto-transition to next phase (default: true)
  }
}
```

### Option Details

| Option | Default | Description |
|--------|---------|-------------|
| `unattended` | `false` | Auto-approve human verification prompts (true = fully autonomous) |
| `max_iterations` | `50` | Maximum iterations before autopilot stops |
| `cost_limit` | `null` | Maximum cost in USD (null = no limit) |
| `auto_continue` | `true` | Automatically continue to next phase (false = stop at phase boundaries) |

### Flag Overrides

Command-line flags override config values:

- `--unattended` → Sets `unattended: true` for this run
- `--max-iterations N` → Overrides `max_iterations` for this run
- `--phase-only` → Sets `auto_continue: false` for this run

---

## What Gets Auto-Approved

When `--unattended` is active, these prompts are auto-approved:

- "Did you get a chance to see the badges..."
- "Type 'approved' if the feature is working correctly"
- Any human verification checklist items from verification
- UAT (User Acceptance Testing) prompts

**Important:** Auto-approvals are logged to `VERIFICATION.md` with timestamps, so you can review what was skipped later.

### Audit Trail

All auto-approvals are recorded in the phase's `VERIFICATION.md` file:

```markdown
## Human Verification Auto-Approved

⚠️ **UNATTENDED MODE** — Human verification items were auto-approved.

3 items would normally require human testing:

1. Visual appearance check
2. User flow completion
3. Real-time behavior verification

**Auto-approved at:** 2025-01-20T14:30:00Z
**Reason:** Autopilot running with --unattended flag
```

---

## Updating Your Fork

When you want to pull updates from your fork:

```bash
cd /path/to/gsd-autopilot
git pull fork main
npm install
npm run build:hooks
node bin/install.js --global  # or --local for specific project
```

### Syncing with Upstream

To merge changes from the original repository:

```bash
cd /path/to/gsd-autopilot

# Fetch upstream changes
git fetch origin

# Merge upstream main into your fork
git merge origin/main

# Resolve any conflicts if needed, then push
git push fork main
```

---

## Troubleshooting

### Hooks Not Found

**Symptoms:** Error messages about missing hook files or `require is not defined`.

**Solution:**
```bash
# Rebuild and reinstall
cd /path/to/gsd-autopilot
npm run build:hooks
node bin/install.js --local /path/to/your/project
```

### Still Getting UAT Prompts

**Symptoms:** Autopilot still pauses for human verification.

**Checklist:**
1. Verify the flag was passed: `/gsd:autopilot --unattended`
2. Check that `Unattended: true` appears in `.planning/STATE.md` during autopilot
3. Verify config: `cat .planning/config.json | grep unattended`
4. Ensure you're using the latest version (rebuild hooks if needed)

**Debug:**
```bash
# Check autopilot status
grep "Unattended:" .planning/STATE.md

# Check config
cat .planning/config.json

# Verify hooks are installed
ls ~/.claude/hooks/gsd-*.cjs
```

### Autopilot Stops Unexpectedly

**Common causes:**
- Max iterations reached → Increase `max_iterations` or use `--max-iterations=N`
- Stuck detection triggered → Check STATE.md for stuck position
- BLOCKED sentinel found → Remove `BLOCKED:` line from STATE.md
- Phase-only flag → Remove `--phase-only` or set `auto_continue: true`

**Check status:**
```bash
# View autopilot status
cat .planning/STATE.md | grep -A 10 "Autopilot Status"

# Check for blockers
grep "^BLOCKED:" .planning/STATE.md
```

---

## Example Workflows

### Full Autonomous Workflow

```bash
# 1. Initialize project (if new)
cd /path/to/your/project
/gsd:new-project

# 2. Create milestone
/gsd:new-milestone

# 3. Run autopilot fully autonomous
/gsd:autopilot --unattended

# 4. Review what happened
cat .planning/phases/*/VERIFICATION.md  # See auto-approvals
cat .planning/STATE.md  # See autopilot status
```

### Testing a Single Phase

```bash
# Run autopilot for current phase only
/gsd:autopilot --phase-only --unattended

# Review phase completion
cat .planning/phases/*/VERIFICATION.md
```

### Production Setup (Always Autonomous)

1. **Set config:**
```json
// .planning/config.json
{
  "autopilot": {
    "unattended": true,
    "max_iterations": 100,
    "auto_continue": true
  }
}
```

2. **Run autopilot:**
```bash
/gsd:autopilot
```

3. **Monitor progress:**
```bash
# Watch STATE.md for updates
watch -n 5 'cat .planning/STATE.md | grep -A 5 "Autopilot Status"'
```

### Resuming After Interruption

If autopilot stops (context limit, error, etc.):

```bash
# Check current status
cat .planning/STATE.md

# Resume from where it left off
/gsd:autopilot --unattended
```

Autopilot automatically detects completed work and continues from the next step.

---

## Advanced Usage

### External Loop (Full Ralph Mode)

For maximum autonomy across multiple milestones, wrap autopilot in a bash loop:

```bash
#!/bin/bash
# ralph-gsd.sh - External loop with fresh Claude context per milestone

while :; do
  echo "Starting GSD autopilot..."
  echo "/gsd:autopilot --unattended --max-iterations=30" | claude
  
  # Check if milestone complete
  if grep -q "Result: Milestone complete" .planning/STATE.md; then
    echo "Milestone complete!"
    
    # Optionally start next milestone automatically
    # echo "/gsd:new-milestone" | claude
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

### Cost Monitoring

While cost tracking isn't fully implemented yet, you can monitor iterations:

```bash
# Count iterations completed
grep "Iteration:" .planning/STATE.md | tail -1

# Estimate: ~2-3 iterations per simple phase, 5-10 per complex phase
```

---

## Safety Features

### Escape Conditions

Autopilot stops automatically when:

1. **Milestone complete** → Success! All phases done.
2. **Max iterations reached** → Prevents runaway loops
3. **BLOCKED sentinel** → Manual escape (`BLOCKED: reason` in STATE.md)
4. **Stuck detection** → Same position for 3+ iterations
5. **Missing project** → Can't find STATE.md or ROADMAP.md

### Manual Escape

To stop autopilot manually:

1. Add `BLOCKED: reason` to `.planning/STATE.md`
2. Autopilot will detect it on next iteration and exit cleanly

Example:
```markdown
BLOCKED: Need API credentials before continuing
```

---

## Best Practices

1. **Start with `--phase-only`** to test autopilot on a single phase
2. **Review auto-approvals** in VERIFICATION.md after each run
3. **Set reasonable `max_iterations`** based on milestone complexity
4. **Use `--unattended` for CI/CD** or fully autonomous workflows
5. **Keep `unattended: false`** for interactive development

---

## Support

- **Repository:** https://github.com/nine-one-six-systems/gsd-autopilot
- **Original GSD:** https://github.com/glittercowboy/get-shit-done
- **Issues:** Open an issue on GitHub

---

## License

Same as original GSD project (MIT License).
