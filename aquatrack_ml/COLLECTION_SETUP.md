# 📸 Dataset Collection Setup Guide

## 🛠️ Thiết bị cần thiết

### Camera/Phone
- **Smartphone với camera tốt** (iPhone/Android)
- **Tablet** (nếu có) - màn hình lớn dễ annotation
- **DSLR/Mirrorless** (optional) - chất lượng cao hơn

### Lighting & Setup
- **Natural light** - gần cửa sổ, ban ngày
- **LED ring light** (optional) - đảm bảo ánh sáng đều
- **White backdrop** - giấy A3 hoặc foam board trắng
- **Tripod mini** - stabilize phone camera

### Containers Collection
- **Glasses**: 200ml (shot glass), 350ml (water glass)
- **Plastic cups**: 500ml disposable, reusable cups
- **Water bottles**: 500ml, 750ml, 1L, 1.5L các loại
- **Mugs**: Coffee mugs ~300ml
- **Cans**: Coca-Cola 330ml, energy drinks
- **Other**: Weird shaped containers, mason jars

### Liquids for Photos
- **Water** - clear, easy to see levels
- **Tea** - brown liquid (use cold tea)
- **Coffee** - dark brown (cold coffee)
- **Orange juice** - orange color
- **Smoothie** - thick texture (yogurt + fruit)

**⚠️ Safety:** Dùng cold liquids để tránh steam làm mờ ảnh!

## 📐 Đo lường chính xác

### Fill Level Tools
- **Graduated cylinder** - đo chính xác ml
- **Kitchen scale** - cân nước (1ml = 1g)
- **Measuring cup** - đo nhanh
- **Permanent marker** - đánh dấu mức trên container

### Volume Reference
```
Container sizes (approximate):
├── Glass small:  200ml = 6.8 fl oz
├── Glass large:  350ml = 11.8 fl oz  
├── Plastic cup:  500ml = 16.9 fl oz
├── Bottle 500:   500ml = 16.9 fl oz
├── Bottle 750:   750ml = 25.4 fl oz
├── Bottle 1000:  1000ml = 33.8 fl oz
├── Bottle 1500:  1500ml = 50.7 fl oz
├── Mug:          300ml = 10.1 fl oz
├── Can 330:      330ml = 11.2 fl oz
└── Other:        ~300ml average
```

## 📱 Software Setup

### Install Dependencies
```bash
cd aquatrack_ml
pip install Pillow numpy  # For validation
```

### Test Collection Tools
```bash
# Test mobile collector
python src/data/mobile_collector.py

# Test validator 
python src/data/dataset_validator.py
```

---

## 🏠 Shooting Station Setup

### Optimal Setup
```
📷 Camera position: 1-2 feet away, slightly above container
💡 Light source: Window light from side (not behind)
🎨 Background: White paper/foam board, clean surface
📐 Container: Center frame, fully visible, stable
```

### Camera Settings (if manual)
- **ISO**: 100-400 (low noise)
- **Aperture**: f/5.6-f/8 (good depth of field)  
- **Shutter**: 1/60s+ (avoid blur)
- **Focus**: Single point AF on container edge
- **Format**: JPEG fine (smaller files for training)

---

## ⚡ Workflow Tối Ưu

### Session Planning (2-3 hours)
1. **Setup station** (15 min) - lighting, background, containers
2. **Batch shooting** (90 min) - 1 container type, all fill levels
3. **Quick annotation** (30 min) - use mobile tool immediately  
4. **Validation** (15 min) - check quality before cleanup

### Efficient Shooting Order
```
Day 1: Water + Clear containers
├── Bottles (500ml, 1L) with water - 5 fill levels each
├── Glasses (small, large) with water - 5 levels each  
└── Expected: ~40 photos

Day 2: Colored liquids  
├── Tea in glasses and mugs - 5 levels each
├── Coffee in mugs - 5 levels
├── Orange juice in glasses - 3 levels
└── Expected: ~35 photos

Day 3: Plastic containers
├── Plastic cups with water, juice - 5 levels each
├── Large bottles (750ml, 1.5L) - 5 levels each
└── Expected: ~30 photos
```

---

## 📊 Quality Control Checklist

### Per Photo Check
- [ ] **Sharp focus** - container edges crisp
- [ ] **Good exposure** - not too dark/bright
- [ ] **Full container visible** - no crop
- [ ] **Stable/straight** - not tilted >15°
- [ ] **Clean background** - minimal distractions
- [ ] **Liquid level clear** - easy to see fill line

### Per Session Check  
- [ ] **Consistent lighting** across batch
- [ ] **Multiple angles** - front, 45° side
- [ ] **Fill level accuracy** - measured, not guessed
- [ ] **File naming** - descriptive, organized
- [ ] **Backup photos** - save to cloud/external

---

## 🎯 Pro Tips

### Speed Collection
- **Pre-measure liquids** - bottles of 25%, 50%, 75% full ready
- **Use timer/remote** - avoid camera shake from button press
- **Batch similar** - all glasses together, all bottles together
- **Quick preview** - check focus immediately, reshoot if needed

### Quality Assurance
- **Take 2-3 shots** per setup, pick best one
- **Zoom to check sharpness** before moving container
- **Use histogram** - avoid clipped highlights/shadows
- **Reference photo** - wide shot showing full setup for context

### Annotation Accuracy
- **Measure, don't guess** fill levels
- **Use consistent lighting** for color accuracy
- **Note any special conditions** - dirty container, foam, etc.
- **Double-check container type** - easy to mix up bottle sizes

Ready to start? 🚀