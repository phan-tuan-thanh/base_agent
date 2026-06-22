# Hướng dẫn tạo Custom Agent (Kiro)

Tài liệu này mô tả **format chuẩn** để tạo một custom agent trong `.kiro/agents/`.
Mỗi agent là một file JSON hợp lệ duy nhất — **không markdown, không văn bản ngoài JSON**.

---

## 1. JSON Schema mẫu

```json
{
  "name": "kebab-case-name",
  "description": "Mô tả ngắn bằng tiếng Việt (vai trò + nhiệm vụ chính).",
  "prompt": "English prompt: ROLE, RESPONSIBILITIES, SCOPE, CONSTRAINTS, OUTPUT FORMAT.",
  "tools": ["fs_read", "fs_write"],
  "resources": ["file://docs/**/*.md", "file://.kiro/**/*.md"]
}
```

| Trường | Bắt buộc | Mô tả |
|--------|----------|-------|
| `name` | ✅ | Tên agent, **kebab-case**, trùng tên file (`<name>.json`). |
| `description` | ✅ | Mô tả ngắn **tiếng Việt** để người dùng nhận diện agent. |
| `prompt` | ✅ | Chỉ thị cho agent, viết **English**, cấu trúc 5 mục (xem mục 3). |
| `tools` | ✅ | Danh sách công cụ agent được phép dùng. |
| `resources` | ✅ | Các pattern file agent được phép truy cập (`file://...`). |

---

## 2. Quy tắc đặt tên

- Dùng **kebab-case**: chữ thường, nối bằng dấu `-` (vd: `task-reviewer`).
- Tên file = `name` + `.json`.
- Tên phản ánh **vai trò/chức năng**, không viết tắt khó hiểu.

---

## 3. Hướng dẫn viết `prompt` (English)

Luôn gồm 5 phần, viết rõ ràng, ngắn gọn:

1. **ROLE** — vai trò chuyên gia (vd: "You are a Senior Code Reviewer").
2. **RESPONSIBILITIES** — danh sách việc agent phải làm.
3. **SCOPE** — phạm vi: làm gì, KHÔNG làm gì (bàn giao cho agent khác).
4. **CONSTRAINTS** — ràng buộc bắt buộc (ngôn ngữ, an toàn, giới hạn).
5. **OUTPUT FORMAT** — định dạng output + template tham chiếu + nơi lưu file.

> Mẹo: khi agent đặt câu hỏi, yêu cầu nó **kèm tư vấn phương án + đề xuất lựa chọn tốt nhất** cho hiện trạng, không chỉ hỏi suông.

---

## 4. Tools phổ biến

| Tool | Dùng khi |
|------|----------|
| `fs_read` | Đọc file (mọi agent). |
| `fs_write` | Tạo/sửa file (agent soạn tài liệu, code). |
| `execute_bash` | Chạy lệnh terminal (agent thực thi/build/test). |

> Agent review **chỉ nên có `fs_read`** (read-only) để không vô tình sửa code.

## 5. Resources phổ biến

| Pattern | Ý nghĩa |
|---------|---------|
| `file://docs/**/*.md` | Toàn bộ tài liệu Markdown trong `docs/`. |
| `file://.kiro/**/*.md` | Steering & cấu hình Kiro. |
| `file://**/*` | Toàn bộ workspace (chỉ cho executor/reviewer). |
| `file://**/*.yaml`, `file://**/*.ps1` | Giới hạn theo loại file cụ thể. |

---

## 6. Ví dụ hoàn chỉnh — `terraform-reviewer`

```json
{
  "name": "terraform-reviewer",
  "description": "Senior DevOps — review Terraform về bảo mật, chi phí và best practices.",
  "prompt": "ROLE: You are a Senior DevOps / Infrastructure Reviewer.\n\nRESPONSIBILITIES:\n- Review Terraform changes for security, cost, and HashiCorp best practices.\n- Check IAM least-privilege, state safety, tagging, and drift risks.\n- Give a 1-10 score and a status: approved / needs-revision / rejected.\n\nSCOPE: Terraform/IaC review only. Read-only.\n\nCONSTRAINTS:\n- Never modify infrastructure code; report findings only.\n- Reference file and resource block for each issue.\n\nOUTPUT FORMAT (Markdown): issues table (severity, resource, fix), score, status. Save to docs/reviews/terraform-review.md.",
  "tools": ["fs_read"],
  "resources": ["file://**/*.tf", "file://docs/**/*.md"]
}
```

---

## 7. Lưu ý quan trọng

- Output của file agent **chỉ là JSON hợp lệ** — không có markdown, không có chú thích, không có văn bản ngoài JSON.
- `prompt` viết **English**; `description` viết **tiếng Việt**.
- Mọi tài liệu agent tạo ra phải lưu vào `docs/` theo cấu trúc đã quy ước.
- Nếu cần loại tài liệu chưa có template → gọi `template-manager` tạo mẫu trước.
