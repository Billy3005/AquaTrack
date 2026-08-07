# Wafubi Admin Console

Bảng điều khiển nội bộ cho nhân sự Wafubi: theo dõi số liệu hydration, quản lý
người dùng, và nhật ký thao tác. Vite + React + TypeScript, không phụ thuộc thư
viện UI hay charting nào ngoài React.

Giao diện được port 1:1 từ bản thiết kế trong `aquatrack/project/admin/`.

---

## Chạy local

Console chọn backend qua `VITE_API_TARGET`, đặt trong `aquatrack_admin/.env.local`
(file này đã gitignored). Mặc định khi không có file: `http://localhost:8000`.

### Cách 1 — dùng backend production trên Railway (không cần chạy backend)

```bash
cd aquatrack_admin
npm install
echo "VITE_API_TARGET=https://aquatrack-production-62b3.up.railway.app" > .env.local
npm run dev          # http://localhost:5173
```

### Cách 2 — dùng backend local

```bash
# terminal 1 — backend (phải là port 8000; chạy `python app/main.py` sẽ ra 8001)
cd aquatrack_backend
python -m uvicorn app.main:app --reload --port 8000

# terminal 2 — console (không cần .env.local, mặc định đã trỏ localhost:8000)
cd aquatrack_admin
npm run dev
```

> ⚠️ **Đừng đặt biến ngay trên dòng lệnh.** `VITE_API_TARGET=... npm run dev` là
> cú pháp bash — trên PowerShell nó không set biến và cũng không báo lỗi, vite
> lặng lẽ rơi về `localhost:8000` rồi đổ một loạt `ECONNREFUSED` khó lần ra
> nguyên nhân. Dùng `.env.local` cho mọi shell.

Sửa `.env.local` xong phải **khởi động lại** vite thì mới có hiệu lực.

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

## Hai chế độ chạy

Console **luôn chạy trên máy bạn**. Thứ duy nhất thay đổi là nó đọc API nào —
không có gì được deploy, không có URL công khai nào tồn tại.

```bash
# Nghịch / demo — backend local + 200 user giả. Làm gì cũng không sao.
npm run dev

# Vận hành thật — dữ liệu người dùng thật trên Railway.
VITE_API_TARGET=https://<railway-url> npm run dev
```

Vite proxy gọi API từ Node chứ không phải từ trình duyệt, nên chế độ thứ hai
**không dính CORS** — không cần đụng `ALLOWED_ORIGINS`.

Ở chế độ thật, mọi thao tác là thật và không hoàn tác được. "Reset dữ liệu" xoá
thật lịch sử uống nước của một người thật; audit log ghi lại nhưng không phục
hồi được.

### Tạo tài khoản nhân sự trên production

`seed_admin_demo.py` từ chối chạy ngoài môi trường dev, nên production cần một
script riêng. Nó **không tạo tài khoản mới** — chỉ nâng/hạ quyền một tài khoản
đã đăng ký qua ứng dụng:

```bash
cd aquatrack_backend
# PowerShell — trỏ vào database production trước
$env:DATABASE_URL="postgresql://..."

python scripts/promote_admin.py --list                    # ai đang là nhân sự
python scripts/promote_admin.py ban@example.com           # nâng lên super_admin
python scripts/promote_admin.py ai_do@example.com --role user   # thu hồi quyền
```

Script in ra database đang nhắm tới, bắt gõ `YES` để xác nhận, ghi vào
`audit_logs`, và từ chối hạ quyền super admin đang hoạt động cuối cùng. Đăng
nhập console bằng chính mật khẩu ứng dụng của tài khoản đó.

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
| Cấp mã đặt lại mật khẩu | ✅ | ✅ | ❌ | ✅ |

Bảng này khớp đúng với `PERMS` trong file thiết kế gốc, trừ dòng cuối — xem
mục dưới. Nó **không** phải thang bậc lồng nhau: Support được khoá tài khoản
(xử lý vi phạm tuyến đầu) trong khi Marketing thì không.

### Cấp mã đặt lại mật khẩu

`POST /auth/forgot-password` gửi mã 6 số qua email, nhưng email giao dịch cần
domain gửi đã xác thực (Gmail và Yahoo bắt buộc DKIM từ 02/2024, Brevo thay
luôn địa chỉ gửi nếu dùng domain miễn phí). Dự án chưa có domain, nên mã sinh
ra không tới tay ai và người quên mật khẩu **không có đường nào quay lại**.

Nút *Cấp mã đặt lại mật khẩu* trong Chi tiết người dùng là đường thủ công: sinh
đúng mã đó, hiện **một lần duy nhất** trên màn hình, nhân sự đọc cho người dùng
qua kênh hỗ trợ, người dùng tự nhập ở màn hình *Quên mật khẩu* trong app. Không
có luồng mật khẩu thứ hai — vẫn là mã dùng một lần, 10 phút, sai 5 lần thì huỷ.

Hai điều cố ý:

* **Mã không ghi vào `audit_logs`.** Mọi vai trò nhân sự đều có `audit.view`,
  nên lưu mã lại đồng nghĩa với việc ai cũng đọc được mã người khác vừa cấp và
  chiếm tài khoản. Nhật ký chỉ ghi *đã cấp mã*, ai cấp, vì lý do gì.
* **Chặn theo cấp bậc như khoá tài khoản.** Cấp mã là chiếm tài khoản chỉ trong
  một bước, nên Support không cấp mã được cho tài khoản Operations — nếu không,
  thay vì chỉ khoá được cấp trên, họ sẽ chiếm được cấp trên.

Khi mua domain và cấu hình DKIM cho Brevo, email tự chạy trở lại — **không cần
sửa code**, chỉ đặt `BREVO_API_KEY` và `FROM_EMAIL` thuộc domain đó. Nút này
vẫn hữu ích cho các ca hỗ trợ lẻ.

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
npm run preview    # xem thử bản build tại :4173 (cũng proxy /api như dev)
```

`dist/` là static thuần, deploy được lên Vercel/Netlify/Cloudflare Pages, hoặc
cho FastAPI serve cùng host. Khi deploy khác host với API, đặt
`VITE_API_BASE_URL=https://<api-host>` lúc build và thêm origin đó vào
`ALLOWED_ORIGINS` trong `aquatrack_backend/app/core/config.py`.

> Console hiện **chưa được deploy**. Nó chạy local để phát triển; muốn đưa lên
> production cần quyết định host và siết `ALLOWED_ORIGINS` (đang còn `"*"`).
