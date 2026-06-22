# Tasks & Subtasks — Feature: [Tên]

## Tổng quan task theo story
| Story | Create | Modify | Test | Config | Docs | Tổng |
|-------|--------|--------|------|--------|------|------|
| US-001 | 2 | 1 | 1 | 0 | 1 | 5 |

---

## US-001 — [Title]

| ID | Type | File(s) | Dependencies | Effort | Done Criteria |
|----|------|---------|--------------|--------|---------------|
| T-001 | create | `src/...` | — | 1h | [ ] [...] |
| T-002 | modify | `src/...` | T-001 | 0.5h | [ ] [...] |
| T-003 | test | `tests/...` | T-002 | 1h | [ ] [...] |

### Chi tiết task
**T-001 — [mô tả]**
- Subtasks:
  - [ ] [...]
  - [ ] [...]
- Done:
  - [ ] [...]

---

## Dependency graph
```
T-001 ──► T-002 ──► T-003
              └───► T-004
```
