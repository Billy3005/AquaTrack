# CLAUDE.md — AquaTrack

## Project
```
App     : AquaTrack — hydration app that feels alive
Tagline : Chụp ảnh ly nước → AI đếm ml → Sống khoẻ hơn mỗi ngày
Stage   : Sắp nộp Google Play (app v1.0.0+1) · backend đã live trên Railway
Stack   : Flutter (Riverpod) · FastAPI (Python 3.11) · Postgres (prod) / SQLite (dev)
          Claude API — Vision cho Smart Scan, chat cho AI Coach
Solo    : 1 dev + researcher (sinh viên)
Repo    : monorepo → aquatrack_app/ · aquatrack_backend/ · aquatrack_admin/ · aquatrack_ml/
```

## Trạng thái thật (cập nhật 06/08/2026)
```
✅ CHẠY THẬT trên production:
- Backend Railway (gói trả phí) · 110 route · rate limiting ĐANG BẬT · /docs tắt
- Auth: email/mật khẩu + Google Sign-In + JWT + đặt lại mật khẩu bằng mã 6 số
- Smart Scan · AI Coach · Stats · Levels/Achievements · Friends · Quests · Shop
- Admin console 4 màn hình thật (chỉ chạy local)
- 183 test backend pass · 14 file test Flutter

⚠️ BIẾT MÀ CHƯA SỬA ĐƯỢC:
- Email KHÔNG gửi được. Brevo cần domain đã xác thực DKIM (Gmail/Yahoo bắt buộc
  từ 02/2024) mà dự án chưa mua domain. Railway chặn SMTP trên gói Hobby nên
  không thay bằng Gmail SMTP được.
  → Lưới an toàn: admin console có nút "Cấp mã đặt lại mật khẩu" (đọc mã qua
    kênh hỗ trợ). Mua domain xong email tự chạy, KHÔNG phải sửa code.
- aquatrack_ml/models/ còn rỗng. Smart Scan chạy 100% server-side bằng Claude
  Vision (settings.VISION_MODEL = claude-haiku-4-5), CHƯA có TFLite on-device.
- Backend URL bị bake cứng vào release build (app_config.dart). Đổi host là
  phải build lại + nộp lại chợ → nên mua domain trỏ api.<domain> về Railway.
```

## Backend — bản đồ route
```
auth          register · login · google · me · refresh · forgot/reset-password
users         profile · preferences · stats · account (xoá/kích hoạt lại)
intake        ghi nước · today · recent · summary · sửa/xoá
vision        estimate-volume (Claude Vision) · scan-history + thống kê độ chính xác
coach         chat · context · suggestions · quick-reply
stats         dashboard · insights · trends daily|hourly · streaks · goals
levels        current · achievements · leaderboard · unlocked-avatars · rewards
friends       27 route: kết bạn · leaderboard tuần · thách đấu · quà · referral
quests · shop · water-profile · admin (11 route, staff-only)

Không có Alembic. Migration nhẹ bằng _ensure_user_columns() / _ensure_indexes()
trong app/core/database.py — create_all() KHÔNG sửa bảng đã tồn tại.

AI Coach có thang dự phòng 4 tầng (ai_coach_service.py):
Anthropic Claude > OpenAI > Ollama qwen2.5:3b (local) > rule-based.
→ Production có ANTHROPIC_API_KEY nên dùng Claude. Máy dev không có key sẽ rơi
  xuống Ollama hoặc rule-based — câu trả lời khác hẳn production, đừng tưởng bug.
```

## Design System
```
Theme       : Dark navy (#0D1B2A background) · Cyan accent (#00B4D8) · Purple XP (#7B5EA7)
Typography  : Inter / SF Pro — Bold heading, Regular body
Drop widget : SVG water drop, fill level = hydration %, breathing animation
Language    : Tiếng Việt (UI) + English (code/comment)
Features    : 16 folder trong aquatrack_app/lib/features/ — auth · home · log_drink
              smart_scan · coach · stats · level · friends · missions · shop
              avatars · body_map · profile · reminders · onboarding · splash
```

## Admin Console (aquatrack_admin/)
```
Stack   : Vite + React 18 + TypeScript · không dùng thư viện UI/chart nào
Chạy    : cd aquatrack_admin && npm run dev  → :5173 (proxy /api → :8000)
Seed    : cd aquatrack_backend && python scripts/seed_admin_demo.py   (chỉ dev)
Login   : hung.le@aquatrack.vn / Admin@12345 (super_admin) + 3 vai trò khác
Prod    : dùng scripts/promote_admin.py --list | <email> --role super_admin

⚠️ KHÔNG deploy console. Chủ dự án tự chạy local — đừng đề xuất Vercel/Netlify
   trừ khi được yêu cầu.

✅ THẬT   : Tổng quan · Người dùng · Chi tiết người dùng · Nhật ký thao tác
⏳ SẮP CÓ : Gamification · Thử thách & nội dung · Báo cáo · Thông báo đẩy · Phân quyền
            (mỗi trang liệt kê rõ việc cần làm trước — KHÔNG dùng mock data)

Phân quyền: app/core/admin_roles.py là nguồn duy nhất. Server chặn bằng
require_cap(), console nhận map qua /admin/me để disable nút. Sửa 1 chỗ.
Kiểm toán : mọi thao tác nhạy cảm ghi vào audit_logs, commit cùng transaction.
            Mã đặt lại mật khẩu CỐ Ý không ghi vào log (mọi role đều audit.view).
Chi tiết  : aquatrack_admin/README.md
```

## Script vận hành (aquatrack_backend/scripts/)
```
promote_admin.py        nâng/hạ quyền staff trên production · không tạo tài khoản
backup_db.py            dump JSON toàn bộ bảng + rà soát tài khoản test trước launch
cleanup_test_accounts.py xoá tài khoản máy sinh & chưa từng ghi nước · dry-run mặc định
seed_admin_demo.py      dữ liệu mẫu cho console · TỪ CHỐI chạy ngoài development
```

## Agents
| Làm việc về | Agent |
|---|---|
| Flutter UI / animation / widget | `.claude/agents/flutter.md` |
| ML model / TFLite / Smart Scan | `.claude/agents/ml.md` |
| FastAPI / DB / AI Coach API | `.claude/agents/backend.md` |
| README / report / commit | `.claude/agents/docs.md` |

## Skills
| Skill | File | Khi nào dùng |
|---|---|---|
| **TDD** | `.claude/skills/engineering/tdd.md` | Trước khi code feature mới · unit/widget testing |
| **Grill-Me** | `.claude/skills/productivity/grill-me.md` | Trước implementation lớn · design review |
| **Diagnose** | `.claude/skills/engineering/diagnose.md` | Debug phức tạp · performance |
| **Improve Architecture** | `.claude/skills/engineering/improve-aquatrack-architecture.md` | Review sau feature · coupling analysis |
| **FastAPI endpoint** | `.claude/skills/backend/fastapi_endpoint.md` | Thêm route mới |
| **Riverpod provider** | `.claude/skills/flutter/riverpod_provider.md` | Thêm state mới |
| **TFLite convert** | `.claude/skills/ml/tflite_convert.md` | Khi bắt đầu làm on-device |

## Rules — luôn áp dụng
```
NGÔN NGỮ  : Trả lời tiếng Việt
OUTPUT    : Code chạy được ngay · ít giải thích · không scaffold thừa
COMMENT   : Tiếng Anh trong code · tiếng Việt nếu cần giải thích dài
DESIGN    : Luôn dùng AppColors/AppTextStyles · không hardcode màu
KHI MƠ HỒ: Hỏi 1 câu ngắn trước · không tự đoán
REVIEW    : Đưa Codex review feature lớn trước khi commit
BẢO MẬT   : /aquatrack/ (bản thiết kế) và aquatrack_backend/backups/ (chứa
            email + hash mật khẩu) PHẢI giữ untracked
```

## Conventions
```
Git branch : feature/<ten-tieng-anh>   (master là nhánh chính)
Git commit : feat|fix|refactor|docs|chore: <mô tả ngắn>
Flutter    : Riverpod · feature-based folder · snake_case file · PascalCase class
Python     : black + isort (setup.cfg đặt profile=black để 2 tool không đánh nhau)
             type hints · .env cho secrets
Test       : pytest -q trong aquatrack_backend · emulator + thiết bị thật cho app
Quyết định : ghi thành ADR trong docs/adr/ (đang có 11 bản)
```

## Việc còn lại trước khi nộp chợ
```
[ ] Deploy lại Railway (nút cấp mã đặt lại mật khẩu chưa có trên production)
[ ] Mua domain (~250-350k/năm) → DKIM cho Brevo + api.<domain> trỏ về Railway
[ ] Điền email hỗ trợ trên trang Google Play (màn hình Quên mật khẩu có nhắc tới)
```

## Reference
```
📐 ADR         : docs/adr/  — 11 quyết định kiến trúc, đọc trước khi sửa vùng liên quan
📖 Backend     : aquatrack_backend/README.md
📖 Admin       : aquatrack_admin/README.md
🗂️ Memory      : ~/.claude/projects/.../memory/MEMORY.md
```

## Checklist — paste đầu mỗi chat
```
- Đang làm: ___
- Block ở: ___
- Code liên quan: [paste nếu có]
```
