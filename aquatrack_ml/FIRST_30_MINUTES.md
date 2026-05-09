# ⏱️ First 30 Minutes - Quick Start Guide

## 🎯 Goal: 10 quality samples để test pipeline

### ✅ MINUTE 1-5: Setup Station
```
📍 Location: Near window with good natural light
🎨 Background: White paper/wall  
📱 Camera: Phone camera, clean lens
🥤 Materials: 2-3 containers + water
```

### ✅ MINUTE 6-20: Shoot & Collect

**Round 1: Water bottle (500ml)**
1. Fill bottle to different levels
2. Take photos:
   - Empty (just drops left)
   - Quarter full (~125ml) 
   - Half full (~250ml)
   - Three-quarter full (~375ml)
   - Nearly full (~475ml)

**Round 2: Glass (any size)**  
1. Repeat with glass container
2. Same fill levels
3. Different liquid if available (tea/juice)

### ✅ MINUTE 21-30: Annotate with Tool

**Open collection tool:**
```bash
cd aquatrack_ml
python quick_start_collector.py
```

**For each photo:**
1. Choose "1. Add new sample"
2. Drag photo file into terminal
3. Select container type (4 for bottle_500, 1 for glass_small)
4. Select liquid (1 for water)
5. Select fill level (1=empty, 2=low, 3=medium, 4=high, 5=full)

### 🎯 Target Result: 10 annotated samples

---

## 📸 Quick Photo Tips

### Frame Setup
```
Camera distance: 2-3 feet away
Container position: Center frame  
Background: Clean, minimal
Lighting: Soft, even (avoid harsh shadows)
```

### Essential Shots Per Container
1. **Front view** - straight on, container centered
2. **Different fill levels** - empty, 1/4, 1/2, 3/4, full
3. **Sharp focus** - container edges crisp
4. **Stable shot** - no blur, straight orientation

### Quick Quality Check
- [ ] Can clearly see liquid level line?
- [ ] Container fully visible (not cropped)?  
- [ ] Good lighting (not too dark/bright)?
- [ ] Sharp focus (edges crisp)?

---

## 🎉 Success Milestones

**After 10 samples:**
- Understanding workflow ✅
- Tool familiarity ✅
- Ready for bigger collection

**After 50 samples:**
- Enough for initial ML testing
- Can start model architecture work
- Good variety established

**After 200 samples:**
- Serious training dataset
- Production-ready foundation
- Can begin actual training

---

## 🚀 Next Steps Plan

### Week 1: Foundation (50 samples)
**Day 1-2**: Common containers với water
- Water bottles: 500ml, 1L
- Glasses: different sizes
- Target: 20 samples

**Day 3-4**: Add liquid variety  
- Tea, coffee trong mugs
- Juice trong glasses
- Target: +15 samples

**Day 5-7**: Container variety
- Plastic cups
- Cans
- Other shapes  
- Target: +15 samples

### Week 2: Scale Up (150 more samples)
- More fill level variations
- Different lighting conditions  
- Background variety
- Edge cases & challenging shots

### Week 3: Quality & Training (100+ more samples)
- Final quality validation
- Balance checking
- Start model training prep
- Test data collection

---

## 🔧 Troubleshooting

**Tool won't start?**
```bash
cd aquatrack_ml  
pip install pillow  # Install missing deps
python quick_start_collector.py
```

**Photo quality issues?**
- Move closer to window (natural light)
- Clean camera lens
- Hold phone steady (use timer)
- Check focus by tapping screen

**Annotation mistakes?**
- Edit `./data/annotations/quick_collection_log.json`
- Or note corrections for later cleanup

**Need inspiration?**
Look for containers around house:
- Kitchen: glasses, mugs, bottles
- Living room: water bottles, cans
- Bathroom: medicine measuring cups
- Office: coffee cups, water tumblers

Ready to collect your first 10 samples? 🚀