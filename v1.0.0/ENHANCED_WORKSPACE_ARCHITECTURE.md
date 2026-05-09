# Multi-agent workspace architecture (stack-agnostic)

> A reusable operating system for AI agents working on **any** repository — backend, frontend, mobile, data, infra. Drop the `.ai/` folder into a fresh repo, point your agents at `AGENTS.md`, and they all play by the same rules.
>
> For the enterprise Agile/Scrum operating model that runs **on top of** this architecture (BA / PO / Tech Lead / Architect / Senior Dev / QA / DevOps / Scrum Master roles, 15-stage SDLC pipeline, full artifact catalogue), see `ENTERPRISE_SDLC_ORCHESTRATOR.md`.

## Why this matters

Real projects break multi-agent setups for predictable reasons:

- **Concurrent tasks** — multiple agents touching different features at once
- **Shared-state conflicts** — "who owns this file?"
- **Context drift** — Architect forgets Planner's constraints two turns later
- **Task dependencies** — Feature A blocks Feature B, but nobody told the agents
- **Stack-specific lock-in** — playbook that only works for one stack dies the moment the team picks a new one

This architecture solves all of the above with **state management + enforced contracts + handoff protocol**, expressed in a way that **does not assume any particular language, framework, or platform**.

## Core principle

A workspace is not just files + a system prompt. It is:

```
Deterministic Workflow + Enforced Contracts + Shared Operational Memory
```

NOT: "call Planner → call Architect → call Impl → pray they're consistent"

The architecture is the same for every repo. Only the contents of the **stack adapter** change.

---

## Architecture layers

```
.ai/
├── rules/        # static, immutable — load once at start
├── memory/       # evolving — agents read & write every task
├── workflows/    # task-specific recipes (feature, bugfix, refactor…)
├── contracts/    # output-format guarantees
├── agents/       # per-agent strengths/weaknesses + lane rules
└── stack/        # the only repo-specific layer (see "Stack adapter" below)
```

### Layer 1: Rules (static, immutable)

Rules are **context-independent guidelines** that don't change during a sprint. They are written once and rarely edited.

```
.ai/rules/
├── global/
│   ├── security.md          # never bypass auth, never hardcode secrets, no PII in logs
│   ├── performance.md       # bound queries, paginate large lists, no unbounded loops
│   ├── architecture.md      # core principles (modularity, single-responsibility, etc.)
│   └── anti-patterns.md     # things we explicitly forbid
└── domain/                  # one file per domain you actually have
    ├── _README.md           # how to add a new domain rules file
    └── …                    # e.g. backend.md, frontend.md, data.md, infra.md, mobile.md
```

The `global/` rules are **stack-agnostic** — they apply everywhere. Domain rules are added as your repo grows. There is no built-in assumption about which domains exist.

### Layer 2: Memory (evolving, agent-curated)

Memory is **state that changes** as the project evolves. All agents read it before every action and update it after.

```
.ai/memory/
├── architecture.md          # current system structure (stack, modules, data flow)
├── decisions.md             # ADRs: why we chose X, not Y
├── coding-style.md          # patterns the codebase actually uses
├── active-tasks.md          # work in progress + blockers (single source of truth)
├── known-issues.md          # bugs + workarounds agents should know about
├── sprint-context.md        # current sprint goals, deadlines
└── integration-map.md       # external services + contract versions
```

**Why separate from rules**: architecture changes mid-sprint when you discover a better pattern. Decisions evolve when a new requirement invalidates an old choice. `active-tasks.md` is *always* changing.

**Golden rule**: if an agent discovers something important, it **must update memory**. Not in PR description, not in commit message — in the shared file. Future agents only see what is in memory.

### Layer 3: Workflows (task-specific execution paths)

Each workflow defines **steps + validation gates** for a specific task type. Workflows are stack-agnostic — they describe phases, not technologies.

```
.ai/workflows/
├── feature.md               # plan → design → implement → test → review → merge
├── bugfix.md                # reproduce → root cause → minimal fix → regression test
├── refactor.md              # scope-bounded, no behavioural change, full test pass
├── review.md                # checklist + approval gates
├── hotfix.md                # emergency: minimal scope, expedited gate
├── migration.md             # data/schema migration: rollback safety, canary first
└── release.md               # versioning, notes, deploy steps
```

A workflow is a shared recipe. Every agent follows the same flow for the same task type. No surprises.

### Layer 4: Contracts (output guarantees)

Contracts ensure **all agent outputs look the same**, regardless of which agent (or model) produced them.

```
.ai/contracts/
├── output-format.md         # every deliverable: Summary | Changed files | Risks | Tests | Next steps
├── pr-checklist.md          # PR must: pass tests, update memory, document breaking changes
├── commit-policy.md         # commit format + squash rules
├── api-design.md            # generic API patterns + versioning (HTTP/RPC/CLI/library API)
├── design-doc.md            # template for architecture proposals
└── test-coverage.md         # minimum thresholds (default 80%, sensitive areas higher)
```

Contracts prevent agents from inventing their own standards. One format works everywhere.

### Layer 5: Agent adapters (per-agent behavior)

Each agent type gets specialised lane rules for its strengths and known weaknesses.

```
.ai/agents/
├── _template.md             # boilerplate: copy this for any new agent type
├── planner.md               # role: scope, risks, blockers
├── architect.md             # role: design API, data model, integration plan
├── implementer.md           # role: code + tests, follow design exactly
├── reviewer.md              # role: validate against contracts, regression
└── orchestrator.md          # rules for agent-to-agent handoff
```

These are **role files**, not model files. The same `implementer.md` can be served by Claude, Gemini, Codex, or a human contractor. If you want model-specific tweaks, add a `model-notes/` subfolder — but do not couple the role to the model.

### Layer 6 (the only repo-specific layer): Stack adapter

This is the **only folder you customise per repo**.

```
.ai/stack/
├── profile.md               # 1-page: what is this repo? language(s), frameworks, deploy target
├── commands.md              # how do I build / test / lint / run locally?
├── conventions.md           # repo-specific naming, layout, dependency policy
└── glossary.md              # domain terms that agents need to recognise
```

`profile.md` is the file every new agent reads first. Everything else (rules, contracts, workflows) stays identical across repos. **Add a new repo → fill in `stack/` → done.**

---

## Critical: state management via `active-tasks.md`

This is the **single source of truth for work in progress**. It is stack-agnostic — works for a Rust CLI, a React app, a Terraform module, or a Jupyter pipeline.

```markdown
# Sprint active tasks

## TASK-042: <short title>

Status: In Progress (Implementation stage)
Owner: <agent or person>
Start date: 2026-05-09
Blocks: TASK-043
Blocked by: INFRA-18

### Stage checklist
- [x] Planner: scope + risks defined
- [x] Architect: design accepted
- [ ] Implementer: code (50% — primary path done, edge cases pending)
- [ ] Reviewer: validate against contracts
- [ ] Merge: approved, waiting on INFRA-18

### Files touched
- <path/to/module>
- <path/to/test>
- <path/to/migration-or-config>

### Risks
- <risk> → <mitigation or open question>

### Dependencies
- INFRA-18 — ETA 2026-05-12
- decisions.md#ADR-007 (idempotency strategy)

### Next agent (when current stage finishes)
→ Reviewer: contract validation + regression on <area>
```

Why this format works for any stack:

1. **No surprises** — Planner sees what Architect already decided.
2. **Blockers visible** — TASK-042 blocks TASK-043; do not start both at once.
3. **Dependencies tracked** — if INFRA-18 fails, TASK-042 is doomed; flag it now.
4. **Risk register** — every concern has an owner.
5. **Clean handoff** — the next agent sees exactly where the previous one left off.

---

## Multi-agent orchestration

### Choreography (simple, ≤3 agents)

Agents work **in sequence**. Each waits for the previous one. Suitable for solo dev + 2 agents.

```
Planner → Architect → Implementer
   │           │            │
   └─── all read shared memory ───┘
```

### Orchestration (4+ agents, parallel work)

One agent **coordinates** — the Orchestrator.

```
Orchestrator:
  1. Load active-tasks.md
  2. Assign Planner task X
  3. Wait for Planner output
  4. Assign Architect task X
  5. Assign Implementer task X (can fan out across independent files)
  6. Assign Reviewer task X
  7. Validate outputs vs contracts
  8. Merge results into memory
  9. Mark task done
```

The orchestration logic does not depend on the stack. The same orchestrator drives a backend feature, a UI tweak, or a database migration.

---

## Context pruning (token efficiency)

Large repos = large context = slow + expensive. Load only what an agent needs for **this task**.

Loading order for any agent:

1. `rules/global/*` — always (security, performance, architecture, anti-patterns).
2. `stack/profile.md` + `stack/conventions.md` — always (so the agent knows the repo).
3. `rules/domain/<relevant>.md` — only if touching that domain.
4. `workflows/<type>.md` — the workflow being executed.
5. `contracts/*` — always (all outputs must comply).
6. `memory/*` — only relevant entries (current task, related ADRs, related architecture sections — *not* the entire file).
7. `agents/<role>.md` — the agent's own role file.

Example: Implementer agent for a backend feature loads:

```
rules/global/security.md
rules/global/performance.md
rules/domain/backend.md
stack/profile.md
stack/conventions.md
stack/commands.md
workflows/feature.md
contracts/output-format.md
contracts/test-coverage.md
agents/implementer.md
memory/architecture.md  (only the section for the module being changed)
memory/decisions.md     (only ADRs tagged backend)
memory/active-tasks.md  (only the active task entry)
```

Does **not** load: unrelated domain rules, unrelated ADRs, completed tasks, sprint OKRs irrelevant to this task.

---

## Conflict prevention

### Conflict #1: two agents modifying the same file

**Prevention**: `active-tasks.md` tracks "files touched".

```markdown
TASK-042 → src/billing/retry.<ext>
TASK-043 → src/billing/invoice.<ext>  (imports retry)

TASK-043 blocked by TASK-042 (file dependency)
```

Rule: do not start TASK-043 until TASK-042 is merged.

### Conflict #2: architectural disagreement

**Example**:
- Planner says "add a caching layer".
- Architect says "caching violates ADR-005 (single source of truth)".

**Prevention**: `decisions.md` is **explicit and immutable** without consensus.

```markdown
## ADR-005: Single source of truth pattern

Status: Accepted
Date: 2026-04-15

### Decision
No client-side or server-side caching for critical business data.

### Reason
- Reduce cache-invalidation complexity
- Simplify audit trail
- Compliance: critical data must always be verified fresh

### Consequence
Higher backing-store load. Mitigation: read replicas, indexed queries, pagination.
```

Architect checks `decisions.md` first. If a proposal violates ADR-005, the design rejects it and the conflict surfaces in the handoff note, not silently in the diff.

### Conflict #3: code-style mismatch

**Prevention**: `coding-style.md` documents the patterns the repo **actually** uses, not the ones it should use.

```markdown
# Patterns we use in this repo

## Module boundaries
✓ One public entry point per module
✗ Wildcard re-exports

## Error handling
✓ Typed errors at module boundary
✓ Centralised mapping to user-facing messages
✗ Throwing strings or untyped error objects

## Testing
✓ Real dependencies via test containers / fixtures
✗ Mocks for I/O boundaries (we got burned: mocked tests passed, prod migration failed)
```

Agent reads this and follows it. No "wait, why is this style different?" mid-PR.

---

## Worked example: a generic feature task

Below is the same workflow you'd run for **any** stack. Replace `<file>` with whatever the relevant path is in your repo.

### 1. Planner stage

**Input**: issue "Add automatic retry for failed outbound calls".

**Planner reads**:
- `rules/global/*`
- `stack/profile.md`, `stack/conventions.md`
- `rules/domain/<relevant>.md`
- `workflows/feature.md`
- `memory/decisions.md` — check for prior decisions on retries / idempotency
- `memory/active-tasks.md` — any blockers?

**Planner decides**:
- Retry strategy: exponential backoff (3 retries, 1s/2s/4s).
- Surface area: internal only, no public API change.
- Storage: add a `retry_state` field to the relevant record.
- Files to touch: ~5.
- Risks: at-least-once delivery → idempotency required.

**Planner output** (follows `contracts/output-format.md`):

```markdown
## Summary
Add exponential-backoff retry for failed outbound calls.

## Changed files
- <path/to/retry-handler> (new)
- <path/to/state-machine> (new)
- <path/to/migration-or-schema-change> (new)
- <path/to/test> (new)
- <path/to/config> (modified)

## Risks
- At-least-once delivery → same call processed twice.
  Mitigation: caller-provided idempotency key, deduped at store boundary.
- Retry storm if downstream stays unhealthy.
  Mitigation: cap at 5 retries, exponential backoff, circuit breaker.

## Tests
- Unit: state-machine transitions (all paths)
- Integration: retry success/exhaustion + circuit-breaker open
- Regression: existing happy-path call still works

## Next steps
1. Architect: design state machine + idempotency key strategy
2. Implementer: code + tests
3. Reviewer: contract + regression
```

**Memory updates**:
- `active-tasks.md#TASK-042` — Planner stage ✓
- `decisions.md` — note: "Use caller-supplied idempotency keys for retry safety" (proposed ADR)

### 2. Architect stage

Reads Planner's plan + relevant ADRs. Produces a design doc following `contracts/design-doc.md`. Updates `architecture.md` with the new component. Hands off to Implementer.

### 3. Implementer stage

Reads design doc + `coding-style.md`. Codes against the design. Writes tests to the coverage threshold in `contracts/test-coverage.md`. Hands off to Reviewer with a PR-style summary.

### 4. Reviewer stage

Reads PR. Validates: contract compliance ✓, coverage threshold ✓, files match design ✓, risks addressed ✓, memory updated ✓. Approves or requests changes.

The same four-stage flow runs for a Rust binary, a Python data pipeline, a TypeScript SPA, or a Helm chart. The **stack adapter** tells each agent which paths and tools apply.

---

## Rules for conflict-free multi-agent work

### 1. One agent = one lane

Planner doesn't implement. Architect doesn't code. Implementer doesn't redesign. Clear separation = clear accountability.

### 2. `active-tasks.md` is the coordination device

Before starting:
- Is this task already assigned? Don't duplicate.
- Does it block me? It is marked blocked.
- Do I have all dependencies? Check "blocked by".

After finishing:
- Mark your stage complete.
- Add risks you discovered.
- Note the next agent.

### 3. Decisions are immutable (except by consensus)

If you disagree with an ADR, do not work around it. Comment in `decisions.md`: "I think ADR-005 should be revisited because…". Wait for the team. Only then change the ADR. **Quietly violating an ADR is the single most common cause of multi-agent rework.**

### 4. Memory is not optional

If Planner discovers a new constraint → add to `decisions.md`.
If Implementer discovers a workaround → add to `known-issues.md`.
If Architect discovers a pattern is outdated → update `architecture.md` and propose an ADR.

### 5. Contracts prevent style wars

All outputs follow `contracts/output-format.md`. Debates about "should the PR include risks?" are settled by the contract, not by the agent.

---

## Stack adapter — how to make this fit any repo

The architecture above is **identical for every repo**. The only thing that changes is `.ai/stack/`. Here is the minimum viable adapter for a fresh repo:

### `.ai/stack/profile.md`

```markdown
# Stack profile

## What this repo is
<one paragraph: purpose, who uses it, what it produces>

## Languages & frameworks
- Primary language: <e.g. TypeScript>
- Runtime: <e.g. Node 20>
- Major frameworks/libraries: <list>

## Persistence / external systems
- <e.g. PostgreSQL 15, Redis, S3, third-party API X>

## Build / test / run
See `commands.md`.

## Deploy target
<e.g. AWS Lambda, Kubernetes cluster, App Store, npm registry, none / library>

## Out of scope
<things this repo deliberately does NOT do, so agents don't drift>
```

### `.ai/stack/commands.md`

```markdown
# Local commands

| Action | Command |
|--------|---------|
| Install deps | <e.g. `npm install`> |
| Build | <…> |
| Run unit tests | <…> |
| Run integration tests | <…> |
| Lint | <…> |
| Type-check | <…> |
| Format | <…> |
| Start dev server | <…> |

Agents must use these exact commands. Do not invent new ones.
```

### `.ai/stack/conventions.md`

```markdown
# Repo conventions

## File layout
<top-level folders and what lives in each>

## Naming
<files, modules, tests, branches>

## Dependency policy
<what may we add? who approves?>

## Test policy
<unit / integration / e2e split, fixtures, snapshots>
```

### `.ai/stack/glossary.md`

```markdown
# Domain glossary

| Term | Meaning |
|------|---------|
| <jargon> | <plain-English definition> |
```

That is it. **Three to four short files** make the entire architecture work for a new repo.

---

## Recommended `AGENTS.md` entry point

```markdown
# Workspace AI Operating System

Every agent must follow the loading order below.

## Mandatory loading order

1. `.ai/rules/global/*`           — universal rules
2. `.ai/stack/profile.md`         — what this repo is
3. `.ai/stack/conventions.md`     — repo-specific layout & policy
4. `.ai/stack/commands.md`        — exact build/test/run commands
5. `.ai/contracts/*`              — output guarantees
6. `.ai/rules/domain/<relevant>`  — only if touching that domain
7. `.ai/workflows/<type>.md`      — the workflow you're running
8. `.ai/memory/*`                 — only the relevant entries
9. `.ai/agents/<your-role>.md`    — your lane

## Core rules (never break these)

- Never modify unrelated files (no opportunistic refactors).
- Never invent commands; use `stack/commands.md`.
- Update memory whenever architecture, decisions, or open issues change.
- Follow contracts strictly.
- Check `active-tasks.md` first to avoid duplicate work.

## Workflow selection

| Task type            | Workflow                | Who starts it |
|----------------------|-------------------------|---------------|
| New feature          | `workflows/feature.md`  | Planner       |
| Bug fix              | `workflows/bugfix.md`   | Planner       |
| Code review          | `workflows/review.md`   | Reviewer      |
| Refactor             | `workflows/refactor.md` | Architect     |
| Schema/data change   | `workflows/migration.md`| Architect     |
| Emergency fix        | `workflows/hotfix.md`   | Anyone + approval |
| Release              | `workflows/release.md`  | Release lead  |

## Agent lane assignment (suggested)

| Lane         | Strength                                     |
|--------------|----------------------------------------------|
| Planner      | Scope, risk, blockers                        |
| Architect    | API surface, data model, integration shape   |
| Implementer  | Code + tests, follow design exactly          |
| Reviewer     | Contract + regression validation             |
| Orchestrator | Sequencing, handoff, conflict resolution     |

Lanes are **roles**, not models. Any capable model (or human) can play a lane, provided they read the role file.
```

---

## Anti-chaos rules (enforce these)

```
NEVER:
- Refactor unrelated modules while implementing a feature
- Introduce new abstractions without architect approval
- Skip tests to ship faster
- Modify migrations retroactively
- Delete tests
- Rewrite top-level package structure mid-task
- Bypass API or schema contracts
- Ignore failure signals (circuit breakers, alerts, retries)
- Commit secrets
- Open a PR titled "WIP" or "temp"

ALWAYS:
- Run the commands in stack/commands.md before declaring done
- Update memory if architecture or decisions change
- Check active-tasks.md for blockers before starting
- Document non-obvious code in comments
- Include any required schema/migration step in the PR
- Document breaking changes in release notes
- Validate against contracts before merging
```

---

## How to clone this architecture into a new repo

1. Run `scripts/init-workspace.sh` (see `QUICK_START_30MIN.md`) — it creates the entire `.ai/` skeleton + `AGENTS.md`.
2. Fill in `.ai/stack/profile.md`, `commands.md`, `conventions.md` (≈10 minutes).
3. Add the first ADR or two to `.ai/memory/decisions.md`.
4. Start tracking work in `.ai/memory/active-tasks.md`.
5. Point your agents at `AGENTS.md`. They are now coordinated.

The same architecture, the same agent rules, the same handoff protocol — but now bound to **your** stack via the adapter.

---

## Conclusion

A good workspace is:

- **Deterministic** — same input, same output (no chaos from creativity).
- **Traceable** — every decision recorded in memory.
- **Enforceable** — contracts + rules + active-task tracking prevent conflicts.
- **Stack-portable** — only `.ai/stack/` changes between repos. The rest is reusable.

This is what turns "multiple chatbots pointing at files" into a coordinated engineering organisation that you can re-use on every project you start.
