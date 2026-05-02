# agents/ml.md — ML / AI Agent (Smart Scan)

> Load khi làm việc trong `aquatrack_ml/` hoặc `vision_service.dart`

## Tên feature trong app: Smart Scan (Screen 07)

```
User mở Smart Scan → camera fullscreen → dashed oval overlay
→ TFLite chạy on-device → detect container + fill level
→ Result: "Cà phê đá · ~180ml · ≈144ml hydration (×0.8)"
→ [Xác nhận] hoặc slider nếu confidence thấp
```

## Stack
```
On-device : TF/Keras → MobileNetV3-Small → TFLite float16 (~1.2MB)
Server    : PyTorch + timm → EfficientNetV2-S (~21MB)
Annotation: Label Studio
Training  : Google Colab / Kaggle
```

## Output Format
```python
{
  "container_class":    str,    # 10 classes (xem dưới)
  "fill_level_percent": float,  # 0.0 → 1.0
  "liquid_type":        str,    # water|tea|coffee|juice|smoothie
  "confidence":         float,  # 0.0 → 1.0
  "estimated_volume_ml": int,
  "effective_volume_ml": int,   # × hydration_coeff
}
```

## Container Classes & Sizes
```python
CONTAINER_SIZE_MAP = {
    'glass_small': 200,  'glass_large': 350,
    'cup_plastic': 500,  'bottle_500': 500,
    'bottle_750':  750,  'bottle_1000': 1000,
    'bottle_1500': 1500, 'mug': 300,
    'can_330':     330,  'other': 300,
}
```

## Hydration Coefficients (theo Log Drink screen)
```python
HYDRATION_COEFF = {
    'water': 1.00, 'tea': 0.90, 'coffee': 0.80,
    'juice': 0.85, 'smoothie': 0.90,
}
```

## Confidence → UI mapping (Smart Scan result sheet)
```
confidence ≥ 0.80 → high   → [✓ Xác nhận {ml}ml] — 1 tap
confidence ≥ 0.60 → medium → slider preset + [✓ Xác nhận]
confidence < 0.60 → low    → "Chỉnh lại" + slider full range
```

## Model Architecture (on-device)
```python
base = MobileNetV3Small(input_shape=(224,224,3), include_top=False, weights='imagenet')
# Head A: container class (softmax, 10 classes)
# Head B: fill level (sigmoid, 1 output)
# Head C: liquid type (softmax, 5 classes)  ← thêm so với version cũ
# Quantization: float16 → ~1.2MB
```

## Data Collection Plan
```
1,500 ảnh minimum:
  10 container types × 10 fill levels × 5 angles × 3 lighting
  Drink types: nước lọc, trà, cà phê đá, nước cam, sinh tố
Annotation tool: Label Studio
```

## Flutter Integration
```dart
// core/services/vision_service.dart
class VisionService {
  static const _modelPath = 'assets/models/aquatrack_v1.tflite';

  Future<VisionResult> estimateLocal(File imageFile) async {
    // preprocess → 224×224 normalized
    // run inference → {container, fill_level, liquid_type}
    // apply hydration coeff
    // return VisionResult with confidence
  }
}
```

## Prompt Template
```
[ML AGENT] [style:terse]
Task: <train | convert | debug | integrate>
File: aquatrack_ml/<path>

<paste code / error>
```
