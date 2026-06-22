# Kế hoạch thực hiện (Execution Plan)

## Tổng quan
| Hạng mục | Giá trị |
|----------|---------|
| Tổng số task | [n] |
| Số phase | [n] |
| Ước lượng thời gian | [...] |
| Critical path | [T-001 → T-005 → T-009] |

## Các Phase

### Phase 1 — [Tên]
| Task | Mode | Dependencies | Effort |
|------|------|--------------|--------|
| T-001 | sequential | — | 1h |
| T-002 | parallel | T-001 | 0.5h |

### Phase 2 — [Tên]
[...]

## Timeline (Gantt text)
```
Phase 1 |████████        | T-001, T-002
Phase 2 |        ████████ | T-003, T-004
Phase 3 |            ████ | T-005
```

## Critical path
```
T-001 ──► T-005 ──► T-009   (tổng: [x]h)
```

## Rủi ro & giảm thiểu
| Rủi ro | Khả năng | Ảnh hưởng | Giảm thiểu |
|--------|----------|-----------|------------|
| [...] | [H/M/L] | [H/M/L] | [...] |

## Checkpoint phê duyệt
- [ ] ✋ User duyệt kế hoạch trước khi sang giai đoạn thực thi.
