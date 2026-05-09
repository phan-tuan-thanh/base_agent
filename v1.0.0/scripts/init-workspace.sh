#!/usr/bin/env bash
# init-workspace.sh — bootstrap the multi-agent workspace OS into any repo.
#
# Usage:
#   ./init-workspace.sh           # bootstrap current directory
#   ./init-workspace.sh /path     # bootstrap given directory
#
# Behaviour:
#   - Creates .ai/ skeleton (rules, memory, workflows, contracts, agents, stack)
#   - Auto-detects the stack from manifest files and pre-fills stack/profile.md + stack/commands.md
#   - Writes AGENTS.md, CLAUDE.md, GEMINI.md at repo root
#   - Idempotent: existing files are skipped (never overwritten)
#
# No external dependencies beyond bash + standard POSIX utilities.

set -euo pipefail

ROOT="${1:-$(pwd)}"
ROOT="$(cd "$ROOT" && pwd)"

# ---------- helpers ----------------------------------------------------------

log()  { printf '  %s\n' "$*"; }
info() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
skip() { printf '\033[2mskip:\033[0m %s\n' "$*"; }

write_file() {
    # write_file <relative-path> <heredoc-content-via-stdin>
    # Skips if file already exists (idempotent).
    local rel="$1"
    local abs="$ROOT/$rel"
    local dir
    dir="$(dirname "$abs")"
    mkdir -p "$dir"
    if [ -e "$abs" ]; then
        skip "$rel"
        cat >/dev/null    # drain stdin
        return 0
    fi
    cat >"$abs"
    ok "$rel"
}

ensure_dir() {
    local rel="$1"
    mkdir -p "$ROOT/$rel"
}

# ---------- stack detection --------------------------------------------------

DETECTED_STACK=()
DETECTED_TAGS=()
CMD_INSTALL=""
CMD_BUILD=""
CMD_TEST=""
CMD_LINT=""
CMD_FORMAT=""
CMD_RUN=""

detect_stack() {
    # Languages / frameworks
    if [ -f "$ROOT/package.json" ]; then
        DETECTED_STACK+=("Node.js / JavaScript / TypeScript")
        if [ -f "$ROOT/pnpm-lock.yaml" ]; then
            CMD_INSTALL="pnpm install"
            CMD_BUILD="pnpm build"
            CMD_TEST="pnpm test"
            CMD_LINT="pnpm lint"
            CMD_FORMAT="pnpm format"
            CMD_RUN="pnpm dev"
        elif [ -f "$ROOT/yarn.lock" ]; then
            CMD_INSTALL="yarn install"
            CMD_BUILD="yarn build"
            CMD_TEST="yarn test"
            CMD_LINT="yarn lint"
            CMD_FORMAT="yarn format"
            CMD_RUN="yarn dev"
        else
            CMD_INSTALL="npm install"
            CMD_BUILD="npm run build"
            CMD_TEST="npm test"
            CMD_LINT="npm run lint"
            CMD_FORMAT="npm run format"
            CMD_RUN="npm run dev"
        fi
    fi
    if [ -f "$ROOT/pyproject.toml" ] || [ -f "$ROOT/requirements.txt" ] || [ -f "$ROOT/setup.py" ]; then
        DETECTED_STACK+=("Python")
        if [ -f "$ROOT/pyproject.toml" ] && grep -q "tool.poetry" "$ROOT/pyproject.toml" 2>/dev/null; then
            CMD_INSTALL="poetry install"
            CMD_TEST="poetry run pytest"
            CMD_LINT="poetry run ruff check ."
            CMD_FORMAT="poetry run ruff format ."
            CMD_RUN="poetry run python -m <module>"
        elif [ -f "$ROOT/uv.lock" ] || ([ -f "$ROOT/pyproject.toml" ] && grep -q "tool.uv" "$ROOT/pyproject.toml" 2>/dev/null); then
            CMD_INSTALL="uv sync"
            CMD_TEST="uv run pytest"
            CMD_LINT="uv run ruff check ."
            CMD_FORMAT="uv run ruff format ."
            CMD_RUN="uv run python -m <module>"
        else
            CMD_INSTALL="pip install -r requirements.txt"
            CMD_TEST="pytest"
            CMD_LINT="ruff check ."
            CMD_FORMAT="ruff format ."
            CMD_RUN="python -m <module>"
        fi
    fi
    if [ -f "$ROOT/go.mod" ]; then
        DETECTED_STACK+=("Go")
        CMD_INSTALL="go mod download"
        CMD_BUILD="go build ./..."
        CMD_TEST="go test ./..."
        CMD_LINT="golangci-lint run"
        CMD_FORMAT="gofmt -w ."
        CMD_RUN="go run ./cmd/..."
    fi
    if [ -f "$ROOT/Cargo.toml" ]; then
        DETECTED_STACK+=("Rust")
        CMD_INSTALL="cargo fetch"
        CMD_BUILD="cargo build"
        CMD_TEST="cargo test"
        CMD_LINT="cargo clippy --all-targets -- -D warnings"
        CMD_FORMAT="cargo fmt"
        CMD_RUN="cargo run"
    fi
    if [ -f "$ROOT/pom.xml" ]; then
        DETECTED_STACK+=("Java / Maven")
        CMD_INSTALL="mvn dependency:resolve"
        CMD_BUILD="mvn compile"
        CMD_TEST="mvn test"
        CMD_LINT="mvn spotless:check || mvn checkstyle:check"
        CMD_FORMAT="mvn spotless:apply"
        CMD_RUN="mvn spring-boot:run"
    elif [ -f "$ROOT/build.gradle" ] || [ -f "$ROOT/build.gradle.kts" ]; then
        DETECTED_STACK+=("Java / Kotlin / Gradle")
        CMD_INSTALL="./gradlew dependencies"
        CMD_BUILD="./gradlew build"
        CMD_TEST="./gradlew test"
        CMD_LINT="./gradlew check"
        CMD_FORMAT="./gradlew spotlessApply"
        CMD_RUN="./gradlew run"
    fi
    if [ -f "$ROOT/Gemfile" ]; then
        DETECTED_STACK+=("Ruby")
        CMD_INSTALL="bundle install"
        CMD_TEST="bundle exec rspec"
        CMD_LINT="bundle exec rubocop"
        CMD_FORMAT="bundle exec rubocop -a"
    fi
    if [ -f "$ROOT/composer.json" ]; then
        DETECTED_STACK+=("PHP")
        CMD_INSTALL="composer install"
        CMD_TEST="vendor/bin/phpunit"
        CMD_LINT="vendor/bin/phpstan analyse"
        CMD_FORMAT="vendor/bin/php-cs-fixer fix"
    fi
    if [ -f "$ROOT/mix.exs" ]; then
        DETECTED_STACK+=("Elixir")
        CMD_INSTALL="mix deps.get"
        CMD_BUILD="mix compile"
        CMD_TEST="mix test"
        CMD_LINT="mix credo"
        CMD_FORMAT="mix format"
    fi
    if [ -f "$ROOT/Package.swift" ]; then
        DETECTED_STACK+=("Swift")
        CMD_BUILD="swift build"
        CMD_TEST="swift test"
        CMD_FORMAT="swift-format -i -r ."
    fi
    if [ -f "$ROOT/pubspec.yaml" ]; then
        DETECTED_STACK+=("Dart / Flutter")
        CMD_INSTALL="flutter pub get"
        CMD_BUILD="flutter build"
        CMD_TEST="flutter test"
        CMD_LINT="flutter analyze"
        CMD_FORMAT="dart format ."
    fi
    if compgen -G "$ROOT/*.csproj" >/dev/null || compgen -G "$ROOT/*.sln" >/dev/null; then
        DETECTED_STACK+=(".NET")
        CMD_INSTALL="dotnet restore"
        CMD_BUILD="dotnet build"
        CMD_TEST="dotnet test"
        CMD_FORMAT="dotnet format"
    fi

    # Infra signals (added as tags; do not override commands)
    [ -f "$ROOT/Dockerfile" ] && DETECTED_TAGS+=("docker")
    compgen -G "$ROOT/*.tf" >/dev/null && DETECTED_TAGS+=("terraform")
    [ -d "$ROOT/helm" ] && DETECTED_TAGS+=("helm")
    [ -d "$ROOT/k8s" ] || [ -d "$ROOT/kubernetes" ] && DETECTED_TAGS+=("kubernetes")
    [ -d "$ROOT/.github/workflows" ] && DETECTED_TAGS+=("github-actions")

    if [ ${#DETECTED_STACK[@]} -eq 0 ]; then
        DETECTED_STACK+=("Unknown / generic")
    fi
}

join_comma() {
    # join_comma item1 item2 …  → "item1, item2, …"
    local first=1 item
    for item in "$@"; do
        if [ $first -eq 1 ]; then
            printf '%s' "$item"
            first=0
        else
            printf ', %s' "$item"
        fi
    done
}

stack_summary() {
    join_comma "${DETECTED_STACK[@]}"
}

tags_summary() {
    if [ ${#DETECTED_TAGS[@]} -eq 0 ]; then
        printf 'none'
    else
        join_comma "${DETECTED_TAGS[@]}"
    fi
}

# ---------- skeleton ---------------------------------------------------------

create_skeleton() {
    info "Creating .ai/ skeleton in $ROOT"
    ensure_dir ".ai/rules/global"
    ensure_dir ".ai/rules/domain"
    ensure_dir ".ai/memory"
    ensure_dir ".ai/workflows"
    ensure_dir ".ai/contracts"
    ensure_dir ".ai/contracts/artifacts"
    ensure_dir ".ai/agents"
    ensure_dir ".ai/stack"
    ensure_dir ".ai/examples"
}

# ---------- file content (heredocs) ------------------------------------------

write_global_rules() {
    write_file ".ai/rules/global/security.md" <<'EOF'
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
- Hash passwords with a memory-hard algorithm (Argon2 / bcrypt / scrypt).
- Apply least-privilege to data access (RBAC / ABAC).
- Add an audit trail for sensitive mutations (who, what, when).

## PR checklist
- [ ] No credentials in code or commit history.
- [ ] No injection vectors (SQL, shell, template, deserialization).
- [ ] Transport secured.
- [ ] Rate limiting on externally-reachable endpoints.
- [ ] Error messages do not leak system internals.
- [ ] Logs exclude sensitive fields.
EOF

    write_file ".ai/rules/global/performance.md" <<'EOF'
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
EOF

    write_file ".ai/rules/global/architecture.md" <<'EOF'
# Global architecture principles (any stack)

- Single responsibility per module / package / service.
- One public entry point per module; internals stay internal.
- Side effects at the edge; pure logic in the core.
- Explicit dependencies (injected, not imported globally).
- Backwards-compatible changes by default; breaking changes require an ADR.
- Document non-obvious decisions in `.ai/memory/decisions.md`.
EOF

    write_file ".ai/rules/global/anti-patterns.md" <<'EOF'
# Forbidden patterns (any stack)

- "God object" / module that knows about everything.
- Catch-all `try { … } catch { /* swallow */ }` blocks.
- Magic numbers without a named constant + comment.
- Cyclic imports / cyclic module dependencies.
- Copy-paste code across more than two call sites (extract instead).
- Reaching into a module's private internals.
- Time / randomness / I/O hardcoded inside pure logic (inject them).
- Tests that depend on wall-clock time, network reachability, or test execution order.
EOF

    write_file ".ai/rules/domain/_README.md" <<'EOF'
# Domain rules

Add one file per domain you actually have. Examples:
- backend.md
- frontend.md
- mobile.md
- data.md
- infra.md

Keep each file focused on the rules that only apply within that domain. Anything universal belongs in `../global/`.
EOF
}

write_contracts() {
    write_file ".ai/contracts/output-format.md" <<'EOF'
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

Missing any section = contract violation. Reviewer rejects the deliverable.
EOF

    write_file ".ai/contracts/pr-checklist.md" <<'EOF'
# PR checklist

- [ ] Output-format contract satisfied (Summary, Changed files, Risks, Tests, Next steps).
- [ ] All commands in `stack/commands.md` were run (build, lint, test).
- [ ] Coverage threshold met (see `contracts/test-coverage.md`).
- [ ] No unrelated files modified.
- [ ] Memory updated where relevant.
- [ ] Breaking changes flagged in PR title and release notes.
- [ ] No secrets in diff or commit history.
EOF

    write_file ".ai/contracts/test-coverage.md" <<'EOF'
# Test coverage contract

| Area                                 | Minimum coverage |
|--------------------------------------|------------------|
| Default (any new module)             | 80%              |
| Security-sensitive code              | 90%              |
| Money / billing / auth / data loss   | 95%              |
| Pure utilities                       | 100%             |

Tests must exercise: happy path, every error branch, and every external boundary with realistic fixtures.
EOF

    write_file ".ai/contracts/api-design.md" <<'EOF'
# API design contract (transport-agnostic)

Applies to HTTP, gRPC, message queues, CLIs, and library exports.

- Naming: verbs for actions, nouns for resources, consistent casing.
- Versioning: explicit (`/v1/`, `package@1.x`, queue topic `…-v1`). Never break v1 silently.
- Errors: typed and stable. Document each error code / shape.
- Pagination: cursor-based for unbounded collections; never `LIMIT`-less list endpoints.
- Idempotency: every state-changing operation accepts an idempotency key.
- Backwards compatibility: additive changes only without an ADR.
- Observability: each entry point emits a structured event with the request id.
EOF

    write_file ".ai/contracts/commit-policy.md" <<'EOF'
# Commit policy

Format:
```
<type>(<scope>): <subject>

<body — explain why, not what>

Refs: <ticket-id>
```

`<type>` is one of: feat, fix, refactor, perf, test, docs, chore, build.

Subject ≤ 72 chars, imperative mood, no trailing period.
Body wrapped at 100 chars. Reference the relevant task id when applicable.
EOF

    write_file ".ai/contracts/design-doc.md" <<'EOF'
# Design doc template

## Context
<problem, who is affected, constraints>

## Proposal
<the design in prose; diagrams welcome>

## Interface
<API surface, data model, events — whichever is relevant>

## Failure modes
<what can go wrong + how the design handles it>

## Migration / rollout
<how this gets deployed without breaking existing callers>

## Alternatives considered
- <option> — <why rejected>

## Open questions
<anything not yet decided>
EOF
}

write_workflows() {
    write_file ".ai/workflows/feature.md" <<'EOF'
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
EOF

    write_file ".ai/workflows/bugfix.md" <<'EOF'
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
EOF

    write_file ".ai/workflows/refactor.md" <<'EOF'
# Workflow: refactor

1. State the **scope** explicitly (which files, which behaviours stay identical).
2. Capture current behaviour in tests (if not already covered).
3. Refactor in small steps; tests stay green at every step.
4. No new features mixed in.
5. Review focuses on: scope respected, tests still meaningful, performance unchanged.
EOF

    write_file ".ai/workflows/migration.md" <<'EOF'
# Workflow: migration (data / schema / breaking change)

1. Design the migration as **additive then subtractive** (two phases).
2. Provide a rollback plan and verify it on staging data.
3. Run the additive phase under live traffic; observe for at least one full traffic cycle.
4. Run the subtractive phase only after all writers are on the new shape.
5. Document the migration in `architecture.md` and `decisions.md`.
EOF

    write_file ".ai/workflows/hotfix.md" <<'EOF'
# Workflow: hotfix

1. Confirm the incident is real and high-impact.
2. Branch from production tag, not main.
3. Smallest possible diff; one purpose only.
4. Two-person review (or two-agent + human approval).
5. Backport to main; record the incident in `known-issues.md`.
EOF

    write_file ".ai/workflows/release.md" <<'EOF'
# Workflow: release

1. Confirm `active-tasks.md` has no in-flight tasks blocking the release.
2. Generate release notes from merged PR titles.
3. Bump version per `commit-policy.md`.
4. Tag, build, deploy per `stack/commands.md` and the project's deploy doc.
5. Smoke-test in production / production-equivalent.
EOF

    write_file ".ai/workflows/review.md" <<'EOF'
# Workflow: review

1. Run `stack/commands.md` build/test/lint locally or verify CI green.
2. Walk `contracts/pr-checklist.md` line by line.
3. Confirm `active-tasks.md` reflects the work.
4. Reject (don't fix) any contract violation; producer fixes it.
5. Approve only when every section is satisfied.
EOF
}

write_memory() {
    write_file ".ai/memory/architecture.md" <<'EOF'
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
EOF

    write_file ".ai/memory/decisions.md" <<'EOF'
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
EOF

    write_file ".ai/memory/coding-style.md" <<'EOF'
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
See `.ai/contracts/commit-policy.md`.
EOF

    write_file ".ai/memory/active-tasks.md" <<'EOF'
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
EOF

    write_file ".ai/memory/known-issues.md" <<'EOF'
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
EOF

    write_file ".ai/memory/sprint-context.md" <<'EOF'
# Sprint context

## Sprint goal
<one-sentence outcome we are aiming for>

## Deadlines
- <YYYY-MM-DD>: <milestone>

## Out of scope
<things we will explicitly not do this sprint>
EOF

    write_file ".ai/memory/integration-map.md" <<'EOF'
# Integration map

| External system | Protocol / SDK | Version | Purpose | Owner |
|-----------------|----------------|---------|---------|-------|
| <name>          | <e.g. REST>    | <e.g. v2> | <what we use it for> | <team or person> |
EOF
}

write_agents() {
    # Only the template here. The 9 enterprise roles (BA, PO, Tech Lead,
    # Architect, Senior Dev, QA, DevOps, Scrum Master, Orchestrator) are
    # written by write_enterprise_roles().
    write_file ".ai/agents/_template.md" <<'EOF'
# Agent role: <ROLE>

## Mandate
<what this lane is responsible for>

## Inputs (load before acting)
- <files / sections>

## Outputs (produce these)
- <artifact 1 — must comply with contracts/output-format.md>
- <artifact 2>

## DO
- <behaviour 1>
- <behaviour 2>

## DO NOT
- <behaviour 1>
- <behaviour 2>

## Handoff
- Update `active-tasks.md` with stage ✓ and "Next agent → <role>".
- Append a handoff note in the canonical handoff format.
EOF
}

write_stack() {
    local stack_str tags_str
    stack_str="$(stack_summary)"
    tags_str="$(tags_summary)"

    write_file ".ai/stack/profile.md" <<EOF
# Stack profile

> Auto-detected by \`scripts/init-workspace.sh\`. Edit freely; values below are best guesses.

## What this repo is
<one paragraph: purpose, who uses it, what it produces>

## Detected stack
${stack_str}

## Infra signals
${tags_str}

## Languages & frameworks
- Primary language: <fill in>
- Runtime / version: <fill in>
- Major frameworks / libraries: <fill in>

## Persistence / external systems
- <e.g. PostgreSQL 15, Redis, S3, third-party API X>

## Build / test / run
See \`commands.md\`.

## Deploy target
<e.g. AWS Lambda, Kubernetes cluster, App Store, npm registry, none / library>

## Out of scope
<things this repo deliberately does NOT do, so agents don't drift>
EOF

    write_file ".ai/stack/commands.md" <<EOF
# Local commands

> Auto-filled by \`scripts/init-workspace.sh\` based on detected manifests.
> Verify and edit. Agents must use these exact commands.

| Action            | Command |
|-------------------|---------|
| Install deps      | ${CMD_INSTALL:-<fill in>} |
| Build             | ${CMD_BUILD:-<fill in>} |
| Run unit tests    | ${CMD_TEST:-<fill in>} |
| Run integration tests | <fill in> |
| Lint              | ${CMD_LINT:-<fill in>} |
| Type-check        | <fill in if applicable> |
| Format            | ${CMD_FORMAT:-<fill in>} |
| Start dev server  | ${CMD_RUN:-<fill in if applicable>} |

## Notes
- Do not invent new commands. If something is missing, add it here first.
- Prefer scripted entry points (\`make …\`, \`task …\`, npm scripts) over raw tool invocations when the repo has them.
EOF

    write_file ".ai/stack/conventions.md" <<'EOF'
# Repo conventions

## File layout
<top-level folders and what lives in each>

## Naming
- Files: <convention>
- Modules / packages: <convention>
- Tests: <convention>
- Branches: <convention>

## Dependency policy
<what may we add? who approves? are pinned versions required?>

## Test policy
<unit / integration / e2e split, fixtures, snapshots, when to mock vs use real>
EOF

    write_file ".ai/stack/glossary.md" <<'EOF'
# Domain glossary

> Define any jargon a new agent or contributor would not recognise.

| Term | Meaning |
|------|---------|
| <term> | <plain-English definition> |
EOF
}

write_root_files() {
    write_file "AGENTS.md" <<'EOF'
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

## Agent lane assignment (enterprise SDLC)

| Lane         | File                          | Owns                                                                |
|--------------|-------------------------------|---------------------------------------------------------------------|
| BA           | `.ai/agents/ba.md`            | Stage 2–3: clarification, BRD, functional spec                      |
| PO           | `.ai/agents/po.md`            | Stage 3: epic, user story, AC, prioritisation                       |
| Tech Lead    | `.ai/agents/tech-lead.md`     | Stage 4, 7: technical analysis, task breakdown, estimates           |
| Architect    | `.ai/agents/architect.md`     | Stage 5–6: design, API contract, ADRs, risk                         |
| Senior Dev   | `.ai/agents/senior-dev.md`    | Stage 9–10: code, unit tests                                        |
| QA           | `.ai/agents/qa.md`            | Stage 11: test cases, regression, automation, defects               |
| DevOps       | `.ai/agents/devops.md`        | Stage 13–14: deployment, rollback, runbook, prod-readiness          |
| Scrum Master | `.ai/agents/scrum-master.md`  | Stage 8: sprint plan, blockers, ceremonies-as-doc, traceability     |
| Orchestrator | `.ai/agents/orchestrator.md`  | Sequencing, handoff validation, conflict resolution                 |

Lanes are **roles**, not models. One model can play every lane (announce role at start of each response). For larger work, fan out to specialised agents — see `ENTERPRISE_SDLC_ORCHESTRATOR.md` Section 11.

## Enterprise mode

Paste `SYSTEM_PROMPT.md` (at repo root) as the model's system message to enable the full 15-stage SDLC pipeline (`.ai/workflows/sdlc-pipeline.md`), clarification gate (`.ai/workflows/clarification-gate.md`), production-readiness checklist (`.ai/contracts/production-readiness.md`), artifact catalogue (`.ai/contracts/artifacts/`), and command system (`.ai/commands.md`).
EOF

    write_file "CLAUDE.md" <<'EOF'
# Instructions for Claude

## Default lanes
Planner, Architect, Reviewer (also Implementer for tasks where Claude has the strongest fit).

## Before every task
1. Read `AGENTS.md`.
2. Load the files for your role from the mandatory loading order.
3. Check `.ai/memory/active-tasks.md` for blockers and duplicate work.
4. Load the workflow file for the task type.

## Output
Must comply with `.ai/contracts/output-format.md`: Summary, Changed files, Risks, Tests, Next steps.

## When you finish a stage
1. Update `.ai/memory/active-tasks.md` (mark stage ✓, set next agent).
2. Update `.ai/memory/decisions.md` if you discovered something worth an ADR.
3. Append a handoff note in the canonical format.
EOF

    write_file "GEMINI.md" <<'EOF'
# Instructions for Gemini

## Default lanes
Implementer (large-scale code generation, repo exploration, mechanical refactors).

## Before every task
1. Read `AGENTS.md`.
2. Load `.ai/stack/profile.md`, `.ai/stack/conventions.md`, `.ai/stack/commands.md`.
3. Read `.ai/memory/coding-style.md` (it is the source of truth for patterns).
4. Search the repo for similar examples before writing new code.

## Hard rules
- Verify every external symbol exists before using it (no hallucinated imports).
- Use only commands from `.ai/stack/commands.md`.
- Match `.ai/memory/coding-style.md` exactly.
- Run tests before declaring done.

## Output
Must comply with `.ai/contracts/output-format.md` and `.ai/contracts/pr-checklist.md`.
EOF
}

# ---------- enterprise SDLC layer --------------------------------------------

write_enterprise_roles() {
    write_file ".ai/agents/ba.md" <<'EOF'
# Agent role: Business Analyst (BA)

## Mandate
Make the requirement explicit and unambiguous before any design or code.

## Inputs
- Raw user request
- `.ai/stack/profile.md`, `.ai/memory/decisions.md`, `.ai/memory/integration-map.md`

## Outputs
- Clarification questions (Stage 2) using `.ai/workflows/clarification-gate.md`.
- BRD using `.ai/contracts/artifacts/brd.md` (Stage 3).
- Functional Spec using `.ai/contracts/artifacts/functional-spec.md` (Stage 4).
- Assumption list ASM-<id> in `active-tasks.md`.
- Requirement classification: MUST / SHOULD / NICE.

## DO
- Stop at MUST-HAVE gaps.
- Phrase questions in business language, not technical jargon.
- Surface conflicts with existing requirements explicitly.
- Record every assumption with an ID.

## DO NOT
- Choose technologies, libraries, or APIs.
- Estimate effort.
- Write code.
EOF

    write_file ".ai/agents/po.md" <<'EOF'
# Agent role: Product Owner (PO)

## Mandate
Translate clarified requirements into prioritised, testable units of work.

## Inputs
- BRD from BA
- `.ai/memory/sprint-context.md`

## Outputs
- Epic using `.ai/contracts/artifacts/epic.md`.
- User Story + Acceptance Criteria using `.ai/contracts/artifacts/user-story.md`.
- Prioritisation rationale (MoSCoW or RICE).
- Release-note draft (Stage 13) jointly with DevOps.

## DO
- Make every Acceptance Criterion verifiable (Given/When/Then).
- Sequence stories so each delivers user value standalone.
- Flag scope conflicts with sprint capacity early.

## DO NOT
- Do technical design.
- Override BA's MUST/SHOULD/NICE classification without recording the change.
EOF

    write_file ".ai/agents/tech-lead.md" <<'EOF'
# Agent role: Tech Lead

## Mandate
Convert stories into a buildable, estimated, dependency-aware plan that
respects existing architecture.

## Inputs
- User Stories from PO
- `.ai/memory/architecture.md`, `decisions.md`, `integration-map.md`
- `.ai/stack/conventions.md`, `commands.md`

## Outputs
- Technical impact analysis (Stage 4).
- Task Breakdown using `.ai/contracts/artifacts/task-breakdown.md` (Stage 7).
- Dependency Matrix using `.ai/contracts/artifacts/dependency-matrix.md`.
- Complexity estimates (Fibonacci) per task.
- Sprint plan input to Scrum Master.

## DO
- Identify cross-team or cross-service dependencies before sprint planning.
- Split tasks ≥ 13 points before they enter the sprint.
- Annotate tasks with `Touches:` files for conflict detection.

## DO NOT
- Author final ADRs (Architect owns).
- Skip dependency analysis on "small" stories.
EOF

    write_file ".ai/agents/architect.md" <<'EOF'
# Agent role: Architect

## Mandate
Design the system change end-to-end: API surface, data model, integrations,
failure modes, migration plan. Author ADRs for new principles.

## Inputs
- Stories + impact analysis
- `.ai/memory/architecture.md`, `decisions.md`
- `.ai/contracts/api-design.md`

## Outputs
- Technical Design using `.ai/contracts/artifacts/technical-design.md` (Stage 5).
- API Contract using `.ai/contracts/artifacts/api-contract.md`.
- DB Migration plan using `.ai/contracts/artifacts/db-migration.md`.
- Sequence + integration diagrams (mermaid).
- New ADR(s) appended to `.ai/memory/decisions.md`.
- Updated section in `.ai/memory/architecture.md`.

## DO
- Verify the design respects every relevant ADR.
- Document state transitions, failure modes, and idempotency strategy.
- Specify migration as additive-then-subtractive.

## DO NOT
- Write production code.
- Bypass `.ai/contracts/api-design.md`.
- Introduce new ADRs silently — surface them for review.
EOF

    write_file ".ai/agents/senior-dev.md" <<'EOF'
# Agent role: Senior Developer

## Mandate
Translate the design into clean, tested, observable, production-grade code.

## Inputs
- Technical Design + API Contract + Task Breakdown
- `.ai/memory/coding-style.md`, `known-issues.md`
- `.ai/stack/commands.md`

## Outputs
- Code that compiles, lints, and passes the test gate.
- Unit tests meeting `.ai/contracts/test-coverage.md`.
- PR description per `.ai/contracts/output-format.md` and `pr-checklist.md`.
- Updates to `coding-style.md` if a new pattern was introduced.

## DO
- Use only commands from `.ai/stack/commands.md`.
- Search the repo for existing patterns before writing new ones.
- Cover happy path AND each error branch.
- Add structured logging with correlation id at every entry point.
- Wire feature flag if the design specifies one.

## DO NOT
- Modify files outside the design's declared scope.
- Introduce new dependencies without an ADR.
- Skip exception handling, retries, or timeouts on external calls.
- Hardcode secrets, URLs, or environment-specific values.
EOF

    write_file ".ai/agents/qa.md" <<'EOF'
# Agent role: QA Engineer

## Mandate
Prove the change behaves as specified across positive, negative, edge,
regression, and integration scenarios. Surface defects, not opinions.

## Inputs
- User Story + Acceptance Criteria
- Technical Design + Risk Matrix
- PR + unit tests

## Outputs
- Test Cases using `.ai/contracts/artifacts/test-cases.md`.
- Regression Checklist using `.ai/contracts/artifacts/regression-checklist.md`.
- Automation Plan using `.ai/contracts/artifacts/automation-plan.md`.
- Risk-based testing matrix mapped to the Risk Matrix.
- Defect reports (BUG-<id>) appended to `active-tasks.md`.

## DO
- Cover positive, negative, edge, regression, integration explicitly.
- Map each high/medium risk to at least one test case.
- Identify impact areas (modules whose tests must also run).
- Reproduce defects with the smallest possible test before handing back.

## DO NOT
- Fix code yourself (file the bug; let Senior Dev fix).
- Approve while AC is unmet.
EOF

    write_file ".ai/agents/devops.md" <<'EOF'
# Agent role: DevOps Engineer

## Mandate
Make the change deployable, observable, recoverable, and rollback-safe in
production.

## Inputs
- Technical Design + API Contract + DB Migration
- Risk Matrix
- `.ai/memory/integration-map.md`
- `.ai/contracts/production-readiness.md`

## Outputs
- Deployment Plan using `.ai/contracts/artifacts/deployment-plan.md`.
- Rollback Plan using `.ai/contracts/artifacts/rollback-plan.md`.
- Config diff (env, secrets, flags) — section in Deployment Plan.
- Monitoring Checklist using `.ai/contracts/artifacts/monitoring-checklist.md`.
- Runbook using `.ai/contracts/artifacts/runbook.md`.
- Troubleshooting Guide using `.ai/contracts/artifacts/troubleshooting.md`.
- Release Note (joint with PO).
- `CHANGELOG.md` entry.

## DO
- Run `.ai/contracts/production-readiness.md` and refuse to advance if not green.
- Time the rollback path on staging.
- Add an alert for every SLO; back every alert with a runbook entry.
- Plan deploy as additive-then-subtractive whenever data is involved.

## DO NOT
- Approve a release without a tested rollback.
- Ship a new path without observability.
- Bypass change control.
EOF

    write_file ".ai/agents/scrum-master.md" <<'EOF'
# Agent role: Scrum Master

## Mandate
Coordinate the team, surface blockers, maintain ceremony artifacts, and
enforce process — without making technical or product decisions.

## Inputs
- Task Breakdown + Dependency Matrix + Estimates
- `.ai/memory/active-tasks.md`, `sprint-context.md`

## Outputs
- Sprint Plan using `.ai/contracts/artifacts/sprint-plan.md` (Stage 8).
- Daily-standup-as-doc summary appended to `active-tasks.md`.
- Blocker register (section of Sprint Plan).
- Throughput / risk report at sprint end.
- Traceability matrix: Epic → Story → Task → PR → Release.

## DO
- Detect blockers from `Depends on` chains across tasks.
- Re-sequence tasks when capacity or dependencies change.
- Consolidate `decisions.md` and `architecture.md` once per sprint.
- Enforce the SDLC pipeline; refuse to skip stages.

## DO NOT
- Make architectural or product decisions (defer to Architect / PO).
- Override Reviewer rejections.
EOF

    write_file ".ai/agents/orchestrator.md" <<'EOF'
# Agent role: Orchestrator

## Mandate
Sequence work across roles, validate handoffs, prevent file conflicts, and
escalate ADR violations.

## Inputs
- All in-flight task entries in `active-tasks.md`
- Handoff notes between roles

## Outputs
- Stage transitions (recorded in `active-tasks.md`).
- Conflict resolutions (serialise tasks with overlapping `Touches:`).
- Escalations to the human user when guardrails fire.

## DO
- Maintain `active-tasks.md` as ground truth.
- Validate handoff notes follow the canonical format.
- Detect file-touch conflicts before they occur and re-sequence.
- Refuse to advance past a stage whose exit gate is not met.

## DO NOT
- Make role decisions (defer to lane owner).
- Override Reviewer rejections.
- Skip clarification, risk, test, docs, or release-prep stages.
EOF
}

write_sdlc_workflows() {
    write_file ".ai/workflows/sdlc-pipeline.md" <<'EOF'
# Workflow: SDLC pipeline (15 stages, enterprise Agile/Scrum)

Every user request enters at Stage 1. Stages may iterate, but the agent
**never skips** Clarification, Risk Analysis, Test, Documentation, or
Release Preparation without an ADR-level approval.

| #  | Stage                     | Owner role(s)                    | Exit gate                                                                 |
|----|---------------------------|----------------------------------|---------------------------------------------------------------------------|
| 1  | User Request              | Orchestrator                     | Captured in `active-tasks.md` with TASK-id                                |
| 2  | Requirement Clarification | BA                               | All MUST-HAVE answered or explicit assumption logged                      |
| 3  | Business Analysis         | BA + PO                          | BRD + Epic + Stories + AC written                                         |
| 4  | Technical Analysis        | Tech Lead                        | Impact + dependency matrix + complexity estimate written                  |
| 5  | Solution Design           | Architect                        | Tech design + sequence + API + DB plan; ADRs raised                       |
| 6  | Risk Analysis             | Architect + DevOps + QA          | Risk Matrix completed; rollback approved                                  |
| 7  | Task Breakdown            | Tech Lead                        | Tasks created with objective / scope / AC / tech notes / DoD              |
| 8  | Sprint Planning           | Scrum Master + Tech Lead         | Sprint plan + capacity + dependency order                                 |
| 9  | Development               | Senior Dev                       | Code complies with `coding-style.md`; covers AC; PR open                  |
| 10 | Unit Test                 | Senior Dev                       | Coverage threshold met; all green                                         |
| 11 | QA Test                   | QA                               | Positive / negative / edge / regression / integration pass                |
| 12 | Documentation             | Senior Dev + Architect + DevOps  | Architecture, ADR, API, runbook, changelog updated; traceability recorded |
| 13 | Release Preparation       | DevOps + PO                      | Release notes + version + config diff + migration order + flag plan       |
| 14 | Deployment Checklist      | DevOps                           | Production-readiness checklist green; smoke + rollback validated          |
| 15 | Post-release Validation   | DevOps + QA + PO                 | Production smoke + KPI / SLO check; rollback or close                     |

## Loops permitted
- Stage 2 ↔ Stage 2 (more clarification)
- Stage 6 → Stage 5 (re-design when risk too high)
- Stage 11 → Stage 9 (defect found)
- Stage 15 → Stage 9 (post-release defect → rollback or hotfix)

## Skipping a stage
Requires an ADR in `.ai/memory/decisions.md` with explicit human approval.
EOF

    write_file ".ai/workflows/clarification-gate.md" <<'EOF'
# Workflow: Clarification gate (Stage 2)

The agent stops and asks when MUST-HAVE categories below are unclear.
Otherwise it logs an explicit assumption (ASM-<id>).

## MUST-HAVE categories
1. Business goal — what success looks like, who benefits.
2. Expected behaviour — happy path + known edge cases.
3. Validation rules — what input is valid, error handling.
4. Permissions / RBAC — who may invoke / see / change.
5. Non-functional requirements — latency, throughput, availability, retention.
6. Rollback expectation — how we revert, how fast, with what guarantees.
7. Compatibility — backwards / sideways / forward; deprecation policy.
8. Integration surface — upstream / downstream systems and their owners.
9. Data sensitivity — PII, financial, regulated; retention; masking.
10. Release strategy — feature flag, canary, dark launch, big bang.

## Output template (use verbatim)

```markdown
[Role: BA] [Stage: 2 — Requirement Clarification]

Before I proceed, I need to confirm the following. Please answer or mark
each as "assume <value>" so I can record it.

## MUST-HAVE
1. <category>: <specific question>
2. …

## SHOULD-HAVE
1. <category>: <specific question>

## NICE-TO-HAVE
1. …

## Assumptions I will record if you do not answer
- <category>: <assumed value> — recorded as ASM-<id>

I will not advance past Stage 2 until MUST-HAVE items are answered or
explicit assumptions are accepted.
```

## Recording assumptions
Append to the task entry in `active-tasks.md`:

```
## Assumptions
- ASM-001: <statement> — accepted by <user> on <YYYY-MM-DD>
```

Assumptions that prove durable become candidates for ADRs.
EOF
}

write_artifact_templates() {
    write_file ".ai/contracts/artifacts/_header.md" <<'EOF'
# <Artifact type>: <Title>

| Field | Value |
|-------|-------|
| Task id | TASK-<id> |
| Epic | <epic id or "—"> |
| Owner role | <role> |
| Date | <YYYY-MM-DD> |
| Version | v<semver> |
| Status | Draft \| Reviewed \| Approved \| Superseded |
| Trace | Jira: <id> · Branch: <name> · PR: <link> · Release: <tag> |

(Body follows. Always end with: ## Risks · ## Tests / Validation · ## Next steps.)
EOF

    write_file ".ai/contracts/artifacts/brd.md" <<'EOF'
# BRD: <Title>

[Header per `_header.md`]

## Business goal
<one paragraph: what outcome, who benefits, why now>

## Stakeholders
| Role | Name / team | Decision power |
|------|-------------|----------------|

## Scope
### In
- <…>
### Out
- <…>

## Requirements
| ID | Statement | MUST / SHOULD / NICE | Source | AC summary |
|----|-----------|----------------------|--------|------------|

## Assumptions
- ASM-<id>: <statement>

## Constraints
- <regulatory, contractual, technical>

## Success metrics
- <KPI or SLO with target>

## Risks (high level — full matrix at Stage 6)
- <risk> → <mitigation>

## Tests / Validation
- BRD reviewed by <stakeholders> on <date>.

## Next steps
1. PO: produce Epic + Stories
2. Tech Lead: technical impact analysis
EOF

    write_file ".ai/contracts/artifacts/epic.md" <<'EOF'
# Epic: <Title>

[Header per `_header.md`]

## Outcome
<single sentence: what user-visible value this epic delivers>

## Stories in this epic
| Story id | Title | MUST/SHOULD/NICE | Status |
|----------|-------|------------------|--------|

## Sequencing rationale
<why this story order — value delivery, dependency, risk burn-down>

## Out of scope
- <…>

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Epic acceptance: <when is the epic 'done'?>

## Next steps
1. Architect: cross-story design
2. Tech Lead: dependency matrix across stories
EOF

    write_file ".ai/contracts/artifacts/user-story.md" <<'EOF'
# User Story: <Title>

[Header per `_header.md`]

## Story
> As a <persona>, I want <capability>, so that <outcome>.

## Priority
MUST | SHOULD | NICE

## Acceptance Criteria (Given / When / Then)
- **AC-1**
  - Given <state>
  - When <action>
  - Then <observable result>
- **AC-2** …

## Out of scope
- <…>

## Dependencies
- <story or system>

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Each AC mapped to a test case in `test-cases.md`.

## Next steps
1. Tech Lead: tech notes + estimate
2. Architect: design touch-points
EOF

    write_file ".ai/contracts/artifacts/functional-spec.md" <<'EOF'
# Functional Spec: <Title>

[Header per `_header.md`]

## Use cases
| ID | Actor | Goal | Trigger | Main flow | Alternate flows | Exceptions |
|----|-------|------|---------|-----------|-----------------|------------|

## User flow
```mermaid
flowchart TD
    Start --> Step1 --> Step2 --> End
```

## Validation rules
| Field | Rule | Error message |
|-------|------|---------------|

## Permissions
| Role | Action | Allowed |
|------|--------|---------|

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Functional spec reviewed by BA + Tech Lead on <date>.

## Next steps
1. Architect: technical design
EOF

    write_file ".ai/contracts/artifacts/technical-design.md" <<'EOF'
# Technical Design: <Title>

[Header per `_header.md`]

## Context
<problem, who is affected, constraints, links to BRD / Stories>

## Proposal
<the design in prose; include diagrams below>

## Architecture diagram
```mermaid
flowchart LR
    Client --> Service --> Store
```

## Sequence diagram
```mermaid
sequenceDiagram
    participant C as Caller
    participant S as Service
    participant D as Datastore
    C->>S: request
    S->>D: write
    S-->>C: response
```

## Interface
- API: see `api-contract.md`
- Events: <topic, schema, version>
- Internal contracts: <module boundaries>

## Data model changes
See `db-migration.md`.

## Failure modes
| Mode | Symptom | Detection | Mitigation |
|------|---------|-----------|------------|

## Migration / rollout
- Phase 1 (additive): <…>
- Phase 2 (subtractive, after all writers migrated): <…>
- Feature flag: <name + default>

## ADR impact
- New ADRs: ADR-<id>: <title>
- Affected ADRs: ADR-<id>

## Alternatives considered
- <option> — <why rejected>

## Open questions
<anything not yet decided>

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Design reviewed by Architect + Tech Lead + DevOps on <date>.

## Next steps
1. DevOps: rollout / rollback plan
2. Tech Lead: task breakdown
EOF

    write_file ".ai/contracts/artifacts/api-contract.md" <<'EOF'
# API Contract: <Title>

[Header per `_header.md`]

## Endpoint(s)
| Method | Path | Purpose |
|--------|------|---------|

## Versioning
- Version: v<n>
- Deprecation policy: <…>
- Compatibility: backwards-compatible | breaking (requires ADR)

## Request
```json
{
  "field": "type — description"
}
```

## Response
| Status | Body | Meaning |
|--------|------|---------|

## Errors
| Code | Body | Meaning | Retryable |
|------|------|---------|-----------|

## Idempotency
- Required header: `Idempotency-Key`
- Dedup window: <…>

## Rate limits
- <per identity / per endpoint>

## Auth
- AuthN: <…>
- AuthZ: <role / scope>

## Observability
- Emitted events / metrics / spans

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Contract test fixtures committed under <path>.

## Next steps
1. Senior Dev: implement against contract
2. QA: contract test cases
EOF

    write_file ".ai/contracts/artifacts/db-migration.md" <<'EOF'
# DB Migration: <Title>

[Header per `_header.md`]

## Change summary
<one paragraph>

## Migration phases
### Phase 1 — Additive
```sql
-- forward
```
```sql
-- rollback
```

### Phase 2 — Subtractive (only after all writers on new shape)
```sql
-- forward
```
```sql
-- rollback
```

## Order of operations
1. <step>
2. <step>

## Lock / downtime impact
- Estimated lock time: <…>
- Online vs offline: <…>

## Data validation
- Pre-migration count / checksum: <…>
- Post-migration validation query: <…>

## Rollback
- Window: <…>
- Data divergence after rollback: <…>

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Tested on staging dataset of size <…> on <date>.

## Next steps
1. DevOps: schedule deploy window
EOF

    write_file ".ai/contracts/artifacts/sprint-plan.md" <<'EOF'
# Sprint Plan: Sprint <n>

[Header per `_header.md`]

## Sprint goal
<one sentence>

## Capacity
| Engineer / agent | Capacity (points) |
|------------------|-------------------|

## Committed scope
| Task id | Title | Points | Owner | Depends on | Blocks |
|---------|-------|--------|-------|------------|--------|

## Stretch
| Task id | Title | Points |
|---------|-------|--------|

## Risks for this sprint
- <risk> → <mitigation>

## Blockers register
| Blocker | Impact | Owner | ETA |
|---------|--------|-------|-----|

## Tests / Validation
- Daily standup-as-doc appended to `active-tasks.md` per task.

## Next steps
1. Daily: update task statuses.
2. End of sprint: throughput / risk report.
EOF

    write_file ".ai/contracts/artifacts/task-breakdown.md" <<'EOF'
# Task Breakdown: <Story or Epic title>

[Header per `_header.md`]

| Task id | Objective | Scope (in / out) | Acceptance criteria | Tech notes | Test notes | Definition of done | Estimate | Touches | Depends on |
|---------|-----------|------------------|---------------------|------------|------------|--------------------|----------|---------|------------|

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Each task has DoD that includes tests + docs updates.

## Next steps
1. Scrum Master: load into sprint plan.
EOF

    write_file ".ai/contracts/artifacts/dependency-matrix.md" <<'EOF'
# Dependency Matrix: <Sprint or Epic>

[Header per `_header.md`]

| Task | Depends on | Blocks | Touches | Cross-team? | Notes |
|------|------------|--------|---------|-------------|-------|

## Critical path
<task → task → task>

## External dependencies
| External system | Owner team | Needed by | Status |
|-----------------|-----------|-----------|--------|

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Dependency walked end-to-end on <date>.

## Next steps
1. Tech Lead: surface external blockers in sprint planning.
EOF

    write_file ".ai/contracts/artifacts/risk-matrix.md" <<'EOF'
# Risk Matrix: <Title>

[Header per `_header.md`]

| Risk | Category | Likelihood (L/M/H) | Impact (L/M/H) | Detection | Mitigation | Residual | Owner |
|------|----------|---------------------|----------------|-----------|------------|----------|-------|

## Categories considered
- Functional regression
- Performance
- Scalability
- Concurrency
- Data integrity
- Backwards compatibility
- Security
- Privacy / compliance
- Availability
- Operational
- Vendor / dependency
- Rollback
- People / process

(Mark "N/A" with one-line reason for any category not applicable.)

## Acceptance rule
Any risk with Likelihood ≥ M and Impact ≥ M must have a mitigation that
drops residual to L, OR an explicit ADR-level acceptance.

## Tests / Validation
- Reviewed by Architect + DevOps + QA on <date>.

## Next steps
1. Tech Lead: task breakdown reflecting mitigations.
EOF

    write_file ".ai/contracts/artifacts/test-cases.md" <<'EOF'
# Test Cases: <Story or Feature>

[Header per `_header.md`]

| ID | AC ref | Type (positive / negative / edge / integration) | Pre-conditions | Steps | Expected | Risk ref |
|----|--------|--------------------------------------------------|----------------|-------|----------|----------|

## Coverage
- AC coverage: <X / Y> ACs covered.
- Risk coverage: <X / Y> high+medium risks covered.

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Dry-run on staging on <date>.

## Next steps
1. Automation Plan for repeatable subset.
EOF

    write_file ".ai/contracts/artifacts/regression-checklist.md" <<'EOF'
# Regression Checklist: <Release / Sprint>

[Header per `_header.md`]

## Impact areas
| Module | Reason it's impacted | Test set |
|--------|----------------------|----------|

## Checklist
- [ ] <area>: <test set> green.
- [ ] <area>: <test set> green.

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Run on <env> on <date>; results attached.

## Next steps
1. QA sign-off before release.
EOF

    write_file ".ai/contracts/artifacts/automation-plan.md" <<'EOF'
# Automation Test Plan: <Scope>

[Header per `_header.md`]

## Automatable cases
| Case id | Layer (unit / contract / integration / e2e) | Tool | Owner |
|---------|---------------------------------------------|------|-------|

## Out-of-scope (manual)
- <case> — <why manual>

## Pipeline integration
- Trigger: <commit / nightly / pre-release>
- Reporting: <dashboard / channel>

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Pilot run on <date>.

## Next steps
1. Wire into CI as <stage>.
EOF

    write_file ".ai/contracts/artifacts/deployment-plan.md" <<'EOF'
# Deployment Plan: <Release>

[Header per `_header.md`]

## Targets
| Environment | Order | Window | Operator |
|-------------|-------|--------|----------|

## Pre-deploy checks
- [ ] CI green on release tag.
- [ ] Migration tested on staging dataset.
- [ ] Feature flag default confirmed.
- [ ] On-call notified.

## Steps
1. <step>
2. <step>

## Config diff
| Key | Old | New | Env |
|-----|-----|-----|-----|

## Smoke tests (post-deploy)
- [ ] <synthetic / canary / manual check>

## Rollback
See `rollback-plan.md`.

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Dry-run on staging on <date>.

## Next steps
1. DevOps: execute window <when>.
EOF

    write_file ".ai/contracts/artifacts/rollback-plan.md" <<'EOF'
# Rollback Plan: <Release>

[Header per `_header.md`]

## Trigger conditions
- <SLO breach / error spike / manual call>

## Rollback steps
1. <step>
2. <step>

## Time budget
- Target: < 15 min from decision to recovery.
- Last measured on staging: <duration> on <date>.

## Data divergence after rollback
- <what data is created during the bad window and how it is reconciled>

## Verification
- [ ] Health checks back to green.
- [ ] Canary metrics within baseline.
- [ ] On-call confirms.

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Rollback rehearsed on staging on <date>.

## Next steps
1. Communicate status: <channel / template>.
EOF

    write_file ".ai/contracts/artifacts/release-note.md" <<'EOF'
# Release Notes: v<semver> — <date>

## Summary
<one paragraph for users / stakeholders>

## Highlights
- <user-visible change>

## Breaking changes
- <change> — migration: <link>

## Deprecations
- <surface> — sunset on <date>

## Fixes
- <fix>

## Internal
- <infra / dependency upgrade / refactor>

## Trace
- Epic(s): <…>
- Stories: <…>
- ADRs: <…>
EOF

    write_file ".ai/contracts/artifacts/monitoring-checklist.md" <<'EOF'
# Monitoring Checklist: <Release / Feature>

[Header per `_header.md`]

## Metrics
- [ ] Latency (p50 / p95 / p99) on new path.
- [ ] Error rate on new path.
- [ ] Throughput / RPS.
- [ ] Saturation (CPU / mem / queue depth).

## Logs
- [ ] Structured, with correlation id at every entry point.
- [ ] No PII / secrets.
- [ ] Sample rate configured.

## Tracing
- [ ] Span on every external call.
- [ ] Trace propagation verified end-to-end.

## Alerts
- [ ] Alert per SLO breach.
- [ ] Routed to on-call channel.
- [ ] Each alert linked to a runbook entry.

## Synthetics
- [ ] Synthetic check exercises new path.

## Dashboards
- [ ] Updated / created.

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Verified in staging on <date>.

## Next steps
1. DevOps: tune alert thresholds after first traffic cycle.
EOF

    write_file ".ai/contracts/artifacts/runbook.md" <<'EOF'
# Runbook: <Service or path>

[Header per `_header.md`]

## What it does
<one paragraph>

## Owners
| Role | Channel |
|------|---------|

## Health signals
- Dashboard: <link>
- Key alerts: <list>

## Common incidents
### <Symptom>
- Likely cause: <…>
- Diagnosis: <…>
- Mitigation: <…>
- Post-incident actions: <…>

### <Symptom>
…

## Operational tasks
- <how to roll a key / restart / drain / scale>

## Escalation
- Tier 1 → tier 2 → tier 3 → engineering lead

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Drilled by on-call on <date>.

## Next steps
1. Quarterly review.
EOF

    write_file ".ai/contracts/artifacts/troubleshooting.md" <<'EOF'
# Troubleshooting Guide: <Service or path>

[Header per `_header.md`]

## Quick diagnosis
| Symptom | First check | Next |
|---------|-------------|------|

## Common errors
| Error code / message | Meaning | Action |
|----------------------|---------|--------|

## Useful queries / commands
```
<query / command>
```

## When to escalate
- <criteria>

## Risks
- <risk> → <mitigation>

## Tests / Validation
- Verified after last release on <date>.

## Next steps
1. Update on every recurring incident.
EOF
}

write_production_readiness() {
    write_file ".ai/contracts/production-readiness.md" <<'EOF'
# Production-readiness checklist (Stage 13)

Every item must be ✓ or have a recorded waiver before Stage 14.

## Scalability
- [ ] Capacity model confirms headroom at peak traffic.
- [ ] Resource requests / limits sized; auto-scaling configured if applicable.
- [ ] No unbounded growth (queues, caches, in-memory collections).

## Observability
- [ ] Structured logs with correlation / request id at every entry point.
- [ ] Metrics for latency, error rate, throughput, saturation (RED / USE).
- [ ] Tracing spans on every external call.
- [ ] Dashboard exists or updated for the new path.

## Monitoring & alerting
- [ ] Alert defined for each SLO breach.
- [ ] Alerts routed to on-call channel.
- [ ] No alert without a runbook entry.
- [ ] Synthetic / smoke check covers the new path.

## Resiliency
- [ ] Timeouts on every external call.
- [ ] Retries bounded (count + total elapsed) with backoff + jitter.
- [ ] Circuit breaker / bulkhead where downstream is shared.
- [ ] Graceful degradation defined for each external dependency.

## Concurrency & data integrity
- [ ] Idempotency on every state-changing operation.
- [ ] Locking / optimistic concurrency strategy documented.
- [ ] Transactions bounded; no long-held locks.
- [ ] Migrations are additive-then-subtractive; rollback proven on staging.

## Rollback safety
- [ ] Rollback steps documented and timed (target < 15 min).
- [ ] Feature flag or deploy-time toggle to disable the new path.
- [ ] Data divergence post-rollback documented.

## Security
- [ ] AuthN / AuthZ verified for new endpoints.
- [ ] Input validation at the boundary.
- [ ] Secrets via secret store, not env / config files in repo.
- [ ] Audit log entry for sensitive mutations.
- [ ] No PII / secrets in logs or telemetry.

## Compliance & data
- [ ] Data classification applied; retention / masking honoured.
- [ ] Cross-region / sovereignty constraints respected.

## Documentation
- [ ] Runbook updated.
- [ ] API docs / changelog updated.
- [ ] ADR(s) merged for any new principle.
- [ ] Traceability: Epic → Story → Task → PR → Release recorded.

## Release mechanics
- [ ] Version bumped per `commit-policy.md`.
- [ ] Release notes published.
- [ ] Deployment plan + rollback plan attached.
- [ ] Pre-prod smoke green.
- [ ] On-call notified; deploy window booked.
EOF
}

write_commands_doc() {
    write_file ".ai/commands.md" <<'EOF'
# Command system

The agent recognises slash-style commands from the user. Commands are
case-insensitive; arguments after the command are free-form.

| Command | Action | Stage |
|---------|--------|-------|
| `/clarify [request]` | Run Stage 2 clarification | 2 |
| `/brd` | Produce a BRD from the current task | 3 |
| `/epic` | Produce an Epic | 3 |
| `/story` | Produce User Story + AC | 3 |
| `/spec` | Produce Functional Spec | 4 |
| `/design` | Produce Technical Design + diagrams | 5 |
| `/api` | Produce API Contract | 5 |
| `/db` | Produce DB Migration plan | 5 |
| `/risk` | Produce Risk Matrix | 6 |
| `/break` | Produce Task Breakdown + estimates | 7 |
| `/sprint` | Produce Sprint Plan | 8 |
| `/code <area>` | Implement under stated scope | 9 |
| `/unit` | Run unit-test gate | 10 |
| `/test` | Produce / execute QA test plan | 11 |
| `/docs` | Update architecture / ADR / runbook / changelog | 12 |
| `/release` | Produce Release Note + Deployment + Rollback | 13 |
| `/check` | Run production-readiness checklist | 14 |
| `/postdeploy` | Post-release validation report | 15 |
| `/runbook` | Produce / update Runbook | 13 |
| `/adr <title>` | Draft a new ADR | any |
| `/status [TASK-id]` | Print task state | — |
| `/handoff <role>` | Emit handoff note | — |
| `/role <role>` | Switch role explicitly | — |

Any command that depends on missing inputs triggers `/clarify` first.
EOF

    write_file ".ai/examples/_README.md" <<'EOF'
# Examples

Real-world worked examples of running the SDLC pipeline. Add one file per
example. They are documentation, not executed code.

Suggested naming: `<NN>_<short-name>.md` (e.g. `01_payment-retry.md`).

Each example should walk Stages 1 → 15 with the actual handoff notes the
agent would emit.
EOF
}

write_system_prompt() {
    write_file "SYSTEM_PROMPT.md" <<'EOF'
# System prompt — Enterprise SDLC Orchestrator

> Paste the block below as the system prompt for the model that will play
> the orchestrator role. Version this file. A/B test changes against a
> fixed eval set.

---

```
You are an Enterprise SDLC Orchestrator: a senior delivery agent for an
Agile/Scrum team operating in an enterprise environment (Jira, Git, CI/CD,
Docs-as-Code, API-first, multi-service / BPM / microservice, formal release
process).

You play multiple roles depending on the stage of the work: Business Analyst,
Product Owner, Tech Lead, Architect, Senior Developer, QA Engineer, DevOps
Engineer, Scrum Master. You must signal which role you are in at the start of
each response (e.g. "[Role: Tech Lead]").

The repository contains a workspace operating system under `.ai/`. You must:

1. Read `AGENTS.md` and `.ai/stack/profile.md` before doing anything.
2. Follow the 15-stage SDLC workflow defined in `.ai/workflows/sdlc-pipeline.md`.
3. Treat `.ai/memory/active-tasks.md` as the single source of truth for
   in-progress work. Never start a stage without first updating it.
4. Use the canonical handoff format from `HANDOFF_PROTOCOL_AND_TEMPLATES.md`
   when passing work between roles.

CORE BEHAVIOURS

- Clarify before acting. If business goal, expected behaviour, validation
  rules, permissions, non-functional requirements, rollback expectation, or
  compatibility constraints are unclear, STOP and ask. Use the clarification
  template. Never code on assumptions you have not surfaced.
- Distinguish MUST / SHOULD / NICE for every requirement. Record assumptions
  explicitly when the user has not answered.
- Analyse business impact, technical impact, dependencies, security,
  performance, and backwards compatibility before producing a design.
- Produce production-grade artifacts. For every change you must consider:
  rollback safety, observability, monitoring, alerting, retry, timeout,
  resiliency, concurrency, scalability.
- Documentation is source-of-truth. Whenever code or design changes, update
  docs in the same change set (Docs-as-Code).
- Maintain traceability: every artifact links to its parent (Epic → Story →
  Task → Commit → PR → Release).
- Challenge unclear or risky requirements. You are a senior team member, not
  a stenographer.

HARD CONSTRAINTS (NEVER violate)

- Do NOT skip clarification when MUST-HAVE information is missing.
- Do NOT write code before requirements are explicit (MUST/SHOULD/NICE
  classified) and a design is recorded.
- Do NOT propose a change without a rollback plan.
- Do NOT skip tests, docs, security review, or monitoring on production paths.
- Do NOT modify files outside the design's declared scope.
- Do NOT invent build/test commands; use only those in `.ai/stack/commands.md`.
- Do NOT silently violate an ADR — surface the conflict and request a
  decision.
- Do NOT log secrets, PII, or full sensitive payloads.

OUTPUT FORMAT

- Open every response with `[Role: <role>] [Stage: <stage>]`.
- Use markdown. Use tables for matrices, mermaid for diagrams, checklists for
  gates.
- Every deliverable must satisfy `.ai/contracts/output-format.md`:
  Summary, Changed files / artifacts, Risks, Tests / validation, Next steps.
- For long-running work, end every response with a `## Next` block listing
  exactly what you will do next, what you need from the user, and which
  task ID in `active-tasks.md` you are operating on.

If the user gives you a fresh request, start at Stage 1 (Requirement
Clarification) of the SDLC workflow. Do not skip stages without explicit
human approval recorded as an ADR.
```
EOF
}

# ---------- main -------------------------------------------------------------

main() {
    info "Multi-agent workspace bootstrap"
    info "Target: $ROOT"
    detect_stack
    info "Detected stack: $(stack_summary)"
    info "Infra signals: $(tags_summary)"
    create_skeleton
    write_global_rules
    write_contracts
    write_workflows
    write_memory
    write_agents
    write_stack
    write_root_files
    info "Adding enterprise SDLC layer"
    write_enterprise_roles
    write_sdlc_workflows
    write_artifact_templates
    write_production_readiness
    write_commands_doc
    write_system_prompt
    info ""
    info "Done. Next steps:"
    log "  1. Edit .ai/stack/profile.md, commands.md, conventions.md, glossary.md"
    log "  2. Add 1–3 ADRs to .ai/memory/decisions.md"
    log "  3. Open .ai/memory/active-tasks.md and add your first task"
    log "  4. Paste SYSTEM_PROMPT.md into your model and point it at AGENTS.md"
}

main "$@"
