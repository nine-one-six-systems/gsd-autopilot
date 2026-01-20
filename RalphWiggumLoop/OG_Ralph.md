# OG Ralph Wiggum Loop

## What It Is

A five-line bash script that runs Claude Code in an infinite loop until a task is verifiably complete.

```bash
while :; do 
  cat PROMPT.md | claude-code
  sleep 5
done
```

## Origin

Created by Geoffrey Huntley, a goat farmer in rural Australia who got frustrated that Claude Code stops when it *thinks* it's done, not when it's *actually* done.

Named after the Simpsons character who fails constantly, makes mistakes, yet stubbornly continues until he eventually succeeds.

## How It Works

1. Feed Claude a prompt from `PROMPT.md`
2. Let it work until it exits
3. Feed it the same prompt again
4. Claude sees what it built last time
5. Repeat until task is complete

**Key principle:** Each iteration gets a completely fresh context window. Only the code on disk and git history persist. Failures get thrown away. Progress accumulates in files.

This prevents "context rot" — the degradation that happens when Claude accumulates too much state in a single session.

## Proof of Concept

Huntley ran a single prompt for three consecutive months:

> "Make me a programming language like Golang but with Gen Z slang keywords."

Result: **Cursed** — a functional compiler with LLVM compilation, standard library, and partial editor support. Keywords include `slay` (function), `sus` (variable), and `based` (true). The compiler can compile itself.

A programming language. From a bash loop. Built while its creator slept.

---

## When It Works

Mechanical tasks with verifiable completion:

- Framework migrations (Jest → Vitest, callbacks → promises)
- Adding type annotations across entire codebases
- Documentation generation with specific templates
- Test coverage expansion
- Dependency upgrades across hundreds of files

**The pattern:** Tasks where tests pass, types resolve, or linters approve. The loop verifies its own success without human judgment.

---

## When It Fails

- "Done" requires human judgment
- Architectural or aesthetic decisions matter
- Tasks are exploratory, not convergent
- No objective success criteria exist

---

## Failure Modes

**Overbaking** — Leave it running too long and Claude adds features nobody asked for. During Cursed development, extended runs produced post-quantum cryptography support unprompted.

**Cost runaway** — No built-in limits. One ambiguous requirement can burn your entire API allocation.

**Merge conflicts** — Long sessions produce stale branches. The codebase moves while Ralph works.

---

## Effective Prompts

### Declarative Specification (describe end state, not steps)

```markdown
# Task: Migrate Authentication

## Current State
- JWT tokens stored in localStorage
- No refresh token logic
- Sessions expire without warning

## Desired State  
- Tokens in httpOnly cookies
- Automatic refresh 5 minutes before expiry
- Graceful session expiration with user notification

## Success Criteria
- All existing tests pass
- New tests cover refresh logic
- No localStorage references remain

Output <promise>COMPLETE</promise> when all criteria verified.
```

### Checkpoints for Complex Tasks

```markdown
## Tasks
- [ ] 1. Initialize project structure
- [ ] 2. Implement core API routes
- [ ] 3. **HARD STOP** - Verify routes return expected responses
- [ ] 4. Add authentication middleware
- [ ] 5. **HARD STOP** - Verify auth blocks unauthorized requests
- [ ] 6. Write integration tests

When you encounter HARD STOP, pause and verify before proceeding.
```

### Escape Valve for Stuck Loops

```markdown
Complete the migration following the spec above.

If after 10 iterations you cannot complete the task:
- Document what's blocking progress
- List approaches attempted
- Suggest alternative solutions

Output <promise>DONE</promise> when complete.
Output <promise>BLOCKED</promise> if unable to proceed.
```

---

## Practical Tips

1. **Be brutally specific about "done"** — Ambiguous criteria burn tokens or produce false victories.

2. **Run on fresh code** — Easier to re-run the loop than resolve merge conflicts. Code is cheap.

3. **Nightly crons > marathon sessions** — One small refactor each morning beats waking up to fifty stale changes.

4. **Treat output as disposable** — Re-run rather than rebase.

5. **Set spending alerts** — No built-in budget controls.

6. **Consider community forks** — `frankbria/ralph-claude-code` adds exit detection, rate limiting, and circuit breakers. `ralph-orchestrator` adds spending limits.

---

## Cost Estimates

| Task Size | Tokens/Iteration | 10 Iterations | 50 Iterations |
|-----------|------------------|---------------|---------------|
| Small (single file) | 10K-30K | $3-10 | $15-50 |
| Medium (multiple files) | 50K-150K | $15-40 | $75-200 |
| Large (codebase-wide) | 200K+ | $50+ | $250+ |

---

## The Philosophy

> "The technique is deterministically bad in an undeterministic world. It's better to fail predictably than succeed unpredictably."

Accept that individual iterations might produce garbage. Trust that enough iterations with clear success criteria will converge on something that works. Treat failures as data, not setbacks.

Persistence + self-correction beats single-shot perfection.