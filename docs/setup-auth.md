# Setup Google Sign-In + Email (ADR 0006)

Thủ tục một lần, ~30 phút. Xong hai mục này thì nút "Tiếp tục với Google" và
"Quên mật khẩu?" chạy thật trên thiết bị.

## 1. Google OAuth Client (miễn phí)

Vào [Google Cloud Console](https://console.cloud.google.com/) → tạo project
(ví dụ `aquatrack`) → **APIs & Services**:

### 1a. OAuth consent screen
- User type: **External** → điền tên app + email → Save.
- Mục **Test users**: thêm Gmail của bạn (khi app ở chế độ Testing, chỉ test
  user đăng nhập được).

### 1b. Credentials → Create Credentials → OAuth client ID (tạo 2 cái)

**Web application** (đây là cái quan trọng — audience để verify token):
- Tạo xong copy **Client ID** (dạng `xxxx.apps.googleusercontent.com`).
- Dán vào `aquatrack_backend/.env`:
  ```
  GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
  ```
- Flutter chạy với cùng giá trị đó:
  ```bash
  flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  ```

**Android**:
- Package name: `com.aquatrack.app`
- SHA-1 debug — lấy bằng:
  ```bash
  cd aquatrack_app/android && ./gradlew signingReport
  # hoặc: keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android
  ```
- Client Android này KHÔNG cần copy đi đâu — chỉ cần tồn tại để Google Play
  Services chấp nhận app. Không cần google-services.json (không dùng Firebase).

## 2. Gmail SMTP cho mã quên mật khẩu (miễn phí, ~500 mail/ngày)

1. Bật **2-Step Verification** cho Google Account.
2. [App Passwords](https://myaccount.google.com/apppasswords) → tạo password
   cho "Mail" → được chuỗi 16 ký tự.
3. `aquatrack_backend/.env`:
   ```
   SMTP_USERNAME=email-cua-ban@gmail.com
   SMTP_PASSWORD=xxxx xxxx xxxx xxxx
   ```

**Chưa cấu hình SMTP?** Ở môi trường development, mã 6 số được in vào log của
backend server thay vì gửi mail — flow vẫn test được end-to-end.

## Checklist test nhanh

- [ ] Đăng nhập Google với Gmail mới → tạo tài khoản passwordless, vào onboarding
- [ ] Đăng nhập Google lần 2 → vào thẳng Home
- [ ] Login password vào tài khoản Google-first → báo "Tài khoản này đăng nhập bằng Google"
- [ ] Đăng ký password trước, rồi đăng nhập Google cùng email → vào đúng tài khoản cũ (auto-link)
- [ ] Quên mật khẩu → nhận mã (mail hoặc log backend) → đặt lại → login bằng mật khẩu mới
