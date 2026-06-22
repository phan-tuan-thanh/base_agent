# Hướng dẫn sử dụng — Skill "Execute"

Tài liệu này hướng dẫn **cách làm việc thực tế** với pipeline khi bạn ngồi vào code. Đọc README.md để hiểu cấu trúc; đọc file này để biết *thao tác từng ngày*.

---

## 1. Cài đặt (1 lần)

1. Giải nén gói, copy thư mục `.kiro/` và `docs/` vào **thư mục gốc dự án** Kiro.
2. Mở Kiro, kiểm tra:
   - 16 agents xuất hiện trong danh sách custom agents.
   - Steering `execute` có thể gọi bằng `#execute`.
3. Xóa thư mục mẫu `docs/features/example-feature/` nếu không cần.

---

## 2. Bắt đầu nhanh (Quick start)

Trong Kiro chat, gõ:

```
#execute
[mô tả việc bạn muốn làm, càng cụ thể càng tốt]
```

Ví dụ:
```
#execute
Tôi muốn làm trang quản lý công việc cá nhân: thêm/sửa/xóa task, có deadline và nhắc nhở.
```

Pipeline sẽ bắt đầu từ **bước 1 (làm rõ yêu cầu)** và đi tuần tự.

---

## 3. Vai trò của BẠN trong từng giai đoạn

Pipeline tự động chạy, nhưng có 3 việc bạn cần làm:

### a) Trả lời câu hỏi làm rõ (bước 1-3)
Các agent sẽ hỏi 3-5 câu/vòng và **kèm đề xuất phương án**. Bạn chỉ cần:
- Chọn phương án (A/B/C) hoặc nói rõ mong muốn.
- Nếu không chắc, hỏi lại "phương án nào tốt nhất cho trường hợp của tôi?" — agent sẽ tư vấn.

### b) Duyệt 2 checkpoint ✋
- **Checkpoint A** (sau bước 4): duyệt phạm vi yêu cầu + thiết kế + ngôn ngữ/tiêu chuẩn tài liệu.
- **Checkpoint B** (sau bước 8): duyệt kế hoạch & timeline trước khi code.

Trả lời `duyệt` / `OK tiếp tục` để đi tiếp, hoặc nêu điều cần sửa.

### c) Theo dõi tiến độ
Mở `docs/features/<feature>/feature-checklist.md` bất cứ lúc nào để xem đang làm tới đâu.

---

## 4. Gọi riêng từng agent (khi cần)

Không bắt buộc luôn chạy cả pipeline. Bạn có thể gọi 1 agent cho 1 việc cụ thể:

| Muốn làm | Gọi agent |
|----------|-----------|
| Làm rõ yêu cầu + tư vấn giải pháp | `requirement-clarifier` |
| Thống nhất UX/màu sắc/luồng | `design-clarifier` |
| Chốt ngôn ngữ + tiêu chuẩn tài liệu | `standards-coordinator` |
| Viết user story | `story-creator` |
| Chia task kỹ thuật | `task-decomposer` |
| Code 1 chức năng | `code-executor` |
| Review code | `task-reviewer` |
| Xem tiến độ / tóm tắt để tiếp tục | `progress-tracker` |
| Tạo mẫu tài liệu còn thiếu | `template-manager` |

---

## 5. Nhảy bước (khi đã có sẵn input)

Nếu bạn đã có sẵn đầu vào của một bước, nói rõ để bắt đầu từ đó:

```
#execute
Tôi đã có requirements-report rồi, bắt đầu từ bước 5 (tạo user story) cho feature "quản lý task".
```

Pipeline chỉ yêu cầu tuần tự **khi input bước trước chưa đủ rõ**.

---

## 6. ★ Tiếp tục công việc qua nhiều phiên (Resume)

Đây là điểm quan trọng để **không mất thời gian tìm hiểu lại**.

**Khi quay lại làm việc sau một thời gian:**

```
#execute
Tiếp tục feature "quản lý task". Cho tôi resume brief.
```

`progress-tracker` sẽ đọc `feature-checklist.md` và trả về:
- **Đã xong:** ...
- **Đang làm:** task nào, dở ở đâu
- **Tiếp theo:** task kế tiếp
- **Blocker:** nếu có

→ Bạn nắm ngay context và code tiếp, không cần đọc lại toàn bộ.

> Mẹo: `code-executor` tự cập nhật checklist sau mỗi task. Nếu bạn code tay ngoài pipeline, nhớ gọi `progress-tracker` để cập nhật lại cho khớp.

---

## 7. Các kịch bản thường gặp

### Kịch bản 1 — Dự án mới hoàn toàn
```
#execute
[mô tả dự án]
```
→ Chạy đủ bước 1 → 15. Duyệt 2 checkpoint.

### Kịch bản 2 — Thêm 1 feature vào dự án đang chạy
```
#execute
Thêm feature "xuất báo cáo PDF". Bắt đầu từ làm rõ yêu cầu cho riêng feature này.
```
→ Tạo thư mục `docs/features/<feature-mới>/` với bộ tài liệu riêng.

### Kịch bản 3 — Tiếp tục feature đang dở
→ Xem mục 6 (Resume).

### Kịch bản 4 — Review fail, cần sửa
→ Pipeline tự lặp: `code-executor` → `task-reviewer` → nếu `needs-revision` thì quay lại `code-executor` cho tới khi `approved`. Bạn chỉ cần duyệt kết quả.

### Kịch bản 5 — Phát sinh bug
```
Ghi nhận bug cho feature "quản lý task": [mô tả].
```
→ Tạo/ghi vào `docs/features/<feature>/bug-report.md`, rồi đưa vào task để sửa.

### Kịch bản 6 — Cần loại tài liệu chưa có mẫu
→ Gọi `template-manager` tạo mẫu trong `docs/templates/` trước, rồi mới soạn nội dung (để lần sau tái dùng).

---

## 8. Quy ước cần nhớ

- Mọi tài liệu nằm trong `docs/`. **Mỗi chức năng = 1 thư mục riêng** trong `docs/features/`.
- `feature-checklist.md` là **nguồn sự thật về tiến độ** — luôn cập nhật.
- Khi code: ưu tiên **tạo component tái sử dụng**, page chỉ *compose* component, tránh phình code.
- Khi agent hỏi: luôn có **đề xuất phương án tốt nhất** — đọc kỹ rồi chọn.
- Ngôn ngữ & tiêu chuẩn tài liệu được chốt 1 lần ở bước 3, áp dụng cho toàn bộ docs.

---

## 9. Xử lý sự cố (FAQ)

| Tình huống | Cách xử lý |
|-----------|------------|
| Agent đề xuất sai hướng | Trả lời rõ ràng hơn ở vòng hỏi tiếp theo, hoặc yêu cầu "đưa thêm phương án". |
| Quên đang làm tới đâu | Gọi `progress-tracker` để lấy resume brief. |
| Tài liệu sai ngôn ngữ | Gọi `standards-coordinator` chốt lại ngôn ngữ, rồi yêu cầu reporter soạn lại. |
| Code bị trùng lặp, phình to | Yêu cầu `code-executor` refactor tách component; hoặc nhờ `task-reviewer` chỉ ra chỗ trùng. |
| Tool terminal/git báo lỗi tên | Sửa trường `tools` trong `code-executor.json` cho khớp tên tool của Kiro bạn đang dùng. |
| Thiếu mẫu tài liệu | `template-manager` tạo mẫu trước khi soạn. |

---

## 10. Cheat sheet

```
#execute                         → bắt đầu / tiếp tục pipeline
"bắt đầu từ bước N"              → nhảy bước
"cho tôi resume brief"           → tóm tắt để tiếp tục công việc
"duyệt" / "OK tiếp tục"          → qua checkpoint
"thêm feature ..."               → tạo bộ tài liệu cho feature mới
"ghi nhận bug ..."               → tạo bug report
```

**Thứ tự pipeline:**
```
1 clarifier → 2 design → 3 standards → 4 reporter
✋A → 5 story → 6 split → 7 tasks → 8 plan → 9 parallel
✋B → 10 code ⇄ 11 tracker → 12/13 review → 14 tracking → (lặp nếu fail) → 15 report
```
