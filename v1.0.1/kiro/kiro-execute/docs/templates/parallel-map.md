# Bản đồ song song (Parallel Map)

## Execution Waves
| Wave | Group ID | Tasks | Parallelizability | Conflicts | Sync point | Max agents |
|------|----------|-------|-------------------|-----------|------------|------------|
| 1 | G-1 | T-001, T-002 | High | — | sau wave | 2 |
| 2 | G-2 | T-003 | Low | file `x.ts` với T-004 | sau wave | 1 |

## Chi tiết Wave

### Wave 1 — [mô tả]
- Tasks: T-001, T-002
- Lý do song song được: [không chung file, không phụ thuộc]
- Sync point: [...]

## Dependency graph
```
Wave1: [T-001] [T-002]
            └────┬────┘
Wave2:      [T-003] [T-004]
```

## Tóm tắt waves đề xuất
1. **Wave 1:** [...] — chạy song song [n] agents
2. **Wave 2:** [...]
