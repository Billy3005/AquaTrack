# AquaTrack Admin Console

Bảng điều khiển nội bộ cho nhân sự AquaTrack: theo dõi số liệu hydration, quản lý
người dùng, và nhật ký thao tác. Vite + React + TypeScript, không phụ thuộc thư
viện UI hay charting nào ngoài React.

Giao diện được port 1:1 từ bản thiết kế trong `aquatrack/project/admin/`.

---

## Chạy local

Cần backend chạy trước:

```bash
# terminal 1 — backend
cd aquatrack_backend
python -m uvicorn app.main:app --reload --port 8000

# terminal 2 — admin console
cd aquatrack_admin
npm install
npm run dev          # http://localhost:5173
```

Vite proxy `/api` sang `http://localhost:8000`. Nếu backend chạy cổng khác:

```bash
VITE_API_TARGET=http://localhost:8010 npm run dev
```

### Tạo tài khoản nhân sự + dữ liệu mẫu

Console cần ít nhất một tài khoản có `role` khác `user`, và cần dữ liệu để
biểu đồ có gì mà vẽ:

```bash
cd aquatrack_backend
python scripts/seed_admin_demo.py            # 4 tài khoản staff + 200 user mẫu
python scripts/seed_admin_demo.py --staff-only   # chỉ tạo 4 tài khoản staff
python scripts/seed_admin_demo.py --wipe     # xoá sạch dữ liệu mẫu đã tạo
```

Mật khẩu chung của 4 tài khoản staff: `Admin@12345`

| Email | Vai trò |
|---|---|
| `hung.le@aquatrack.vn` | Super admin |
| `vananh.tran@aquatrack.vn` | Operations |
| `maichi.ng@aquatrack.vn` | Marketing |
| `duy.phan@aquatrack.vn` | Support |

Script **chỉ chạy được ở môi trường dev** và không có cờ ghi đè: phải đồng thời
`ENVIRONMENT=development` và database là localhost. Nó tạo tài khoản đặc quyền
với mật khẩu ghi sẵn trong repo, nên không được phép chạm vào bất cứ thứ gì
thật. Đặt `SEED_ADMIN_PASSWORD` nếu muốn mật khẩu riêng.

Mọi lần đổi vai trò — kể cả do script — đều ghi vào `audit_logs`.

---

## Đăng nhập & phân quyền

Console dùng chung `POST /api/v1/auth/login` với ứng dụng di động — không có kho
mật khẩu riêng. Sau khi có token, `GET /api/v1/admin/me` mới quyết định tài
khoản đó có phải nhân sự hay không; user thường nhận 403 và bị đăng xuất ngay.

Ma trận phân quyền là **một nguồn duy nhất** ở
`aquatrack_backend/app/core/admin_roles.py`. Server dùng nó để chặn request,
console nhận nó qua `/admin/me` để làm mờ (chứ không ẩn) các nút không được
phép — người dùng vẫn thấy chức năng tồn tại và biết mình thiếu quyền.

| Quyền | Super admin | Operations | Marketing | Support |
|---|:--:|:--:|:--:|:--:|
| Xem dữ liệu & báo cáo | ✅ | ✅ | ✅ | ✅ |
| Xuất CSV | ✅ | ✅ | ✅ | ❌ |
| Khoá / mở khoá tài khoản | ✅ | ✅ | ❌ | ✅ |
| Tặng xu / XP thủ công | ✅ | ✅ | ❌ | ❌ |
| Reset dữ liệu người dùng | ✅ | ❌ | ❌ | ❌ |

Bảng này khớp đúng với `PERMS` trong file thiết kế gốc. Nó **không** phải thang
bậc lồng nhau: Support được khoá tài khoản (xử lý vi phạm tuyến đầu) trong khi
Marketing thì không.

---

## Các màn hình

| Màn hình | Trạng thái | Nguồn dữ liệu |
|---|---|---|
| **Tổng quan** | ✅ Thật | DAU, tỉ lệ đạt mục tiêu, phân bổ level, khung giờ uống nước, cohort retention — tính trực tiếp từ `intake_logs` + `users` |
| **Người dùng** | ✅ Thật | Tìm kiếm / lọc / phân trang phía server; khoá, mở khoá, reset, tặng xu-XP, xuất CSV |
| **Chi tiết người dùng** | ✅ Thật | 4 tab: tổng quan, lịch sử uống nước, gamification, nhật ký thao tác |
| **Nhật ký thao tác** | ✅ Thật | Bảng `audit_logs` — ai, làm gì, lên ai, lúc nào, từ IP nào, vì lý do gì |
| Gamification | ⏳ Sắp có | Cần đưa cấu hình level/XP từ code xuống DB |
| Thử thách & nội dung | ⏳ Sắp có | Cần mô hình dữ liệu mới |
| Báo cáo | ⏳ Sắp có | Chưa có bảng reports |
| Thông báo đẩy | ⏳ Sắp có | Chưa tích hợp FCM |
| Cài đặt & phân quyền | ⏳ Sắp có | Ma trận quyền còn là hằng số trong code |

Năm màn hình chưa làm **cố tình để trống** thay vì dùng dữ liệu giả, và mỗi
trang liệt kê chính xác những việc phải làm trước khi bật được. Một bảng điều
khiển hiển thị số liệu bịa còn nguy hiểm hơn một bảng điều khiển thiếu.

---

## Vài quyết định thiết kế đáng lưu ý

**Không có cache phía client.** Mỗi màn hình fetch lại khi tham số đổi hoặc sau
mỗi thao tác. Admin hành động dựa trên số liệu cũ là kịch bản tệ nhất cần tránh.

**Chỉ hiện delta khi tính được trung thực.** Thẻ "Streak trung bình" không có
dòng so sánh vì hệ thống chưa lưu snapshot streak theo ngày — trả về `null` chứ
không bịa ra 0%.

**Reset dữ liệu giữ lại xu và XP.** Đó là tài sản người dùng đã kiếm được, và
hộp thoại xác nhận chỉ hứa xoá *dữ liệu hydration*. Muốn đổi XP thì có thao tác
tặng thưởng riêng, có kiểm toán riêng.

**Khoá tài khoản = `users.is_active = false`**, đúng cờ mà `/auth/login` đã kiểm
tra sẵn — không thêm trạng thái song song để rồi lệch nhau.

**Không ai thao tác được lên nhân sự ngang hoặc cao cấp hơn mình.** Ngoại lệ duy
nhất: super admin khoá được nhau (để còn gỡ quyền người nghỉ việc), nhưng không
bao giờ khoá được super admin đang hoạt động cuối cùng.

**Mọi mốc ngày/giờ tính theo một múi giờ báo cáo tường minh** (`Asia/Ho_Chi_Minh`
trong `admin_service.REPORT_TZ`), không theo UTC và cũng không theo timezone của
phiên database. Nếu không, lượt uống lúc 6h sáng sẽ bị tính sang hôm trước và
biểu đồ giờ lệch đúng 7 tiếng.

---

## Build & deploy

```bash
npm run build      # -> dist/
npm run preview    # xem thử bản build tại :4173
```

`dist/` là static thuần, deploy được lên Vercel/Netlify/Cloudflare Pages, hoặc
cho FastAPI serve cùng host. Khi deploy khác host với API, đặt
`VITE_API_BASE_URL=https://<api-host>` lúc build và thêm origin đó vào
`ALLOWED_ORIGINS` trong `aquatrack_backend/app/core/config.py`.

> Console hiện **chưa được deploy**. Nó chạy local để phát triển; muốn đưa lên
> production cần quyết định host và siết `ALLOWED_ORIGINS` (đang còn `"*"`).
