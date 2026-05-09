# Quick start: workspace AI architecture in 10 minutes (any repo)

> Bootstraps the **same** multi-agent operating system into any repository — Node, Python, Go, Rust, Java, mobile, infra, data — so agents work the same way everywhere.

## What you'll have at the end

- ✓ `.ai/` directory with rules, memory, workflows, contracts, agents, and a stack adapter
- ✓ `AGENTS.md` entry point
- ✓ `CLAUDE.md` and `GEMINI.md` role pointers
- ✓ Stack profile auto-detected from your manifest files
- ✓ Ready to run multi-agent workflows

## Step 1 — copy the bootstrap script (1 min)

Copy `scripts/init-workspace.sh` from this repo into the **new** repo. It is a single self-contained bash script with no external dependencies (POSIX `sh` + standard utilities).

```sh
cp /path/to/base_agent/scripts/init-workspace.sh ./scripts/init-workspace.sh
chmod +x ./scripts/init-workspace.sh
```

(Alternatively, run it directly from the source location — it always operates on the current working directory.)

## Step 2 — run the bootstrap (1 min)

From the new repo's root:

```sh
./scripts/init-workspace.sh
```

The script:

1. Creates the `.ai/` skeleton (rules, memory, workflows, contracts, agents, stack).
2. Writes the canonical templates from `HANDOFF_PROTOCOL_AND_TEMPLATES.md`.
3. **Auto-detects the stack** by inspecting manifest files:
   - `package.json` → Node / TypeScript / JavaScript
   - `pyproject.toml`, `requirements.txt`, `setup.py` → Python
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `pom.xml`, `build.gradle*` → Java / Kotlin / JVM
   - `Gemfile` → Ruby
   - `composer.json` → PHP
   - `mix.exs` → Elixir
   - `Package.swift` → Swift
   - `pubspec.yaml` → Dart / Flutter
   - `*.csproj`, `*.sln` → .NET
   - `Dockerfile`, `*.tf`, `helm/`, `k8s/` → infra signals (added as tags)
4. Writes a starter `.ai/stack/profile.md` pre-filled with the detected stack and the inferred build/test/lint commands.
5. Writes `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` at the repo root.
6. Is **idempotent** — re-running it never overwrites your edits. Files that already exist are skipped (you'll see a `skip:` line per file).

## Step 3 — fill in the stack adapter (5–10 min)

Open the four files under `.ai/stack/` and complete what the script could not infer:

| File              | What to add                                                  |
|-------------------|--------------------------------------------------------------|
| `profile.md`      | One-paragraph "what this repo is", deploy target, scope      |
| `commands.md`     | Verify and tweak the commands the script auto-filled         |
| `conventions.md`  | File layout, naming, dependency policy, test policy          |
| `glossary.md`     | Domain jargon (1–2 lines per term)                           |

Everything else (rules, contracts, workflows, agent roles) is already canonical and rarely needs editing. **The stack adapter is the only repo-specific layer.**

## Step 4 — first ADRs (5 min)

Open `.ai/memory/decisions.md`. Write down the two or three most important decisions that already shape this codebase. Examples:

- "We use cursor-based pagination because of dataset size."
- "Auth is delegated to provider X; never roll our own session storage."
- "Database migrations are additive-then-subtractive; never both in one PR."

ADRs are the highest-leverage memory entry — they prevent agents from re-litigating settled questions.

## Step 5 — start tracking work (1 min)

Open `.ai/memory/active-tasks.md` and add your first real task using the template at the top of the file.

```markdown
### TASK-001: <first thing you want an agent to do>

Status: Planner
Owner: <agent or you>
Start date: 2026-05-09

#### Stage checklist
- [ ] Planner
- [ ] Architect
- [ ] Implementer
- [ ] Reviewer
- [ ] Merged
```

## Step 6 — commit (1 min)

```sh
git add .ai/ scripts/init-workspace.sh AGENTS.md CLAUDE.md GEMINI.md
git commit -m "chore: initialize multi-agent workspace OS

- .ai/rules/      — global + domain rules
- .ai/contracts/  — output, PR, coverage, API contracts
- .ai/workflows/  — feature, bugfix, refactor, migration, hotfix, release
- .ai/memory/     — architecture, decisions, coding-style, active-tasks
- .ai/agents/     — planner, architect, implementer, reviewer, orchestrator
- .ai/stack/      — repo-specific adapter (profile, commands, conventions, glossary)
- AGENTS.md       — operating-system entry point
"
```

## ✓ Done

The repo is now wired for coordinated multi-agent work — same protocol, same contracts, same handoff format, regardless of language or platform.

---

## Run a smoke-test workflow

Try a tiny task to verify the loop works end-to-end:

> "Add a hello-world entry point to the project."

1. **Planner** prompt: "Read `AGENTS.md` and `workflows/feature.md`. Plan a minimal hello-world entry point following our conventions. Output per `contracts/output-format.md`."
2. **Architect** prompt: "Here is the plan. Design the entry point following `contracts/api-design.md`."
3. **Implementer** prompt: "Here is the design. Implement it. Use only commands from `stack/commands.md`. Tests required."
4. **Reviewer** prompt: "Here is the PR. Validate against `contracts/pr-checklist.md`."

Each output should include all five contract sections (Summary, Changed files, Risks, Tests, Next steps). If any are missing, the contract is the answer — reject and ask the previous lane to fix it.

---

## When you start the next repo

```sh
cd /path/to/next-repo
/path/to/base_agent/scripts/init-workspace.sh
```

Same architecture, same agents, same protocol. The only thing that changes is `.ai/stack/`. **That is the entire point.**

---

## Going deeper

- `ENTERPRISE_SDLC_ORCHESTRATOR.md` — the production-grade specification: SYSTEM PROMPT, 9 enterprise roles (BA / PO / Tech Lead / Architect / Senior Dev / QA / DevOps / Scrum Master / Orchestrator), 15-stage SDLC pipeline, clarification gate, full artifact catalogue (BRD / Epic / Story / Tech Design / API Contract / DB Migration / Sprint Plan / Risk Matrix / Test Cases / Deployment Plan / Rollback Plan / Runbook / …), risk framework, production-readiness checklist, command system (`/clarify`, `/design`, `/code`, `/test`, `/release`, `/check`, …), examples, and prompt-optimisation strategy.
- `ENHANCED_WORKSPACE_ARCHITECTURE.md` — why each `.ai/` layer exists and how they interact.
- `HANDOFF_PROTOCOL_AND_TEMPLATES.md` — the canonical handoff format and every starter template.
- `.ai/agents/_template.md` — copy this when you want to add a new agent role.

## Enterprise mode

After bootstrap, paste `SYSTEM_PROMPT.md` (written by the script at the repo root) as the model's system message. The agent will then operate as the full SDLC team described in `ENTERPRISE_SDLC_ORCHESTRATOR.md`: it announces its role at the top of every response, refuses to code before MUST-HAVE clarification is complete, and produces the full set of production artifacts at the right stages.

---

**You just installed the operating system for coordinated AI agents on a brand-new repo. From here, the agents do the work — and you do not have to redesign anything when the next repo arrives.**
