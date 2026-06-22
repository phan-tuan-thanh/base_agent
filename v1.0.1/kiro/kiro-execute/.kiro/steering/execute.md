---
inclusion: manual
---

# Skill: Execute (End-to-End Execution)

Workflow tự động từ **làm rõ yêu cầu** → **phân tích & thiết kế** → **lập kế hoạch** → **thực hiện** → **review** → **báo cáo tổng kết**. Mỗi bước do một custom agent đảm nhiệm, output lưu vào `docs/`.

Kích hoạt bằng `#execute` trong chat.

---

## Sơ đồ Pipeline

```
                ┌───────────────────────────────────────────────┐
                │  GIAI ĐOẠN 1 — DISCOVERY & DESIGN             │
                ├───────────────────────────────────────────────┤
   (1) requirement-clarifier   ── hỏi + tư vấn giải pháp ──┐     │
   (2) design-clarifier        ── UX / màu sắc / luồng ────┤     │
   (3) standards-coordinator   ── ngôn ngữ + tiêu chuẩn ───┤     │
                                                           ▼     │
   (4) requirement-reporter    ── tài liệu phân tích đầy đủ      │
                └───────────────────[ ✋ CHECKPOINT A ]──────────┘
                                          │
                ┌───────────────────────▼───────────────────────┐
                │  GIAI ĐOẠN 2 — BREAKDOWN & PLAN (per feature) │
                ├───────────────────────────────────────────────┤
   (5) story-creator     ── Epic + User Stories                  │
   (6) story-splitter    ── chia story L/XL                      │
   (7) task-decomposer   ── tasks/subtasks atomic (<2h)          │
   (8) task-planner      ── timeline + critical path             │
   (9) parallel-evaluator── execution waves                      │
                └───────────────────[ ✋ CHECKPOINT B ]──────────┘
                                          │
                ┌───────────────────────▼───────────────────────┐
                │  GIAI ĐOẠN 3 — EXECUTION                       │
                ├───────────────────────────────────────────────┤
  (10) code-executor     ── implement + cập nhật checklist  ◄─┐  │
  (11) progress-tracker  ── checklist per-feature, resume brief│  │
                └─────────────────────────┬────────────────────┘  │
                                          │                       │
                ┌───────────────────────▼───────────────────────┐│
                │  GIAI ĐOẠN 4 — REVIEW & REPORT                ││
                ├───────────────────────────────────────────────┤│
  (12) task-reviewer     ── review từng task                    ││
  (13) group-reviewer    ── review tích hợp nhóm                ││
  (14) result-updater    ── tracking + audit trail              ││
        │ nếu fail → quay lại (10) ───────────────────────────────┘
        ▼
  (15) execution-reporter── báo cáo tổng kết cuối cùng
```

> Tiện ích xuyên suốt: **template-manager** — bất kỳ lúc nào cần một loại tài liệu chưa có template, gọi agent này tạo mẫu trước rồi mới soạn nội dung.

---

## Hướng dẫn chi tiết từng bước

| # | Agent | Input | Output | Lưu tại |
|---|-------|-------|--------|---------|
| 1 | `requirement-clarifier` | Yêu cầu gốc của user | Hỏi 3-5 câu/vòng, **kèm đề xuất phương án + chọn phương án tốt nhất cho hiện trạng**; requirements confirmed | `docs/00-discovery/requirements-clarified.md` |
| 2 | `design-clarifier` | Requirements đã rõ | Luồng UX, màu sắc (palette + hex), typography, trạng thái, accessibility, tư vấn hướng thiết kế | `docs/00-discovery/design-decisions.md` |
| 3 | `standards-coordinator` | Requirements + design | Chốt **ngôn ngữ tài liệu** + **tiêu chuẩn** (Agile/IEEE/lightweight) + định nghĩa **bộ tài liệu per-feature** | `docs/00-discovery/standards-decision.md` |
| 4 | `requirement-reporter` | (1)(2)(3) | Tài liệu phân tích đầy đủ, chuyên nghiệp, theo tiêu chuẩn đã chốt | `docs/00-discovery/requirements-report.md` |
| 5 | `story-creator` | Báo cáo requirements | Epic + User Stories (Given/When/Then, INVEST, sizing) cho từng feature | `docs/features/<feature>/epic.md`, `.../user-stories.md` |
| 6 | `story-splitter` | Stories L/XL | Story con 1-3 ngày + INVEST checklist | `docs/features/<feature>/stories-split.md` |
| 7 | `task-decomposer` | Stories | Tasks/subtasks atomic (<2h) + dependency graph | `docs/features/<feature>/tasks.md` |
| 8 | `task-planner` | Tasks | Timeline theo phase + critical path + rủi ro | `docs/execution/execution-plan.md` |
| 9 | `parallel-evaluator` | Tasks + plan | Execution waves + xung đột file + sync points | `docs/execution/parallel-map.md` |
| 10 | `code-executor` | Tasks + waves | Code thực thi + cập nhật checklist + log per task | code + `docs/features/<feature>/feature-checklist.md` + `docs/execution/execution-log.md` |
| 11 | `progress-tracker` | Checklist + log | Duy trì checklist, **resume brief** đầu phiên làm việc | `docs/features/<feature>/feature-checklist.md` |
| 12 | `task-reviewer` | Code changes | Review vs done criteria, điểm 1-10, status | `docs/features/<feature>/reviews/task-reviews.md` |
| 13 | `group-reviewer` | Nhóm task | Review tích hợp (data flow, API, shared state) | `docs/features/<feature>/reviews/group-reviews.md` |
| 14 | `result-updater` | Kết quả review | Dashboard + audit trail thay đổi trạng thái | `docs/execution/tracking.md` |
| 15 | `execution-reporter` | Toàn bộ docs | Báo cáo tổng kết: metrics, coverage, lessons, khuyến nghị | `docs/reports/final-report.md` |

---

## Quy tắc Pipeline

1. **Tuần tự bắt buộc** các bước 1 → 9. Không nhảy bước nếu input bước trước chưa đủ rõ.
2. **Khi hỏi phải tư vấn**: mọi agent ở giai đoạn discovery (1-3) không chỉ đặt câu hỏi mà phải **đưa ra 2-3 phương án, phân tích trade-off và đề xuất phương án tốt nhất cho hiện trạng hiện tại**.
3. **Vòng lặp review**: bước 10 ↔ 12/13/14 — nếu review `needs-revision`/`rejected` thì quay lại `code-executor` cho tới khi `approved`.
4. **Checkpoint xin phê duyệt user**:
   - ✋ **Checkpoint A** — sau bước 4 (requirements + design + standards): user duyệt phạm vi, thiết kế, ngôn ngữ & tiêu chuẩn tài liệu.
   - ✋ **Checkpoint B** — sau bước 8 (execution plan): user duyệt kế hoạch & timeline trước khi code.
5. **Dừng nếu chưa rõ**: nếu bước trước còn câu hỏi mở quan trọng, dừng lại và làm rõ, không tự suy diễn.
6. **Bộ tài liệu per-feature**: mỗi yêu cầu chức năng có **thư mục riêng** `docs/features/<feature>/` chứa đầy đủ bộ tài liệu (epic, stories, tasks, checklist, bugs, reviews) theo tiêu chuẩn đã chốt.
7. **Checklist liền mạch**: `code-executor` + `progress-tracker` luôn cập nhật `feature-checklist.md` ngay sau mỗi task để phiên làm việc sau **resume không mất công tìm hiểu lại**.
8. **Thiếu mẫu thì tạo mẫu trước**: nếu cần loại tài liệu chưa có template → gọi `template-manager` tạo `docs/templates/<name>.md` rồi mới soạn, để tái sử dụng.
9. **Mọi output lưu vào `docs/`** theo cấu trúc thư mục bên dưới.

---

## Cấu trúc thư mục `docs/`

```
docs/
├── templates/                     # mẫu tài liệu tái sử dụng
├── 00-discovery/
│   ├── requirements-clarified.md
│   ├── design-decisions.md
│   ├── standards-decision.md
│   └── requirements-report.md
├── features/
│   └── <feature-id>-<name>/
│       ├── epic.md
│       ├── user-stories.md
│       ├── stories-split.md
│       ├── tasks.md
│       ├── feature-checklist.md   # ★ tiến độ liền mạch
│       ├── bug-report.md
│       └── reviews/
│           ├── task-reviews.md
│           └── group-reviews.md
├── execution/
│   ├── execution-plan.md
│   ├── parallel-map.md
│   ├── execution-log.md
│   └── tracking.md
└── reports/
    └── final-report.md
```

---

## Bảng mapping Bước ↔ Template

| Bước | Agent | Template (`docs/templates/`) |
|------|-------|------------------------------|
| 1 | requirement-clarifier | `requirements-clarified.md` |
| 2 | design-clarifier | `design-decisions.md` |
| 3 | standards-coordinator | `standards-decision.md` |
| 4 | requirement-reporter | `requirements-report.md` |
| 5 | story-creator | `epic.md`, `user-stories.md` |
| 6 | story-splitter | `stories-split.md` |
| 7 | task-decomposer | `tasks.md` |
| 8 | task-planner | `execution-plan.md` |
| 9 | parallel-evaluator | `parallel-map.md` |
| 10 | code-executor | `execution-log.md`, `feature-checklist.md` |
| 11 | progress-tracker | `feature-checklist.md` |
| 12 | task-reviewer | `task-review.md` |
| 13 | group-reviewer | `group-review.md` |
| 14 | result-updater | `tracking.md` |
| 15 | execution-reporter | `final-report.md` |
| — | (bug bất kỳ lúc nào) | `bug-report.md` |

---

## Cách sử dụng

- Gõ **`#execute`** trong chat để kích hoạt skill và bắt đầu từ bước 1.
- Có thể **nhảy bước** nếu input của bước đó đã có sẵn (vd: đã có requirements-report → vào thẳng bước 5). Nêu rõ bạn muốn bắt đầu từ bước nào.
- Tôn trọng 2 checkpoint phê duyệt (A sau bước 4, B sau bước 8).
- Khi quay lại làm việc sau một thời gian, gọi `progress-tracker` để nhận **resume brief** trước khi tiếp tục.
