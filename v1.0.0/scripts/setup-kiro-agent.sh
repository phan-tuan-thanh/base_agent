#!/usr/bin/env bash
# =============================================================================
# setup-kiro-agent.sh  v3.0
# Cấu trúc chuẩn Kiro Agent: steering/ + specs/ + hooks/
#
# Cách dùng:
#   chmod +x setup-kiro-agent.sh
#   ./setup-kiro-agent.sh [--project-dir /path/to/project]
#
# Sau khi chạy, mở Kiro và gõ: /init-project
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERR]${RESET}   $*"; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
            echo -e "${BOLD}${CYAN}  $*${RESET}"
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ── Tham số ──────────────────────────────────────────────────────────────────
PROJECT_DIR="$(pwd)"
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    *) warn "Unknown arg: $1"; shift ;;
  esac
done

KIRO_DIR="$PROJECT_DIR/.kiro"
info "Project dir : $PROJECT_DIR"
info "Kiro dir    : $KIRO_DIR"

# ── Cấu trúc thư mục ─────────────────────────────────────────────────────────
header "1. Tạo cấu trúc thư mục .kiro (chuẩn Steering + Specs + Hooks)"

mkdir -p \
  "$KIRO_DIR/steering" \
  "$KIRO_DIR/specs/.template" \
  "$KIRO_DIR/hooks" \
  "$KIRO_DIR/settings" \
  "$KIRO_DIR/memory" \
  "$KIRO_DIR/plans"
# Lưu ý: KHÔNG tạo .kiro/commands/ — Kiro IDE không đọc folder này
# Slash commands = hooks type:manual + steering files inclusion:manual

success "Đã tạo thư mục .kiro/"

# =============================================================================
# ██████  STEERING
# Luôn được agent đọc — định nghĩa WHO (product), WHAT (tech), HOW (process)
# =============================================================================
header "2. Tạo Steering files"

# ── 2.1 product.md ────────────────────────────────────────────────────────────
cat > "$KIRO_DIR/steering/product.md" << 'EOF'
---
inclusion: always
---

# Product Context

<!-- /init-project sẽ điền tự động. Có thể chỉnh thủ công. -->

## Tên dự án
> _Chưa cấu hình — chạy `/init-project` để thiết lập_

## Mô tả
> _Mục đích và giá trị cốt lõi của sản phẩm_

## Loại hình
- [ ] Internal tool / back-office
- [ ] Customer-facing web app
- [ ] API / Microservice
- [ ] Mobile app
- [ ] Data pipeline / ETL
- [ ] Khác: ___

## Người dùng mục tiêu
> _Ai sẽ dùng sản phẩm này?_

## Tính năng cốt lõi
> _Liệt kê 3–5 tính năng chính_

## Thuật ngữ nghiệp vụ (Glossary)

| Thuật ngữ | Định nghĩa | Ghi chú |
|-----------|-----------|---------|
| _ví dụ: BPM_ | _IBM Business Process Manager_ | _v8.6_ |

## Quy định & Compliance
> _PCI-DSS / SBV / HIPAA / ISO 27001 / Không có_

## Ngôn ngữ giao tiếp với agent
> _Tiếng Việt / English / Song ngữ_
EOF
success "steering/product.md"

# ── 2.2 tech.md ──────────────────────────────────────────────────────────────
cat > "$KIRO_DIR/steering/tech.md" << 'EOF'
---
inclusion: always
---

# Tech Stack

<!-- /init-project sẽ điền tự động. Có thể chỉnh thủ công. -->

## Backend
| Hạng mục   | Công nghệ | Phiên bản |
|------------|-----------|-----------|
| Ngôn ngữ   | _chưa cấu hình_ | |
| Framework  | | |
| Runtime    | | |

## Frontend
| Hạng mục   | Công nghệ | Phiên bản |
|------------|-----------|-----------|
| Framework  | _chưa cấu hình / không có_ | |
| Build tool | | |
| UI library | | |

## Mobile
> _React Native / Flutter / Native / Không có_

## Data
| Hạng mục       | Công nghệ | Phiên bản |
|----------------|-----------|-----------|
| Database chính | _chưa cấu hình_ | |
| Cache          | | |
| Search         | | |
| Message Queue  | | |

## Infrastructure
| Hạng mục       | Công nghệ |
|----------------|-----------|
| Cloud platform | _chưa cấu hình_ |
| Container      | |
| Orchestration  | |
| CI/CD          | |
| Monitoring     | |

## Authentication & Security
> _JWT / OAuth2 / LDAP / Azure AD / Keycloak / Khác_

## External Integrations
> _Liệt kê các hệ thống bên ngoài kết nối vào_

## API Protocol
> _REST / GraphQL / gRPC / SOAP / WebSocket_

## Môi trường
| Tên | URL / Host | Ghi chú |
|-----|-----------|---------|
| dev | | |
| staging | | |
| prod | | |
EOF
success "steering/tech.md"

# ── 2.3 structure.md ─────────────────────────────────────────────────────────
cat > "$KIRO_DIR/steering/structure.md" << 'EOF'
---
inclusion: always
---

# Project Structure

## Cấu trúc thư mục

```
project-root/
├── .kiro/
│   ├── steering/          ← Ngữ cảnh luôn được đọc (product, tech, process)
│   ├── specs/             ← Đặc tả từng feature (requirements + design + tasks)
│   ├── hooks/             ← Tự động hóa: pre-commit, code-review, test-gen
│   ├── memory/            ← Shared context, decisions, glossary
│   └── plans/             ← File kế hoạch task (tự động tạo)
├── src/
├── docs/
└── README.md
```

## Quy tắc tổ chức file

- **Mỗi feature** có thư mục riêng trong `specs/<feature-name>/`
- **Plans** được đặt tên: `YYYY-MM-DD_<slug-task>.md`
- **Không** đặt business logic trong thư mục `.kiro/`

## File & Folder KHÔNG được tự động chỉnh sửa

```
# Danh sách này được /init-project điền tự động
# Ví dụ:
# config/production.yml
# certs/
# .env.prod
# migration/V*.sql (chỉ append, không sửa)
```

## Đường dẫn quan trọng

| Loại | Đường dẫn |
|------|-----------|
| Source code | `src/` |
| Tests | `tests/` |
| Config | `config/` |
| Docs | `docs/` |
| DB Migrations | `migrations/` |
| CI/CD | `.github/workflows/` hoặc `.gitlab-ci.yml` |
EOF
success "steering/structure.md"

# ── 2.4 coding-standards.md ──────────────────────────────────────────────────
cat > "$KIRO_DIR/steering/coding-standards.md" << 'EOF'
---
inclusion: always
---

# Coding Standards

<!-- /init-project bổ sung phần stack-specific tự động -->

## Nguyên tắc chung

- **Tên biến / hàm / class**: tiếng Anh, rõ nghĩa, không viết tắt tuỳ tiện
- **Comment nghiệp vụ**: tiếng Việt khi cần giải thích logic phức tạp
- **Không hardcode** secret, password, API key — dùng biến môi trường
- **Validate** tất cả input từ bên ngoài (user, API, file upload)
- **Log lỗi** nhưng không log dữ liệu nhạy cảm (PII, credentials)

## Git Conventions

```
Commit message: <type>(<scope>): <mô tả ngắn gọn bằng tiếng Anh>

Types:
  feat     — tính năng mới
  fix      — sửa lỗi
  refactor — cải thiện code, không đổi behavior
  test     — thêm / sửa test
  docs     — tài liệu
  chore    — công việc hạ tầng, build, config
  perf     — cải thiện performance

Ví dụ:
  feat(auth): add JWT refresh token endpoint
  fix(payment): handle timeout when calling external gateway
  docs(api): update OpenAPI spec for user endpoints
```

## Bảo mật (Security)

- Mã hóa dữ liệu nhạy cảm at-rest và in-transit
- Không trả về stack trace trong response production
- Dùng parameterized query — không ghép chuỗi SQL
- Rate limiting cho các endpoint public

## Stack-Specific Standards

<!-- /init-project hoặc /update-agent stack sẽ điền phần này -->

> _Chưa cấu hình — chạy `/init-project` để thiết lập theo stack thực tế_

### Template (sẽ được thay thế):

| Stack | Formatter | Linter | Style Guide |
|-------|-----------|--------|-------------|
| Java | — | Checkstyle | Google Java Style |
| TypeScript | Prettier | ESLint strict | Airbnb / project |
| Python | Black | Ruff / flake8 | PEP8 + type hints |
| Go | gofmt | golangci-lint | Effective Go |
| C# | — | StyleCop | Microsoft conventions |
EOF
success "steering/coding-standards.md"

# ── 2.5 api-standards.md ─────────────────────────────────────────────────────
cat > "$KIRO_DIR/steering/api-standards.md" << 'EOF'
---
inclusion: fileMatch
filePatterns:
  - "src/api/**"
  - "src/routes/**"
  - "src/controllers/**"
  - "**/handler*"
  - "**/endpoint*"
---

# API Standards

## URL Design (REST)

```
Pattern : /api/v{N}/{resource}/{id}/{sub-resource}
Ví dụ   : /api/v1/users/123/orders

Quy tắc:
  - Danh từ số nhiều cho resource (users, orders, products)
  - Lowercase + dấu gạch ngang (kebab-case)
  - Version trong URL: /api/v1/...
  - Không dùng động từ trong URL (/getUser → GET /users/:id)
```

## HTTP Methods

| Method | Ý nghĩa | Idempotent |
|--------|---------|-----------|
| GET | Đọc | ✅ |
| POST | Tạo mới | ❌ |
| PUT | Replace toàn bộ | ✅ |
| PATCH | Cập nhật một phần | ✅ |
| DELETE | Xóa | ✅ |

## Response Format

```json
// Success
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "total": 100 }
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Mô tả lỗi thân thiện với user",
    "details": [{ "field": "email", "message": "Invalid format" }]
  }
}
```

## HTTP Status Codes

| Code | Khi dùng |
|------|---------|
| 200 | Thành công (GET, PUT, PATCH) |
| 201 | Tạo mới thành công (POST) |
| 204 | Thành công, không có body (DELETE) |
| 400 | Request không hợp lệ |
| 401 | Chưa xác thực |
| 403 | Đã xác thực nhưng không có quyền |
| 404 | Không tìm thấy resource |
| 409 | Conflict (duplicate, optimistic lock) |
| 422 | Validation failed |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

## Pagination

```
Query params: ?page=1&limit=20&sort=createdAt&order=desc
Response meta: { "page": 1, "limit": 20, "total": 150, "totalPages": 8 }
```

## Versioning Strategy

> _API versioning dùng URL path (/api/v1, /api/v2)_
> _Deprecated version cần thông báo trước ít nhất 3 tháng_

## Documentation

- Mọi endpoint phải có OpenAPI/Swagger spec
- Cập nhật spec trước hoặc cùng lúc với code
EOF
success "steering/api-standards.md"

# ── 2.6 testing-standards.md ─────────────────────────────────────────────────
cat > "$KIRO_DIR/steering/testing-standards.md" << 'EOF'
---
inclusion: fileMatch
filePatterns:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/tests/**"
  - "**/test/**"
---

# Testing Standards

## Coverage Requirements

| Loại | Mức tối thiểu | Mục tiêu |
|------|--------------|---------|
| Unit test | 70% | 85% |
| Integration test | Bắt buộc cho API endpoints | — |
| E2E test | Bắt buộc cho happy path | — |

## Nguyên tắc viết test

- **Tên test**: mô tả hành vi, không mô tả implement
  ```
  ❌ test_getUserById()
  ✅ should_return_user_when_valid_id_provided()
  ✅ should_throw_404_when_user_not_found()
  ```
- **Cấu trúc AAA**: Arrange → Act → Assert
- Mỗi test chỉ kiểm tra **một behavior**
- Test phải **độc lập** — không phụ thuộc thứ tự chạy
- Dùng **factory / builder** để tạo test data, không hardcode

## Test Pyramid

```
          ┌─────┐
          │ E2E │  ← Ít nhất, chạy chậm (critical user journeys)
         ┌┴─────┴┐
         │ Integ │  ← Vừa phải (API, DB, service boundaries)
        ┌┴───────┴┐
        │  Unit   │  ← Nhiều nhất, chạy nhanh (business logic)
        └─────────┘
```

## Mocking Strategy

- Mock external services (HTTP, email, SMS, payment gateway)
- Không mock internal module trừ khi có lý do rõ ràng
- Dùng in-memory DB cho integration test (không dùng DB prod)

## Test Naming Convention

```
File: <module>.test.ts / <module>_test.go / test_<module>.py
Class: <Feature>Test / Test<Feature>
Method: test_<behavior>_when_<condition>_should_<expected>
```

## Test Framework

> _Được điền bởi /init-project theo stack thực tế_
> _Ví dụ: Jest (Node), JUnit 5 (Java), pytest (Python), Go test_

## CI Requirements

- Tất cả test phải pass trước khi merge
- Test không được phụ thuộc vào external service thật
- Thời gian chạy unit test < 5 phút
EOF
success "steering/testing-standards.md"

# =============================================================================
# ██████  SPECS — Template + 2 ví dụ minh hoạ
# =============================================================================
header "3. Tạo Specs (template + examples)"

# ── Template spec (dùng cho /new-spec) ───────────────────────────────────────
cat > "$KIRO_DIR/specs/.template/requirements.md" << 'EOF'
---
specName: FEATURE_NAME
version: 1.0
status: draft          # draft | review | approved | implemented
createdAt: YYYY-MM-DD
---

# Requirements: FEATURE_NAME

## 1. Bối cảnh & Vấn đề

> _Tại sao cần feature này? Vấn đề gì đang tồn tại?_

## 2. Mục tiêu

> _Feature thành công khi nào? Đo lường như thế nào?_

## 3. User Stories

```
As a <vai trò người dùng>
I want to <hành động / tính năng>
So that <lợi ích / giá trị>

Acceptance Criteria:
  GIVEN <điều kiện ban đầu>
  WHEN  <hành động xảy ra>
  THEN  <kết quả mong đợi>
```

## 4. Functional Requirements

| ID | Yêu cầu | Ưu tiên | Ghi chú |
|----|---------|---------|---------|
| FR-01 | | Must Have | |
| FR-02 | | Should Have | |
| FR-03 | | Nice to Have | |

## 5. Non-Functional Requirements

| Loại | Yêu cầu cụ thể |
|------|---------------|
| Performance | |
| Security | |
| Availability | |
| Scalability | |

## 6. Out of Scope

> _Những gì KHÔNG thuộc phạm vi feature này_

## 7. Phụ thuộc

> _Feature khác / API / service cần có trước_

## 8. Rủi ro & Giả định

| Rủi ro | Xác suất | Mức độ ảnh hưởng | Biện pháp |
|--------|---------|-----------------|---------|
EOF

cat > "$KIRO_DIR/specs/.template/design.md" << 'EOF'
---
specName: FEATURE_NAME
version: 1.0
status: draft
---

# Design: FEATURE_NAME

## 1. Kiến trúc tổng quan

```
[Sơ đồ / mô tả luồng dữ liệu]
```

## 2. Data Model

```sql
-- Bảng mới hoặc thay đổi schema
```

## 3. API Contracts

### Endpoint: METHOD /api/v1/...

**Request:**
```json
{
  "field": "type"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {}
}
```

**Error cases:**
| Code | Khi nào | Response |
|------|---------|---------|

## 4. Business Logic

> _Mô tả các rule nghiệp vụ, validation, edge case_

## 5. Security Considerations

> _Authentication, authorization, data validation, encryption_

## 6. Performance Considerations

> _Index DB, caching strategy, async processing_

## 7. Dependencies

> _Library mới, service ngoài, internal module_

## 8. Migration Plan (nếu có)

> _Thay đổi breaking, migration script, rollback_
EOF

cat > "$KIRO_DIR/specs/.template/tasks.md" << 'EOF'
---
specName: FEATURE_NAME
version: 1.0
status: todo           # todo | in-progress | done
estimatedDays: 0
---

# Tasks: FEATURE_NAME

## Checklist triển khai

### Phase 1 — Backend
- [ ] T01: Tạo/cập nhật data model & migration
- [ ] T02: Implement service/business logic
- [ ] T03: Tạo API endpoint(s)
- [ ] T04: Viết unit test cho service
- [ ] T05: Viết integration test cho API

### Phase 2 — Frontend (nếu có)
- [ ] T06: Tạo UI components
- [ ] T07: Kết nối API
- [ ] T08: Viết component tests

### Phase 3 — QA & Hoàn thiện
- [ ] T09: Code review
- [ ] T10: E2E test / manual testing
- [ ] T11: Cập nhật documentation
- [ ] T12: Performance check

## Phân công

| Task | Người làm | Deadline | Trạng thái |
|------|-----------|---------|-----------|

## Ghi chú implementation

> _Quyết định kỹ thuật, trade-off, lưu ý đặc biệt_
EOF
success "specs/.template/ (requirements, design, tasks)"

# ── Ví dụ minh hoạ: user-authentication ──────────────────────────────────────
mkdir -p "$KIRO_DIR/specs/user-authentication"

cat > "$KIRO_DIR/specs/user-authentication/requirements.md" << 'EOF'
---
specName: user-authentication
version: 1.0
status: approved
createdAt: 2025-06-01
---

# Requirements: User Authentication

## 1. Bối cảnh & Vấn đề

Hệ thống hiện tại chưa có cơ chế xác thực. Cần bổ sung authentication
để bảo vệ các API endpoint và quản lý phiên đăng nhập người dùng.

## 2. Mục tiêu

- Người dùng có thể đăng nhập bằng email + password
- Session được quản lý bằng JWT (access token + refresh token)
- Tốc độ login < 500ms (P95)

## 3. User Stories

```
As a registered user
I want to log in with my email and password
So that I can access protected features

Acceptance Criteria:
  GIVEN a valid email and password
  WHEN  I POST /api/v1/auth/login
  THEN  I receive access_token (15 phút) + refresh_token (7 ngày)

  GIVEN an invalid password (>5 lần liên tiếp)
  WHEN  I attempt to login
  THEN  account bị khóa tạm thời 15 phút
```

## 4. Functional Requirements

| ID | Yêu cầu | Ưu tiên |
|----|---------|---------|
| FR-01 | Login bằng email + password | Must Have |
| FR-02 | JWT access token (15 phút) | Must Have |
| FR-03 | Refresh token (7 ngày) | Must Have |
| FR-04 | Logout (revoke token) | Must Have |
| FR-05 | Khóa account sau 5 lần sai | Should Have |
| FR-06 | Đổi mật khẩu | Should Have |

## 5. Out of Scope

- Social login (Google, Facebook) — phase 2
- 2FA / MFA — phase 2
- SSO / SAML — phase 3
EOF

cat > "$KIRO_DIR/specs/user-authentication/design.md" << 'EOF'
---
specName: user-authentication
version: 1.0
status: approved
---

# Design: User Authentication

## 1. Kiến trúc tổng quan

```
Client → POST /auth/login → AuthController → AuthService
                                                 ↓
                                           UserRepository (DB)
                                                 ↓
                                           JWTService → tokens
```

## 2. Data Model

```sql
-- Không cần bảng mới, dùng bảng users hiện có
ALTER TABLE users ADD COLUMN failed_login_attempts INT DEFAULT 0;
ALTER TABLE users ADD COLUMN locked_until TIMESTAMP NULL;

-- Bảng lưu refresh token (để revoke được)
CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  VARCHAR(64) NOT NULL UNIQUE,
  expires_at  TIMESTAMP NOT NULL,
  revoked_at  TIMESTAMP NULL,
  created_at  TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
```

## 3. API Contracts

### POST /api/v1/auth/login
```json
// Request
{ "email": "user@example.com", "password": "s3cr3t" }

// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}

// Response 401 — sai credential
{ "success": false, "error": { "code": "INVALID_CREDENTIALS", "message": "Email hoặc mật khẩu không đúng" } }

// Response 423 — tài khoản bị khóa
{ "success": false, "error": { "code": "ACCOUNT_LOCKED", "message": "Tài khoản tạm khóa, thử lại sau 15 phút" } }
```

## 4. Business Logic

- Mật khẩu hash bằng bcrypt (cost factor 12)
- Access token ký bằng RS256 (private key)
- Refresh token lưu hash SHA-256 vào DB (không lưu raw)
- Sau 5 lần sai → lock account 15 phút, đặt lại counter khi login thành công

## 5. Security

- Rate limit: 10 request/phút trên endpoint /auth/login
- HTTPS bắt buộc
- HttpOnly cookie cho refresh token (tránh XSS)
EOF

cat > "$KIRO_DIR/specs/user-authentication/tasks.md" << 'EOF'
---
specName: user-authentication
version: 1.0
status: in-progress
estimatedDays: 4
---

# Tasks: User Authentication

### Phase 1 — Backend
- [x] T01: Tạo migration bảng refresh_tokens
- [x] T02: Implement AuthService (login, logout, refresh)
- [ ] T03: Tạo AuthController + routes
- [ ] T04: Unit test AuthService
- [ ] T05: Integration test /auth/login endpoint

### Phase 2 — Security hardening
- [ ] T06: Rate limiting middleware
- [ ] T07: Account lock logic
- [ ] T08: Security test (brute force, token replay)

### Phase 3 — QA
- [ ] T09: Code review
- [ ] T10: Cập nhật OpenAPI spec
EOF
success "specs/user-authentication/ (ví dụ minh hoạ)"

# ── Ví dụ minh hoạ: payment-service ─────────────────────────────────────────
mkdir -p "$KIRO_DIR/specs/payment-service"

cat > "$KIRO_DIR/specs/payment-service/requirements.md" << 'EOF'
---
specName: payment-service
version: 1.0
status: draft
createdAt: 2025-06-01
---

# Requirements: Payment Service

## 1. Bối cảnh

Tích hợp cổng thanh toán để xử lý giao dịch từ người dùng cuối.

## 2. User Stories

```
As a customer
I want to pay for my order using card or e-wallet
So that I can complete my purchase

Acceptance Criteria:
  GIVEN a valid order and payment method
  WHEN  I confirm payment
  THEN  transaction is processed within 3 seconds
  AND   I receive confirmation email

  GIVEN a failed payment
  WHEN  gateway returns error
  THEN  order status stays "pending"
  AND   I can retry payment
```

## 3. Functional Requirements

| ID | Yêu cầu | Ưu tiên |
|----|---------|---------|
| FR-01 | Thanh toán qua thẻ Visa/MC | Must Have |
| FR-02 | Thanh toán qua ví điện tử | Should Have |
| FR-03 | Webhook nhận kết quả từ gateway | Must Have |
| FR-04 | Retry tự động (idempotent) | Must Have |
| FR-05 | Hoàn tiền (refund) | Should Have |
| FR-06 | Lịch sử giao dịch | Must Have |

## 4. Non-Functional Requirements

| Loại | Yêu cầu |
|------|---------|
| Reliability | Idempotent — không charge 2 lần cùng 1 order |
| Security | PCI-DSS compliant, không lưu raw card data |
| Audit | Log đầy đủ mọi giao dịch, bất biến |
EOF

cat > "$KIRO_DIR/specs/payment-service/design.md" << 'EOF'
---
specName: payment-service
version: 1.0
status: draft
---

# Design: Payment Service

## 1. Kiến trúc

```
Client → PaymentController → PaymentService → GatewayAdapter
                                   ↓                 ↓
                           TransactionRepo     [External Gateway]
                                   ↓
                           EventPublisher → OrderService (webhook)
```

## 2. Idempotency

Mỗi request thanh toán phải có `idempotency_key` (UUID).
PaymentService kiểm tra key trước khi gọi gateway:
- Key tồn tại → trả về kết quả cũ (không charge lại)
- Key mới → tạo transaction, gọi gateway, lưu kết quả

## 3. Data Model

```sql
CREATE TABLE transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id         UUID NOT NULL,
  idempotency_key  UUID NOT NULL UNIQUE,
  amount           DECIMAL(15,2) NOT NULL,
  currency         CHAR(3) NOT NULL DEFAULT 'VND',
  status           VARCHAR(20) NOT NULL,  -- pending|success|failed|refunded
  gateway          VARCHAR(50) NOT NULL,
  gateway_tx_id    VARCHAR(255),
  gateway_response JSONB,
  created_at       TIMESTAMP DEFAULT NOW(),
  updated_at       TIMESTAMP DEFAULT NOW()
);
```
EOF

cat > "$KIRO_DIR/specs/payment-service/tasks.md" << 'EOF'
---
specName: payment-service
version: 1.0
status: todo
estimatedDays: 8
---

# Tasks: Payment Service

### Phase 1 — Foundation
- [ ] T01: Tạo migration bảng transactions
- [ ] T02: Implement GatewayAdapter interface
- [ ] T03: Tích hợp gateway đầu tiên (sandbox)
- [ ] T04: Idempotency middleware

### Phase 2 — Core Flow
- [ ] T05: PaymentService (initiate, confirm, cancel)
- [ ] T06: Webhook handler (nhận callback từ gateway)
- [ ] T07: Event publish sang OrderService
- [ ] T08: Unit + Integration tests

### Phase 3 — Hardening
- [ ] T09: Retry logic với exponential backoff
- [ ] T10: Refund flow
- [ ] T11: Audit log (bất biến)
- [ ] T12: Load test (100 TPS)
EOF
success "specs/payment-service/ (ví dụ minh hoạ)"

# =============================================================================
# ██████  HOOKS — Schema thật của Kiro IDE
# Extension: .kiro.hook  (KHÔNG phải .json)
# Schema: { "name", "description", "version",
#           "when": { "type", "patterns" },
#           "then": { "type", "prompt" } }
# Kiro IDE tự đọc tất cả *.kiro.hook trong .kiro/hooks/ khi mở project
# =============================================================================
header "4. Tạo Hooks (.kiro.hook — schema thật Kiro IDE đọc được)"

# ── 4a. Security scan khi lưu file source ─────────────────────────────────────
cat > "$KIRO_DIR/hooks/security-scan-on-save.kiro.hook" << 'EOF'
{
  "name": "Security scan on save",
  "description": "Scan for hardcoded secrets and security issues when saving source files",
  "version": "1",
  "when": {
    "type": "fileEdited",
    "patterns": [
      "src/**/*.ts",
      "src/**/*.js",
      "src/**/*.py",
      "src/**/*.java",
      "src/**/*.go",
      "config/**/*",
      "**/*.env*"
    ]
  },
  "then": {
    "type": "askAgent",
    "prompt": "A source file was just saved. Scan it for security issues:\n1. Hardcoded secrets, API keys, passwords, or tokens\n2. Sensitive data (PII, credentials) in log statements\n3. SQL injection vulnerabilities (string concatenation in queries)\n4. Hardcoded URLs or IPs that should be environment config\n\nIf issues found: list them with line numbers and suggest fixes. Do NOT auto-fix — report only.\nIf clean: one line response 'Security scan: clean'."
  }
}
EOF
success "hooks/security-scan-on-save.kiro.hook"

# ── 4b. Auto-generate test khi tạo file source mới ───────────────────────────
cat > "$KIRO_DIR/hooks/test-scaffold-on-create.kiro.hook" << 'EOF'
{
  "name": "Test scaffold on file create",
  "description": "Suggest test file skeleton when a new source file is created",
  "version": "1",
  "when": {
    "type": "fileCreated",
    "patterns": [
      "src/**/*.ts",
      "src/**/*.js",
      "src/**/*.py",
      "src/**/*.java",
      "src/**/*.go"
    ]
  },
  "then": {
    "type": "askAgent",
    "prompt": "A new source file was just created. Analyze it and:\n1. Identify public functions/methods/classes that need tests\n2. Suggest the test file path following project convention\n3. Generate a test skeleton with:\n   - Describe/suite blocks per class or module\n   - Empty test stubs for each public method (happy path + error case)\n   - Import statements and mock setup for external dependencies\n\nDo NOT write full implementations — skeleton only. Ask user to confirm before creating the file."
  }
}
EOF
success "hooks/test-scaffold-on-create.kiro.hook"

# ── 4c. Update docs khi file source thay đổi ─────────────────────────────────
cat > "$KIRO_DIR/hooks/doc-sync-on-save.kiro.hook" << 'EOF'
{
  "name": "Doc sync check",
  "description": "Check if API documentation needs updating when route or controller files change",
  "version": "1",
  "when": {
    "type": "fileEdited",
    "patterns": [
      "src/**/routes/**",
      "src/**/controllers/**",
      "src/**/api/**",
      "src/**/handlers/**",
      "src/**/*Controller*",
      "src/**/*Router*",
      "src/**/*Service*"
    ]
  },
  "then": {
    "type": "askAgent",
    "prompt": "A route/controller/service file was saved. Quickly check:\n1. Were any public API signatures changed (parameters, return types, endpoint paths)?\n2. Were any new endpoints added or existing ones removed?\n3. Does the OpenAPI/Swagger spec (if present) need updating?\n\nIf yes: list what changed and suggest specific doc updates.\nIf no API changes: respond 'Doc check: no API changes detected'.\nDo NOT modify any files automatically."
  }
}
EOF
success "hooks/doc-sync-on-save.kiro.hook"

# ── 4d. Code review — Manual Trigger ─────────────────────────────────────────
cat > "$KIRO_DIR/hooks/code-review-manual.kiro.hook" << 'EOF'
{
  "name": "Code review",
  "description": "Structured code review of the current file against project steering standards. Run manually from Kiro panel.",
  "version": "1",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Perform a thorough code review of the currently open file against .kiro/steering/ standards:\n\n**Correctness**\n- Logic matches spec in .kiro/specs/ (if exists)\n- Edge cases handled (null, empty, boundary)\n- Error handling is meaningful\n\n**Code Quality** (steering/coding-standards.md)\n- Naming conventions followed\n- No obvious code duplication\n- Functions under 50 lines\n\n**Security** (steering/api-standards.md)\n- Input validated, authorization checked\n- No sensitive data exposed\n\n**Testing** (steering/testing-standards.md)\n- Tests exist for new logic\n- Tests cover happy path and error cases\n\n### ✅ Looks good\n### 🔴 Must fix (blocking)\n- [Line N] Issue → Fix suggestion\n### 🟡 Suggestions (non-blocking)\n### ❓ Questions\n**Verdict:** Approved / Request Changes"
  }
}
EOF
success "hooks/code-review-manual.kiro.hook"

# ── 4e. Pre Task Execution — chuẩn bị trước khi chạy spec task ───────────────
cat > "$KIRO_DIR/hooks/pre-task-checklist.kiro.hook" << 'EOF'
{
  "name": "Pre-task checklist",
  "description": "Clarify context and ambiguities before any spec task begins execution",
  "version": "1",
  "when": {
    "type": "preTaskExecution"
  },
  "then": {
    "type": "askAgent",
    "prompt": "A spec task is about to begin. Before proceeding:\n1. Read .kiro/steering/product.md and tech.md for project context\n2. Read the spec requirements.md and design.md for this task\n3. Check .kiro/memory/context.json for recent changes that might affect this task\n4. Identify ambiguities:\n   - Are acceptance criteria clear and complete?\n   - Are file paths and names specified?\n   - Are there dependencies on other incomplete tasks?\n\nIf ambiguities exist: list them and ask user to clarify BEFORE starting.\nIf everything is clear: summarize in 3-5 bullet points what you will do, then proceed."
  }
}
EOF
success "hooks/pre-task-checklist.kiro.hook"

# ── 4f. Post Task Execution — tổng kết sau khi xong spec task ────────────────
cat > "$KIRO_DIR/hooks/post-task-summary.kiro.hook" << 'EOF'
{
  "name": "Post-task summary",
  "description": "Summarize completed work and update shared context after spec task finishes",
  "version": "1",
  "when": {
    "type": "postTaskExecution"
  },
  "then": {
    "type": "askAgent",
    "prompt": "A spec task just completed. Do the following:\n1. List all files that were created or modified\n2. Summarize what was implemented in 3-5 bullet points\n3. Note any deviations from the spec design.md\n4. Update .kiro/memory/context.json:\n   - lastTask: description and status\n   - lastModifiedFiles: list of changed files\n   - openIssues: anything incomplete or needing follow-up\n5. Check if steering/coding-standards.md or api-standards.md need updating\n\nEnd with: 'What would you like to work on next?'"
  }
}
EOF
success "hooks/post-task-summary.kiro.hook"

# ── README cho hooks/ ─────────────────────────────────────────────────────────
cat > "$KIRO_DIR/hooks/README.md" << 'EOF'
# .kiro/hooks/ — Agent Hooks

## ⚠️ Quan trọng: Kiro IDE chỉ nhận file JSON, KHÔNG nhận file .md

Hooks phải là file `.json` theo format:
```json
{
  "name": "Tên hook",
  "description": "Mô tả",
  "eventType": "fileSaved",
  "filePatterns": ["src/**/*.ts"],
  "hookAction": "askAgent",
  "outputPrompt": "Prompt gửi cho agent khi trigger..."
}
```

## Event types hợp lệ

| eventType | Khi nào trigger |
|-----------|----------------|
| `fileSaved` | Sau khi lưu file khớp filePatterns |
| `fileCreated` | Khi tạo file mới khớp filePatterns |
| `fileDeleted` | Khi xóa file khớp filePatterns |
| `manual` | Bấm nút ▷ trong Kiro panel |
| `preTaskExecution` | Trước khi spec task bắt đầu |
| `postTaskExecution` | Sau khi spec task hoàn thành |
| `promptSubmit` | Khi user gửi prompt |
| `agentStop` | Khi agent kết thúc turn |
| `preToolUse` | Trước khi agent dùng tool |
| `postToolUse` | Sau khi agent dùng tool |

## hookAction hợp lệ

| hookAction | Mô tả |
|-----------|-------|
| `askAgent` | Gửi outputPrompt cho agent xử lý |
| `runCommand` | Chạy shell command (dùng field "command" thay vì "outputPrompt") |

## Cách load vào Kiro IDE

**Cách 1 — Tự động (nếu Kiro nhận):**
Kiro IDE đọc tất cả `.json` trong `.kiro/hooks/` khi mở project.

**Cách 2 — Thủ công qua UI:**
Kiro panel → Agent Hooks → nút `+` → Manually create a hook

**Cách 3 — Dùng AI:**
Kiro panel → Agent Hooks → nút `+` → Ask Kiro to create a hook
→ Mô tả hook bằng tiếng tự nhiên

## Các hooks đã tạo sẵn

| File | Trigger | Mục đích |
|------|---------|---------|
| `security-scan-on-save.json` | fileSaved (src/**) | Quét secret/vulnerability |
| `test-scaffold-on-create.json` | fileCreated (src/**) | Tạo test skeleton tự động |
| `doc-sync-on-save.json` | fileSaved (routes/controllers) | Kiểm tra docs cần cập nhật |
| `code-review-manual.json` | manual | Review code theo chuẩn steering |
| `pre-task-checklist.json` | preTaskExecution | Làm rõ ngữ cảnh trước task |
| `post-task-summary.json` | postTaskExecution | Tổng kết + cập nhật context |
EOF
success "hooks/README.md"

# =============================================================================
# ██████  MEMORY — Shared context & decisions
# =============================================================================
header "5. Tạo Memory files"

cat > "$KIRO_DIR/memory/context.json" << 'EOF'
{
  "_note": "Tự động cập nhật sau mỗi task — KHÔNG sửa thủ công thường xuyên",
  "lastUpdated": "",
  "lastTask": {
    "description": "",
    "status": "",
    "planFile": ""
  },
  "currentFocus": "",
  "lastModifiedFiles": [],
  "openIssues": [],
  "activeSpec": "",
  "environment": "dev",
  "notes": ""
}
EOF

cat > "$KIRO_DIR/memory/decisions.md" << 'EOF'
# Architecture Decision Log (ADL)

Ghi lại các quyết định kỹ thuật quan trọng.
Agent đọc file này để không hỏi lại những gì đã thống nhất.

## Template

```markdown
### [YYYY-MM-DD] Tiêu đề quyết định
**Trạng thái:** Accepted / Deprecated / Superseded by [ADL-XXX]
**Vấn đề:** Mô tả vấn đề cần quyết định
**Quyết định:** Chúng ta sẽ làm gì
**Lý do:** Tại sao chọn hướng này
**Hệ quả:** Ảnh hưởng / trade-off
```

---

<!-- Thêm quyết định mới bên dưới, mới nhất ở trên -->
EOF
success "memory/ (context.json, decisions.md)"

# =============================================================================
# ██████  MCP CONFIG — Đúng đường dẫn: .kiro/settings/mcp.json
# KHÔNG phải .kiro/mcp/mcp.json — Kiro IDE đọc từ .kiro/settings/
# Sau khi tạo file: Settings (Cmd+,) → search "MCP" → bật MCP support
# =============================================================================
header "5b. Tạo MCP config (đúng đường dẫn Kiro IDE)"

cat > "$KIRO_DIR/settings/mcp.json" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."],
      "env": {}
    }
  }
}
EOF

cat > "$KIRO_DIR/settings/README.md" << 'EOF'
# .kiro/settings/ — Kiro IDE Settings

## ⚠️ File MCP config phải đặt tại đây, KHÔNG phải .kiro/mcp/

### mcp.json — MCP Server configuration

Format chuẩn:
```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "npx",
      "args": ["-y", "<package-name>"],
      "env": {
        "API_KEY": "${ENV_VAR_NAME}"
      }
    }
  }
}
```

### Cách bật MCP trong Kiro IDE

1. Tạo / chỉnh sửa `.kiro/settings/mcp.json`
2. Mở Settings: `Cmd+,` (Mac) hoặc `Ctrl+,` (Windows/Linux)
3. Tìm kiếm "MCP"
4. Bật toggle **MCP support**
5. Kiểm tra: Kiro panel → tab **MCP Servers**

### MCP servers phổ biến

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    },
    "gitlab": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gitlab"],
      "env": {
        "GITLAB_PERSONAL_ACCESS_TOKEN": "${GITLAB_TOKEN}",
        "GITLAB_API_URL": "https://gitlab.com"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

### Remote MCP (HTTP) — Kiro v0.5+

```json
{
  "mcpServers": {
    "stripe": {
      "url": "https://mcp.stripe.com",
      "headers": {
        "Authorization": "Bearer ${STRIPE_API_KEY}"
      }
    }
  }
}
```

### Troubleshoot

Nếu MCP không load:
- Kiểm tra file đúng path: `.kiro/settings/mcp.json` (không phải `.kiro/mcp/`)
- Bật MCP support trong Settings
- Xem log: Help → Toggle Developer Tools → Console
- Kiro panel → MCP Servers tab → kiểm tra status
EOF
success "settings/mcp.json + settings/README.md"

# =============================================================================
# ██████  PLANS — Thư mục lưu kế hoạch task
# =============================================================================
cat > "$KIRO_DIR/plans/.gitkeep" << 'EOF'
# Thư mục này chứa các file kế hoạch được tạo tự động bởi Kiro Agent.
# File plan: YYYY-MM-DD_<slug-task>.md
# Tạo bởi /start-task hoặc khi agent bắt đầu bất kỳ task nào.
EOF
success "plans/ (sẵn sàng nhận file kế hoạch)"

# =============================================================================
# ██████  SLASH COMMANDS — Cơ chế thật của Kiro IDE
#
# Kiro IDE KHÔNG có thư mục commands/ — không đọc file .md trong commands/
# Slash commands thật = 2 loại:
#   1. Hook type "manual"  → xuất hiện trong menu / khi gõ trong chat
#   2. Steering file inclusion:manual → xuất hiện trong menu / khi gõ
#
# Hook manual đã có sẵn: code-review-manual.kiro.hook
# Phần này tạo steering files inclusion:manual cho các workflow lớn
# =============================================================================
header "6. Tạo Slash Commands (steering inclusion:manual)"

# ── /init-project — steering manual ──────────────────────────────────────────
cat > "$KIRO_DIR/steering/init-project.md" << 'EOF'
---
inclusion: manual
---

# /init-project — Cấu hình dự án

Khi được gọi, hãy thu thập thông tin dự án theo 6 nhóm sau, hỏi từng nhóm và chờ trả lời trước khi sang nhóm tiếp theo.

## Nhóm A — Định danh
- Tên dự án?
- Mô tả mục đích (1–2 câu)?
- Loại hình: internal tool / customer-facing / API / mobile / data pipeline?

## Nhóm B — Stack & Framework
- Ngôn ngữ backend + phiên bản? (Java 17 / Node 20+TS / Python 3.12 / Go / C# .NET)
- Framework backend + phiên bản? (Spring Boot / Express / FastAPI / Gin / ASP.NET)
- Frontend? (React / Vue / Angular / Next.js / Không có)
- Mobile? (React Native / Flutter / Không có)
- Package manager? (npm / maven / gradle / pip / go mod)

## Nhóm C — Data & Infrastructure
- Database chính + phiên bản? (PostgreSQL / MySQL / Oracle / MongoDB…)
- Cache? (Redis / Không)
- Message Queue? (Kafka / RabbitMQ / AWS SQS / Không)
- Cloud platform? (AWS / GCP / Azure / On-premise / Hybrid)
- Container? (Docker / Kubernetes / Docker Compose / Không)
- CI/CD? (GitHub Actions / GitLab CI / Jenkins / Azure DevOps / Không)

## Nhóm D — Integrations
- Authentication? (JWT / OAuth2 / Keycloak / Azure AD / LDAP)
- API protocol? (REST / GraphQL / gRPC / SOAP)
- External services? (liệt kê tên hệ thống bên ngoài)
- Compliance? (PCI-DSS / SBV / HIPAA / ISO 27001 / Không)

## Nhóm E — Team & Process
- Số lượng developer?
- Git workflow? (Git Flow / GitHub Flow / Trunk-based)
- Test framework? (Jest / JUnit / pytest / Go test / Không có)
- Môi trường hiện tại? (dev / staging / prod)

## Nhóm F — Ràng buộc
- File/folder KHÔNG được tự ý sửa? (liệt kê path)
- Thuật ngữ nghiệp vụ đặc thù? (tên module, viết tắt nội bộ)
- Ngôn ngữ giao tiếp? (Tiếng Việt / English / Song ngữ)

## Sau khi thu thập đủ

Hiển thị bảng tóm tắt → chờ xác nhận → cập nhật tuần tự:
1. `steering/product.md` — tên, mô tả, glossary, compliance, ngôn ngữ
2. `steering/tech.md` — toàn bộ stack
3. `steering/structure.md` — doNotTouch list
4. `steering/coding-standards.md` — stack-specific rules
5. `memory/context.json` — environment, notes
6. `settings/mcp.json` — gợi ý MCP server phù hợp stack
EOF
success "steering/init-project.md (inclusion:manual → /init-project)"

# ── /start-task — steering manual ────────────────────────────────────────────
cat > "$KIRO_DIR/steering/start-task.md" << 'EOF'
---
inclusion: manual
---

# /start-task — Bắt đầu task mới

Khi được gọi, thực hiện theo quy trình sau:

## Bước 1 — Đọc context
1. Đọc `steering/product.md` và `steering/tech.md`
2. Đọc `memory/context.json` — xem task gần nhất và trạng thái
3. Nếu có `--spec <name>` → đọc `specs/<name>/requirements.md` và `design.md`

## Bước 2 — Làm rõ (PHẢI làm trước khi tiến hành)

Hỏi người dùng những gì còn thiếu:
- Phạm vi: file/module nào bị ảnh hưởng?
- Output mong đợi trông như thế nào?
- Có acceptance criteria cụ thể không?
- Có file nào KHÔNG được chỉnh sửa?
- Ràng buộc về thời gian / performance?

Nếu đã đủ thông tin → tóm tắt và hỏi xác nhận.

## Bước 3 — Tạo file kế hoạch

Tạo `.kiro/plans/YYYY-MM-DD_<slug>.md` với nội dung:

```
# Kế hoạch: <Tên task>
**Ngày:** | **Spec:** | **Ước tính:**

## Mục tiêu
## Các bước
- [ ] Bước 1
- [ ] Bước 2
## File sẽ thay đổi
| File | Loại | Ghi chú |
## Rủi ro
## Done criteria
## Rollback
```

Trình bày plan → chờ approve ("ok" / "bắt đầu" / "proceed").

## Bước 4 — Thực thi

Thực hiện từng bước, đánh dấu [x] khi xong.

## Bước 5 — Wrap-up

Cập nhật `memory/context.json`: lastTask, lastModifiedFiles, openIssues.
EOF
success "steering/start-task.md (inclusion:manual → /start-task)"

# ── /new-spec — steering manual ───────────────────────────────────────────────
cat > "$KIRO_DIR/steering/new-spec.md" << 'EOF'
---
inclusion: manual
---

# /new-spec — Tạo spec feature mới

Khi được gọi với `/new-spec <feature-name>`:

## Quy trình

1. Hỏi: "Mô tả ngắn về feature này (1–2 câu)?"
2. Hỏi: "User story chính là gì? (As a... I want... So that...)"
3. Hỏi: "Acceptance criteria cơ bản?"
4. Tạo thư mục `specs/<feature-name>/`
5. Copy và điền nội dung từ `specs/.template/`:
   - `requirements.md` — điền thông tin vừa thu thập
   - `design.md` — để skeleton, điền sau
   - `tasks.md` — để skeleton, điền sau
6. Trình bày `requirements.md` cho user review

## Sau khi tạo

Gợi ý bước tiếp theo:
1. Hoàn thiện `requirements.md` (user stories đầy đủ, FR/NFR)
2. Viết `design.md` (API contract, data model)
3. Implement: `/start-task --spec <feature-name> <mô tả>`
EOF
success "steering/new-spec.md (inclusion:manual → /new-spec)"

# ── /update-agent — hook manual ───────────────────────────────────────────────
cat > "$KIRO_DIR/hooks/update-agent-manual.kiro.hook" << 'EOF'
{
  "name": "Update agent config",
  "description": "Cập nhật nhanh một phần cấu hình steering khi dự án thay đổi. Chạy thủ công từ Kiro panel hoặc gõ / trong chat.",
  "version": "1",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "User wants to update agent configuration. Ask them:\n1. What changed? (stack / infra / security / glossary / donottouch / api / testing)\n2. Describe the change in detail\n\nThen:\n- Read the relevant steering file(s)\n- Show a summary of what will change\n- Wait for confirmation\n- Update the file(s)\n- Update memory/context.json with timestamp and changed files\n\nTarget files by change type:\n- stack → steering/tech.md + steering/coding-standards.md\n- infra → steering/tech.md + settings/mcp.json\n- security → steering/product.md + steering/coding-standards.md\n- glossary → steering/product.md (Glossary section)\n- donottouch → steering/structure.md\n- api → steering/api-standards.md\n- testing → steering/testing-standards.md"
  }
}
EOF
success "hooks/update-agent-manual.kiro.hook (manual → /update-agent)"

# ── /show-context — hook manual ───────────────────────────────────────────────
cat > "$KIRO_DIR/hooks/show-context-manual.kiro.hook" << 'EOF'
{
  "name": "Show project context",
  "description": "Hiển thị tóm tắt ngữ cảnh dự án hiện tại. Gõ / trong chat để chạy.",
  "version": "1",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Read and summarize the current project context from:\n1. .kiro/steering/product.md — project name, type, compliance\n2. .kiro/steering/tech.md — full tech stack\n3. .kiro/memory/context.json — last task, modified files, open issues\n\nFormat output as:\n\n📋 PROJECT CONTEXT\n├── 🏷️  Project  : <name>\n├── 🔧 Backend   : <language + framework>\n├── 🖥️  Frontend  : <framework or N/A>\n├── 🗄️  Database  : <db>\n├── ☁️  Platform  : <cloud>\n├── 🔐 Auth      : <auth mechanism>\n├── 📋 Compliance: <requirements>\n│\n├── 📌 Last task : <description + status>\n├── 📁 Modified  : <files>\n├── ⚠️  Open issues: <list>\n└── 🎯 Focus     : <currentFocus>\n\nThen ask: 'What would you like to work on?'"
  }
}
EOF
success "hooks/show-context-manual.kiro.hook (manual → /show-context)"

# =============================================================================
# ██████  README — Phản ánh đúng cấu trúc thật
# =============================================================================
header "7. Tạo README.md"

cat > "$KIRO_DIR/README.md" << 'EOF'
# .kiro — Kiro Agent Configuration

Cấu hình chuẩn cho Kiro Agent: **Steering + Specs + Hooks**.

## Cấu trúc thực tế (Kiro IDE đọc được)

```
.kiro/
│
├── steering/                        ← Luôn được đọc (inclusion:always)
│   ├── product.md                   ← Tên, mô tả, glossary, compliance
│   ├── tech.md                      ← Toàn bộ tech stack
│   ├── structure.md                 ← Cấu trúc folder, doNotTouch list
│   ├── coding-standards.md          ← Chuẩn code + stack-specific
│   ├── api-standards.md             ← URL design, response format
│   ├── testing-standards.md         ← Test pyramid, coverage, naming
│   │
│   ├── init-project.md   [manual]   ← /init-project slash command
│   ├── start-task.md     [manual]   ← /start-task slash command
│   └── new-spec.md       [manual]   ← /new-spec slash command
│
├── specs/                           ← Đặc tả từng feature
│   ├── .template/
│   │   ├── requirements.md
│   │   ├── design.md
│   │   └── tasks.md
│   ├── user-authentication/         ← Ví dụ
│   └── payment-service/             ← Ví dụ
│
├── hooks/                           ← Extension: .kiro.hook (KHÔNG phải .json)
│   ├── security-scan-on-save.kiro.hook     ← fileSaved
│   ├── test-scaffold-on-create.kiro.hook   ← fileCreated
│   ├── doc-sync-on-save.kiro.hook          ← fileSaved
│   ├── code-review-manual.kiro.hook        ← manual → /code-review
│   ├── update-agent-manual.kiro.hook       ← manual → /update-agent
│   ├── show-context-manual.kiro.hook       ← manual → /show-context
│   ├── pre-task-checklist.kiro.hook        ← preTaskExecution
│   └── post-task-summary.kiro.hook         ← postTaskExecution
│
├── settings/
│   └── mcp.json                     ← MCP servers (bật trong Settings→MCP)
│
├── memory/
│   ├── context.json                 ← Trạng thái hiện tại (tự động cập nhật)
│   └── decisions.md                 ← Architecture Decision Log
│
└── plans/                           ← File kế hoạch (YYYY-MM-DD_task.md)
```

## Slash Commands (gõ / trong chat)

| Command | Loại | Tác dụng |
|---------|------|---------|
| `/init-project` | steering manual | Hỏi 6 nhóm thông tin, cập nhật steering/ |
| `/start-task` | steering manual | Làm rõ → tạo plan → thực thi |
| `/new-spec` | steering manual | Tạo spec feature mới từ template |
| `/code-review` | hook manual | Review file hiện tại theo steering/ |
| `/update-agent` | hook manual | Cập nhật nhanh một phần cấu hình |
| `/show-context` | hook manual | Tóm tắt ngữ cảnh dự án hiện tại |

## Thứ tự sử dụng

```
1. ./setup-kiro-agent.sh   ← Tạo cấu trúc này
2. /init-project            ← Điền thông tin dự án (quan trọng nhất)
3. /new-spec <feature>      ← Tạo spec cho feature đầu tiên
4. /start-task              ← Bắt đầu làm việc hàng ngày
5. /code-review             ← Review code bất cứ lúc nào
6. /update-agent            ← Khi stack/team thay đổi
```

## Nguyên tắc cốt lõi

1. **Hỏi trước, làm sau** — Luôn làm rõ ngữ cảnh trước khi thực thi
2. **Plan trước khi code** — Tạo `.kiro/plans/` và chờ approve
3. **Spec-driven** — Task liên kết với `specs/<feature>/` khi có thể
4. **Cập nhật context** — Sau mỗi task ghi vào `memory/context.json`
EOF
success "README.md"


# =============================================================================
# TỔNG KẾT
# =============================================================================
header "✅ Hoàn thành!"
echo ""
echo -e "${BOLD}Cấu trúc đã tạo ($(find "$KIRO_DIR" -type f | wc -l | tr -d ' ') files):${RESET}"
find "$KIRO_DIR" -type f | sort | sed "s|$PROJECT_DIR/||" | \
  awk '{
    if ($0 ~ /steering\//) color="\033[0;33m"
    else if ($0 ~ /specs\//) color="\033[0;35m"
    else if ($0 ~ /hooks\//) color="\033[0;32m"
    else color="\033[0;37m"
    printf "  %s%s\033[0m\n", color, $0
  }'

echo ""
echo -e "${BOLD}Màu sắc:${RESET}"
echo -e "  ${YELLOW}■${RESET} steering/ (always+manual)   ${BOLD}■${RESET} specs/   ${GREEN}■${RESET} hooks/ (.kiro.hook)"
echo ""
echo -e "${BOLD}Bước tiếp theo — quan trọng:${RESET}"
echo -e "  ${BOLD}${CYAN}Mở dự án trong Kiro và chạy ngay:${RESET}"
echo -e "  ${GREEN}  /init-project${RESET}  ← Điền thông tin công nghệ & nền tảng"
echo ""
echo -e "${GREEN}${BOLD}Setup hoàn tất! 🚀${RESET}"
