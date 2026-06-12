# Smart Scan dùng Vision API thuần, không train model — hybrid là giai đoạn 2

---
status: accepted
date: 2026-06-11
---

Smart Scan (ước lượng lượng nước từ ảnh) dùng **Claude Vision API thuần** thay vì tự train model nhận diện hay hybrid. Bối cảnh: solo dev sinh viên, budget vision API $10–15/tháng, KPI sai số thể tích <15% và correction rate <25%. Với chi phí ~$0.002/scan (Haiku 4.5), budget cho ~5.500–8.300 scan/tháng — quá đủ; trong khi tự train model tốn vài tháng thu thập + gán nhãn dữ liệu mà độ chính xác fill-level gần như chắc chắn thua Vision API ở giai đoạn chưa có data.

## Các quyết định kèm theo

1. **Ước lượng capacity liên tục, bỏ bảng container cứng.** Bảng 10 lớp container × dung tích cố định (cũ: `bottle_500`, `glass_large`…) bị bỏ vì lỗi phân loại rời rạc một mình đã ăn hết error budget ±15% (ví dụ: chai 650ml bị ép vào `bottle_750` → sai 15.4% trước khi fill-level kịp sai). Model trả về `container_capacity_ml` dạng số liên tục (đọc nhãn chai, ước lượng kích thước) + `fill_level`; loại container chỉ còn để hiển thị UI.

2. **Vision response chỉ trả `estimated_volume_ml` (thể tích vật lý), không trả effective volume.** Hệ số hydration được áp đúng **một lần** tại bước log (Log Drink). Lý do: luồng cũ truyền `effective_volume_ml` vào Log Drink rồi Log Drink nhân hệ số lần nữa → double-discount (cà phê 300ml bị ghi 192ml thay vì 240ml). Người dùng xác nhận con số họ nhìn thấy được bằng mắt (thể tích trong ly), không phải khái niệm trừu tượng.

3. **Model ID nằm trong env (`VISION_MODEL`), không hardcode; mặc định `claude-haiku-4-5`.** Bài học trực tiếp: code cũ hardcode `claude-3-haiku-20240307`, model bị retire (19/04/2026) khiến mọi scan âm thầm rơi vào fallback random với confidence 0.5 mà không ai phát hiện. Việc chọn Haiku 4.5 hay Sonnet 4.6 do **tập eval thực tế** quyết định (ảnh chai/ly đã biết thể tích thật): Haiku đạt <15% thì giữ, không thì đổi env var sang Sonnet (~$0.0055/scan, vẫn trong budget). Dùng structured outputs (`output_config.format`) để loại bỏ parse JSON thủ công.

4. **Backend là nguồn canonical duy nhất cho scan history; lưu toàn bộ ảnh scan (bản resize 1024px).** Local SharedPreferences provider bị xóa. Lý do quyết định: correction của người dùng (`user_corrected_volume`) **kèm ảnh** chính là training dataset cho giai đoạn hybrid — correction không có ảnh là label chết, còn data kẹt trên từng máy (giới hạn 100 records) thì không bao giờ gom được. Cả scan được confirm đúng lẫn scan bị sửa đều được giữ (cần cả positive lẫn negative examples, vì correction rate mục tiêu <25% nghĩa là ~75% data là positive). Điều kiện: privacy notice phải ghi rõ ảnh scan được lưu để cải thiện AI, trước khi có user thật.

## Kết quả eval vòng 1 (2026-06-11, n=10, nước lọc trong vật chứa trong suốt)

**Chốt `claude-haiku-4-5`** — Sonnet 4.6 cho độ chính xác tương đương (~61% vs ~57% mean error) ở giá gấp 3, nên bị loại. Hai phát hiện vận hành quan trọng:

1. **Capacity đọc từ nhãn rất ổn định** (đúng hướng với quyết định capacity liên tục), nhưng **fill-level trên nước trong suốt là failure mode chính** — model thường không thấy mặt nước (phán rỗng khi có nước và ngược lại), lỗi bền vững qua các vòng prompt. Tăng `VISION_MAX_IMAGE_DIMENSION` lên 1568px để cho model tối đa chi tiết; trần năng lực (Opus hi-res) chưa được kiểm chứng.
2. **Confidence tự báo không calibrated** — model báo 0.85+ ở chính các ảnh sai nặng nhất, và phớt lờ chỉ dẫn hạ confidence. Ngưỡng auto-fill 0.85 vì vậy chưa đáng tin về mặt thống kê; UX "luôn chỉnh sửa được, không bao giờ ép chụp lại" là lưới an toàn chính. Theo dõi correction rate từ `scan_history` sau khi có user thật trước khi tin vào auto-fill.

## Đường lên hybrid (giai đoạn 2)

Khi `scan_history` tích lũy đủ vài nghìn bản ghi có ảnh + volume đã xác nhận, train model nhẹ (TFLite) trên dataset đó để chạy on-device, Vision API lùi về làm fallback cho ca khó. Không làm sớm hơn — hybrid trước khi có data là gánh hai độ phức tạp mà không có gì để train.
