# 0006 — Social sign-in: Google duy nhất, verify trực tiếp trên backend, auto-link theo email đã xác minh

- Status: Accepted
- Date: 2026-06-12

## Context

Màn Login/Register ship UI trước khi có chức năng thật: ba nút social
(Apple/Google/Facebook) đều `onPressed: () {}`, icon Google là `Icons.search`
placeholder, "Quên mật khẩu?" là TODO, "Ghi nhớ tôi" là state cục bộ không nối
đi đâu. Đây đúng pattern "fake shop" mà ADR 0004 đã xử lý ở Shop.

Chi phí thật của từng provider rất chênh lệch: Google miễn phí (~1-2 ngày
công); Apple cần Apple Developer Program $99/năm và chỉ có ý nghĩa khi ship
iOS — mà App Store guideline 4.8 biến nó thành *nghĩa vụ* (đã có social login
trên iOS thì bắt buộc có Sign in with Apple); Facebook cần app review + Data
Use Checkup + privacy policy public, nhiều tuần thủ tục. AquaTrack hiện chỉ
chạy Android/Windows, chưa có Apple dev account, chưa có privacy policy.

Backend đã có hệ JWT hoạt động tốt và một kiến trúc nhất quán
"backend-canonical" (streak, scan history, token storage đều một nguồn).

## Decision

1. **Google là provider duy nhất; Apple và Facebook bị xóa khỏi UI** — xóa
   hẳn, không "Sắp ra mắt" (honest UI, ADR 0004). Apple chỉ quay lại như
   nghĩa vụ kèm theo nếu ship iOS (ADR riêng lúc đó). Một provider = một nút
   full-width "Tiếp tục với Google" (logo G theo brand guideline), dùng chung
   cho cả Login lẫn Register vì với Google hai việc là một (find-or-create).

2. **Verify trực tiếp, không Firebase.** Flutter dùng `google_sign_in` lấy ID
   token → `POST /auth/google {id_token}` → FastAPI verify chữ ký + audience
   bằng `google-auth` → find-or-create user → trả về đúng cặp JWT hiện có.
   Firebase Auth bị loại vì nó đưa hệ identity thứ hai vào app (user tồn tại
   ở hai nơi, backend phải verify token Firebase) chỉ để tiết kiệm vài dòng
   verify — backend của AquaTrack vẫn là chủ identity duy nhất.

3. **Auto-link theo email đã xác minh, khóa bằng `google_sub`.** Google
   sign-in mang email trùng tài khoản password hiện có → đăng nhập thẳng vào
   tài khoản đó (một người một tài khoản, hai cửa). Điều kiện an toàn:
   - Chỉ link khi token Google có `email_verified=true`.
   - Identity Google ghi bằng cột `google_sub` (subject ID vĩnh viễn,
     unique) — không bao giờ dùng email làm khóa (email đổi được).
   - Link vào tài khoản password có email **chưa xác minh** (hiện là tất cả,
     vì app không enforce verify) thì **vô hiệu hóa mật khẩu cũ** (set NULL):
     chặn kịch bản kẻ xấu đăng ký trước bằng email nạn nhân rồi giữ mật khẩu
     của tài khoản sau khi nạn nhân Google-link vào. Mật khẩu dùng lại được
     qua Password Reset.
   - `hashed_password` cho phép NULL: tài khoản Google-first không có mật
     khẩu; login password vào đó trả lời trung thực "tài khoản này đăng nhập
     bằng Google".

4. **Password Reset bằng mã 6 số gửi email; verify email khi đăng ký chưa
   enforce.** Mã ngắn hạn nhập trong app (không deep link — đơn giản hơn
   nhiều trên mobile), SMTP Gmail App Password đủ cho giai đoạn này. Flow này
   đồng thời là đường tái-vũ-trang mật khẩu bị vô hiệu ở quyết định 3 và
   đường thêm mật khẩu cho tài khoản Google-first. Verify email tiếp tục
   *không* chặn đăng ký — friction giết conversion của app sinh viên; xem lại
   ở Phase 4 Production Readiness.

5. **Xóa "Ghi nhớ tôi".** Mobile app với refresh token thì mọi user đều được
   ghi nhớ mặc định — checkbox là di sản web, không có hành vi thật nào để
   gắn. Control không thể thật thì không đứng trên màn hình.

## Consequences

- Schema users thêm `google_sub` (String, unique, nullable),
  `hashed_password` chuyển nullable; thêm bảng/cột lưu mã reset ngắn hạn.
- Cần OAuth Client ID trên Google Cloud Console (Android client + Web client
  làm audience) — thủ tục một lần, miễn phí.
- User Google và user password đi chung đường ống session: cùng JWT, cùng
  `/auth/me`, mọi flow phía sau không phân biệt nguồn đăng nhập.
- UI Login/Register gọn lại: một nút Google, không hàng 3 nút, không checkbox
  chết; "Quên mật khẩu?" sống thật.
- SMTP Gmail có rate limit (~500 mail/ngày) — quá đủ hiện tại, đổi sang
  transactional service khi có user thật.

## When to revisit

- Ship iOS → Apple Sign-In thành bắt buộc (guideline 4.8): ADR mới cho Apple
  + cân nhắc lại cấu trúc `google_sub` thành bảng `linked_identities` đa
  provider.
- Social features mở cho người lạ / spam xuất hiện → enforce verify email khi
  đăng ký (Phase 4).
- Có user thật → privacy policy public + chuyển SMTP sang dịch vụ
  transactional.
