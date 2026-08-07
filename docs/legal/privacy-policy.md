# Chính sách quyền riêng tư — AquaTrack

**Cập nhật lần cuối:** 07/08/2026
**Áp dụng cho:** ứng dụng AquaTrack trên Android (`com.aquatrack.app`)

AquaTrack là ứng dụng theo dõi lượng nước uống. Tài liệu này nói rõ ứng dụng
thu thập dữ liệu gì, dùng để làm gì, gửi cho ai, và bạn xoá chúng bằng cách nào.

Liên hệ: **giabao3052005@gmail.com**

---

## 1. Dữ liệu chúng tôi thu thập

### 1.1 Bạn cung cấp khi đăng ký

| Dữ liệu | Bắt buộc | Vì sao cần |
|---|---|---|
| Địa chỉ email | Có | Định danh tài khoản, đăng nhập, đặt lại mật khẩu |
| Mật khẩu | Có (nếu không dùng Google) | Xác thực. Lưu dưới dạng **băm argon2**, chúng tôi không đọc được mật khẩu của bạn |
| Tên hiển thị | Không | Hiển thị trong hồ sơ và bảng xếp hạng bạn bè |

Nếu bạn chọn **Đăng nhập với Google**, chúng tôi nhận từ Google địa chỉ email và
tên của bạn. Chúng tôi không nhận mật khẩu Google của bạn.

### 1.2 Dữ liệu sức khoẻ và cơ thể

Để tính lượng nước khuyến nghị mỗi ngày, ứng dụng hỏi: **giới tính, tuổi, chiều
cao, cân nặng, mức vận động, tính chất công việc, tình trạng sức khoẻ, mức ăn
rau, số cốc cà phê và số đơn vị rượu bia mỗi ngày**.

Đây là dữ liệu sức khoẻ. Nó chỉ dùng để tính công thức nước, không dùng cho mục
đích nào khác, và **không được bán hay chia sẻ cho bên quảng cáo nào**.

Bạn có thể bỏ qua bước này — khi đó ứng dụng dùng mục tiêu mặc định.

### 1.3 Dữ liệu sử dụng

- Mỗi lần ghi nước: thể tích, loại đồ uống, thời điểm
- Thống kê tổng hợp theo ngày, chuỗi ngày liên tiếp, cấp độ, XP, thành tựu
- Quan hệ bạn bè, thử thách, quà tặng, mã giới thiệu (nếu bạn dùng tính năng xã hội)
- Lịch sử trò chuyện với AI Coach

### 1.4 Ảnh chụp (Smart Scan)

Khi bạn chụp ảnh ly nước để AI ước lượng thể tích:

- Ảnh được **gửi lên máy chủ của chúng tôi**, thu nhỏ, rồi **gửi tiếp cho
  Anthropic** để phân tích (xem mục 3)
- Ảnh được **lưu lại** cùng kết quả quét, để bạn xem lại lịch sử và để chúng tôi
  đánh giá độ chính xác của mô hình
- Ảnh chỉ gắn với tài khoản của bạn, không ai khác xem được qua ứng dụng

Nếu bạn không dùng Smart Scan, không có ảnh nào được thu thập. Ứng dụng chỉ xin
quyền camera vào lúc bạn mở tính năng này.

### 1.5 Vị trí

Ứng dụng xin **vị trí gần đúng** để lấy nhiệt độ nơi bạn ở, dùng cho gợi ý của
AI Coach (trời nóng thì nhắc uống nhiều hơn).

- Toạ độ được gửi **trực tiếp từ điện thoại** tới dịch vụ thời tiết Open-Meteo
- Chúng tôi **không lưu vị trí của bạn** trên máy chủ
- Từ chối quyền này vẫn dùng được ứng dụng — hệ thống sẽ mặc định là TP.HCM

### 1.6 Dữ liệu kỹ thuật

Máy chủ ghi nhật ký kỹ thuật thông thường (thời điểm, đường dẫn API, mã trạng
thái) để vận hành và chống lạm dụng. Nếu bạn bật nhắc nhở, ứng dụng lưu một mã
thiết bị để gửi thông báo.

---

## 2. Chúng tôi KHÔNG làm gì

- **Không bán dữ liệu** của bạn cho bất kỳ ai
- **Không có quảng cáo**, không có mã theo dõi quảng cáo, không lập hồ sơ để
  nhắm mục tiêu
- **Không chia sẻ dữ liệu sức khoẻ** cho công ty bảo hiểm, nhà tuyển dụng hay
  bên môi giới dữ liệu
- Nhân viên vận hành chỉ xem được dữ liệu tài khoản ở mức cần thiết để hỗ trợ,
  và mọi thao tác nhạy cảm đều được ghi vào nhật ký kiểm toán

---

## 3. Bên thứ ba

| Bên | Nhận gì | Mục đích |
|---|---|---|
| **Anthropic** (Claude API) | Ảnh Smart Scan; nội dung bạn nhắn với AI Coach; số liệu thống kê tổng hợp | Ước lượng thể tích, trả lời tư vấn, sinh nhận xét |
| **Open-Meteo** | Toạ độ gần đúng, gửi thẳng từ điện thoại | Lấy nhiệt độ hiện tại |
| **Google** | Email, tên — chỉ khi bạn chọn Đăng nhập với Google | Xác thực |
| **Railway** | Toàn bộ dữ liệu tài khoản (nhà cung cấp hạ tầng) | Chạy máy chủ và cơ sở dữ liệu |
| **Cloudflare R2** | Ảnh Smart Scan | Lưu trữ ảnh |
| **Brevo** | Địa chỉ email | Gửi mã đặt lại mật khẩu |

Chúng tôi không gửi dữ liệu của bạn cho bên nào khác ngoài danh sách trên.

---

## 4. Lưu trữ và bảo mật

- Dữ liệu nằm trên máy chủ Railway (khu vực US West) và Cloudflare R2
- Kết nối giữa ứng dụng và máy chủ **luôn dùng HTTPS**
- Mật khẩu lưu dưới dạng băm argon2, không lưu bản gốc
- Truy cập API yêu cầu JWT có thời hạn

Không hệ thống nào an toàn tuyệt đối. Đây là dự án do một sinh viên phát triển,
không phải sản phẩm của doanh nghiệp có đội ngũ bảo mật chuyên trách — bạn nên
cân nhắc điều này trước khi nhập thông tin sức khoẻ nhạy cảm.

---

## 5. Quyền của bạn

### Xoá tài khoản

Trong ứng dụng: **Hồ sơ → Xoá tài khoản**. Thao tác này xoá vĩnh viễn:

- Tài khoản và thông tin đăng nhập
- Toàn bộ lịch sử uống nước, thống kê, cấp độ, XP, thành tựu
- Ảnh Smart Scan đã lưu
- Lịch sử trò chuyện với AI Coach
- Quan hệ bạn bè, thử thách, quà tặng

Việc xoá diễn ra **ngay lập tức và không thể khôi phục**. Không có giai đoạn chờ,
không có bản sao lưu để hoàn tác.

Nếu bạn đã gỡ ứng dụng, xem hướng dẫn tại **https://billy3005.github.io/AquaTrack/delete-account.html**
hoặc gửi email tới **giabao3052005@gmail.com**.

**Ngoại lệ duy nhất:** nhật ký kiểm toán ghi lại thao tác của nhân viên vận hành
được giữ lại, nhưng đã gỡ bỏ liên kết tới tài khoản của bạn. Việc này để hồ sơ
"ai đã làm gì" không thể bị xoá bằng cách xoá chính tài khoản liên quan.

### Xem và sửa dữ liệu

Toàn bộ dữ liệu của bạn hiển thị trong ứng dụng. Thông tin cơ thể sửa được tại
Hồ sơ → Dữ liệu cơ thể. Muốn nhận bản sao dữ liệu, gửi email cho chúng tôi.

---

## 6. Trẻ em

AquaTrack không hướng tới trẻ dưới 13 tuổi và chúng tôi không cố ý thu thập dữ
liệu của trẻ em. Nếu bạn là phụ huynh và phát hiện con mình đã tạo tài khoản,
hãy liên hệ để chúng tôi xoá.

---

## 7. Thay đổi chính sách

Khi có thay đổi đáng kể, chúng tôi cập nhật ngày ở đầu tài liệu và thông báo
trong ứng dụng. Tiếp tục sử dụng sau khi thay đổi nghĩa là bạn đồng ý với bản mới.

---

## 8. Liên hệ

Mọi câu hỏi về quyền riêng tư: **giabao3052005@gmail.com**
