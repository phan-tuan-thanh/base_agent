# Skill "Execute" — Hệ thống pipeline thực hiện End-to-End cho Kiro

Bộ cấu hình tạo pipeline tự động: **làm rõ yêu cầu → phân tích & thiết kế → lập kế hoạch → thực hiện → review → báo cáo**.

Kích hoạt bằng `#execute` trong Kiro chat.

> 📖 Cách làm việc thực tế hằng ngày: xem **[usage-guide.md](usage-guide.md)**.

## Cấu trúc

```
.kiro/
├── agents/                  # 16 custom agents + hướng dẫn
│   ├── _agent-template.md
│   ├── requirement-clarifier.json    # hỏi + tư vấn phương án tốt nhất
│   ├── design-clarifier.json         # UX / màu sắc / luồng trải nghiệm
│   ├── standards-coordinator.json    # ngôn ngữ + tiêu chuẩn tài liệu
│   ├── requirement-reporter.json
│   ├── story-creator.json
│   ├── story-splitter.json
│   ├── task-decomposer.json
│   ├── task-planner.json
│   ├── parallel-evaluator.json
│   ├── code-executor.json            # implement + cập nhật checklist
│   ├── progress-tracker.json         # checklist liền mạch giữa các phiên
│   ├── task-reviewer.json
│   ├── group-reviewer.json
│   ├── result-updater.json
│   ├── execution-reporter.json
│   └── template-manager.json         # tạo mẫu còn thiếu trước khi dùng
└── steering/
    └── execute.md           # bộ điều phối pipeline (#execute)

docs/
├── templates/               # 17 mẫu tài liệu tái sử dụng
├── 00-discovery/            # requirements, design, standards, report
├── features/<feature>/      # bộ tài liệu RIÊNG mỗi chức năng
│   ├── epic.md
│   ├── user-stories.md
│   ├── stories-split.md
│   ├── tasks.md
│   ├── feature-checklist.md # ★ tiến độ liền mạch
│   ├── bug-report.md
│   └── reviews/
├── execution/               # plan, parallel-map, log, tracking
└── reports/                 # final-report
```

## Điểm cải tiến chính
1. **Làm rõ yêu cầu kèm thiết kế/UX/màu sắc** và **tư vấn + đề xuất phương án tốt nhất** cho hiện trạng (không chỉ hỏi suông).
2. **Chốt ngôn ngữ + tiêu chuẩn tài liệu** trước khi soạn docs chuyên nghiệp.
3. **Mỗi chức năng có bộ tài liệu riêng** (epic, story, task, subtask, bug, review) theo tiêu chuẩn đã chọn.
4. **Checklist per-feature** giúp tiến độ luôn cập nhật → phiên làm việc sau resume không mất công tìm hiểu lại.
5. Lệnh đổi từ `thuc-hien` → **`execute`** (thống nhất tiếng Anh).
6. **Thiếu mẫu thì tạo mẫu trước** (template-manager) để tái sử dụng.

## Cách dùng
1. Copy `.kiro/` và `docs/` vào thư mục gốc dự án Kiro.
2. Trong Kiro chat, gõ `#execute` để bắt đầu.
3. Tôn trọng 2 checkpoint phê duyệt (sau requirements, sau plan).
