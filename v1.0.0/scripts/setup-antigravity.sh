#!/usr/bin/env bash
# =============================================================================
# setup-antigravity.sh
# Khởi tạo toàn bộ cấu hình cho Antigravity AI Agent
# Phiên bản 2.0 — Hệ thống 3-Phase: Requirements → Design → Tasks
# =============================================================================

set -euo pipefail

# ── Màu sắc terminal ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[✔]${RESET} $*"; }
info() { echo -e "${CYAN}[ℹ]${RESET} $*"; }
warn() { echo -e "${YELLOW}[⚠]${RESET} $*"; }
step() { echo -e "\n${BOLD}${BLUE}▶ $*${RESET}"; }
die()  { echo -e "${RED}[✘] $*${RESET}" >&2; exit 1; }

# ── Thư mục gốc ───────────────────────────────────────────────────────────────
ROOT="${1:-.antigravity}"
AG="$ROOT"

banner() {
  echo -e "${BOLD}${CYAN}"
  cat <<'EOF'
  ___          _   _                  _ _
 / _ \        | | (_)                (_) |
/ /_\ \_ ___ | |_ _  __ _ _ __ __ ___   _| |_ _   _
|  _  | '_ \| __| |/ _` | '__/ _` \ \ / / | __| | | |
| | | | | | | |_| | (_| | | | (_| |\ V /| | |_| |_| |
\_| |_/_| |_|\__|_|\__, |_|  \__,_| \_/ |_|\__|\__, |
                    __/ |                        __/ |
                   |___/                        |___/
EOF
  echo -e "${RESET}"
  echo -e "  ${BOLD}Antigravity AI Agent — Scaffold Setup v2.1${RESET}"
  echo -e "  ${BOLD}Clarify → 3-Phase → Report${RESET}"
  echo -e "  Root: ${YELLOW}$ROOT${RESET}\n"
}

# =============================================================================
# 1. CẤU TRÚC THƯ MỤC
# =============================================================================
create_dirs() {
  step "Tạo cấu trúc thư mục"
  local dirs=(
    "$AG/rules"
    "$AG/hooks"
    "$AG/mcp"
    "$AG/skills"
    "$AG/commands"
    "$AG/workflows"
    "$AG/memory"
    "$AG/plans"
    "$AG/context"
    "$AG/templates"
    "$AG/logs"
    "$AG/reports"
    "$AG/utils"
  )
  for d in "${dirs[@]}"; do
    mkdir -p "$d"
    log "  $d"
  done
}

# =============================================================================
# 2. RULES — Quy tắc hành vi cốt lõi (3-Phase)
# =============================================================================
create_rules() {
  step "Tạo Rules (3-Phase)"

  # 2-a. Core Rules
  cat > "$AG/rules/00-core.md" <<'RULE'
# Antigravity — Core Rules (v2.0 — 3-Phase)

## Nguyên tắc bất biến

1. **Quy trình 3-Phase bắt buộc**
   - Trước BẤT KỲ task nào, Agent PHẢI hoàn thành đầy đủ 3 tài liệu theo đúng thứ tự:
     **Phase 1: Requirements** → **Phase 2: Design** → **Phase 3: Tasks**
   - Agent TUYỆT ĐỐI KHÔNG ĐƯỢC viết code khi chưa hoàn tất và được approve cả 3 phase.
   - Mỗi phase phải được người dùng review và approve trước khi chuyển sang phase tiếp theo.

2. **Tự động thực thi Command theo quy trình**
   - **Khởi chạy task**: Agent PHẢI tự động chạy `bash .antigravity/commands/new-task.sh "<mô tả task>"` để khởi tạo scaffold 3 file (requirements, design, tasks).
   - **Tạo Design**: Khi requirements đã approved, Agent PHẢI tự động chạy `bash .antigravity/commands/create-design.sh "<mô tả task>"` nếu file design chưa tồn tại.
   - **Thực thi**: Khi cả 3 file đều approved, Agent PHẢI tự động chạy `bash .antigravity/commands/execute-plan.sh "<đường dẫn tasks file>"`.
   - **Cập nhật trạng thái**: Trước khi báo cáo, Agent PHẢI chạy `bash .antigravity/commands/status.sh`.

3. **Cập nhật tiến độ live**
   - Sau mỗi step hoàn thành, Agent PHẢI:
     (a) Cập nhật checkbox `[x]` trong file tasks tương ứng.
     (b) Ghi Progress Log vào file design.
     (c) Chạy `bash .antigravity/hooks/post-step.sh "<task-slug>" "<step>" "<status>"`.

4. **Đọc Steering Data trước mọi quyết định**
   - Agent PHẢI đọc `memory/project.context.json` (chứa architecture patterns, coding standards, tech stack) trước khi viết design hoặc code.

5. **Ghi log mọi hành động**
   - Append vào `logs/agent.log` theo format ISO-8601.

6. **Không bao giờ giả định**
   - Nếu thông tin còn mơ hồ → hỏi thêm, không tự suy diễn.

7. **Ưu tiên an toàn**
   - Các lệnh phá hoại (xóa, ghi đè, deploy) luôn yêu cầu xác nhận tường minh từ người dùng.
RULE
  log "rules/00-core.md"

  # 2-b. Requirements Rule
  cat > "$AG/rules/01-requirements.md" <<'RULE'
# Requirements Rule (Phase 1)

## Bắt buộc viết tài liệu yêu cầu chuẩn PROD

Trước khi chuyển sang Design, Agent PHẢI hoàn thành file requirements với đầy đủ:

### Checklist bắt buộc
```
[ ] ≥1 User Story theo format: "As a [role], I want to [action], so that [benefit]"
[ ] ≥1 Acceptance Criteria cho MỖI story theo format: "Given [context], When [action], Then [result]"
[ ] Non-functional Requirements (Performance, Security, Accessibility)
[ ] Out of Scope (những gì KHÔNG làm)
[ ] User đã review và APPROVED file requirements
```

### Tự động chạy lệnh khởi tạo
- Khi nhận task mới, Agent tự động chạy:
  `bash .antigravity/commands/new-task.sh "<mô tả task>"`
- Đọc nội dung file requirements mới tại `.antigravity/context/requirements-*.md` để điền.

### Mẫu User Story
```markdown
### US-1: Đăng nhập bằng email
> **As a** người dùng đã đăng ký,
> **I want to** đăng nhập bằng email và mật khẩu,
> **so that** tôi có thể truy cập tài khoản cá nhân.

#### Acceptance Criteria
- [ ] **Given** email và mật khẩu hợp lệ, **When** nhấn nút Login, **Then** chuyển hướng đến trang dashboard.
- [ ] **Given** email không tồn tại, **When** nhấn nút Login, **Then** hiển thị lỗi "Email không tồn tại".
- [ ] **Given** mật khẩu sai, **When** nhấn nút Login, **Then** hiển thị lỗi "Mật khẩu không đúng".
```

### Điều kiện chuyển phase
- Tất cả ô checklist đã được đánh dấu **VÀ**
- Người dùng đã approve file requirements
- Chạy: `bash .antigravity/commands/approve-plan.sh "<requirements-file>"`
RULE
  log "rules/01-requirements.md"

  # 2-c. Design & Tasks Rule
  cat > "$AG/rules/02-design-tasks.md" <<'RULE'
# Design & Tasks Rule (Phase 2 + Phase 3)

## Phase 2: Design — Bắt buộc phân tích thiết kế

Trước khi chia task, Agent PHẢI hoàn thành file design với đầy đủ:

### Checklist Design bắt buộc
```
[ ] Architecture Overview (sơ đồ thành phần, data flow)
[ ] Data Model (nếu có: schema, entities, relationships)
[ ] API Contracts (nếu có: endpoints, request/response)
[ ] File Map — bảng liệt kê file [NEW], [MODIFY], [DELETE]
[ ] Technical Decisions (lý do chọn giải pháp A thay vì B)
[ ] Risks & Mitigation
[ ] User đã review và APPROVED file design
```

### Quy tắc viết Design
- Đọc `memory/project.context.json` để tuân thủ architecture patterns, coding standards
- Chạy `bash .antigravity/hooks/pre-design.sh` trước khi tạo design (kiểm tra requirements đã approved)
- Chạy `bash .antigravity/commands/create-design.sh "<mô tả task>"` nếu file chưa tồn tại

## Phase 3: Tasks — Bắt buộc chia nhỏ công việc

### Checklist Tasks bắt buộc
```
[ ] Mỗi task là một checkbox `- [ ]` rõ ràng
[ ] Mỗi task liên kết ngược tới User Story (US-1, US-2, ...)
[ ] Có Verification Checklist (AC met, tests pass, no regression)
[ ] User đã review và APPROVED file tasks
```

### Cập nhật tiến độ live
- Sau mỗi step → cập nhật `- [x]` trong file tasks
- Sau mỗi step → ghi Progress Log trong file design
- Chạy `bash .antigravity/hooks/post-step.sh "<task>" "<step>" "<status>"`
RULE
  log "rules/02-design-tasks.md"

  # 2-d. Memory & Steering Rule
  cat > "$AG/rules/03-memory.md" <<'RULE'
# Memory & Steering Rule

## Shared Context Memory

- `memory/project.context.json` — thông tin dự án + steering data (architecture, coding style, tech stack)
- `memory/session.context.json` — thông tin phiên làm việc hiện tại
- `memory/decisions.log.md`    — lịch sử quyết định quan trọng
- `memory/glossary.md`         — thuật ngữ dự án

## Steering Data (tích hợp trong project.context.json)

Agent PHẢI đọc các trường sau trong `project.context.json` trước khi viết design hoặc code:
- `architecture_patterns` — folder structure, design pattern, state management
- `coding_standards` — naming convention, formatting, linting
- `testing_strategy` — test framework, coverage minimum
- `api_conventions` — REST/GraphQL style, versioning, error format

## Tải context khi bắt đầu

Antigravity PHẢI:
1. Đọc toàn bộ file memory trước khi hỏi làm rõ, để tránh hỏi lại những gì đã biết.
2. Chạy `bash .antigravity/commands/status.sh` để đồng bộ và hiển thị trạng thái.

## Cập nhật context sau mỗi task

Sau khi hoàn thành, append vào `memory/decisions.log.md`:
```
## [YYYYMMDD] <Task title>
- Quyết định: ...
- Lý do: ...
- Kết quả: ...
```
RULE
  log "rules/03-memory.md"

  # 2-e. Clarify & Confirm Rule
  cat > "$AG/rules/04-clarify-confirm.md" <<'RULE'
# Clarify & Confirm Rule (Pre-Execute Protocol)

## Bắt buộc trước mỗi task thực thi — 4 bước không được bỏ qua

### Bước 1: Phân tích yêu cầu
Agent PHẢI tự phân tích và xác định:
- Mục tiêu rõ ràng là gì?
- Phạm vi ảnh hưởng (files, modules, systems)?
- Những điều còn mơ hồ cần làm rõ?

### Bước 2: Làm rõ (nếu cần)
- Nếu còn điểm mơ hồ → hỏi tối đa 3 câu, ưu tiên câu quan trọng nhất trước
- Format câu hỏi bắt buộc:
  ```
  ❓ [1/3] <câu hỏi quan trọng nhất>
  ❓ [2/3] <câu hỏi thứ hai>
  ❓ [3/3] <câu hỏi thứ ba>
  ```
- Không hỏi những điều đã có trong `memory/project.context.json`
- Không hỏi nhiều hơn 3 câu mỗi lượt

### Bước 3: Trình bày Solution Summary
Sau khi đủ thông tin, Agent PHẢI chạy:
`bash .antigravity/commands/clarify.sh "<task-description>"` để tạo file Solution Summary,
sau đó trình bày nội dung cho user theo format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📐 SOLUTION SUMMARY — <tên task>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Hiểu của tôi: <1-2 câu tóm tắt yêu cầu>

💡 Giải pháp:
   Approach: <hướng tiếp cận>
   Pattern:  <design pattern nếu có>

✅ Sẽ làm:
   - <action 1>
   - <action 2>

🚫 Sẽ KHÔNG làm:
   - <item ngoài scope>

📁 Files ảnh hưởng:
   [NEW]    <file>
   [MODIFY] <file>

⚠️  Rủi ro:
   - <risk nếu có, hoặc "Không có rủi ro đáng kể">
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👉 Bạn có muốn tiến hành với giải pháp này không?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Bước 4: Chờ user chốt
- TUYỆT ĐỐI KHÔNG bắt đầu thực thi cho đến khi user xác nhận
- Nếu user yêu cầu chỉnh sửa → cập nhật solution và trình bày lại
- Chỉ proceed khi user nói: "OK", "Đồng ý", "Proceed", "Làm đi", hoặc tương đương
- Khi user chốt → chạy: `bash .antigravity/commands/approve-plan.sh "<solution-summary-file>"`

### Forbidden actions (không bao giờ làm)
- Bắt đầu code trước khi user chốt solution
- Refactor code ngoài scope đã khai báo
- Xóa code "có vẻ không dùng" mà không hỏi
- Tự thêm abstraction/helper ngoài yêu cầu
- Giả định tech stack nếu chưa có trong project.context.json
RULE
  log "rules/04-clarify-confirm.md"

  # 2-f. Reporting Rule
  cat > "$AG/rules/05-reporting.md" <<'RULE'
# Reporting Rule (Post-Execute Protocol)

## Bắt buộc sau mỗi task hoàn thành

### Agent PHẢI thực hiện đủ 3 bước:

**Bước 1 — Tạo báo cáo:**
Chạy: `bash .antigravity/commands/generate-report.sh "<tasks-file>" "<status>"`
→ Báo cáo được lưu tự động vào `reports/<ts>-<slug>.report.md`

**Bước 2 — Hiển thị summary cho user:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 BÁO CÁO HOÀN THÀNH: <task name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Tasks hoàn thành : X/Y
🎯 Acceptance Criteria: X/Y đã met
📁 Files thay đổi   : N file(s)
⏱️  Thời gian        : <thực tế>
📄 Báo cáo đầy đủ  : reports/<filename>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Đề xuất tiếp theo: <1-2 câu gợi ý>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Bước 3 — Cập nhật memory:**
- Append vào `memory/decisions.log.md`
- Cập nhật `memory/session.context.json`

### Nội dung báo cáo bắt buộc
- Tổng quan kết quả (3-5 câu)
- Công việc đã hoàn thành (từ checkbox [x])
- Công việc chưa hoàn thành (nếu có)
- Files đã tạo / sửa / xóa (từ design file map)
- Acceptance Criteria: từng AC đã met hay chưa
- Vấn đề gặp phải và cách xử lý
- Đề xuất bước tiếp theo

### Khi task thất bại (status: failed / partial)
Báo cáo PHẢI bao gồm thêm:
- Root cause phân tích
- Bước nào thất bại và lý do
- Rollback đã thực hiện (nếu có)
- Đề xuất fix
RULE
  log "rules/05-reporting.md"
}

# =============================================================================
# 3. HOOKS — Lifecycle hooks (3-Phase)
# =============================================================================
create_hooks() {
  step "Tạo Hooks (3-Phase)"

  # 3-a. Pre-task hook
  cat > "$AG/hooks/pre-task.sh" <<'HOOK'
#!/usr/bin/env bash
# pre-task.sh — Chạy trước mỗi task
# Usage: bash hooks/pre-task.sh "<task_description>"

set -euo pipefail
TASK="${1:-unknown task}"
TS=$(date '+%Y%m%d-%H%M%S')
LOG=".antigravity/logs/agent.log"

echo "[${TS}] [PRE-TASK] Starting: ${TASK}" >> "$LOG"

# Load shared context
if [[ -f ".antigravity/memory/project.context.json" ]]; then
  echo "📂 Project context (steering data) loaded."
fi

# Reminder: 3-Phase Documentation Required
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 ANTIGRAVITY — 3-Phase Documentation Required"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task: $TASK"
echo ""
echo "Trước khi viết code, Agent PHẢI hoàn thành 3 phase:"
echo "  Phase 1: 📋 REQUIREMENTS — User Stories + Acceptance Criteria"
echo "  Phase 2: 🏗️  DESIGN      — Architecture + File Map + Data Model"
echo "  Phase 3: ✅ TASKS        — Task Breakdown (checkbox liên kết US)"
echo ""
echo "Mỗi phase phải được USER approve trước khi chuyển tiếp."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
HOOK
  chmod +x "$AG/hooks/pre-task.sh"
  log "hooks/pre-task.sh"

  # 3-b. Post-task hook (tự động generate report)
  cat > "$AG/hooks/post-task.sh" <<'HOOK'
#!/usr/bin/env bash
# post-task.sh — Chạy sau mỗi task: cập nhật log + tự động tạo báo cáo
# Usage: bash hooks/post-task.sh "<task_slug>" "<status: success|partial|failed>" [tasks-file]

set -euo pipefail
TASK="${1:-unknown}"
STATUS="${2:-success}"
TASKS_FILE="${3:-}"
TS=$(date '+%Y%m%d-%H%M%S')
LOG=".antigravity/logs/agent.log"
MEM=".antigravity/memory/decisions.log.md"

echo "[${TS}] [POST-TASK] $TASK => $STATUS" >> "$LOG"

# Cập nhật decisions log
cat >> "$MEM" <<MD

## [$TS] $TASK
- Status: $STATUS
- Ghi chú: (điền tự động hoặc thủ công)
MD

# Tự động generate report nếu có tasks file
if [[ -n "$TASKS_FILE" && -f "$TASKS_FILE" ]]; then
  echo ""
  echo "📊 Đang tạo báo cáo..."
  bash .antigravity/commands/generate-report.sh "$TASKS_FILE" "$STATUS"
else
  # Tìm tasks file gần nhất theo task slug
  LATEST_TASKS=$(find .antigravity/plans -name "*tasks*.md" 2>/dev/null | sort -r | head -1)
  if [[ -n "$LATEST_TASKS" ]]; then
    echo ""
    echo "📊 Đang tạo báo cáo từ: $LATEST_TASKS"
    bash .antigravity/commands/generate-report.sh "$LATEST_TASKS" "$STATUS"
  else
    echo "⚠️  Không tìm thấy tasks file để tạo báo cáo."
    echo "   Chạy thủ công: bash .antigravity/commands/generate-report.sh <tasks-file>"
  fi
fi
HOOK
  chmod +x "$AG/hooks/post-task.sh"
  log "hooks/post-task.sh"

  # 3-c. Pre-design hook (thay thế pre-plan)
  cat > "$AG/hooks/pre-design.sh" <<'HOOK'
#!/usr/bin/env bash
# pre-design.sh — Kiểm tra trước khi tạo design
# Usage: bash hooks/pre-design.sh
set -euo pipefail

CTX_DIR=".antigravity/context"
PLAN_DIR=".antigravity/plans"

# Kiểm tra requirements đã approved chưa
REQ_APPROVED=$(grep -rl "Status: APPROVED" "$CTX_DIR" 2>/dev/null | head -1 || true)
if [[ -z "$REQ_APPROVED" ]]; then
  echo "⚠️  Chưa có file requirements nào được APPROVED!"
  echo "   Hãy hoàn thành Phase 1 (Requirements) trước."
  echo "   Chạy: bash .antigravity/commands/approve-plan.sh <requirements-file>"
fi

# Kiểm tra design/tasks draft chưa xử lý
DRAFTS=$(grep -rl "Status: DRAFT" "$PLAN_DIR" 2>/dev/null || true)
if [[ -n "$DRAFTS" ]]; then
  DRAFT_COUNT=$(echo "$DRAFTS" | wc -l | tr -d ' ')
  echo "📋 Có $DRAFT_COUNT file DRAFT chưa xử lý:"
  echo "$DRAFTS" | head -5
fi

echo "✅ Pre-design check complete."
HOOK
  chmod +x "$AG/hooks/pre-design.sh"
  log "hooks/pre-design.sh"

  # 3-d. Post-step hook (MỚI — cập nhật tiến độ live)
  cat > "$AG/hooks/post-step.sh" <<'HOOK'
#!/usr/bin/env bash
# post-step.sh — Chạy sau mỗi step trong execution
# Usage: bash hooks/post-step.sh "<task-slug>" "<step-number>" "<status: done|failed>"

set -euo pipefail
TASK="${1:-unknown}"
STEP="${2:-0}"
STATUS="${3:-done}"
TS=$(date '+%Y%m%d-%H%M%S')
LOG=".antigravity/logs/agent.log"

echo "[${TS}] [POST-STEP] Task=$TASK Step=$STEP Status=$STATUS" >> "$LOG"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step $STEP: $STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ Nhắc nhở Agent:"
echo "  1. Cập nhật checkbox [x] trong file tasks tương ứng"
echo "  2. Ghi Progress Log vào file design"
echo "  3. Kiểm tra AC liên quan đã met chưa"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
HOOK
  chmod +x "$AG/hooks/post-step.sh"
  log "hooks/post-step.sh"
}

# =============================================================================
# 4. MCP — Model Context Protocol configs (3-Phase Gates)
# =============================================================================
create_mcp() {
  step "Tạo MCP configs (3-Phase Gates)"

  cat > "$AG/mcp/mcp.config.json" <<'JSON'
{
  "version": "2.0",
  "agent": "Antigravity",
  "servers": [
    {
      "name": "filesystem",
      "type": "local",
      "description": "Đọc/ghi file trong project",
      "enabled": true,
      "config": {
        "root": ".",
        "allowWrite": true,
        "watchPatterns": ["**/*.md", "**/*.json", "**/*.sh"]
      }
    },
    {
      "name": "memory-store",
      "type": "local",
      "description": "Shared context memory + Steering data",
      "enabled": true,
      "config": {
        "path": ".antigravity/memory",
        "autoLoad": true,
        "autoSave": true
      }
    },
    {
      "name": "document-manager",
      "type": "local",
      "description": "Quản lý tài liệu 3-phase (requirements, design, tasks)",
      "enabled": true,
      "config": {
        "requirements_path": ".antigravity/context",
        "design_path": ".antigravity/plans",
        "tasks_path": ".antigravity/plans",
        "requireApproval": true
      }
    }
  ],
  "middleware": {
    "requirementsGate": {
      "enabled": true,
      "requireUserStories": true,
      "requireAcceptanceCriteria": true,
      "blockOnUnapproved": true,
      "description": "Chặn nếu requirements chưa có User Stories + AC hoặc chưa approved"
    },
    "designGate": {
      "enabled": true,
      "requireArchitectureOverview": true,
      "requireFileMap": true,
      "blockOnUnapproved": true,
      "description": "Chặn nếu design chưa có Architecture Overview + File Map hoặc chưa approved"
    },
    "tasksGate": {
      "enabled": true,
      "requireTaskBreakdown": true,
      "requireLinkToUserStory": true,
      "blockOnUnapproved": true,
      "description": "Chặn nếu tasks chưa có task breakdown hoặc chưa approved"
    },
    "auditLog": {
      "enabled": true,
      "path": ".antigravity/logs/agent.log"
    }
  }
}
JSON
  log "mcp/mcp.config.json"

  cat > "$AG/mcp/context-protocol.md" <<'MD'
# Context Protocol — Antigravity MCP (v2.0 — 3-Phase)

## Payload chuẩn gửi vào mỗi request

```json
{
  "agent": "Antigravity",
  "version": "2.0",
  "timestamp": "<ISO-8601>",
  "session_id": "<uuid>",
  "project_context": "<nội dung memory/project.context.json — bao gồm steering data>",
  "session_context": "<nội dung memory/session.context.json>",
  "phase_status": {
    "requirements": {
      "completed": false,
      "approved": false,
      "ref": "<đường dẫn file requirements>"
    },
    "design": {
      "completed": false,
      "approved": false,
      "ref": "<đường dẫn file design>"
    },
    "tasks": {
      "completed": false,
      "approved": false,
      "ref": "<đường dẫn file tasks>",
      "current_task": "<task đang thực thi>"
    }
  },
  "execution_status": {
    "total_tasks": 0,
    "completed_tasks": 0,
    "current_step": "<bước đang thực hiện>"
  }
}
```

## Các field bắt buộc

| Field | Bắt buộc | Mô tả |
|-------|----------|-------|
| agent | ✅ | Luôn là "Antigravity" |
| project_context | ✅ | Không được null — chứa steering data |
| phase_status.requirements.approved | ✅ | Phải là `true` trước khi chuyển Phase 2 |
| phase_status.design.approved | ✅ | Phải là `true` trước khi chuyển Phase 3 |
| phase_status.tasks.approved | ✅ | Phải là `true` trước khi execution |
| phase_status.requirements.ref | ✅ | Path đến file requirements |
| phase_status.design.ref | ✅ | Path đến file design |
| phase_status.tasks.ref | ✅ | Path đến file tasks |

## Execution Flow Gate

```
requirementsGate → designGate → tasksGate → EXECUTION
```

Nếu bất kỳ gate nào chưa pass, Agent PHẢI dừng và hoàn thành phase tương ứng.
MD
  log "mcp/context-protocol.md"
}

# =============================================================================
# 5. SKILLS — Khả năng của agent (3-Phase)
# =============================================================================
create_skills() {
  step "Tạo Skills (3-Phase)"

  # 5-a. Requirements Skill
  cat > "$AG/skills/requirements.skill.md" <<'SKILL'
# Skill: Requirements (Phase 1)

## Mô tả
Thu thập yêu cầu, viết User Stories và Acceptance Criteria chuẩn PROD.

## Trigger
- Bất kỳ task mới nào được giao
- Khi context không đủ rõ ràng
- Khi phát hiện mâu thuẫn trong yêu cầu

## Quy trình

```
1. Tự động chạy lệnh: bash .antigravity/commands/new-task.sh "<task_description>" để tạo scaffold 3 file.
2. Đọc memory/project.context.json và session.context.json.
3. Xác định những gì đã biết vs chưa biết.
4. Phỏng vấn user để thu thập yêu cầu (tối đa 3 câu/lượt).
5. Soạn User Stories theo format: "As a [role], I want to [action], so that [benefit]".
6. Soạn Acceptance Criteria cho MỖI story: "Given [context], When [action], Then [result]".
7. Liệt kê Non-functional Requirements và Out of Scope.
8. Điền đầy đủ vào file context/requirements-<ts>.md.
9. Hiển thị cho user review.
10. Khi approved → chạy: bash .antigravity/commands/approve-plan.sh <requirements-file>
11. Chuyển sang skill: design.
```

## Output
- `context/requirements-<ts>.md` — tài liệu yêu cầu chuẩn PROD
- `memory/session.context.json` — context được cập nhật

## Template câu hỏi theo domain

### Coding task
- "Ngôn ngữ / framework nào đang dùng?"
- "Có test suite không? Coverage yêu cầu?"
- "CI/CD pipeline hiện tại là gì?"

### Data task
- "Schema / cấu trúc dữ liệu đầu vào?"
- "Volume dữ liệu dự kiến?"
- "Output format yêu cầu?"

### Design task
- "Target audience là ai?"
- "Brand guidelines / design system?"
- "Platform (web/mobile/print)?"
SKILL
  log "skills/requirements.skill.md"

  # 5-b. Design Skill
  cat > "$AG/skills/design.skill.md" <<'SKILL'
# Skill: Design (Phase 2)

## Mô tả
Phân tích kiến trúc, tạo file design và chia nhỏ task breakdown từ requirements đã approved.

## Trigger
- Sau khi skill:requirements hoàn tất và file requirements đã APPROVED
- Context đã đủ (checklist ✅)

## Điều kiện tiên quyết
- File requirements tồn tại với Status: APPROVED

## Quy trình

```
1. Chạy: bash .antigravity/hooks/pre-design.sh (kiểm tra requirements approved).
2. Đọc memory/project.context.json để lấy steering data (architecture, coding style, tech stack).
3. Đọc file requirements đã approved để hiểu User Stories + AC.
4. Soạn Design Analysis vào file plans/<ts>-<slug>.design.md:
   - Architecture Overview
   - Data Model (nếu có)
   - API Contracts (nếu có)
   - File Map ([NEW], [MODIFY], [DELETE])
   - Technical Decisions
   - Risks & Mitigation
5. Soạn Task Breakdown vào file plans/<ts>-<slug>.tasks.md:
   - Chia nhỏ thành sub-tasks checkbox
   - Mỗi task liên kết tới User Story (US-1, US-2, ...)
   - Verification Checklist
6. Hiển thị cho user review cả design và tasks.
7. Khi approved → chạy:
   bash .antigravity/commands/approve-plan.sh <design-file>
   bash .antigravity/commands/approve-plan.sh <tasks-file>
8. Chuyển sang skill: execute.
```

## Validation checklist

```
[ ] Architecture Overview rõ ràng
[ ] File Map đầy đủ (files tạo mới/sửa/xóa)
[ ] Technical Decisions có lý do
[ ] Risks đã được xác định
[ ] Tasks liên kết ngược tới User Stories
[ ] Mỗi task có checkbox
[ ] Verification Checklist tồn tại
```
SKILL
  log "skills/design.skill.md"

  # 5-c. Execute Skill
  cat > "$AG/skills/execute.skill.md" <<'SKILL'
# Skill: Execute

## Mô tả
Thực thi các task trong file tasks đã được approved, cập nhật tiến độ live.

## Điều kiện tiên quyết
- File requirements tồn tại với Status: APPROVED
- File design tồn tại với Status: APPROVED
- File tasks tồn tại với Status: APPROVED

## Quy trình

```
1. Kiểm tra cả 3 file (requirements + design + tasks) đều APPROVED.
2. Chạy: bash .antigravity/commands/execute-plan.sh "<đường dẫn tasks-file>".
3. Thực hiện từng task theo thứ tự trong file tasks.
4. SAU MỖI TASK HOÀN THÀNH:
   a. Cập nhật checkbox: - [ ] → - [x] trong file tasks.
   b. Ghi Progress Log vào file design (Time, Step, Result, Notes).
   c. Chạy: bash .antigravity/hooks/post-step.sh "<task-slug>" "<step>" "<done|failed>".
5. Nếu task thất bại:
   a. Dừng ngay.
   b. Báo cáo lỗi chi tiết.
   c. Đề xuất rollback hoặc fix.
   d. Hỏi người dùng cách tiếp tục.
6. Khi hoàn tất toàn bộ:
   a. Chạy: bash .antigravity/commands/status.sh để báo cáo.
   b. Chạy: bash .antigravity/hooks/post-task.sh "<task>" "success".
   c. Cập nhật memory/decisions.log.md.
   d. Kiểm tra Verification Checklist trong file tasks.
```

## Reporting format sau mỗi step

```
✅ Task N (US-X): <tên task>
   - Kết quả: <output ngắn gọn>
   - Thời gian: <thực tế>
   - Files changed: <danh sách>
   - AC met: <danh sách AC đã hoàn thành>
```
SKILL
  log "skills/execute.skill.md"

  # 5-d. Review Skill
  cat > "$AG/skills/review.skill.md" <<'SKILL'
# Skill: Review

## Mô tả
Kiểm tra kết quả sau khi thực thi, đối chiếu với Acceptance Criteria và cập nhật memory.

## Quy trình

```
1. Đọc file requirements → lấy danh sách Acceptance Criteria.
2. Đối chiếu từng AC với kết quả thực tế.
3. Kiểm tra Verification Checklist trong file tasks.
4. Tạo báo cáo review: context/review-<ts>.md.
5. Cập nhật memory/decisions.log.md.
6. Mark file tasks: Status: DONE.
7. Đề xuất cải tiến (nếu có).
8. Hỏi: "Bạn có muốn tiếp tục với task khác không?"
```

## Review Checklist
```
[ ] Tất cả AC trong requirements đã met
[ ] Tất cả tasks checkbox đã [x]
[ ] Code pass linting/formatting (theo coding_standards trong steering)
[ ] Tests pass (nếu có)
[ ] Không có regression
[ ] Progress Log đầy đủ trong file design
```
SKILL
  log "skills/review.skill.md"

  # 5-e. Clarify Skill (MỚI)
  cat > "$AG/skills/clarify.skill.md" <<'SKILL'
# Skill: Clarify (Pre-Execute Protocol)

## Mô tả
Làm rõ yêu cầu, tóm tắt giải pháp và chờ user chốt trước khi thực thi bất kỳ thay đổi nào.

## Trigger
- Ngay khi nhận được task mới (trước Phase 1)
- Khi yêu cầu còn mơ hồ hoặc thiếu thông tin
- Khi scope thay đổi so với requirements đã approved

## Quy trình

```
1. Đọc memory/project.context.json (tech stack, coding standards, file size limits).
2. Đọc memory/decisions.log.md để tránh lặp quyết định cũ.
3. Phân tích yêu cầu: xác định rõ / chưa rõ.
4. Nếu chưa rõ → hỏi tối đa 3 câu theo format:
     ❓ [1/3] <câu hỏi quan trọng nhất>
     ❓ [2/3] ...
     ❓ [3/3] ...
5. Chạy: bash .antigravity/commands/clarify.sh "<task-description>"
   → Tạo file context/solution-summary-<ts>.md
6. Điền Solution Summary vào file:
   - Hiểu của tôi về yêu cầu
   - Giải pháp đề xuất (approach, pattern)
   - Sẽ làm / Sẽ KHÔNG làm
   - Files ảnh hưởng (sơ bộ)
   - Rủi ro
7. Trình bày Solution Summary cho user.
8. Chờ user phản hồi:
   - Nếu user yêu cầu chỉnh → cập nhật, trình bày lại
   - Nếu user chốt → chạy: bash .antigravity/commands/approve-plan.sh <solution-file>
9. Khi approved → chuyển sang skill: requirements.
```

## Output
- `context/solution-summary-<ts>.md` — Solution Summary đã được user approve
- Đây là điều kiện tiên quyết để bắt đầu Phase 1 (Requirements)
SKILL
  log "skills/clarify.skill.md"
}

# =============================================================================
# 6. COMMANDS — Lệnh nhanh (3-Phase)
# =============================================================================
create_commands() {
  step "Tạo Commands (3-Phase)"

  # 6-a. new-task.sh — Tạo scaffold 3 file
  cat > "$AG/commands/new-task.sh" <<'CMD'
#!/usr/bin/env bash
# new-task.sh — Khởi tạo task mới với scaffold 3-Phase
# Usage: bash commands/new-task.sh "Mô tả task"

set -euo pipefail
TASK_DESC="${1:-}"
[[ -z "$TASK_DESC" ]] && { echo "Usage: $0 <task description>"; exit 1; }

SLUG=$(echo "$TASK_DESC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)
TS=$(date '+%Y%m%d-%H%M%S')
REQ_FILE=".antigravity/context/requirements-${TS}-${SLUG}.md"
DESIGN_FILE=".antigravity/plans/${TS}-${SLUG}.design.md"
TASKS_FILE=".antigravity/plans/${TS}-${SLUG}.tasks.md"

# Chạy hook
bash .antigravity/hooks/pre-task.sh "$TASK_DESC"

# ── Phase 1: Requirements scaffold ──
cat > "$REQ_FILE" <<MD
# Requirements — $TASK_DESC
**Date**: $(date '+%Y-%m-%d %H:%M:%S')  |  **Task ID**: ${TS}-${SLUG}  |  **Status**: DRAFT

---

## 📋 Tổng quan yêu cầu
> <!-- Mô tả ngắn gọn mục tiêu nghiệp vụ của task này -->

## 👤 User Stories

### US-1: <!-- Tên story -->
> **As a** [vai trò], **I want to** [hành động], **so that** [lợi ích].

#### Acceptance Criteria
- [ ] **Given** [ngữ cảnh], **When** [hành động], **Then** [kết quả mong đợi]
- [ ] **Given** ..., **When** ..., **Then** ...

### US-2: <!-- Tên story -->
> **As a** [vai trò], **I want to** [hành động], **so that** [lợi ích].

#### Acceptance Criteria
- [ ] **Given** ..., **When** ..., **Then** ...

## 🔒 Non-functional Requirements
- [ ] Performance: <!-- Thời gian phản hồi, throughput -->
- [ ] Security: <!-- Xác thực, phân quyền, mã hóa -->
- [ ] Accessibility: <!-- WCAG, hỗ trợ đa ngôn ngữ -->

## 🚫 Out of Scope
- <!-- Những gì KHÔNG làm trong task này -->

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
| **Notes** | |
MD

# ── Phase 2: Design scaffold ──
cat > "$DESIGN_FILE" <<MD
# Design — $TASK_DESC
**Task ID**: ${TS}-${SLUG}  |  **Requirements ref**: $REQ_FILE  |  **Status**: DRAFT

---

## 🏗️ Architecture Overview
> <!-- Mô tả kiến trúc tổng quan, sơ đồ thành phần chính -->

## 📊 Data Model
> <!-- Schema, entities, relationships (nếu có) -->

## 🔌 API Contracts (nếu có)

| Method | Endpoint | Request | Response | Notes |
|--------|----------|---------|----------|-------|
| | | | | |

## 📁 File Map

| Action | File Path | Mô tả thay đổi |
|--------|-----------|-----------------|
| [NEW]    | | |
| [MODIFY] | | |
| [DELETE] | | |

## 🧠 Technical Decisions

| Quyết định | Lý do | Phương án thay thế đã cân nhắc |
|------------|-------|-------------------------------|
| | | |

## ⚠️ Risks & Mitigation

| Rủi ro | Xác suất | Tác động | Giảm thiểu |
|--------|----------|----------|------------|
| | | | |

## 📊 Progress Log
> Cập nhật sau mỗi step trong execution

| Time | Task | Result | Notes |
|------|------|--------|-------|
| | | | |

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
| **Notes** | |
MD

# ── Phase 3: Tasks scaffold ──
cat > "$TASKS_FILE" <<MD
# Tasks — $TASK_DESC
**Task ID**: ${TS}-${SLUG}  |  **Design ref**: $DESIGN_FILE  |  **Status**: DRAFT

---

## ✅ Task Breakdown

### US-1: <!-- Tên story liên kết -->
- [ ] Task 1.1: <!-- Mô tả task cụ thể -->
- [ ] Task 1.2: <!-- Mô tả task cụ thể -->
- [ ] Task 1.3: <!-- Mô tả task cụ thể -->

### US-2: <!-- Tên story liên kết -->
- [ ] Task 2.1: <!-- Mô tả task cụ thể -->
- [ ] Task 2.2: <!-- Mô tả task cụ thể -->

## 🧪 Verification Checklist
- [ ] Tất cả AC trong requirements đã met
- [ ] Code đã pass linting/formatting
- [ ] Tests đã pass (nếu có)
- [ ] Không có regression
- [ ] Progress Log trong design đầy đủ

## 📊 Progress Summary

| Tổng tasks | Hoàn thành | Còn lại | % |
|------------|------------|---------|---|
| | | | |

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
| **Notes** | |
MD

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Scaffold 3-Phase đã tạo thành công!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 Phase 1 — Requirements: $REQ_FILE"
echo "  🏗️  Phase 2 — Design:       $DESIGN_FILE"
echo "  ✅ Phase 3 — Tasks:        $TASKS_FILE"
echo ""
echo "➡️  Tiếp theo:"
echo "  1. Điền User Stories + AC vào file requirements"
echo "  2. Approve: bash .antigravity/commands/approve-plan.sh \"$REQ_FILE\""
echo "  3. Sau đó điền Design → approve → điền Tasks → approve → Execute"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CMD
  chmod +x "$AG/commands/new-task.sh"
  log "commands/new-task.sh"

  # 6-b. create-design.sh (thay thế create-plan.sh)
  cat > "$AG/commands/create-design.sh" <<'CMD'
#!/usr/bin/env bash
# create-design.sh — Tạo file design (nếu chưa tồn tại từ new-task.sh)
# Usage: bash commands/create-design.sh "Task description"

set -euo pipefail
TASK_DESC="${1:-unnamed task}"
SLUG=$(echo "$TASK_DESC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)
TS=$(date '+%Y%m%d-%H%M%S')

# Kiểm tra pre-design
bash .antigravity/hooks/pre-design.sh

# Kiểm tra xem đã có design file chưa
EXISTING=$(find .antigravity/plans -name "*${SLUG}*.design.md" 2>/dev/null | head -1)
if [[ -n "$EXISTING" ]]; then
  echo "📄 Design file đã tồn tại: $EXISTING"
  echo "   Hãy mở và chỉnh sửa file trên."
  exit 0
fi

DESIGN_FILE=".antigravity/plans/${TS}-${SLUG}.design.md"
TASKS_FILE=".antigravity/plans/${TS}-${SLUG}.tasks.md"

# Tìm file requirements liên quan
REQ_FILE=$(find .antigravity/context -name "requirements-*${SLUG}*.md" 2>/dev/null | head -1)
REQ_REF="${REQ_FILE:-<chưa tìm thấy — hãy chạy new-task.sh trước>}"

cat > "$DESIGN_FILE" <<MD
# Design — $TASK_DESC
**Task ID**: ${TS}-${SLUG}  |  **Requirements ref**: $REQ_REF  |  **Status**: DRAFT

---

## 🏗️ Architecture Overview
> <!-- Mô tả kiến trúc -->

## 📊 Data Model
> <!-- Schema, entities -->

## 📁 File Map

| Action | File Path | Mô tả thay đổi |
|--------|-----------|-----------------|
| [NEW]    | | |
| [MODIFY] | | |

## 🧠 Technical Decisions

| Quyết định | Lý do | Phương án thay thế |
|------------|-------|-------------------|
| | | |

## ⚠️ Risks & Mitigation

| Rủi ro | Xác suất | Tác động | Giảm thiểu |
|--------|----------|----------|------------|
| | | | |

## 📊 Progress Log

| Time | Task | Result | Notes |
|------|------|--------|-------|
| | | | |

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
MD

echo ""
echo "✅ Design file created: $DESIGN_FILE"
echo ""
echo "📌 Hãy:"
echo "  1. Điền đầy đủ thông tin thiết kế"
echo "  2. Review và approve: bash .antigravity/commands/approve-plan.sh \"$DESIGN_FILE\""
CMD
  chmod +x "$AG/commands/create-design.sh"
  log "commands/create-design.sh"

  # 6-c. approve-plan.sh (hỗ trợ multi-phase)
  cat > "$AG/commands/approve-plan.sh" <<'CMD'
#!/usr/bin/env bash
# approve-plan.sh — Duyệt file (requirements, design, hoặc tasks)
# Usage: bash commands/approve-plan.sh <path-to-file.md>

set -euo pipefail
FILE="${1:-}"
[[ -z "$FILE" ]] && { echo "Usage: $0 <file-path>"; exit 1; }
[[ -f "$FILE" ]] || { echo "❌ File không tồn tại: $FILE"; exit 1; }

# Nhận diện loại file
if echo "$FILE" | grep -q "requirements"; then
  TYPE="📋 REQUIREMENTS"
elif echo "$FILE" | grep -q "design"; then
  TYPE="🏗️  DESIGN"
elif echo "$FILE" | grep -q "tasks"; then
  TYPE="✅ TASKS"
else
  TYPE="📄 DOCUMENT"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$TYPE — Review & Approve"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -rp "✅ Duyệt file này? [y/N] " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  TS=$(date '+%Y-%m-%d %H:%M:%S')
  # Cập nhật Status
  if grep -q "Status: DRAFT" "$FILE"; then
    sed -i '' "s/Status: DRAFT/Status: APPROVED/" "$FILE" 2>/dev/null || \
    sed -i "s/Status: DRAFT/Status: APPROVED/" "$FILE"
  fi
  # Cập nhật Approval
  sed -i '' "s/| \*\*Approved by\*\* | _________________ |/| **Approved by** | ${USER:-agent} |/" "$FILE" 2>/dev/null || \
  sed -i "s/| \*\*Approved by\*\* | _________________ |/| **Approved by** | ${USER:-agent} |/" "$FILE"
  sed -i '' "s/| \*\*Approved at\*\* | _________________ |/| **Approved at** | $TS |/" "$FILE" 2>/dev/null || \
  sed -i "s/| \*\*Approved at\*\* | _________________ |/| **Approved at** | $TS |/" "$FILE"

  LOG=".antigravity/logs/agent.log"
  echo "[$(date '+%Y%m%d-%H%M%S')] [APPROVED] $FILE" >> "$LOG"

  echo ""
  echo "✅ $TYPE APPROVED: $FILE"

  # Hướng dẫn bước tiếp theo
  if echo "$FILE" | grep -q "requirements"; then
    echo "➡️  Tiếp theo: Điền file Design → approve"
  elif echo "$FILE" | grep -q "design"; then
    echo "➡️  Tiếp theo: Điền file Tasks → approve"
  elif echo "$FILE" | grep -q "tasks"; then
    echo "➡️  Tiếp theo: Bắt đầu Execution!"
    echo "   Chạy: bash .antigravity/commands/execute-plan.sh \"$FILE\""
  fi
else
  echo "❌ File không được duyệt. Chỉnh sửa và thử lại."
fi
CMD
  chmod +x "$AG/commands/approve-plan.sh"
  log "commands/approve-plan.sh"

  # 6-d. execute-plan.sh (kiểm tra 3 file)
  cat > "$AG/commands/execute-plan.sh" <<'CMD'
#!/usr/bin/env bash
# execute-plan.sh — Thực thi tasks đã approved (kiểm tra đầy đủ 3-phase)
# Usage: bash commands/execute-plan.sh <tasks-file>

set -euo pipefail
TASKS_FILE="${1:-}"
[[ -z "$TASKS_FILE" ]] && { echo "Usage: $0 <tasks-file>"; exit 1; }
[[ -f "$TASKS_FILE" ]] || { echo "File không tồn tại: $TASKS_FILE"; exit 1; }

# Kiểm tra tasks file approved
if ! grep -q "Status: APPROVED" "$TASKS_FILE"; then
  echo "⛔ Tasks file chưa được duyệt!"
  echo "Chạy: bash .antigravity/commands/approve-plan.sh \"$TASKS_FILE\""
  exit 1
fi

# Lấy design ref từ tasks file
DESIGN_REF=$(grep "Design ref" "$TASKS_FILE" | sed 's/.*Design ref.*: *//' | sed 's/ .*//' | tr -d '|*' | xargs)
if [[ -n "$DESIGN_REF" && -f "$DESIGN_REF" ]]; then
  if ! grep -q "Status: APPROVED" "$DESIGN_REF"; then
    echo "⛔ Design file chưa được duyệt: $DESIGN_REF"
    exit 1
  fi
  echo "✅ Design file APPROVED: $DESIGN_REF"

  # Lấy requirements ref từ design file
  REQ_REF=$(grep "Requirements ref" "$DESIGN_REF" | sed 's/.*Requirements ref.*: *//' | sed 's/ .*//' | tr -d '|*' | xargs)
  if [[ -n "$REQ_REF" && -f "$REQ_REF" ]]; then
    if ! grep -q "Status: APPROVED" "$REQ_REF"; then
      echo "⛔ Requirements file chưa được duyệt: $REQ_REF"
      exit 1
    fi
    echo "✅ Requirements file APPROVED: $REQ_REF"
  fi
fi

echo "✅ Tasks file APPROVED: $TASKS_FILE"

# Lấy task title
TASK=$(head -1 "$TASKS_FILE" | sed 's/# Tasks — //')
bash .antigravity/hooks/pre-task.sh "$TASK"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Bắt đầu thực thi: $TASK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📄 Tasks: $TASKS_FILE"
echo "  🏗️  Design: ${DESIGN_REF:-N/A}"
echo "  📋 Requirements: ${REQ_REF:-N/A}"
echo ""
echo "⚡ Agent sẽ:"
echo "  1. Thực hiện từng task theo thứ tự"
echo "  2. Cập nhật [x] trong tasks file sau mỗi step"
echo "  3. Ghi Progress Log vào design file"
echo "  4. Chạy post-step.sh sau mỗi step"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Hook kết thúc
trap 'bash .antigravity/hooks/post-task.sh "$TASK" "interrupted"' INT TERM
CMD
  chmod +x "$AG/commands/execute-plan.sh"
  log "commands/execute-plan.sh"

  # 6-e. status.sh (hiển thị 3-phase)
  cat > "$AG/commands/status.sh" <<'CMD'
#!/usr/bin/env bash
# status.sh — Hiển thị trạng thái tổng quan 3-Phase

set -euo pipefail
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ANTIGRAVITY STATUS (3-Phase System)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CTX_DIR=".antigravity/context"
PLAN_DIR=".antigravity/plans"

echo ""
echo "📋 Phase 1 — Requirements:"
echo "  DRAFT:    $(grep -rl 'Status: DRAFT'    "$CTX_DIR" 2>/dev/null | grep -c 'requirements' || echo 0)"
echo "  APPROVED: $(grep -rl 'Status: APPROVED' "$CTX_DIR" 2>/dev/null | grep -c 'requirements' || echo 0)"

echo ""
echo "🏗️  Phase 2 — Design:"
echo "  DRAFT:    $(grep -rl 'Status: DRAFT'    "$PLAN_DIR" 2>/dev/null | grep -c 'design' || echo 0)"
echo "  APPROVED: $(grep -rl 'Status: APPROVED' "$PLAN_DIR" 2>/dev/null | grep -c 'design' || echo 0)"
echo "  DONE:     $(grep -rl 'Status: DONE'     "$PLAN_DIR" 2>/dev/null | grep -c 'design' || echo 0)"

echo ""
echo "✅ Phase 3 — Tasks:"
echo "  DRAFT:    $(grep -rl 'Status: DRAFT'    "$PLAN_DIR" 2>/dev/null | grep -c 'tasks' || echo 0)"
echo "  APPROVED: $(grep -rl 'Status: APPROVED' "$PLAN_DIR" 2>/dev/null | grep -c 'tasks' || echo 0)"
echo "  DONE:     $(grep -rl 'Status: DONE'     "$PLAN_DIR" 2>/dev/null | grep -c 'tasks' || echo 0)"

echo ""
echo "🧠 Memory:"
MEM=".antigravity/memory"
[[ -f "$MEM/project.context.json" ]]  && echo "  ✅ project.context.json (steering data)" || echo "  ❌ project.context.json (chưa tạo)"
[[ -f "$MEM/session.context.json" ]]  && echo "  ✅ session.context.json"  || echo "  ❌ session.context.json (chưa tạo)"
[[ -f "$MEM/decisions.log.md" ]]      && echo "  ✅ decisions.log.md"      || echo "  ❌ decisions.log.md (chưa tạo)"

echo ""
echo "📜 Recent logs:"
tail -5 ".antigravity/logs/agent.log" 2>/dev/null || echo "  (chưa có log)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CMD
  chmod +x "$AG/commands/status.sh"
  log "commands/status.sh"

  # 6-f. new-skill.sh (giữ nguyên)
  cat > "$AG/commands/new-skill.sh" <<'CMD'
#!/usr/bin/env bash
# new-skill.sh — Tạo một skill mới cho Agent từ template
# Usage: bash .antigravity/commands/new-skill.sh "Tên Skill"

set -euo pipefail

SKILL_NAME="${1:-}"
[[ -z "$SKILL_NAME" ]] && { echo "Usage: $0 <skill name>"; exit 1; }

SLUG=$(echo "$SKILL_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')
SKILL_FILE=".antigravity/skills/${SLUG}.skill.md"

if [[ -f "$SKILL_FILE" ]]; then
    echo "❌ Lỗi: Skill file đã tồn tại: $SKILL_FILE"
    exit 1
fi

TEMPLATE_FILE=".antigravity/templates/skill.md"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Lỗi: Không tìm thấy template tại $TEMPLATE_FILE"
    exit 1
fi

sed "s/{{SKILL_NAME}}/$SKILL_NAME/g" "$TEMPLATE_FILE" > "$SKILL_FILE"

echo ""
echo "✨ Đã tạo skill mới thành công!"
echo "📂 Đường dẫn: $SKILL_FILE"
echo "➡️  Hãy mở file trên để cập nhật Quy trình & Trình kích hoạt (Trigger) cho skill."
echo ""
CMD
  chmod +x "$AG/commands/new-skill.sh"
  log "commands/new-skill.sh"

  # 6-g. init-project.sh (giữ logic tương tự)
  cat > "$AG/commands/init-project.sh" <<'CMD'
#!/usr/bin/env bash
# init-project.sh — Khởi tạo ngữ cảnh dự án và steering data
# Usage: bash .antigravity/commands/init-project.sh

set -euo pipefail

TS=$(date '+%Y%m%d-%H%M%S')
INIT_CTX_FILE=".antigravity/context/requirements-${TS}-init-project.md"

# Khởi chạy pre-task hook
bash .antigravity/hooks/pre-task.sh "Khởi tạo ngữ cảnh dự án & steering data"

cat > "$INIT_CTX_FILE" <<MD
# Requirements — Khởi tạo ngữ cảnh dự án
**Date**: $(date '+%Y-%m-%d %H:%M:%S')  |  **Task ID**: ${TS}-init-project  |  **Status**: DRAFT

---

## 📋 Tổng quan
> Khởi tạo thông tin dự án và steering data cho Agent.

## 👤 User Stories

### US-1: Cấu hình thông tin dự án
> **As a** developer, **I want to** cấu hình đầy đủ thông tin dự án, **so that** Agent hiểu rõ ngữ cảnh và tuân thủ quy tắc.

#### Acceptance Criteria
- [ ] **Given** file project.context.json rỗng, **When** hoàn thành phỏng vấn, **Then** tất cả trường trong file đều có giá trị.

## 📝 Câu hỏi phỏng vấn Steering Data
- [ ] Tên dự án và mục tiêu cốt lõi là gì?
- [ ] Tech stack chính (Language, Framework, Database, Infrastructure)?
- [ ] Quy định về coding style, commit message và branch naming?
- [ ] Architecture patterns (folder structure, design pattern, state management)?
- [ ] Testing strategy (framework, coverage minimum)?
- [ ] API conventions (REST/GraphQL, versioning, error format)?
- [ ] Môi trường chạy thử (Staging) và chạy thật (Production)?

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
MD

echo ""
echo "✨ Đã tạo file phỏng vấn ban đầu tại: $INIT_CTX_FILE"
echo "➡️  Bước tiếp theo: Hãy trả lời các câu hỏi trong file trên"
echo "   để Agent hoàn thiện file cấu hình project.context.json (steering data)"
echo ""
CMD
  chmod +x "$AG/commands/init-project.sh"
  log "commands/init-project.sh"

  # 6-h. clarify.sh — Tạo Solution Summary scaffold
  cat > "$AG/commands/clarify.sh" <<'CMD'
#!/usr/bin/env bash
# clarify.sh — Tạo file Solution Summary để agent trình bày trước khi thực thi
# Usage: bash commands/clarify.sh "Task description"

set -euo pipefail
TASK_DESC="${1:-}"
[[ -z "$TASK_DESC" ]] && { echo "Usage: $0 <task description>"; exit 1; }

SLUG=$(echo "$TASK_DESC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)
TS=$(date '+%Y%m%d-%H%M%S')
SUMMARY_FILE=".antigravity/context/solution-summary-${TS}-${SLUG}.md"

cat > "$SUMMARY_FILE" <<MD
# Solution Summary — $TASK_DESC
**Date**: $(date '+%Y-%m-%d %H:%M:%S')  |  **Task**: ${TS}-${SLUG}  |  **Status**: DRAFT

---

## 🎯 Hiểu của tôi về yêu cầu
> <!-- Agent điền: 1-2 câu tóm tắt ngắn gọn yêu cầu bằng ngôn ngữ của mình -->

## 💡 Giải pháp đề xuất

**Approach**: <!-- Hướng tiếp cận tổng thể -->

**Pattern / Kỹ thuật**: <!-- Design pattern, thư viện, thuật toán nếu có -->

**Lý do chọn giải pháp này**: <!-- So với các phương án khác -->

## ✅ Sẽ làm (In Scope)
- [ ] <!-- action 1 -->
- [ ] <!-- action 2 -->
- [ ] <!-- action 3 -->

## 🚫 Sẽ KHÔNG làm (Out of Scope)
- <!-- item 1 — lý do ngoài scope -->
- <!-- item 2 -->

## 📁 Files sẽ bị ảnh hưởng (sơ bộ)

| Action | File | Ghi chú |
|--------|------|---------|
| [NEW]    | | |
| [MODIFY] | | |
| [DELETE] | | |

## ⚠️ Rủi ro & Lưu ý
- <!-- risk 1, hoặc "Không có rủi ro đáng kể" nếu task đơn giản -->

## ❓ Câu hỏi còn lại (nếu có)
- <!-- câu hỏi 1, hoặc xóa section này nếu đã rõ -->

---

## 🔏 User Confirmation

| | |
|-|-|
| **Confirmed by** | _________________ |
| **Confirmed at** | _________________ |
| **Notes / Chỉnh sửa** | |
MD

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📐 Solution Summary scaffold đã tạo:"
echo "   $SUMMARY_FILE"
echo ""
echo "➡️  Tiếp theo:"
echo "  1. Điền nội dung Solution Summary"
echo "  2. Trình bày cho user"
echo "  3. Khi user chốt → approve: bash .antigravity/commands/approve-plan.sh \"$SUMMARY_FILE\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CMD
  chmod +x "$AG/commands/clarify.sh"
  log "commands/clarify.sh"

  # 6-i. generate-report.sh — Tạo báo cáo sau khi hoàn thành task
  cat > "$AG/commands/generate-report.sh" <<'CMD'
#!/usr/bin/env bash
# generate-report.sh — Tạo báo cáo hoàn thành task, lưu vào reports/
# Usage: bash commands/generate-report.sh <tasks-file> [status: success|partial|failed]

set -euo pipefail
TASKS_FILE="${1:-}"
STATUS="${2:-success}"
[[ -z "$TASKS_FILE" ]] && { echo "Usage: $0 <tasks-file> [status]"; exit 1; }
[[ -f "$TASKS_FILE" ]] || { echo "❌ File không tồn tại: $TASKS_FILE"; exit 1; }

TS=$(date '+%Y%m%d-%H%M%S')
DATE_READABLE=$(date '+%Y-%m-%d %H:%M:%S')

# Lấy metadata từ tasks file
TASK_TITLE=$(head -1 "$TASKS_FILE" | sed 's/# Tasks — //')
TASK_ID=$(grep -o 'Task ID\*\*: [^ |]*' "$TASKS_FILE" | head -1 | sed 's/Task ID\*\*: //' || echo "unknown")
SLUG=$(echo "$TASK_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)

REPORT_FILE=".antigravity/reports/${TS}-${SLUG}.report.md"
LOG=".antigravity/logs/agent.log"

# ── Đếm tasks ──
TOTAL=$(grep -c '^- \[' "$TASKS_FILE" 2>/dev/null || echo 0)
DONE=$(grep -c '^- \[x\]' "$TASKS_FILE" 2>/dev/null || echo 0)
REMAINING=$((TOTAL - DONE))

# ── Lấy design ref ──
DESIGN_REF=$(grep -o 'Design ref\*\*: [^ |]*' "$TASKS_FILE" | head -1 | sed 's/Design ref\*\*: //' | tr -d '*' || echo "")

# ── Lấy requirements ref từ design file ──
REQ_REF=""
if [[ -n "$DESIGN_REF" && -f "$DESIGN_REF" ]]; then
  REQ_REF=$(grep -o 'Requirements ref\*\*: [^ |]*' "$DESIGN_REF" | head -1 | sed 's/Requirements ref\*\*: //' | tr -d '*' || echo "")
fi

# ── Đếm Acceptance Criteria ──
AC_TOTAL=0; AC_MET=0
if [[ -n "$REQ_REF" && -f "$REQ_REF" ]]; then
  AC_TOTAL=$(grep -c 'Given.*When.*Then' "$REQ_REF" 2>/dev/null || echo 0)
  AC_MET=$(grep -c '^\- \[x\].*Given' "$REQ_REF" 2>/dev/null || echo 0)
fi

# ── Lấy danh sách tasks đã làm / chưa làm ──
TASKS_DONE=$(grep '^- \[x\]' "$TASKS_FILE" 2>/dev/null | sed 's/^- \[x\] /  ✅ /' || echo "  (chưa có)")
TASKS_PENDING=$(grep '^- \[ \]' "$TASKS_FILE" 2>/dev/null | sed 's/^- \[ \] /  ⏳ /' || echo "  (không có)")

# ── Lấy File Map từ design ──
FILE_MAP="(Xem chi tiết tại: ${DESIGN_REF:-N/A})"
if [[ -n "$DESIGN_REF" && -f "$DESIGN_REF" ]]; then
  FILE_MAP=$(awk '/## 📁 File Map/,/^## /' "$DESIGN_REF" 2>/dev/null | grep '^\|' | grep -v 'Action\|---' || echo "$FILE_MAP")
fi

# ── Xác định status label ──
case "$STATUS" in
  success) STATUS_LABEL="✅ THÀNH CÔNG" ;;
  partial) STATUS_LABEL="⚠️  HOÀN THÀNH MỘT PHẦN" ;;
  failed)  STATUS_LABEL="❌ THẤT BẠI" ;;
  *)       STATUS_LABEL="$STATUS" ;;
esac

# ── Tạo file báo cáo ──
cat > "$REPORT_FILE" <<MD
# Báo cáo hoàn thành — $TASK_TITLE
**Task ID**: $TASK_ID  |  **Ngày**: $DATE_READABLE  |  **Trạng thái**: $STATUS_LABEL

---

## 📊 Tổng quan kết quả

| Chỉ số | Kết quả |
|--------|---------|
| Tasks hoàn thành | $DONE / $TOTAL |
| Tasks còn lại | $REMAINING |
| Acceptance Criteria met | $AC_MET / $AC_TOTAL |
| Trạng thái | $STATUS_LABEL |
| Thời gian hoàn thành | $DATE_READABLE |

---

## ✅ Công việc đã hoàn thành

$TASKS_DONE

## ⏳ Công việc chưa hoàn thành

$TASKS_PENDING

---

## 📁 Files đã thay đổi

$FILE_MAP

> Chi tiết: $DESIGN_REF

---

## 🎯 Acceptance Criteria

> Chi tiết: $REQ_REF

<!-- Agent điền: từng AC đã met hay chưa -->
| AC | Mô tả | Status |
|----|-------|--------|
| | | ✅/❌ |

---

## 🐛 Vấn đề gặp phải

> <!-- Agent điền: mô tả vấn đề nếu có, hoặc "Không có vấn đề đáng kể" -->

## 💡 Đề xuất bước tiếp theo

> <!-- Agent điền: 1-3 gợi ý hành động tiếp theo -->

---

## 📎 Tài liệu liên quan

| Loại | Đường dẫn |
|------|-----------|
| Requirements | ${REQ_REF:-N/A} |
| Design | ${DESIGN_REF:-N/A} |
| Tasks | $TASKS_FILE |
| Report | $REPORT_FILE |

---
*Báo cáo tạo tự động bởi Antigravity Agent v2.1*
MD

# Ghi log
echo "[${TS}] [REPORT] ${STATUS_LABEL} — ${REPORT_FILE}" >> "$LOG"

# ── Hiển thị summary cho user ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 BÁO CÁO HOÀN THÀNH: $TASK_TITLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  $STATUS_LABEL"
echo "  ✅ Tasks     : $DONE/$TOTAL hoàn thành"
echo "  🎯 AC met    : $AC_MET/$AC_TOTAL criteria"
if (( REMAINING > 0 )); then
  echo "  ⏳ Còn lại  : $REMAINING tasks"
fi
echo "  📄 Báo cáo  : $REPORT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CMD
  chmod +x "$AG/commands/generate-report.sh"
  log "commands/generate-report.sh"
}

# =============================================================================
# 7. WORKFLOWS — Quy trình tổng hợp (3-Phase)
# =============================================================================
create_workflows() {
  step "Tạo Workflows (3-Phase)"

  cat > "$AG/workflows/standard-task.workflow.md" <<'WF'
# Workflow: Standard Task (v2.1 — Clarify + 3-Phase + Report)

## Tổng quan
Quy trình chuẩn: **Clarify → Requirements → Design → Tasks → Execute → Review → Report**.

```
┌──────────────────────────────────────────────────────────┐
│                    TASK NHẬN ĐƯỢC                         │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│  1. LOAD MEMORY + STEERING                               │
│     🔧 HOOK: pre-task.sh                                 │
│     - Đọc project.context.json (steering data)           │
│     - Đọc session.context.json                           │
│     - Đọc decisions.log.md                               │
│     📟 CMD: status.sh                                    │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│  1b. CLARIFY & CONFIRM ←───────────────────────────┐     │
│     - Phân tích yêu cầu: rõ / chưa rõ?             │     │
│     - Nếu chưa rõ → hỏi tối đa 3 câu               │     │
│     📟 CMD: clarify.sh → tạo solution-summary file  │     │
│     - Điền Solution Summary:                        │     │
│       • Hiểu của tôi về yêu cầu                    │     │
│       • Giải pháp đề xuất (approach, pattern)       │     │
│       • Sẽ làm / Sẽ KHÔNG làm                      │     │
│       • Files sẽ bị ảnh hưởng                      │     │
│       • Rủi ro                                      │     │
│     - Trình bày Solution Summary cho user           │     │
│                                                     │     │
│     ┌──────────────┐    ┌─────────────────────┐     │     │
│     │  User chốt?  │ No │ Chỉnh sửa & trình   │─────┘     │
│     │     Yes      │───▶│ bày lại             │           │
│     └──────┬───────┘    └─────────────────────┘           │
│     📟 CMD: approve-plan.sh <solution-summary-file>       │
└────────────┼─────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│  2. PHASE 1: REQUIREMENTS ←────────────────────────┐     │
│     📟 CMD: new-task.sh → tạo scaffold 3 file      │     │
│     - Viết User Stories                             │     │
│     - Viết Acceptance Criteria (Given/When/Then)    │     │
│     - Non-functional Requirements                   │     │
│     - Out of Scope                                  │     │
│     🔒 MCP: requirementsGate                        │     │
│                                                     │     │
│     ┌──────────────┐    ┌─────────────────────┐     │     │
│     │  Approved?   │ No │ Chỉnh sửa & review  │─────┘     │
│     │     Yes      │───▶│                     │           │
│     └──────┬───────┘    └─────────────────────┘           │
│     📟 CMD: approve-plan.sh <requirements-file>           │
└────────────┼─────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────┐
│  3. PHASE 2: DESIGN ←──────────────────────────────┐     │
│     🔧 HOOK: pre-design.sh (kiểm tra req approved) │     │
│     📟 CMD: create-design.sh                        │     │
│     - Đọc steering data từ project.context.json     │     │
│     - Architecture Overview                         │     │
│     - Data Model / API Contracts                    │     │
│     - File Map ([NEW] [MODIFY] [DELETE])            │     │
│     - Technical Decisions                           │     │
│     - Risks & Mitigation                            │     │
│     🔒 MCP: designGate                              │     │
│                                                     │     │
│     ┌──────────────┐    ┌─────────────────────┐     │     │
│     │  Approved?   │ No │ Chỉnh sửa & review  │─────┘     │
│     │     Yes      │───▶│                     │           │
│     └──────┬───────┘    └─────────────────────┘           │
│     📟 CMD: approve-plan.sh <design-file>                 │
└────────────┼─────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────┐
│  4. PHASE 3: TASKS ←───────────────────────────────┐     │
│     - Chia nhỏ thành sub-tasks checkbox             │     │
│     - Mỗi task liên kết US-1, US-2, ...            │     │
│     - Verification Checklist                        │     │
│     🔒 MCP: tasksGate                               │     │
│                                                     │     │
│     ┌──────────────┐    ┌─────────────────────┐     │     │
│     │  Approved?   │ No │ Chỉnh sửa & review  │─────┘     │
│     │     Yes      │───▶│                     │           │
│     └──────┬───────┘    └─────────────────────┘           │
│     📟 CMD: approve-plan.sh <tasks-file>                  │
└────────────┼─────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────┐
│  5. EXECUTION                                            │
│     📟 CMD: execute-plan.sh <tasks-file>                 │
│     - Thực hiện từng task theo thứ tự                    │
│     - SAU MỖI STEP:                                     │
│       • Cập nhật [x] trong tasks file                   │
│       • Ghi Progress Log vào design file                │
│       🔧 HOOK: post-step.sh                             │
│                                                         │
│     ┌──────────────┐    ┌──────────────────────┐        │
│     │  Step fail?  │ Yes│ Dừng → báo cáo → hỏi │        │
│     │     No       │───▶│ ý kiến user          │        │
│     └──────┬───────┘    └──────────────────────┘        │
└────────────┼────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────┐
│  6. REVIEW                                               │
│     - Đối chiếu kết quả với Acceptance Criteria          │
│     - Kiểm tra Verification Checklist                    │
│     📟 CMD: status.sh                                    │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│  7. MEMORY UPDATE                                        │
│     🔧 HOOK: post-task.sh                                │
│     - Cập nhật decisions.log.md                          │
│     - Mark tasks file: Status: DONE                      │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│  8. REPORT (BẮT BUỘC)                                    │
│     📟 CMD: generate-report.sh <tasks-file> <status>     │
│     - Tạo báo cáo đầy đủ → lưu vào reports/             │
│     - Hiển thị summary cho user:                        │
│       ✅ Tasks: X/Y  |  🎯 AC: X/Y  |  📁 N files       │
│     - Đề xuất bước tiếp theo                            │
│     - Hỏi: "Bạn có muốn tiếp tục với task khác không?"  │
└──────────────────────────────────────────────────────────┘
```

## Thời gian mỗi phase (ước tính)

| Phase | Thời gian điển hình |
|-------|---------------------|
| Load Memory + Steering | < 5s |
| Clarify & Confirm | 2-10 phút |
| Phase 1: Requirements | 5-15 phút |
| Phase 2: Design | 10-30 phút |
| Phase 3: Tasks | 5-10 phút |
| Execution | Tùy task |
| Review | 5-10 phút |
| Memory Update | < 1 phút |
| Report | < 1 phút (tự động) |
WF
  log "workflows/standard-task.workflow.md"

  cat > "$AG/workflows/emergency-task.workflow.md" <<'WF'
# Workflow: Emergency Task

## Khi nào dùng
- Task khẩn cấp, không có thời gian full 3-phase
- Yêu cầu rõ ràng 100%, không cần hỏi thêm

## Điều kiện bypass

Người dùng phải tường minh nói một trong:
- "Khẩn cấp, bỏ qua hỏi đáp"
- "EMERGENCY: ..."
- "Skip clarification"

## Quy trình rút gọn

```
TASK → Mini-requirements (US + AC ngắn gọn) → Mini-design (File Map) → Execute → Log
```

## Lưu ý

⚠️ Vẫn BẮT BUỘC tạo mini requirements + mini design dù khẩn cấp.
Có thể rút gọn nhưng không được bỏ qua hoàn toàn.
WF
  log "workflows/emergency-task.workflow.md"
}

# =============================================================================
# 8. MEMORY — Shared context memory + Steering data
# =============================================================================
create_memory() {
  step "Tạo Memory files (với Steering data)"

  cat > "$AG/memory/project.context.json" <<'JSON'
{
  "_description": "Context cố định của dự án + Steering data — cập nhật thủ công hoặc qua init-project",
  "project": {
    "name": "",
    "description": "",
    "version": "",
    "repository": "",
    "team": []
  },
  "tech_stack": {
    "language": [],
    "framework": [],
    "database": [],
    "infrastructure": [],
    "package_manager": ""
  },
  "architecture_patterns": {
    "folder_structure": "",
    "design_pattern": "",
    "state_management": "",
    "component_pattern": ""
  },
  "coding_standards": {
    "naming_convention": "",
    "formatting_tool": "",
    "linting_tool": "",
    "max_file_length": "",
    "import_order": "",
    "file_size_limits": {
      "_note": "Giới hạn số dòng để agent đọc hiệu quả. Vượt giới hạn → tách file",
      "component": 150,
      "service": 100,
      "utility": 80,
      "route_handler": 80,
      "model_schema": 100,
      "config": 50,
      "test": 200,
      "constants": 50
    }
  },
  "testing_strategy": {
    "unit_test_framework": "",
    "integration_test_framework": "",
    "e2e_tool": "",
    "coverage_min": "",
    "test_naming_convention": ""
  },
  "api_conventions": {
    "style": "",
    "versioning": "",
    "error_format": "",
    "auth_method": ""
  },
  "conventions": {
    "branch_naming": "",
    "commit_format": "",
    "pr_template": "",
    "code_review_process": ""
  },
  "environments": {
    "development": {},
    "staging": {},
    "production": {}
  },
  "glossary_ref": ".antigravity/memory/glossary.md",
  "last_updated": ""
}
JSON
  log "memory/project.context.json"

  cat > "$AG/memory/session.context.json" <<'JSON'
{
  "_description": "Context phiên làm việc hiện tại — tự động cập nhật",
  "session_id": "",
  "started_at": "",
  "current_task": "",
  "current_phase": "",
  "requirements_file": "",
  "design_file": "",
  "tasks_file": "",
  "completed_steps": [],
  "pending_steps": [],
  "notes": []
}
JSON
  log "memory/session.context.json"

  cat > "$AG/memory/decisions.log.md" <<'MD'
# Decisions Log — Antigravity

Lịch sử các quyết định quan trọng trong dự án.

---

<!-- Các entry được tự động thêm bởi post-task hook -->
MD
  log "memory/decisions.log.md"

  cat > "$AG/memory/glossary.md" <<'MD'
# Glossary — Thuật ngữ dự án

| Thuật ngữ | Định nghĩa | Ngữ cảnh sử dụng |
|-----------|-----------|-----------------|
| | | |

<!-- Thêm thuật ngữ dự án vào đây -->
MD
  log "memory/glossary.md"
}

# =============================================================================
# 9. TEMPLATES — Mẫu tài liệu (3-Phase)
# =============================================================================
create_templates() {
  step "Tạo Templates (3-Phase)"

  # 9-a. Solution Summary template (MỚI)
  cat > "$AG/templates/solution-summary.md" <<'TMPL'
# Solution Summary — {{TASK_TITLE}}
**Date**: {{DATE}}  |  **Task**: {{TASK_ID}}  |  **Status**: DRAFT

---

## 🎯 Hiểu của tôi về yêu cầu
> {{UNDERSTANDING}}

## 💡 Giải pháp đề xuất

**Approach**: {{APPROACH}}

**Pattern / Kỹ thuật**: {{PATTERN}}

**Lý do**: {{REASON}}

## ✅ Sẽ làm (In Scope)
- [ ] {{ACTION_1}}
- [ ] {{ACTION_2}}

## 🚫 Sẽ KHÔNG làm (Out of Scope)
- {{OUT_OF_SCOPE}}

## 📁 Files sẽ bị ảnh hưởng (sơ bộ)

| Action | File | Ghi chú |
|--------|------|---------|
| [NEW]    | | |
| [MODIFY] | | |

## ⚠️ Rủi ro & Lưu ý
- {{RISKS}}

## ❓ Câu hỏi còn lại
- {{QUESTIONS}}

---

## 🔏 User Confirmation

| | |
|-|-|
| **Confirmed by** | _________________ |
| **Confirmed at** | _________________ |
| **Notes / Chỉnh sửa** | |
TMPL
  log "templates/solution-summary.md"

  # 9-a2. Requirements template
  cat > "$AG/templates/requirements.md" <<'TMPL'
# Requirements — {{TASK_TITLE}}
**Date**: {{DATE}}  |  **Task ID**: {{TASK_ID}}  |  **Status**: DRAFT

---

## 📋 Tổng quan yêu cầu
> Mô tả ngắn gọn mục tiêu nghiệp vụ của task này.

{{OVERVIEW}}

## 👤 User Stories

### US-1: {{STORY_TITLE}}
> **As a** [vai trò], **I want to** [hành động], **so that** [lợi ích].

#### Acceptance Criteria
- [ ] **Given** [ngữ cảnh], **When** [hành động], **Then** [kết quả mong đợi]
- [ ] **Given** ..., **When** ..., **Then** ...

### US-2: {{STORY_TITLE}}
> **As a** [vai trò], **I want to** [hành động], **so that** [lợi ích].

#### Acceptance Criteria
- [ ] **Given** ..., **When** ..., **Then** ...

## 🔒 Non-functional Requirements
- [ ] Performance: {{PERFORMANCE}}
- [ ] Security: {{SECURITY}}
- [ ] Accessibility: {{ACCESSIBILITY}}

## 🚫 Out of Scope
- {{OUT_OF_SCOPE}}

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
| **Notes** | |
TMPL
  log "templates/requirements.md"

  # 9-b. Design template
  cat > "$AG/templates/design.md" <<'TMPL'
# Design — {{TASK_TITLE}}
**Task ID**: {{TASK_ID}}  |  **Requirements ref**: {{REQ_FILE}}  |  **Status**: DRAFT

---

## 🏗️ Architecture Overview
> Mô tả kiến trúc tổng quan, sơ đồ thành phần chính.

{{ARCHITECTURE}}

## 📊 Data Model
> Schema, entities, relationships (nếu có).

{{DATA_MODEL}}

## 🔌 API Contracts (nếu có)

| Method | Endpoint | Request | Response | Notes |
|--------|----------|---------|----------|-------|
| | | | | |

## 📁 File Map

| Action | File Path | Mô tả thay đổi |
|--------|-----------|-----------------|
| [NEW]    | | |
| [MODIFY] | | |
| [DELETE] | | |

## 🧠 Technical Decisions

| Quyết định | Lý do | Phương án thay thế đã cân nhắc |
|------------|-------|-------------------------------|
| | | |

## ⚠️ Risks & Mitigation

| Rủi ro | Xác suất | Tác động | Giảm thiểu |
|--------|----------|----------|------------|
| | | | |

## 📊 Progress Log
> Cập nhật sau mỗi step trong execution

| Time | Task | Result | Notes |
|------|------|--------|-------|
| | | | |

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
| **Notes** | |
TMPL
  log "templates/design.md"

  # 9-c. Tasks template (MỚI)
  cat > "$AG/templates/tasks.md" <<'TMPL'
# Tasks — {{TASK_TITLE}}
**Task ID**: {{TASK_ID}}  |  **Design ref**: {{DESIGN_FILE}}  |  **Status**: DRAFT

---

## ✅ Task Breakdown

### US-1: {{STORY_TITLE}}
- [ ] Task 1.1: {{TASK_DESC}}
- [ ] Task 1.2: {{TASK_DESC}}
- [ ] Task 1.3: {{TASK_DESC}}

### US-2: {{STORY_TITLE}}
- [ ] Task 2.1: {{TASK_DESC}}
- [ ] Task 2.2: {{TASK_DESC}}

## 🧪 Verification Checklist
- [ ] Tất cả AC trong requirements đã met
- [ ] Code đã pass linting/formatting
- [ ] Tests đã pass (nếu có)
- [ ] Không có regression
- [ ] Progress Log trong design đầy đủ

## 📊 Progress Summary

| Tổng tasks | Hoàn thành | Còn lại | % |
|------------|------------|---------|---|
| | | | |

---

## 🔏 Approval

| | |
|-|-|
| **Approved by** | _________________ |
| **Approved at** | _________________ |
| **Notes** | |
TMPL
  log "templates/tasks.md"

  # 9-d. Review template
  cat > "$AG/templates/review.md" <<'TMPL'
# Review — {{TASK_TITLE}}
**Task ID**: {{TASK_ID}}
**Requirements ref**: {{REQ_FILE}}
**Completed**: {{COMPLETED_AT}}

---

## ✅ Acceptance Criteria Check

| US | AC | Status | Notes |
|----|----|--------|-------|
| US-1 | AC-1 | ✅/❌ | |
| US-1 | AC-2 | ✅/❌ | |

---

## 📊 Kết quả thực tế

| Task | Expected | Actual | Diff |
|------|----------|--------|------|
| | | | |

---

## 🧪 Verification Results
- [ ] Tất cả AC met
- [ ] Tất cả tasks [x]
- [ ] Code pass linting
- [ ] Tests pass
- [ ] No regression

## 💡 Lessons Learned
- ...

## 🔧 Cải tiến đề xuất
- ...

## 📝 Quyết định ghi nhớ
- ...
TMPL
  log "templates/review.md"

  # 9-e. Report template (MỚI)
  cat > "$AG/templates/report.md" <<'TMPL'
# Báo cáo hoàn thành — {{TASK_TITLE}}
**Task ID**: {{TASK_ID}}  |  **Ngày**: {{DATE}}  |  **Trạng thái**: {{STATUS}}

---

## 📊 Tổng quan kết quả

| Chỉ số | Kết quả |
|--------|---------|
| Tasks hoàn thành | {{DONE}}/{{TOTAL}} |
| Acceptance Criteria met | {{AC_MET}}/{{AC_TOTAL}} |
| Trạng thái | {{STATUS}} |
| Thời gian | {{DURATION}} |

---

## ✅ Công việc đã hoàn thành
{{TASKS_DONE}}

## ⏳ Công việc chưa hoàn thành
{{TASKS_PENDING}}

---

## 📁 Files đã thay đổi

| Action | File | Ghi chú |
|--------|------|---------|
| | | |

## 🎯 Acceptance Criteria

| AC | Mô tả | Status |
|----|-------|--------|
| | | ✅/❌ |

---

## 🐛 Vấn đề gặp phải
> {{ISSUES}}

## 💡 Đề xuất bước tiếp theo
> {{NEXT_STEPS}}

---

## 📎 Tài liệu liên quan

| Loại | Đường dẫn |
|------|-----------|
| Solution Summary | {{SOLUTION_SUMMARY}} |
| Requirements | {{REQ_FILE}} |
| Design | {{DESIGN_FILE}} |
| Tasks | {{TASKS_FILE}} |
TMPL
  log "templates/report.md"

  # 9-f. Skill template
  cat > "$AG/templates/skill.md" <<'TMPL'
# Skill: {{SKILL_NAME}}

## Mô tả
> Mô tả ngắn gọn về chức năng và mục đích của skill này.

## Trigger
> Điều kiện hoặc thời điểm kích hoạt skill này (ví dụ: khi nhận task, khi chạy bước N trong plan, khi gặp lỗi...).

## Điều kiện tiên quyết
- [ ] 
- [ ] 

## Quy trình thực hiện
```
1. Bước 1...
2. Bước 2...
3. Bước 3...
```

## Đầu ra (Output)
- 

## Tài liệu / Context tham khảo
- 
TMPL
  log "templates/skill.md"
}

# =============================================================================
# 10. LOG INITIALIZATION
# =============================================================================
create_logs() {
  step "Khởi tạo Log files"
  local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[${ts}] [INIT] Antigravity scaffold v2.1 (Clarify+3-Phase+Report) initialized at $ROOT" > "$AG/logs/agent.log"
  log "logs/agent.log"
}

# =============================================================================
# 11. MAIN CONFIG
# =============================================================================
create_config() {
  step "Tạo file cấu hình chính"

  cat > "$AG/antigravity.config.yaml" <<'YAML'
# Antigravity Agent — Main Configuration (v2.0 — 3-Phase)

agent:
  name: Antigravity
  version: "2.0.0"
  description: "AI agent với quy trình 3-Phase: Requirements → Design → Tasks"

behavior:
  # 3-Phase Documentation bắt buộc
  require_requirements: true
  require_design: true
  require_tasks: true

  # Bắt buộc approve từng phase
  require_phase_approval: true

  # Tự động approve (chỉ dùng cho CI/automation)
  auto_approve: false

  # Dừng và hỏi nếu step thất bại
  stop_on_failure: true

  # Ghi log mọi hành động
  audit_log: true

  # Cập nhật tiến độ live sau mỗi step
  live_progress_update: true

  # Bắt buộc clarify & solution summary trước khi execute
  require_clarification: true

  # Bắt buộc generate report sau mỗi task
  require_report: true

clarification:
  max_questions_per_round: 3
  solution_summary_path: context/
  require_user_confirmation: true

reporting:
  auto_generate: true
  output_path: reports/
  include_ac_check: true
  include_file_map: true
  include_next_steps: true

memory:
  auto_load: true
  auto_save: true
  project_context: memory/project.context.json
  session_context: memory/session.context.json
  decisions_log: memory/decisions.log.md

paths:
  solution_summary: context/
  requirements: context/
  design: plans/
  tasks: plans/
  reports: reports/
  logs: logs/
  templates: templates/

hooks:
  pre_task: hooks/pre-task.sh
  post_task: hooks/post-task.sh
  pre_design: hooks/pre-design.sh
  post_step: hooks/post-step.sh

workflow:
  default: workflows/standard-task.workflow.md
  emergency: workflows/emergency-task.workflow.md
YAML
  log "antigravity.config.yaml"

  cat > "$AG/README.md" <<'MD'
# Antigravity AI Agent (v2.1 — Clarify + 3-Phase + Report)

Agent hỗ trợ với quy trình đầy đủ: **Clarify → Requirements → Design → Tasks → Execute → Review → Report**.

## Quy trình đầy đủ

```
📐 CLARIFY — Làm rõ yêu cầu + Solution Summary → User chốt
       ↓ (user confirmed)
📋 Phase 1: REQUIREMENTS — User Stories + Acceptance Criteria
       ↓ (approve)
🏗️  Phase 2: DESIGN — Architecture + File Map + Data Model
       ↓ (approve)
✅ Phase 3: TASKS — Task Breakdown (checkbox liên kết US)
       ↓ (approve)
🚀 EXECUTION — Code + Live Progress Update
       ↓
🔍 REVIEW — Đối chiếu AC + Verification Checklist
       ↓
📋 REPORT — Báo cáo tự động → lưu vào reports/
```

## Cấu trúc

```
.antigravity/
├── antigravity.config.yaml   # Cấu hình chính (v2.0)
├── rules/                    # Quy tắc hành vi (3-Phase)
│   ├── 00-core.md
│   ├── 01-requirements.md
│   ├── 02-design-tasks.md
│   └── 03-memory.md
├── hooks/                    # Lifecycle hooks
│   ├── pre-task.sh
│   ├── post-task.sh
│   ├── pre-design.sh        # Kiểm tra requirements approved
│   └── post-step.sh         # Cập nhật tiến độ live
├── mcp/                      # MCP configuration (3 gates)
│   ├── mcp.config.json
│   └── context-protocol.md
├── skills/                   # Khả năng agent
│   ├── clarify.skill.md      # Làm rõ + Solution Summary
│   ├── requirements.skill.md
│   ├── design.skill.md
│   ├── execute.skill.md
│   └── review.skill.md
├── commands/                 # Lệnh nhanh
│   ├── clarify.sh            # Tạo Solution Summary scaffold
│   ├── generate-report.sh    # Tạo báo cáo sau khi hoàn thành
│   ├── new-task.sh           # Tạo scaffold 3 file
│   ├── create-design.sh      # Tạo file design
│   ├── approve-plan.sh       # Approve bất kỳ phase
│   ├── execute-plan.sh       # Thực thi (kiểm tra 3 file)
│   ├── status.sh             # Trạng thái 3-phase
│   ├── new-skill.sh
│   └── init-project.sh       # Khởi tạo steering data
├── workflows/                # Quy trình tổng hợp
│   ├── standard-task.workflow.md
│   └── emergency-task.workflow.md
├── memory/                   # Shared context + Steering data
│   ├── project.context.json  # ← Steering data + file_size_limits
│   ├── session.context.json
│   ├── decisions.log.md
│   └── glossary.md
├── templates/                # Mẫu tài liệu
│   ├── solution-summary.md   # Template Solution Summary
│   ├── requirements.md       # Template User Stories + AC
│   ├── design.md             # Template Architecture + File Map
│   ├── tasks.md              # Template Task Breakdown
│   ├── report.md             # Template báo cáo
│   ├── review.md
│   └── skill.md
├── plans/                    # Design + Tasks files (tạo động)
├── context/                  # Requirements + Solution Summary (tạo động)
├── reports/                  # Báo cáo hoàn thành (tạo động)
└── logs/
    └── agent.log
```

## Sử dụng nhanh

```bash
# Khởi tạo steering data cho dự án
bash .antigravity/commands/init-project.sh

# Xem trạng thái
bash .antigravity/commands/status.sh

# Bắt đầu task mới: Clarify → tạo Solution Summary
bash .antigravity/commands/clarify.sh "Mô tả task của bạn"

# Sau khi user chốt → tạo scaffold 3-phase
bash .antigravity/commands/new-task.sh "Mô tả task của bạn"

# Approve từng phase
bash .antigravity/commands/approve-plan.sh ".antigravity/context/solution-summary-*.md"
bash .antigravity/commands/approve-plan.sh ".antigravity/context/requirements-*.md"
bash .antigravity/commands/approve-plan.sh ".antigravity/plans/*-design.md"
bash .antigravity/commands/approve-plan.sh ".antigravity/plans/*-tasks.md"

# Thực thi (sau khi cả 3 phase đều approved)
bash .antigravity/commands/execute-plan.sh ".antigravity/plans/*-tasks.md"

# Tạo báo cáo sau khi hoàn thành
bash .antigravity/commands/generate-report.sh ".antigravity/plans/*-tasks.md" success
```

## Nguyên tắc cốt lõi

1. 📐 **Clarify trước** — Làm rõ yêu cầu + Solution Summary → user chốt
2. 📋 **3-Phase bắt buộc** — Requirements → Design → Tasks trước khi code
3. 👤 **User Stories + AC** — Mọi yêu cầu đều chuẩn PROD
4. 🏗️ **Design trước code** — Architecture, File Map, Technical Decisions
5. ✅ **Task Breakdown** — Mỗi task liên kết User Story, cập nhật [x] live
6. ✋ **Approve từng phase** — Không skip, không giả định
7. 📋 **Report bắt buộc** — Báo cáo tự động sau mỗi task, lưu vào reports/
8. 📝 **Ghi log mọi thứ** — Mọi hành động đều có audit trail
9. 🧠 **Steering data** — Tuân thủ architecture, coding style, file size limits
MD
  log "README.md"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  banner
  create_dirs
  create_rules
  create_hooks
  create_mcp
  create_skills
  create_commands
  create_workflows
  create_memory
  create_templates
  create_logs
  create_config

  echo ""
  echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${GREEN}  ✅ Antigravity scaffold v2.1 (Clarify+3-Phase+Report) hoàn tất!${RESET}"
  echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "  📁 Root:    ${YELLOW}$ROOT${RESET}"
  echo -e "  📄 Config:  ${YELLOW}$AG/antigravity.config.yaml${RESET}"
  echo -e "  📖 Docs:    ${YELLOW}$AG/README.md${RESET}"
  echo ""
  echo -e "  ${BOLD}Bước tiếp theo:${RESET}"
  echo -e "  1. Khởi tạo steering data: ${CYAN}bash $AG/commands/init-project.sh${RESET}"
  echo -e "  2. Xem trạng thái:         ${CYAN}bash $AG/commands/status.sh${RESET}"
  echo -e "  3. Clarify task đầu tiên:  ${CYAN}bash $AG/commands/clarify.sh \"\<mô tả\>\"${RESET}"
  echo -e "  4. Tạo 3-phase scaffold:   ${CYAN}bash $AG/commands/new-task.sh \"\<mô tả\>\"${RESET}"
  echo -e "  5. Tạo báo cáo sau khi xong: ${CYAN}bash $AG/commands/generate-report.sh \"\<tasks-file\>\" success${RESET}"
  echo ""
}

main "$@"
