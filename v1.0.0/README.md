# base_agent — multi-agent workspace OS for any repo

A reusable operating system for AI agents working on **any** codebase. Drop the bootstrap script into a fresh repo, fill in a one-page stack adapter, and your agents (Claude, Gemini, Codex, humans) all play by the same rules — same lanes, same contracts, same handoff protocol.

## What's in here

| File | Purpose |
|------|---------|
| `ENTERPRISE_SDLC_ORCHESTRATOR.md`    | Production-grade spec for an enterprise Agile/Scrum agent: SYSTEM PROMPT, 9 roles (BA / PO / Tech Lead / Architect / Senior Dev / QA / DevOps / Scrum Master / Orchestrator), 15-stage SDLC pipeline, clarification gate, artifact catalogue, risk framework, production-readiness checklist, command system, examples, prompt-optimisation strategy. |
| `ENHANCED_WORKSPACE_ARCHITECTURE.md` | Foundational design: layers, conflict prevention, why each piece exists. Stack-agnostic. |
| `HANDOFF_PROTOCOL_AND_TEMPLATES.md`  | Canonical handoff format + every starter template under `.ai/`. |
| `QUICK_START_30MIN.md`               | 10-minute bootstrap for a brand-new repo. |
| `scripts/init-workspace.sh`          | Self-contained bash script that scaffolds the entire `.ai/` skeleton (rules, memory, workflows, contracts, **9 enterprise roles**, **20+ artifact templates**, SDLC pipeline, clarification gate, production-readiness checklist, commands), writes `SYSTEM_PROMPT.md`, and auto-detects the stack. |

## Use it on a new repo

```sh
cd /path/to/new-repo
/path/to/base_agent/scripts/init-workspace.sh
```

The script:

- Creates `.ai/{rules,memory,workflows,contracts,agents,stack}/` with canonical templates.
- Auto-detects the stack from manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `Gemfile`, `composer.json`, `mix.exs`, `Package.swift`, `pubspec.yaml`, `*.csproj`).
- Pre-fills `.ai/stack/profile.md` and `.ai/stack/commands.md` with the inferred stack and build/test/lint commands.
- Writes `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` at the repo root.
- Is idempotent — re-running never overwrites your edits.

After it runs, spend ~10 minutes filling in `.ai/stack/profile.md`, `commands.md`, `conventions.md`, `glossary.md`, then add a few ADRs to `.ai/memory/decisions.md`. Paste `SYSTEM_PROMPT.md` (also written by the script) into your model. Done — the agent now operates as a full enterprise SDLC team.

## Core idea

```
Deterministic Workflow + Enforced Contracts + Shared Operational Memory
```

The architecture (rules, memory, workflows, contracts, agent roles) is **identical** across repos. Only `.ai/stack/` changes. That single decision is what makes the system reusable for backend, frontend, mobile, data, infra — any repo, same agent loop.

## Read in this order

1. `QUICK_START_30MIN.md` — get a new repo wired up.
2. `ENTERPRISE_SDLC_ORCHESTRATOR.md` — the system prompt + role + workflow + artifact specification (the *what the agent does*).
3. `ENHANCED_WORKSPACE_ARCHITECTURE.md` — why each `.ai/` layer exists (the *how the workspace is structured*).
4. `HANDOFF_PROTOCOL_AND_TEMPLATES.md` — canonical handoff format + foundational templates.

## Customising

- **New agent role** → copy `.ai/agents/_template.md` to `.ai/agents/<role>.md` and fill it in.
- **New domain rules** → drop `.ai/rules/domain/<domain>.md`.
- **New workflow** → add `.ai/workflows/<type>.md` and reference it from `AGENTS.md`.
- **New contract** → add `.ai/contracts/<thing>.md`; outputs that touch it must include the relevant section.

The script is the source of truth for the canonical skeleton. Edit it once; every future repo gets the update next time you re-run the script there (skipping anything you've already customised).
