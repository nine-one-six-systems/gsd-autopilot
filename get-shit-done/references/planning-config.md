<planning_config>

Configuration options for `.planning/` directory behavior.

<config_schema>
```json
{
  "mode": "yolo|interactive",
  "depth": "quick|standard|comprehensive",
  "parallelization": true,
  "commit_docs": true,
  "planning": {
    "commit_docs": true,
    "search_gitignored": false
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true
  },
  "autopilot": {
    "max_iterations": 50,
    "cost_limit": null,
    "auto_continue": true
  }
}
```

| Option | Default | Description |
|--------|---------|-------------|
| `planning.commit_docs` | `true` | Whether to commit planning artifacts to git |
| `planning.search_gitignored` | `false` | Add `--no-ignore` to broad rg searches |
| `autopilot.max_iterations` | `50` | Maximum iterations before autopilot stops |
| `autopilot.cost_limit` | `null` | Maximum cost in USD (null = no limit) |
| `autopilot.auto_continue` | `true` | Automatically continue to next phase (false = stop at phase boundaries) |
</config_schema>

<commit_docs_behavior>

**When `commit_docs: true` (default):**
- Planning files committed normally
- SUMMARY.md, STATE.md, ROADMAP.md tracked in git
- Full history of planning decisions preserved

**When `commit_docs: false`:**
- Skip all `git add`/`git commit` for `.planning/` files
- User must add `.planning/` to `.gitignore`
- Useful for: OSS contributions, client projects, keeping planning private

**Checking the config:**

```bash
# Check config.json first
COMMIT_DOCS=$(cat .planning/config.json 2>/dev/null | grep -o '"commit_docs"[[:space:]]*:[[:space:]]*[^,}]*' | grep -o 'true\|false' || echo "true")

# Auto-detect gitignored (overrides config)
git check-ignore -q .planning 2>/dev/null && COMMIT_DOCS=false
```

**Auto-detection:** If `.planning/` is gitignored, `commit_docs` is automatically `false` regardless of config.json. This prevents git errors when users have `.planning/` in `.gitignore`.

**Conditional git operations:**

```bash
if [ "$COMMIT_DOCS" = "true" ]; then
  git add .planning/STATE.md
  git commit -m "docs: update state"
fi
```

</commit_docs_behavior>

<search_behavior>

**When `search_gitignored: false` (default):**
- Standard rg behavior (respects .gitignore)
- Direct path searches work: `rg "pattern" .planning/` finds files
- Broad searches skip gitignored: `rg "pattern"` skips `.planning/`

**When `search_gitignored: true`:**
- Add `--no-ignore` to broad rg searches that should include `.planning/`
- Only needed when searching entire repo and expecting `.planning/` matches

**Note:** Most GSD operations use direct file reads or explicit paths, which work regardless of gitignore status.

</search_behavior>

<setup_uncommitted_mode>

To use uncommitted mode:

1. **Set config:**
   ```json
   "planning": {
     "commit_docs": false,
     "search_gitignored": true
   }
   ```

2. **Add to .gitignore:**
   ```
   .planning/
   ```

3. **Existing tracked files:** If `.planning/` was previously tracked:
   ```bash
   git rm -r --cached .planning/
   git commit -m "chore: stop tracking planning docs"
   ```

</setup_uncommitted_mode>

<autopilot_config>

## Autopilot Configuration

Control autonomous loop behavior:

**`autopilot.max_iterations`** (default: `50`)
- Maximum iterations before autopilot stops
- Prevents runaway loops
- Override with `--max-iterations` flag

**`autopilot.cost_limit`** (default: `null`)
- Maximum cost in USD before autopilot stops
- Requires cost tracking implementation
- `null` = no cost limit

**`autopilot.auto_continue`** (default: `true`)
- `true`: Automatically transition to next phase
- `false`: Stop at phase boundaries (equivalent to `--phase-only`)

**Example config:**
```json
{
  "autopilot": {
    "max_iterations": 100,
    "cost_limit": 50.0,
    "auto_continue": true
  }
}
```

**Reading autopilot config:**
```bash
# Read max_iterations (default: 50)
MAX_ITERATIONS=$(cat .planning/config.json 2>/dev/null | grep -o '"max_iterations"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' || echo "50")

# Read auto_continue (default: true)
AUTO_CONTINUE=$(cat .planning/config.json 2>/dev/null | grep -o '"auto_continue"[[:space:]]*:[[:space:]]*[^,}]*' | grep -o 'true\|false' || echo "true")
```

</autopilot_config>

</planning_config>
