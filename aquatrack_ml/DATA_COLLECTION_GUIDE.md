# 📷 AquaTrack Dataset Collection Guide

## 🎯 Mục tiêu
Thu thập **500+ ảnh** đa dạng để train model phát hiện:
- **Container type** (10 loại)
- **Fill level** (mức đầy 0-100%)  
- **Liquid type** (5 loại)

---

## 📊 Target Dataset Distribution

### Container Types (510 total)
```
glass_small   (200ml) - 60 ảnh  ████████████████████
glass_large   (350ml) - 60 ảnh  ████████████████████
bottle_500    (500ml) - 70 ảnh  ███████████████████████
bottle_1000   (1L)    - 60 ảnh  ████████████████████
cup_plastic   (500ml) - 50 ảnh  ████████████████
bottle_750    (750ml) - 50 ảnh  ████████████████
mug          (300ml) - 50 ảnh  ████████████████
can_330      (330ml) - 40 ảnh  █████████████
bottle_1500  (1.5L)  - 40 ảnh  █████████████
other        (mixed) - 30 ảnh  ██████████
```

### Fill Levels (distributed across containers)
- **Empty** (0-10%) - 20%
- **Low** (10-40%) - 20%  
- **Medium** (40-70%) - 30%
- **High** (70-90%) - 20%
- **Full** (90-100%) - 10%

### Liquid Types
- **Water** - 200 ảnh (clear, most important)
- **Tea** - 80 ảnh (brown/yellow)
- **Coffee** - 80 ảnh (dark brown)
- **Juice** - 60 ảnh (orange/red colors)
- **Smoothie** - 40 ảnh (thick texture)

---

## 📸 Photo Quality Guidelines

### ✅ GOOD Photos
- **Clear focus** - container & liquid well-defined
- **Good lighting** - natural or bright indoor light
- **Full container visible** - không bị cắt
- **Stable angle** - không nghiêng quá 15°
- **Clean background** - ít clutter
- **Resolution** - minimum 800x600px

### ❌ AVOID
- Blurry/out of focus
- Very dark or overexposed  
- Container partially hidden
- Extreme angles (top-down, bottom-up)
- Dirty lens or reflection glare
- Too much background noise

---

## 🎨 Variation Requirements

### Lighting Conditions
- **Natural light** (40%) - near window, outdoor
- **Indoor artificial** (40%) - LED, fluorescent  
- **Mixed lighting** (20%) - natural + artificial

### Background Types  
- **Clean/minimal** (50%) - white/neutral background
- **Kitchen counter** (30%) - realistic usage context
- **Textured/pattern** (20%) - wood, marble, fabric

### Camera Angles
- **Front view** (50%) - straight on 
- **Side view** (25%) - 45° side angle
- **Slight top** (25%) - 15° from above

### Container Conditions
- **Clean containers** (70%) 
- **Slightly dirty/used** (30%) - realistic condition

---

## 📱 Collection Tools

### 1. Mobile App (Recommended)
```bash
# Take photos directly with annotation
python src/data/mobile_collector.py
```

### 2. Manual Collection
```bash  
# Add existing photos
python src/data/dataset_collector.py
```

### 3. Batch Processing
```bash
# Process multiple photos at once  
python src/data/batch_annotator.py
```

---

## 🗂️ File Organization

```
data/
├── raw/                    # Original photos
│   ├── glass_small_0.75_water_20241210_143025.jpg
│   ├── bottle_500_0.60_tea_20241210_143156.jpg
│   └── ...
└── annotations/
    ├── dataset_metadata.json  # All annotations
    └── collection_log.txt      # Collection progress
```

---

## ⚡ Quick Collection Workflow

### Phase 1: Common Containers (Week 1)
1. **Water bottles** (500ml, 1L) với các mức đầy khác nhau
2. **Glasses** (small/large) với water và juice 
3. **Mugs** với coffee/tea

### Phase 2: Edge Cases (Week 2)  
1. **Plastic cups** với smoothies
2. **Large bottles** (750ml, 1.5L)
3. **Cans** và **other** containers

### Phase 3: Diversity (Week 3)
1. Different lighting conditions
2. Various backgrounds  
3. Different liquid colors
4. Quality validation

---

## 📊 Progress Tracking

Check collection status:
```bash
python src/data/dataset_collector.py
# Option 1: Show collection status
```

Priority list:
```bash  
# Xem containers nào cần collect thêm
python src/data/dataset_collector.py  
# Option 3: Show priorities
```

---

## 🏆 Collection Tips

### Efficiency Tips
- **Setup shooting station** - good lighting, clean background
- **Batch similar containers** - collect all glass types together  
- **Vary liquid levels** - empty → full in steps
- **Take multiple angles** - front, side per container

### Quality Assurance
- **Review immediately** - delete bad shots right away
- **Check focus** - zoom in to verify sharpness  
- **Consistent lighting** - avoid mixed light sources
- **Fill levels accurate** - use measuring tools

### Speed Collection
- **Prepare containers** in advance với measured liquids
- **Use timer/remote** to avoid camera shake
- **Mobile tripod** for consistent angles
- **Batch annotation** after shooting session

---

## 🎯 Success Metrics

Target: **500+ high-quality, diverse images**

**Quality targets:**
- 📸 95% good focus & lighting
- 🎨 30% diversity in backgrounds  
- 💡 40% natural lighting mix
- 📐 80% front/side angle mix
- 🥤 Balanced fill level distribution

**Ready to start collecting!** 🚀