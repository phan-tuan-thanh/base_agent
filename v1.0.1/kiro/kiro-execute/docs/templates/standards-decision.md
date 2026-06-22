# Quyết định ngôn ngữ & tiêu chuẩn tài liệu

| Hạng mục | Quyết định | Lý do |
|----------|-----------|-------|
| Ngôn ngữ tài liệu | [vi / en] | [...] |
| Tiêu chuẩn | [Agile-Scrum / IEEE-830 / Lightweight / ...] | [...] |
| Sơ đồ ID | [vd: EPIC-xx, US-xx, T-xx, BUG-xx] | — |
| Quy ước đặt tên | kebab-case, `docs/features/<feature-id>-<name>/` | — |

## Phương án đã cân nhắc
- **Phương án A — [tên]:** *ưu* [...] / *nhược* [...]
- **Phương án B — [tên]:** *ưu* [...] / *nhược* [...]
- ⭐ **Đề xuất:** [Phương án X] phù hợp quy mô dự án/đội ngũ vì [...]

## Bộ tài liệu bắt buộc cho mỗi chức năng

| Loại tài liệu | Template | Bắt buộc? |
|---------------|----------|-----------|
| Epic | `epic.md` | [x] |
| User Story | `user-stories.md` | [x] |
| Story split | `stories-split.md` | [ ] khi có L/XL |
| Task / Subtask | `tasks.md` | [x] |
| Checklist tiến độ | `feature-checklist.md` | [x] |
| Bug | `bug-report.md` | [ ] khi phát sinh |
| Review | `task-review.md`, `group-review.md` | [x] |

## Layout thư mục
```
docs/features/<feature-id>-<name>/
├── epic.md
├── user-stories.md
├── tasks.md
├── feature-checklist.md
└── reviews/
```

## Template còn thiếu cần tạo (template-manager)
- [ ] [tên-template].md
