# Quick start: Workspace AI architecture in 30 minutes

## What you'll have at the end

- ✓ .ai/ directory with rules, workflows, contracts, memory, agents
- ✓ AGENTS.md entry point
- ✓ CLAUDE.md + GEMINI.md role definitions
- ✓ Ready to run multi-agent workflows

## Step 1: Create directory structure (5 min)

From repo root:

```
mkdir -p .ai/{rules,memory,workflows,contracts,agents}
mkdir -p .ai/rules/{global,backend,devops}

# Create files
touch .ai/rules/global/{security.md,architecture.md}
touch .ai/rules/backend/{java.md,sql.md}
touch .ai/workflows/{feature.md,bugfix.md}
touch .ai/contracts/{output-format.md,api-design.md}
touch .ai/memory/{architecture.md,decisions.md,coding-style.md,active-tasks.md}
touch .ai/agents/{claude.md,gemini.md}
```

## Step 2: Create AGENTS.md in repo root (3 min)

```
# Workspace AI Operating System

## Loading order (all agents)

1. .ai/rules/global/* (security, performance)
2. .ai/contracts/* (output format)
3. .ai/rules/{domain}/* (backend, frontend, devops)
4. .ai/workflows/{type}.md (feature, bugfix)
5. .ai/memory/* (architecture, decisions, active-tasks)
6. .ai/agents/{role}.md (claude, gemini)

## Core rules

- Never modify unrelated files
- Always run tests before commit
- Update memory if architecture changes
- Check active-tasks.md before starting work
- Follow contracts strictly

## Agent roles

**Planner** (Claude): Break down scope, identify risks, list blockers
**Architect** (Claude): Design API, data models, integration strategy
**Impl** (Gemini): Code, write tests, follow design exactly
**QA**: Validate, regression test, approve

## Memory sources

1. architecture.md — system design
2. decisions.md — ADRs, why we chose X
3. active-tasks.md — work in progress
4. coding-style.md — patterns we use
```

## Step 3: Create memory files (5 min)

### .ai/memory/architecture.md

```
# System architecture

## Overview
[Your system in 1 paragraph]

## Tech stack
- Backend: Spring Boot 3.x
- Frontend: React 18
- Database: PostgreSQL 15
- Message broker: Kafka
- Deployment: Kubernetes

## Key domains
[List your domains]

## Performance targets
- API latency: p99 < 200ms
- Success rate: > 99.5%
```

### .ai/memory/decisions.md

```
# Architecture Decision Records

## ADR-001: [Title]

Status: Accepted
Date: [date]

### Decision
[What you decided]

### Reason
[Why this choice]

### Consequence
[What changes]
```

### .ai/memory/coding-style.md

```
# Coding style

## Java
- Dependency injection: @Autowired on field
- Error handling: Custom exceptions + @ControllerAdvice
- Testing: JUnit 5 + Mockito + Testcontainers

## React
- Hooks only (no class components)
- Functional components: camelCase
- Context for global state

## Database
- Migrations: Flyway (V{version}__description.sql)
- Naming: snake_case tables/columns
- Indexes: On foreign keys + frequent queries
```

### .ai/memory/active-tasks.md

```
# Sprint active tasks

[Will be populated as work begins]

## Template for new task

TASK-XXX: [Title]
Status: [Planner | Architect | Impl | QA | Merged]
Owner: [Agent]
Files to touch: [list]
Risks: [what could go wrong + mitigation]
Depends on: [other tasks]
```

## Step 4: Create workflow + contract files (5 min)

### .ai/workflows/feature.md

```
# Feature workflow

## Steps

1. Planner: Read scope, check architecture, write plan
   Input: Issue/ticket
   Output: Plan (summary, files, risks, next agent)
   
2. Architect: Design API, data models, integration
   Input: Planner's plan
   Output: Design doc (API spec, DB schema)

3. Impl: Code according to design, write tests
   Input: Architect's design
   Output: PR (code, tests, summary)
   
4. QA: Validate, regression test, approve
   Input: PR
   Output: Approval

5. Merge: Squash to main, update memory

## Success criteria
- ✓ All outputs follow contracts/output-format.md
- ✓ Code passes tests (coverage ≥ 80%)
- ✓ Memory updated (decisions.md or active-tasks.md)
```

### .ai/workflows/bugfix.md

```
# Bugfix workflow

## Steps

1. Reproduce: Get clear reproduction steps
2. Root cause: Find why it happened
3. Minimal fix: Smallest code change
4. Regression test: Verify it won't happen again
5. Merge: Fast-track (bugs don't need extended review)

## Rules
- NO refactoring while fixing
- NO architectural changes
- YES write test for bug scenario
- YES regression test suite
```

### .ai/contracts/output-format.md

```
# Output contract

Every agent output must include:

1. **Summary** (1-3 sentences)
2. **Changed files** (bulleted list)
3. **Risks** (risks + mitigations)
4. **Tests** (unit, integration, regression)
5. **Next steps** (who's next, blockers)

Missing any section = contract violation.
```

## Step 5: Create agent rules (5 min)

### CLAUDE.md (in repo root)

```
# Instructions for Claude

## Your roles

1. **Planner**: Break down scope, identify risks, list blockers
2. **Architect**: Design API, data models, integration strategy

## Before every task

1. Read AGENTS.md
2. Load memory files (architecture.md, decisions.md, active-tasks.md)
3. Check: Any blockers? Any duplicate work?
4. Load .ai/workflows/{type}.md (feature, bugfix, etc)

## Output must follow

- contracts/output-format.md exactly
- Summary + Changed files + Risks + Tests + Next steps

## When you finish

1. Update active-tasks.md (mark your stage ✓, note next agent)
2. Update memory/decisions.md if you discovered something important
3. Hand off with clear summary for next agent
```

### GEMINI.md (in repo root)

```
# Instructions for Gemini

## Your role

Implementation: Code according to design, write tests

## Before every task

1. Read AGENTS.md
2. Read Architect's design
3. Load memory/coding-style.md (patterns we use)
4. Search codebase for similar examples (don't hallucinate)

## DO NOT

- Hallucinate API signatures (verify in code)
- Skip checking framework versions (pom.xml, package.json)
- Assume import paths (find actual location)
- Generate code violating coding-style.md
- Skip tests

## Output must follow

- contracts/output-format.md exactly
- PR with comprehensive summary
- 80% minimum test coverage
```

## Step 6: Commit (1 min)

```
git add .ai/
git add AGENTS.md CLAUDE.md GEMINI.md
git commit -m "[infra] Initialize workspace AI architecture

- .ai/rules/ — security, performance, architecture rules
- .ai/workflows/ — feature, bugfix workflows
- .ai/contracts/ — output format, API design
- .ai/memory/ — architecture, decisions, coding-style, active-tasks
- AGENTS.md — operating system entry point
- CLAUDE.md — Planner/Architect role definitions
- GEMINI.md — Implementation role definitions

This enables multi-agent (Claude + Gemini) coordinated workflows."

git push
```

## ✓ Setup complete! (30 min total)

You now have:
- ✓ Structured .ai/ directory with rules, workflows, contracts, memory
- ✓ Entry point (AGENTS.md)
- ✓ Agent role definitions (CLAUDE.md, GEMINI.md)
- ✓ Ready for first workflow

## Next: Run a test workflow

Try: "Add hello-world endpoint"

1. Ask Claude (Planner): "Use AGENTS.md + workflows/feature.md. Plan a GET /hello endpoint."
2. Ask Claude (Architect): "Design the API following api-design.md"
3. Ask Gemini (Impl): "Code the endpoint following coding-style.md"
4. Verify: Each output includes Summary + Changed files + Risks + Tests + Next steps

Result: Coordinated 3-agent workflow without any conflicts.

## For deeper understanding

Read:
1. ENHANCED_WORKSPACE_ARCHITECTURE.md — why each layer matters
2. HANDOFF_PROTOCOL_AND_TEMPLATES.md — detailed hand-off format
3. Your memory files — architecture.md + decisions.md before work

---

**You just built the operating system for coordinated AI agents. Good luck!**
