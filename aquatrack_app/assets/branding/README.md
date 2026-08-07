# Branding assets

Không phải asset runtime — `pubspec.yaml` cố ý không khai `assets:` cho thư mục
này, nên nó không nằm trong APK/AAB. Đây là nguồn để sinh icon và để nộp chợ.

| File | Dùng để |
|---|---|
| `app_icon.svg` | **Nguồn duy nhất.** Sửa icon là sửa file này. |
| `app_icon_1024.png` | Bản render 1024 để xem nhanh / nộp App Store nếu làm iOS |
| `play_store_icon_512.png` | Icon 512×512 cho trang niêm yết Google Play |

## Thiết kế

Hướng **B — "Vòng tay ôm"**, lấy từ dự án Claude Design *Wafubi*, file
`Wafubi Icon.html`. Hai cánh tay khoác nhau tạo thành vòng ôm lấy giọt nước.
Chọn hướng này vì silhouette còn đọc được ở 29px, an toàn nhất cho cỡ nhỏ.

Quy tắc từ bản thiết kế, giữ nguyên khi sửa:

- Hai nhân vật phân biệt bằng **trắng** và **xanh nhạt** — không thêm màu thứ ba
- Không có chữ trong icon
- Mọi nét cách mép ≥ 80px ở khung 1024
- Nét mỏng nhất 56px ở khung 1024 (để không vỡ ở 40px)

## Sinh lại bộ icon

```bash
cd aquatrack_app
python tool/generate_icons.py .
```

Ghi đè toàn bộ `android/app/src/main/res/mipmap-*/` và hai file PNG ở đây.
Chỉ cần Pillow, không cần thư viện SVG — script tự dựng lại các hình trong
`app_icon.svg` bằng thuật toán arc/bezier của W3C. **Sửa `app_icon.svg` thì phải
sửa `tool/generate_icons.py` cho khớp**, hai file không tự đồng bộ.

Sinh ra:

- `mipmap-*/ic_launcher.png` — icon phẳng, cho Android < 26
- `mipmap-*/ic_launcher_foreground.png` — lớp tranh, đặt trong vùng an toàn 66%
- `mipmap-*/ic_launcher_background.png` — lớp nền gradient
- `mipmap-anydpi-v26/ic_launcher.xml` — khai báo adaptive icon (viết tay, script
  không đụng tới)

Lớp nền là PNG chứ không phải `<gradient>` XML vì `android:angle` chỉ nhận bội
số 45°, còn gradient gốc chạy ở khoảng 63° — bản XML sẽ lệch so với icon phẳng.
