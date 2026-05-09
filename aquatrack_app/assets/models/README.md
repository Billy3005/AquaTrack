# AquaTrack ML Models

## aquatrack_v1.tflite
Custom TFLite model for volume estimation from drink container photos.

### Model Architecture:
- **Input:** 224x224x3 RGB image (normalized 0-1)
- **Output 1:** Container classification (10 classes: glass_small, glass_large, cup_plastic, bottle_500, bottle_750, bottle_1000, bottle_1500, mug, can_330, other)
- **Output 2:** Fill level regression (0.0-1.0)
- **Output 3:** Liquid type classification (5 classes: water, tea, coffee, juice, smoothie)

### Training Data Requirements:
- 1000+ images per container type
- Various lighting conditions and angles
- Multiple fill levels (0%, 25%, 50%, 75%, 100%)
- Different liquid types với proper labeling

### Performance Targets:
- Container classification: >85% accuracy
- Fill level estimation: <10% MAE
- Liquid type detection: >80% accuracy
- Inference time: <500ms on mobile

### Current Status:
- Model architecture implemented in VisionService
- Mock data pipeline working
- Ready for actual model file placement