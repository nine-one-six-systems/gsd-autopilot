# Goal Template

Template for `GOAL.md` — declarative success criteria for autonomous execution.

Used with `/gsd:autopilot --goal=GOAL.md` or external Ralph Wiggum loops.

---

## File Template

```markdown
# Goal

[One sentence describing what you want built]

## Success Criteria

[Verifiable criteria that prove the goal is achieved]

- [ ] [Criterion 1 - testable/observable]
- [ ] [Criterion 2 - testable/observable]
- [ ] [Criterion 3 - testable/observable]

## Constraints

[Hard limits on the implementation]

- [Constraint 1]
- [Constraint 2]

## Out of Scope

[Explicitly what NOT to build - prevents overbaking]

- [Thing 1]
- [Thing 2]

## If Blocked

If you cannot proceed after 10 iterations:
1. Document what's blocking progress in STATE.md
2. Add `BLOCKED: [reason]` to STATE.md
3. List approaches attempted
4. Exit cleanly

Do NOT loop indefinitely on the same error.
```

---

## Example: Authentication System

```markdown
# Goal

Build a complete authentication system with email/password login and JWT tokens.

## Success Criteria

- [ ] User can register with email and password
- [ ] User can log in and receive JWT token
- [ ] Protected routes reject requests without valid token
- [ ] Token refresh works before expiry
- [ ] All auth tests pass

## Constraints

- Use bcrypt for password hashing (cost factor 12)
- JWT expiry: 15 minutes access, 7 days refresh
- Store refresh tokens in httpOnly cookies
- No third-party auth providers (OAuth) in v1

## Out of Scope

- Password reset flow (v2)
- Email verification (v2)
- Rate limiting (v2)
- Social login (v2)

## If Blocked

If you cannot proceed after 10 iterations:
1. Document what's blocking progress in STATE.md
2. Add `BLOCKED: [reason]` to STATE.md
3. List approaches attempted
4. Exit cleanly

Do NOT loop indefinitely on the same error.
```

---

## Example: Framework Migration

```markdown
# Goal

Migrate all Jest tests to Vitest.

## Success Criteria

- [ ] All test files use Vitest syntax
- [ ] No Jest dependencies remain in package.json
- [ ] `npm test` runs Vitest successfully
- [ ] All tests pass
- [ ] CI pipeline updated to use Vitest

## Constraints

- Maintain test coverage (no tests deleted)
- Keep same test file locations
- One commit per file migrated

## Out of Scope

- Adding new tests
- Refactoring test logic
- Changing test assertions (only syntax migration)

## If Blocked

If you cannot proceed after 10 iterations:
1. Document what's blocking progress in STATE.md
2. Add `BLOCKED: [reason]` to STATE.md
3. List approaches attempted
4. Exit cleanly

Do NOT loop indefinitely on the same error.
```

---

## Guidelines

<when_to_use>

**Good candidates for GOAL.md:**
- Mechanical migrations (testing frameworks, linting rules)
- Adding type annotations across codebase
- Documentation generation
- Dependency upgrades
- Refactoring patterns (callbacks → promises)

**Poor candidates:**
- Open-ended features ("make it better")
- Aesthetic decisions ("make it look nice")
- Exploratory work ("figure out why X happens")
- Anything without verifiable completion

</when_to_use>

<success_criteria_guidelines>

**Good success criteria are:**
- Binary (pass/fail, not subjective)
- Verifiable by running commands or checking files
- Independent (each can be checked separately)
- Complete (covering all criteria = goal achieved)

**Examples of good criteria:**
- "All tests pass" (run test suite)
- "No TypeScript errors" (run tsc)
- "Endpoint returns 200" (curl command)
- "File exists at path" (ls command)

**Examples of bad criteria:**
- "Code is clean" (subjective)
- "Performance is good" (not specific)
- "Users like it" (requires human judgment)

</success_criteria_guidelines>

<out_of_scope_importance>

**Explicitly listing out-of-scope prevents overbaking.**

Ralph Wiggum loops can run for hours. Without clear boundaries, Claude may add:
- Features nobody asked for
- "Improvements" that change scope
- Edge cases that weren't needed

The "Out of Scope" section is your guardrail against scope creep.

</out_of_scope_importance>

<blocked_handling>

**The escape valve is critical.**

Without it, a loop can:
- Burn through API credits on impossible tasks
- Create hundreds of failed commits
- Waste hours on something that needs human input

The "If Blocked" section teaches Claude to fail gracefully.

</blocked_handling>
