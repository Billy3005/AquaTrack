# AquaTrack — Công thức tính lượng nước uống mỗi ngày

## Luồng thu thập dữ liệu (5 bước)

```
B1 · Body      → giới tính, tuổi, chiều cao, cân nặng
B2 · Lifestyle → mức vận động, tính chất công việc
B3 · Health    → tình trạng sức khỏe đặc biệt
B4 · Diet      → rau củ quả, cà phê, rượu bia
B5 · Review    → hiển thị kết quả & tóm tắt
```

---

## Công thức tổng quát

```
total_ml = base + activity_add + job_add + health_add + veggie_add + coffee_add + alcohol_add

total_ml = round(total_ml / 50) × 50     // làm tròn đến 50ml gần nhất
total_ml = max(total_ml, 1500)           // tối thiểu 1.500ml
```

> Không có thành phần khí hậu trong luồng thu thập — AquaTrack tự động điều chỉnh theo thời tiết & lịch ngày (ghi chú màn hình B5).

---

## B1 · Body — Thông tin cơ thể

### Các trường thu thập

| Trường | Kiểu | Giới hạn | Ghi chú |
|---|---|---|---|
| `gender` | enum | — | Nam / Nữ / Khác |
| `age` | integer | — | đơn vị: tuổi |
| `height` | integer | 130–210 cm | slider |
| `weight` | float | 30–150 kg | slider, bước 0.1 |

### Công thức nền tảng

```
base = weight_kg × 35
```

### Hệ số theo giới tính

```
if gender == "male":   base = base × 1.0
if gender == "female": base = base × 0.95
if gender == "other":  base = base × 1.0
```

---

## B2 · Lifestyle — Nhịp sống

### Mức độ vận động thường ngày

| Giá trị | Nhãn hiển thị | Mô tả | activity_ml_per_kg |
|---|---|---|---|
| `sedentary` | Ít vận động | Ngồi nhiều, hiếm khi tập | 0 |
| `light` | Nhẹ nhàng | Đi bộ và lâu lâu | 12 |
| `moderate` | Vừa phải | Tập 3–4 buổi/tuần | 14 |
| `active` | Năng động | Tập gần như mỗi ngày | 16 |
| `very_active` | Rất năng động | VĐV / lao động nặng | 19 |

```
activity_add = weight_kg × activity_ml_per_kg
```

**Nguồn:** Institute of Medicine (IOM)

### Tính chất công việc

| Giá trị | Nhãn hiển thị | Mô tả | job_add (ml) |
|---|---|---|---|
| `office` | Văn phòng | Máy tính, ngồi nhiều | 0 |
| `mixed` | Hỗn hợp | Vừa ngồi vừa di chuyển | +150 |
| `outdoor` | Ngoài trời | Phơi nắng, đi lại nhiều | +400 |
| `manual` | Tay chân | Xây dựng, vận chuyển | +500 |

---

## B3 · Health — Sức khỏe

### Tình trạng sức khỏe đặc biệt
Cho phép chọn nhiều mục. Mặc định: `none`.

| Giá trị | Nhãn hiển thị | health_add (ml) | Ghi chú |
|---|---|---|---|
| `none` | Không có | 0 | — |
| `diabetes` | Tiểu đường | +200 | — |
| `hypertension` | Cao huyết áp | +150 | — |
| `neurological` | Bệnh thần | 0 | hiển thị cảnh báo |
| `heart` | Tim mạch | 0 | hiển thị cảnh báo + điều chỉnh cà phê |
| `pregnant` | Đang mang thai | +500 | — |
| `lactating` | Đang cho con bú | +700 | — |
| `gout` | Gout | +300 | — |

```
health_add = sum của tất cả health_add các mục được chọn
```

### Cảnh báo bắt buộc hiển thị (B3)

```
if "neurological" OR "heart" in selected_conditions:
    show_warning("Thông tin này không thay thế lời khuyên y tế. 
                  Với bệnh thần hoặc tim mạch, hãy hỏi bác sĩ 
                  về lượng nước phù hợp.")
```

---

## B4 · Diet — Thói quen ăn uống

### Lượng rau củ quả mỗi ngày

| Giá trị | Nhãn hiển thị | Định nghĩa | veggie_add (ml) |
|---|---|---|---|
| `low` | Ít | < 1 phần/ngày | −100 |
| `medium` | Vừa | 1–2 phần/ngày | −250 |
| `high` | Nhiều | 3+ phần/ngày | −400 |

**Nguồn:** IOM — 20–30% nước hàng ngày đến từ thực phẩm

### Cà phê / ngày

```
coffee_add:
  if "heart" NOT in selected_conditions:
      coffee_add = coffee_cups × 120       // lợi tiểu nhẹ, bù 120ml/cốc
  else:
      coffee_add = coffee_cups × 120
      show_note("Lợi tiểu — AquaTrack sẽ thêm 120ml/cốc")
      // Tim mạch: giữ nguyên công thức nhưng nhắc người dùng hỏi bác sĩ
```

> Hiển thị note dưới spinner: *"Lợi tiểu — Aquatrack sẽ thêm 120ml/cốc"*

### Rượu bia / ngày

```
alcohol_add = alcohol_units × 200
```

> 1 đơn vị = 1 lon bia / 1 ly rượu vang  
> Hiển thị note dưới spinner: *"1 đơn vị = 1 lon bia / 1 ly rượu vang"*

---

## B5 · Review — Mục tiêu của bạn

### Hiển thị kết quả

```
daily_goal_ml  = total_ml
daily_goal_L   = round(total_ml / 1000, 2)       // ví dụ: 2.865 → "2,865 lít"
daily_goal_cups = round(total_ml / 250)           // ví dụ: "khoảng 11 cốc 250ml"
```

### Tóm tắt thông tin người dùng (góc phải màn hình B5)

| Dòng | Nội dung |
|---|---|
| Giới tính · Tuổi | ví dụ: "Nam - 28 tuổi" |
| Chiều cao · Cân nặng | ví dụ: "168 cm - 60 kg" |
| Vận động | ví dụ: "Vừa phải" |
| Công việc | ví dụ: "Văn phòng" |

### Ghi chú cuối màn hình B5

> *"AquaTrack sẽ tự điều chỉnh mục tiêu theo thời tiết, vận động và lịch ngày. Bạn có thể chỉnh lại trong Hồ sơ."*

---

## Ví dụ tính (đúng với màn hình demo)

**Đầu vào:** Nam · 28 tuổi · 168cm · 60kg · Vừa phải · Văn phòng · Không có bệnh · Rau vừa (1-2 phần) · 1 cốc cà phê · 0 rượu bia

| Thành phần | Tính | Kết quả |
|---|---|---|
| Nền tảng | 60 × 35 × 1.0 | +2.100ml |
| Vận động (vừa phải) | 60 × 14 | +840ml |
| Công việc (văn phòng) | — | 0 |
| Sức khỏe (không có) | — | 0 |
| Rau củ (vừa) | — | −250ml |
| Cà phê (1 cốc) | 1 × 120 | +120ml |
| Rượu bia (0) | — | 0 |
| **Tổng (làm tròn 50ml)** | | **≈ 2.850ml** |

→ Khớp với màn hình B5: **2.850ml**

---

## Quy đổi đơn vị

```
lít       = total_ml / 1000                     → 2 chữ số thập phân
cốc 250ml = round(total_ml / 250)
fl oz     = round(total_ml / 29.574)
```
