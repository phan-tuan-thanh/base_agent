# Handoff protocol + starter templates (stack-agnostic)

> Generic handoff format and starter `.ai/` templates that work for **any** repo. Replace `<placeholder>` with whatever fits your stack.
>
> For the full enterprise artifact catalogue (BRD, Epic, User Story, Technical Design, API Contract, DB Migration, Sprint Plan, Risk Matrix, Test Cases, Deployment Plan, Rollback Plan, Runbook, …) — all wired to the 15-stage SDLC pipeline — see `ENTERPRISE_SDLC_ORCHESTRATOR.md` and the auto-scaffolded templates under `.ai/contracts/artifacts/`.

## Handoff protocol

When one agent finishes and passes work to the next, it emits a **handoff note** in the format below. The note is appended to `.ai/memory/active-tasks.md` under the relevant task entry.

### Handoff note format

```
FROM: <agent-or-role> (<stage>)
TO:   <next-role> (<next-stage>)
STATUS: ready | blocked | has-risks
ARTIFACT: <link or file path produced this stage>
MEMORY_UPDATES:
- <files changed under .ai/memory/>

## What the next agent needs to know
<3–8 bullets: constraints, decisions made, open questions>

## What the next agent should do
<numbered list of concrete next actions>

## Risks discovered this stage
- <risk> → <mitigation or open question>

## When you're done
Update active-tasks.md#<TASK-ID>:
- mark <next-stage> ✓
- set "Next agent → <role-after-next>"
```

The protocol is identical regardless of language, framework, or platform. Only the artifact link changes.

---

### Example: Planner → Architect

```markdown
FROM: Planner
TO:   Architect
STATUS: ready
ARTIFACT: active-tasks.md#TASK-042 (plan section)
MEMORY_UPDATES:
- active-tasks.md (TASK-042 planner stage ✓)
- decisions.md (proposed: idempotency keys for retry safety)

## What the architect needs to know

- Goal: exponential-backoff retry for failed outbound calls.
- Files in scope: ~5 (handler, state machine, schema/config change, tests, wiring).
- Hard constraint: at-least-once delivery → must be idempotent end-to-end.
- Soft constraint: no public API change.
- Dependencies: none external.
- Blocks: TASK-043 (downstream feature relies on retry).

## What the architect should design

1. State machine for retry lifecycle (states + allowed transitions).
2. Idempotency-key strategy (who generates, where stored, how deduped).
3. Failure backstop (circuit breaker thresholds, fallback behaviour).
4. Persistence change (new fields/columns/keys + migration plan).

## Risks discovered this stage
- Retry storm if downstream stays unhealthy → cap retries + circuit breaker.
- Schema change requires migration safety review.

## When you're done
Update active-tasks.md#TASK-042:
- mark architect stage ✓
- attach design-doc reference
- set "Next agent → Implementer"
```

### Example: Architect → Implementer

```markdown
FROM: Architect
TO:   Implementer
STATUS: ready
ARTIFACT: <path/to/design-doc.md>
MEMORY_UPDATES:
- active-tasks.md (TASK-042 architect stage ✓)
- architecture.md (added Retry component to <module>)

## Design summary

- States: PENDING → RETRYING → SUCCESS | FAILED
- Idempotency: caller-supplied UUID, stored as unique key on the record
- Persistence: add `idempotency_key` (unique) + `retry_count` (int) + `last_retry_at`
- Backstop: circuit breaker with 50% failure threshold + max 5 retries
- Observability: emit structured event on every retry attempt

## What the implementer should code

1. Retry handler module (state-machine logic).
2. Circuit-breaker integration (using whichever library is already in `stack/profile.md`).
3. Migration / schema change (see `workflows/migration.md`).
4. Test suite (state transitions, idempotency, breaker behaviour).
5. Wire into existing call site.

## Code patterns to follow
See `coding-style.md` for module boundary, error-handling, and test conventions.

## Risks discovered this stage
- Race condition on idempotency-key insert under high concurrency.
  Mitigation: rely on store-level unique constraint + retry on conflict.
- Breaker threshold may be too aggressive in low-traffic environments.
  Decision: log every breaker trip to monitoring.

## When you're done
Update active-tasks.md#TASK-042:
- mark implementer stage ✓
- link the PR / commit
- set "Next agent → Reviewer"
```

### Example: Implementer → Reviewer

```markdown
FROM: Implementer
TO:   Reviewer
STATUS: ready
ARTIFACT: PR #<number>
MEMORY_UPDATES:
- active-tasks.md (TASK-042 implementer stage ✓)
- known-issues.md (existing records pre-migration won't dedupe retroactively — accepted)

## Implementation summary
- Retry handler: ~120 lines, 92% coverage
- Tests: state-machine paths, idempotency, breaker open/closed
- Migration: additive (safe to roll back)

## Contract compliance
- ✓ Summary
- ✓ Changed files listed
- ✓ Risks documented
- ✓ Coverage above threshold (92% > 80%)
- ✓ Migration provided + reversible

## What the reviewer should validate
1. All tests pass (CI green).
2. Coverage above the threshold in `contracts/test-coverage.md`.
3. State-machine paths exhaustively covered.
4. Regression: existing happy-path call still works.
5. Migration is safe to roll back.

## When you're done
Update active-tasks.md#TASK-042:
- mark reviewer stage ✓
- mark task "Ready to merge"
```

---

## Starter template files

Copy these into `.ai/` when bootstrapping a new repo. The included `scripts/init-workspace.sh` writes them automatically (see `QUICK_START_30MIN.md`); the versions below are the canonical reference if you ever want to edit them.

### `.ai/rules/global/security.md`

```markdown
# Global security rules (any stack)

NEVER:
- Hardcode credentials, API keys, or tokens in code or config.
- Log secrets, tokens, full request bodies for sensitive routes, or PII.
- Send secrets in URLs or query strings (use headers / env / secret store).
- Skip transport security (always TLS for cross-network calls).
- Concatenate untrusted input into queries, shell commands, or eval-like calls.
- Store passwords or sensitive payloads in plaintext.

ALWAYS:
- Read secrets from environment variables or a secrets manager.
- Validate and normalise all external input at the boundary.
- Use parameterised queries / prepared statements / safe builders.
- Hash passwords with a memory-hard algorithm (e.g. Argon2, bcrypt, scrypt).
- Apply least-privilege to data access (RBAC / ABAC).
- Add an audit trail for sensitive mutations (who, what, when).

## PR checklist
- [ ] No credentials in code or commit history.
- [ ] No injection vectors (SQL, shell, template, deserialization).
- [ ] Transport secured (TLS / signed RPC).
- [ ] Rate limiting on externally-reachable endpoints.
- [ ] Error messages do not leak system internals.
- [ ] Logs exclude sensitive fields.
```

### `.ai/rules/global/performance.md`

```markdown
# Global performance rules (any stack)

NEVER:
- Issue unbounded queries / scans / list operations on large data sets.
- Hold expensive resources (connections, file handles, locks) longer than needed.
- Run unbounded loops over external input.
- Block the main thread / event loop on I/O.
- Use O(n²) algorithms on inputs that can grow without bound.

ALWAYS:
- Paginate or stream collections that can exceed a known bound.
- Set timeouts on every external call.
- Bound retries (count + total elapsed time).
- Add an index for any field used in WHERE / equality / range filters.
- Profile before optimising; document any non-obvious tuning.
```

### `.ai/rules/global/architecture.md`

```markdown
# Global architecture principles (any stack)

- Single responsibility per module / package / service.
- One public entry point per module; internals stay internal.
- Side effects at the edge; pure logic in the core.
- Explicit dependencies (injected, not imported globally).
- Backwards-compatible changes by default; breaking changes require an ADR.
- Document non-obvious decisions in `.ai/memory/decisions.md`.
```

### `.ai/rules/global/anti-patterns.md`

```markdown
# Forbidden patterns (any stack)

- "God object" / module that knows about everything.
- Catch-all `try { … } catch { /* swallow */ }` blocks.
- Magic numbers without a named constant + comment.
- Cyclic imports / cyclic module dependencies.
- Copy-paste code across more than two call sites (extract instead).
- Reaching into a module's private internals.
- Time/randomness/I/O hardcoded inside pure logic (inject them).
- Tests that depend on wall-clock time, network reachability, or test-execution order.
```

### `.ai/contracts/output-format.md`

```markdown
# Output contract (every agent deliverable)

Every plan, design, PR description, or review note must include all five sections.

## Summary
1–3 sentences: what was done or proposed.

## Changed files
Bulleted list of files touched, each annotated `(added | modified | deleted)`.

## Risks
Risks + mitigations:
- Risk: <what could go wrong>
  Mitigation: <how it is bounded>

## Tests
- Unit: <count, coverage>
- Integration: <what is exercised>
- Regression: <what was verified to still work>

## Next steps
1. <next concrete action>
2. <dependency>
3. <blocker if any>

Missing any section = contract violation. The reviewer rejects the deliverable.
```

### `.ai/contracts/pr-checklist.md`

```markdown
# PR checklist

- [ ] Output-format contract satisfied (Summary, Changed files, Risks, Tests, Next steps).
- [ ] All commands in `stack/commands.md` were run (build, lint, test).
- [ ] Coverage threshold met (see `contracts/test-coverage.md`).
- [ ] No unrelated files modified.
- [ ] Memory updated where relevant (`architecture.md`, `decisions.md`, `known-issues.md`, `active-tasks.md`).
- [ ] Breaking changes flagged in PR title and release notes.
- [ ] No secrets in diff or commit history.
```

### `.ai/contracts/test-coverage.md`

```markdown
# Test coverage contract

| Area                                 | Minimum coverage |
|--------------------------------------|------------------|
| Default (any new module)             | 80%              |
| Security-sensitive code              | 90%              |
| Money / billing / auth / data loss   | 95%              |
| Pure utilities                       | 100%             |

Coverage alone is not enough. Tests must exercise:
- Happy path
- Each error branch
- Each external boundary (with realistic fixtures, not blanket mocks)
```

### `.ai/contracts/api-design.md`

```markdown
# API design contract (transport-agnostic)

Applies to HTTP, gRPC, message queues, CLIs, and library exports.

- Naming: verbs for actions, nouns for resources, consistent casing.
- Versioning: explicit (`/v1/`, `package@1.x`, queue topic `…-v1`). Never break v1 silently.
- Errors: typed and stable. Document each error code / shape.
- Pagination: cursor-based for unbounded collections; never `LIMIT`-less list endpoints.
- Idempotency: every state-changing operation accepts an idempotency key.
- Backwards compatibility: additive changes only without an ADR.
- Observability: each entry point emits a structured event with the request id.
```

### `.ai/memory/architecture.md` (skeleton)

```markdown
# System architecture

## Overview
<1 paragraph: what this system does, who uses it, what it produces>

## Modules / services
- <module-1>: <responsibility>
- <module-2>: <responsibility>

## Data flow
<text or ASCII diagram of how data moves end-to-end>

## External integrations
- <name>: <protocol, version, what we depend on>

## Persistence
- <store>: <purpose, retention, backup policy>

## Deploy target
<runtime, environments, rollout strategy>

## Performance targets
- <metric>: <target>
```

### `.ai/memory/decisions.md` (skeleton)

```markdown
# Architecture Decision Records

## ADR-001: <title>

Status: Accepted
Date: <YYYY-MM-DD>
Owner: <person or role>

### Decision
<what was decided>

### Reason
<why this choice over alternatives>

### Consequence
<what changes — good and bad — and how the bad parts are mitigated>

### Alternatives considered
- <option> — <why rejected>
```

### `.ai/memory/coding-style.md` (skeleton)

```markdown
# Coding style (this repo)

This file documents the patterns the repo **actually** uses, not the ones it should use. Update it when patterns change.

## Module structure
<conventions>

## Error handling
<conventions>

## Logging & observability
<conventions>

## Testing
<conventions: unit vs integration, fixtures, naming>

## Dependency injection / wiring
<conventions>

## Naming
- Files: <convention>
- Functions: <convention>
- Constants: <convention>

## Commits
<format + examples>
```

### `.ai/memory/active-tasks.md` (skeleton)

```markdown
# Active tasks

> Single source of truth for in-progress work. Update before starting and after finishing a stage.

## Template

### TASK-<id>: <title>

Status: <Planner | Architect | Implementer | Reviewer | Merged>
Owner: <agent or person>
Start date: <YYYY-MM-DD>
Deadline: <YYYY-MM-DD or none>

#### Stage checklist
- [ ] Planner
- [ ] Architect
- [ ] Implementer
- [ ] Reviewer
- [ ] Merged

#### Files touched
- <path>

#### Depends on
- <task or ticket id>

#### Blocks
- <task or ticket id>

#### Risks
- <risk> → <mitigation>

#### Notes / handoffs
<append handoff notes here in chronological order>
```

### `.ai/memory/known-issues.md` (skeleton)

```markdown
# Known issues + workarounds

## <short title>

Discovered: <YYYY-MM-DD>
Affects: <module or area>

### Symptom
<what goes wrong>

### Root cause
<best current understanding, or "unknown — investigation needed">

### Workaround
<what to do until it's fixed>

### Fix tracking
<task id, ADR, or "not planned">
```

### `.ai/agents/_template.md`

```markdown
# Agent role: <ROLE>

## Strength
<what this lane is good at>

## Known weaknesses
<what to watch for; e.g. scope creep, hallucinated APIs, over-engineering>

## DO
- <behaviour 1>
- <behaviour 2>

## DO NOT
- <behaviour 1>
- <behaviour 2>

## Inputs (load before acting)
- <files / sections>

## Outputs (produce these)
- <artifact 1>
- <artifact 2 — must comply with contracts/output-format.md>

## Handoff
- Update `active-tasks.md` with stage ✓ and "Next agent → <role>".
- Append a handoff note in the format from `HANDOFF_PROTOCOL_AND_TEMPLATES.md`.
```

### `.ai/agents/planner.md`

```markdown
# Agent role: Planner

## Strength
Scope decomposition, risk identification, dependency mapping.

## Known weaknesses
Drifting into design (architect's lane); over-specifying implementation details.

## DO
- Read `stack/profile.md` and `stack/conventions.md` first.
- Read `decisions.md` to spot conflicts before they happen.
- List files in scope (best estimate) so downstream lanes can plan around conflicts.
- Surface every external dependency / blocker explicitly.

## DO NOT
- Choose libraries, schemas, or APIs (Architect's job).
- Write code.
- Skip risk identification because it "looks easy".

## Outputs
- Plan, in `contracts/output-format.md` shape, appended to `active-tasks.md`.
```

### `.ai/agents/architect.md`

```markdown
# Agent role: Architect

## Strength
API surface, data model, integration shape, design trade-offs.

## Known weaknesses
Over-engineering; introducing speculative abstractions.

## DO
- Verify the design respects every relevant ADR.
- Document state transitions and failure modes.
- Specify migration / rollout plan for any persistent change.
- Update `architecture.md` with the new component.

## DO NOT
- Write production code.
- Invent new ADRs without flagging them for consensus.
- Bypass `contracts/api-design.md`.

## Outputs
- Design doc using `contracts/design-doc.md`.
- ADR proposal(s) if new principles are introduced.
```

### `.ai/agents/implementer.md`

```markdown
# Agent role: Implementer

## Strength
Translating a design into working code + tests.

## Known weaknesses
Hallucinated imports / APIs; opportunistic refactors; skipping edge-case tests.

## DO
- Use only commands listed in `stack/commands.md`.
- Search the repo for existing patterns before writing new ones.
- Verify every external symbol exists before using it.
- Cover happy path AND each error branch.
- Update `known-issues.md` with anything you had to work around.

## DO NOT
- Modify files outside the design's scope.
- Introduce new dependencies without an ADR.
- Skip the test commands in `stack/commands.md`.

## Outputs
- PR (or patch) compliant with `contracts/output-format.md` and `contracts/pr-checklist.md`.
```

### `.ai/agents/reviewer.md`

```markdown
# Agent role: Reviewer

## Strength
Validating outputs against contracts, catching regressions, asking the awkward question.

## Known weaknesses
Rubber-stamping; nitpicking style instead of catching real risk.

## DO
- Check the PR against `contracts/pr-checklist.md` line by line.
- Re-run `stack/commands.md` build/test/lint locally or in CI.
- Confirm `active-tasks.md` and any other memory file have been updated.
- Reject (don't fix) contract violations — the producer fixes them.

## DO NOT
- Touch the implementation yourself.
- Approve while a contract section is missing.
```

### `.ai/agents/orchestrator.md`

```markdown
# Agent role: Orchestrator

## Responsibility
Sequence work across lanes, prevent duplicate work, resolve handoff ambiguity.

## DO
- Maintain `active-tasks.md` as ground truth.
- Detect file-touch conflicts before they happen and re-sequence accordingly.
- Validate handoff notes follow the protocol.
- Escalate ADR violations rather than work around them.

## DO NOT
- Decide architectural questions (defer to Architect).
- Override Reviewer rejections.
```

### `.ai/workflows/feature.md`

```markdown
# Workflow: feature

1. **Planner** reads scope + relevant ADRs, writes plan, lists files in scope.
2. **Architect** designs API/data/integration; writes design doc; updates `architecture.md`.
3. **Implementer** codes against design + writes tests to coverage threshold.
4. **Reviewer** validates against contracts and runs `stack/commands.md` build/test.
5. **Merge**: squash to main; mark task merged in `active-tasks.md`.

## Success criteria
- ✓ Every output complies with `contracts/output-format.md`.
- ✓ Coverage threshold met.
- ✓ Memory updated.
```

### `.ai/workflows/bugfix.md`

```markdown
# Workflow: bugfix

1. **Reproduce** with the smallest possible test case; commit it as a failing test.
2. **Root cause** documented in PR description.
3. **Minimal fix** — no opportunistic refactors.
4. **Regression test** — the failing test from step 1 must now pass.
5. **Review + merge**.

## Rules
- NO refactoring while fixing.
- NO architectural changes.
- YES write the failing test first.
- YES add the bug pattern to `known-issues.md` if it could recur elsewhere.
```

### `.ai/workflows/refactor.md`

```markdown
# Workflow: refactor

1. State the **scope** explicitly (which files, which behaviours stay identical).
2. Capture current behaviour in tests (if not already covered).
3. Refactor in small steps; tests stay green at every step.
4. No new features mixed in.
5. Review focuses on: scope respected, tests still meaningful, performance unchanged.
```

### `.ai/workflows/migration.md`

```markdown
# Workflow: migration (data / schema / breaking change)

1. Design the migration as **additive then subtractive** (two phases).
2. Provide a rollback plan and verify it on staging data.
3. Run the additive phase under live traffic; observe for at least one full traffic cycle.
4. Run the subtractive phase only after all writers are on the new shape.
5. Document the migration in `architecture.md` and `decisions.md`.
```

### `.ai/workflows/hotfix.md`

```markdown
# Workflow: hotfix

1. Confirm the incident is real and high-impact.
2. Branch from production tag, not main.
3. Smallest possible diff; one purpose only.
4. Two-person review (or two-agent + human approval).
5. Backport to main; record the incident in `known-issues.md`.
```

### `.ai/workflows/release.md`

```markdown
# Workflow: release

1. Confirm `active-tasks.md` has no in-flight tasks blocking the release.
2. Generate release notes from merged PR titles.
3. Bump version per `commit-policy.md`.
4. Tag, build, deploy per `stack/commands.md` and the project's deploy doc.
5. Smoke-test in production / production-equivalent.
```

---

## How to use these templates

1. Run `scripts/init-workspace.sh` from the new repo's root — it writes the entire `.ai/` skeleton (these templates) and a starter `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`.
2. Fill in `.ai/stack/profile.md`, `commands.md`, `conventions.md`, `glossary.md` (≈10 minutes).
3. Add the first ADR or two to `.ai/memory/decisions.md`.
4. Open `active-tasks.md` and start tracking work.
5. Point your agents at `AGENTS.md`. They are now coordinated under the same protocol on this new repo.

---

## Success metrics

The workspace is mature when:

1. ✓ Every agent reads `active-tasks.md` before starting.
2. ✓ Memory files are updated after every task (not just before).
3. ✓ `decisions.md` has 5+ ADRs that reflect real choices.
4. ✓ Reviewer rejects on contract violations and is upheld.
5. ✓ A new agent (or new contributor) gets productive in under 30 minutes.
6. ✓ Switching to a new repo means filling in `stack/`, not redesigning the workspace.
