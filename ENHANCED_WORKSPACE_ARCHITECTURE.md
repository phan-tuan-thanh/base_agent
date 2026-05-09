# Enhanced multi-agent workspace architecture

## Why this matters

The original architecture was solid. But real-world projects have:
- **Concurrent tasks** — multiple agents working on different features at same time
- **Shared state conflicts** — "who owns this file?"
- **Context drift** — Architect forgets planner's constraints
- **Task dependencies** — Feature A blocks Feature B
- **Integration complexity** — IBM BPM + Kubernetes + React

This document adds **state management** + **conflict prevention** + **handoff protocols**.

## Core principle

A workspace is not just files + prompt. It's:

```
Deterministic Workflow + Enforced Contracts + Shared Operational Memory
```

NOT: "call Planner → call Architect → call Impl → pray they're consistent"

---

## Architecture layers

### Layer 1: Rules (static, immutable)

Rules are **context-independent** guidelines that don't change during a sprint.

```
.ai/rules/
├── global/
│   ├── security.md          # never bypass auth, never hardcode secrets
│   ├── performance.md       # no N+1 queries, paginate >1k items
│   ├── architecture.md      # core principles (microservices, API patterns)
│   └── anti-patterns.md     # things we explicitly forbid
├── backend/
│   ├── java.md              # Spring Boot conventions
│   ├── sql.md               # query guards, migration safety
│   └── payment-module.md    # PCI-DSS rules specific to payment service
├── frontend/
│   ├── react.md             # hooks rules, component patterns
│   └── accessibility.md     # WCAG 2.1 AA minimum
├── ibm-bpm/
│   ├── process-design.md    # BPD snapshot safety
│   ├── coach-compat.md      # coach version matrix
│   └── deployment.md        # merge + deploy order
└── devops/
    ├── k8s.md               # resource requests, pod disruption budgets
    ├── terraform.md         # state file safety
    └── secrets.md           # Sealed Secrets pattern
```

**Key**: Rules are loaded at start. Agent says "follow rules/global/* + rules/backend/*" once.

### Layer 2: Shared memory (evolving, agent-curated)

Memory is **state that changes** as the project evolves. All agents read it before every action.

```
.ai/memory/
├── architecture.md          # current system structure (tech stack, domains, data models)
├── decisions.md             # ADRs: why we chose X not Y
├── coding-style.md          # patterns the codebase actually uses
├── active-tasks.md          # state of work in progress + blockers
├── known-issues.md          # bugs + workarounds agents should know
├── sprint-context.md        # current sprint goals, OKRs
└── integration-map.md       # external services + contract versions
```

**Why separate from rules**: Architecture changes mid-sprint (we discovered a better pattern). Decisions evolve (new requirement invalidates old choice). Active-tasks are *always* changing.

**Golden rule**: If an agent discovers something important, it **must update memory.md**. Not in comments. Not in PR description. In the shared file.

### Layer 3: Workflows (task-specific execution paths)

Each workflow defines **steps + validation gates** for a specific task type.

```
.ai/workflows/
├── feature.md               # new feature: plan → design → implement → test → merge
├── bugfix.md                # bug: reproduce → root cause → minimal fix → regression test
├── review.md                # code review: checklist + approval gates
├── refactor.md              # refactoring: scope limit + no behavioral changes
├── hotfix.md                # emergency: minimal scope, no big changes
├── migration.md             # data migration: rollback safety, canary first
└── release.md               # release: versioning, notes, announcement
```

**Workflow = a shared recipe**. All agents follow the same flow for the same task type. No surprises.

### Layer 4: Contracts (output guarantees)

Contracts ensure **all agent outputs look the same**, regardless of which agent produced them.

```
.ai/contracts/
├── output-format.md         # all deliverables must include: Summary | Changed files | Risks | Tests | Next steps
├── pr-checklist.md          # PR must: pass tests, update memory, document breaking changes
├── commit-policy.md         # commit format + squash rules
├── api-design.md            # REST/gRPC patterns + versioning
├── design-doc.md            # template for architecture proposals
└── test-coverage.md         # minimum 80%, specific domains need 90%+
```

**Why**: Contracts prevent agents from inventting their own standards. One format works everywhere.

### Layer 5: Agent adapters (agent-specific behavior)

Each agent type gets specialized rules for its strengths/weaknesses.

```
.ai/agents/
├── claude.md                # Claude-specific: reasoning, refactoring, architecture
├── gemini.md                # Gemini-specific: repo understanding, code gen, scale
├── codex.md                 # Codex/GPT-4-specific: precise implementation
└── orchestrator.md          # rules for agent-to-agent handoff
```

Example Claude rule:
```
DO NOT:
- refactor unrelated files while implementing a feature
- introduce new abstractions unless requested
- split files unless necessary for circular imports
- make architectural changes mid-implementation

DO:
- question whether a feature aligns with architecture
- stop if you find a conflicting decision
- defer to active-tasks.md for context
- ask for clarification before implementing
```

Example Gemini rule:
```
DO NOT:
- hallucinate import paths
- assume file structure without checking
- generate code in unfamiliar frameworks without repo analysis

DO:
- verify file exists before referencing
- check framework version in package.json/pom.xml
- search similar patterns in codebase
- ask if you're unsure about architecture
```

---

## Critical: State management via active-tasks.md

This is the **single source of truth for work in progress**.

```markdown
# Sprint active tasks

## FEAT-042: Payment retry logic

Status: In Progress (Impl stage)
Owner: Claude
Start date: 2025-05-09
Blocks: FEAT-043 (invoice generation)
Blocked by: INFRA-18 (Kafka SSL cert)

### Task breakdown
- [ ] Planner: determine retry strategy (exponential backoff? fixed delay?)
- [x] Architect: design retry service API + state machine
- [ ] Impl: code retry handler (50% done — request de-dup in progress)
- [ ] QA: regression on transaction ledger
- [ ] Merge: approved, waiting for INFRA-18

### Files touched
- services/payment/retry-handler.java
- services/payment/state-machine.java
- migration/002_add_retry_state.sql
- test/payment/RetryServiceTest.java

### Risks
- Kafka delivery semantics: at-most-once vs at-least-once?
  → DECISION: use at-least-once + idempotency key
- Retry storm if circuit breaker fails?
  → MITIGATION: max 5 retries over 24h, exponential backoff

### Dependencies
- INFRA-18: SSL cert provisioning (ETA: 2025-05-12)
- decisions.md#Idempotency-strategy

### Next agent (when Impl finishes)
→ QA: regression test on transaction ledger + double-charge scenario

---

## BUGFIX-18: Duplicate order emails

Status: In Review
Owner: Gemini
Root cause: ORDER_CREATED event fired twice, webhook retried

### Task breakdown
- [x] Reproduce: script in test/bugfix/order-email-dup.sh
- [x] Root cause: missing dedup in ORDER_CREATED handler
- [x] Impl: add idempotency key to webhook
- [ ] Test: reproduce scenario, verify no duplicates
- [ ] Merge: PR #1247

### Risks
- Rollback: old orders without idempotency key won't dedupe retroactively
  → accept: only new orders after deploy get protection

---
```

**Why this matters**:
1. **No surprises** — Planner knows what Architect is doing
2. **Blockers visible** — FEAT-042 blocks FEAT-043, don't start both simultaneously
3. **Dependencies tracked** — if INFRA-18 fails, FEAT-042 is doomed
4. **Risk management** — Kafka semantics, transaction safety, rollback strategy documented
5. **Agent handoff** — next agent knows exactly where previous one left off

---

## Multi-agent orchestration workflow

### Choreography (simple, <3 agents)

Agents work **in sequence**, each waits for the previous one.

```
Planner writes plan → Architect reads plan, designs → Impl reads design, codes
       ↑                                                      ↓
       └──────────── Both read shared memory ─────────────────
```

### Orchestration (complex, 4+ agents)

One agent **coordinates** — the Orchestrator.

```
Orchestrator:
  1. Load active-tasks.md
  2. Assign Planner task X
  3. Wait for Planner output
  4. Assign Architect task X
  5. Assign Impl task X (can run in parallel if independent)
  6. Assign QA task X
  7. Validate outputs vs contracts
  8. Merge results into memory
  9. Mark task done
```

**For your case**: Use orchestration with Planner → Architect → Impl → QA lanes running sequentially within a task.

---

## Context pruning (token efficiency)

Large repos = large context = slow + expensive.

**Principle**: Load only what agent needs for this task.

Agent loads rules as:
1. `rules/global/*` — always (security, performance, architecture)
2. `rules/{domain}/*` — if touching that domain (backend, frontend, ibm-bpm)
3. `workflows/{type}.md` — if executing that workflow
4. `contracts/*` — always (all outputs must follow contracts)
5. `memory/*` — only relevant entries (not all of memory!)

Example: Impl agent for Java backend feature loads:
```
rules/global/security.md
rules/global/performance.md
rules/backend/java.md
rules/backend/sql.md
rules/backend/payment-module.md (if touching payment)
workflows/feature.md
contracts/output-format.md
contracts/test-coverage.md
memory/architecture.md (Java stack section only)
memory/decisions.md (backend decisions only)
memory/active-tasks.md (current task only)
```

NOT:
- `rules/frontend/*` (not relevant)
- `memory/sprint-context.md` (full file not needed)
- Past completed tasks in active-tasks.md

---

## Conflict prevention

### Conflict #1: Two agents modifying same file

**Prevention**: active-tasks.md tracks "files touched"

```markdown
FEAT-042 → payment-retry-handler.java
FEAT-043 → invoice-generator.java (imports from payment-retry-handler)

FEAT-043 blocked by FEAT-042 (same file, dependency)
```

**Rule**: Don't start FEAT-043 until FEAT-042 is merged.

### Conflict #2: Architectural disagreement

**Example**: 
- Planner says "add caching layer"
- Architect says "caching violates decision ADR-005 (single source of truth)"

**Prevention**: decisions.md is **explicit**:

```markdown
## ADR-005: Single source of truth pattern

Status: Accepted
Date: 2025-04-15

### Decision
No client-side or server-side caching for critical business data (orders, payments, users).

### Reason
- Reduce complexity of cache invalidation
- Simplify audit trail (always fresh data)
- PCI-DSS compliance (payments always verified)

### Consequence
Higher DB load. Mitigation: use read replicas, indexed queries, pagination.

### Who disagrees
None (consensus from team).
```

Architect checks decisions.md first. If caching violates ADR-005, design rejects it.

### Conflict #3: Code style mismatch

**Prevention**: coding-style.md documents actual patterns

```markdown
# Java patterns we use

## Dependency injection
✓ Spring @Autowired on field
✗ Constructor injection (legacy, being phased out)

## Error handling
✓ Custom exceptions + try-catch
✓ @ControllerAdvice for HTTP mapping
✗ Checked exceptions in service layer

## Testing
✓ JUnit 5 + Mockito
✓ @DataJpaTest for repo tests
✗ H2 in-memory (use Testcontainers + real DB)
```

Agent sees this, follows it. No "wait, why is this different style?"

---

## Example: FEAT-042 workflow (payment retry)

### 1. Planner stage

**Input**: Issue "Add retry logic for payment failures"

**Planner reads**:
- `rules/global/*` — security, performance, architecture
- `rules/backend/payment-module.md` — payment rules
- `workflows/feature.md` — feature workflow
- `memory/decisions.md` — check ADR-004 (idempotency)
- `memory/active-tasks.md` — any blockers?

**Planner decides**:
- Retry strategy: exponential backoff (3 retries, 1s/2s/4s delays)
- API changes: none (internal service)
- Database: add `retry_state` column
- Files to touch: 5 files (handler, state machine, test, migration, config)
- Risks: Kafka delivery semantics (must be idempotent)

**Planner output** (contract):
```markdown
## Summary
Add automatic retry logic for failed payment processing with exponential backoff.

## Changed files
- services/payment/retry-handler.java (new)
- services/payment/state-machine.java (new)
- migration/002_add_retry_state.sql (new)
- test/payment/RetryServiceTest.java (new)
- docker/docker-compose.yml (Kafka version upgrade to 3.6)

## Risks
- Kafka consumer group rebalancing could cause message loss
  → Mitigation: use exactly-once semantics + offset management
- Retry storm if circuit breaker fails
  → Mitigation: cap at 5 retries, exponential backoff

## Next steps
1. Architect: design retry state machine
2. Architect: design API for idempotency key
3. Impl: implement + integrate with payment handler
```

**Updates memory**:
- `active-tasks.md#FEAT-042` — marks Planner stage ✓
- `memory/decisions.md` — adds note: "Use idempotency keys for retry safety"

### 2. Architect stage

**Input**: Planner's plan

**Architect reads**:
- Planner's output (plan above)
- `rules/backend/payment-module.md`
- `memory/architecture.md` — current payment service design
- `memory/decisions.md` — idempotency strategy
- `contracts/api-design.md` — REST patterns
- `contracts/design-doc.md` — template for design

**Architect decides**:
- State machine: `PENDING → RETRYING → SUCCESS | FAILED`
- Idempotency: UUID generated by caller, stored in `payments.idempotency_key`
- API: `POST /payments/{id}/retry` (admin only, role-based)
- Database schema: add `idempotency_key (UUID, unique)` + `retry_count (int)`
- Kafka: subscribe to `payment-failed` events, emit `payment-retrying` + `payment-succeeded/failed`
- Circuit breaker: Hystrix with 5s timeout, 50% failure threshold

**Architect output** (contract):
```markdown
## Summary
State machine-based retry handler with idempotency guarantees.

## Design diagram
[ASCII or Mermaid diagram of state transitions]

## Database schema changes
```sql
ALTER TABLE payments ADD COLUMN idempotency_key UUID UNIQUE;
ALTER TABLE payments ADD COLUMN retry_count INT DEFAULT 0;
ALTER TABLE payments ADD COLUMN last_retry_at TIMESTAMP;
```

## API design
POST /payments/{id}/retry
Header: Authorization: Bearer {token}
Body: { "idempotency_key": "uuid" }
Response: { "status": "retrying", "retry_count": 1 }

## Risks
- Race condition: two retry requests with same UUID
  → Mitigation: database unique constraint + optimistic locking

## Tests to write
- State machine transitions (all paths)
- Idempotency (duplicate request returns same result)
- Circuit breaker behavior (50% failures trigger open state)
```

**Updates memory**:
- `active-tasks.md#FEAT-042` — marks Architect stage ✓
- `memory/architecture.md` — adds retry service to payment domain

### 3. Implementation stage

**Input**: Architect's design doc

**Impl reads**:
- Architect's design (above)
- `contracts/output-format.md` — PR must include Summary, Tests, Migration
- `contracts/test-coverage.md` — 80% min (payment module needs 90%)
- `memory/coding-style.md` — Java patterns to follow

**Impl codes**:
```java
// services/payment/RetryHandler.java
@Service
public class RetryHandler {
  private static final int MAX_RETRIES = 5;
  private static final int[] BACKOFF_MS = {1000, 2000, 4000, 8000, 16000};
  
  @CircuitBreaker(name = "payment-processor", ...)
  public void retryPayment(Payment payment) {
    if (payment.getRetryCount() >= MAX_RETRIES) {
      publish(PaymentFailedEvent.of(payment));
      return;
    }
    
    int delay = BACKOFF_MS[payment.getRetryCount()];
    scheduledExecutor.schedule(() -> {
      processPayment(payment);
    }, delay, TimeUnit.MILLISECONDS);
  }
}
```

**Impl writes tests**:
```java
@Test
void testIdempotencyKey() {
  Payment p1 = retry(payment, "uuid-1");
  Payment p2 = retry(payment, "uuid-1");
  
  assertThat(p1.getRetryCount()).isEqualTo(p2.getRetryCount());
  assertThat(events).containsExactly(PaymentRetryingEvent);
}

@Test
void testExponentialBackoff() {
  // verify delays: 1s, 2s, 4s, 8s, 16s
}

@Test
void testCircuitBreakerOpens() {
  // 50% failures → circuit opens
}
```

**Impl output** (contract):
```markdown
## Summary
Implemented exponential backoff retry handler with circuit breaker.

## Changed files
- services/payment/retry-handler.java (+120 lines)
- test/payment/RetryHandlerTest.java (+180 lines)
- migration/002_add_retry_state.sql (+2 columns)

## Coverage
- RetryHandler: 92% (exceeds 90% requirement)
- All state machine paths covered

## Risks
- Existing payments without idempotency_key won't retry
  → Mitigation: migration adds key as UUID v4 for past records

## Tests
- All tests pass (TestRetryHandler, TestCircuitBreaker)
- Regression test on order payment flow: ✓

## Migration
Run migration/002_add_retry_state.sql on all environments.
```

**Updates memory**:
- `active-tasks.md#FEAT-042` → Impl complete, mark QA stage
- `memory/active-tasks.md` → "Waiting for QA approval"

### 4. QA stage

**Input**: Impl's PR

QA runs contract validation:
- Tests pass? ✓ (92% coverage > 80% requirement)
- Files match design? ✓ (only payment retry files touched)
- Risks addressed? ✓ (circuit breaker tested, migration safe)
- Memory updated? ✓ (active-tasks.md updated)

QA approves. Task merged to main.

**Updates memory**:
- `active-tasks.md#FEAT-042` → Merged ✓
- Remove from "in progress", add to "recently completed"

---

## Rules for conflict-free multi-agent work

### 1. One agent = one lane

Planner doesn't implement. Architect doesn't code. Impl doesn't design.

Clear separation = clear accountability.

### 2. active-tasks.md is the coordination device

Before you start: check active-tasks.md.
- Is this task already assigned? Don't duplicate.
- Does it block me? Marked as blocked.
- Do I have all dependencies? Check "blocked by".

After you finish: update active-tasks.md.
- Mark your stage complete.
- Add risks you discovered.
- Note the next agent.

### 3. Decisions are immutable (except by consensus)

If you disagree with a decision (ADR-005), don't work around it.
- Comment in memory/decisions.md: "This violates ADR-005, I think we should..."
- Wait for team consensus.
- Only then change the ADR.

### 4. Memory is not optional

If Planner discovers: "Kafka must use exactly-once semantics"
→ Add to memory/decisions.md immediately

If Impl discovers: "Payment retry needs circuit breaker"
→ Add to memory/known-issues.md (and risk note in active-tasks)

If Architect discovers: "Our REST API pattern is outdated"
→ Update memory/architecture.md + propose ADR

### 5. Contracts prevent style wars

All outputs follow `contracts/output-format.md`. No debates about "should PR include risks?" — answer is in the contract.

---

## For IBM BPM projects specifically

Add to rules:

```
.ai/rules/ibm-bpm/
├── snapshot-safety.md
├── coach-compatibility.md
├── deployment-order.md
└── integration-safety.md
```

Example rule:
```markdown
# Snapshot safety

DO NOT:
- Modify snapshot directly (use tracks)
- Deploy snapshot without merging tracks
- Rename integration service IDs

DO:
- Always merge all tracks before deploy
- Test coach compatibility with target version
- Use version matrix in memory/architecture.md
- Document breaking changes in decisions.md
```

Add to active-tasks.md for BPM work:
```markdown
## PROC-015: Update order processing BPD

Status: In Progress (Impl stage)

### IBM BPM specifics
- BPD snapshot ID: ord_proc_001
- Coach version: 2.7.1 → 3.0.0 (breaking changes!)
- Deployed on: 8.6 Fix Pack 15
- Tracks merged: Yes (team lead approved)

### Compatibility risks
- Coach 3.0 renamed ButtonWidget → Button (requires coach rebuild)
- Integration service OrderService requires Java 11 (cluster has 8, need upgrade)

### Deployment checklist
- [ ] Coach rebuild on 3.0 tooling
- [ ] Test on dev environment
- [ ] Run integration test suite
- [ ] Backup current BPD
- [ ] Deploy to staging, smoke test
- [ ] Deploy to prod (maintenance window: Sat 02:00 UTC)
```

---

## How to clone this architecture

1. **Copy .ai/ directory structure** from this guide
2. **Populate rules/** with your domain-specific rules
3. **Start with skeleton memory/**:
   - `architecture.md` — describe your tech stack
   - `decisions.md` — list your ADRs
   - `coding-style.md` — document patterns you use
   - `active-tasks.md` — start with no tasks (fill as work begins)
4. **Define contracts/** — what does a good PR look like?
5. **Write workflows/** — how does your team work?
6. **Create AGENTS.md** — entry point that loads everything in order

---

## Recommended AGENTS.md entry point

```markdown
# Workspace AI Operating System

## Mandatory loading order

1. .ai/rules/global/* — all agents load
2. .ai/contracts/* — enforce output guarantees
3. .ai/rules/{domain}/* — if working in that domain
4. .ai/workflows/{type}.md — if executing that workflow
5. .ai/memory/* — shared context (relevant entries only)
6. .ai/agents/{your-agent}.md — agent-specific rules

## Core rules (never break these)

- **Never modify unrelated files** — if implementing Feature A, don't refactor Module B
- **Always run tests** — no commit without green tests
- **Update memory if architecture changes** — shared understanding is everything
- **Follow contracts strictly** — all outputs have same format
- **Check active-tasks.md first** — avoid duplicate work

## Workflow selection

| Task type | Workflow | Who starts it |
|-----------|----------|---------------|
| New feature | workflows/feature.md | Planner |
| Bug fix | workflows/bugfix.md | Planner |
| Code review | workflows/review.md | Reviewer |
| Refactor | workflows/refactor.md | Architect |
| Database migration | workflows/migration.md | Architect |
| Emergency fix | workflows/hotfix.md | Any + approval |
| Release | workflows/release.md | Release lead |

## Memory sources (load in order)

1. `memory/architecture.md` — current system design
2. `memory/decisions.md` — why we chose X, not Y
3. `memory/active-tasks.md` — work in progress + blockers
4. `memory/known-issues.md` — bugs, workarounds, gotchas
5. `memory/coding-style.md` — patterns the codebase uses
6. `memory/sprint-context.md` — current goals, deadlines
7. `memory/integration-map.md` — external services + versions

## For multi-agent projects

Recommended agent lane assignment:

| Agent | Best for | Why |
|-------|----------|-----|
| Claude | Architecture, refactoring, design review, hard problems | Strong reasoning, anti-over-engineering |
| Gemini | Repo exploration, code generation, large-scale changes | Long context, search/nav capability |
| Codex/GPT-4 | Precise implementation, workflow execution, tests | Reliable on standard patterns |
| Human | Final review, decision-making, conflict resolution | No substitute for judgment |

See .ai/agents/ for agent-specific rules.

---

## Anti-chaos rules (ENFORCE THESE)

```
NEVER:
- Refactor unrelated modules while implementing feature
- Introduce new abstraction without architect approval
- Skip tests to ship faster
- Modify migrations retroactively
- Delete tests
- Rewrite package structure
- Bypass API contracts
- Ignore circuit breaker failures
- Commit secrets (API keys, passwords)
- Name a PR "WIP" or "temp" — be descriptive

ALWAYS:
- Run tests before commit
- Update memory if architecture changes
- Check active-tasks.md for blockers
- Write comments for non-obvious code
- Include migration script in PR
- Document breaking changes in release notes
- Get code review from 2nd pair of eyes
- Validate against contracts before merging
```

---

## Conclusion

A good workspace is:

- **Deterministic**: same input → same output (no chaos from creativity)
- **Traceable**: every decision recorded (in memory)
- **Enforceable**: contracts + rules + active-task tracking prevent conflicts
- **Scalable**: 2 agents or 20, same structure works

This is what transforms "multiple chatbots pointing at files" into "coordinated engineering organization."
