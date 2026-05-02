# skills/ml/tflite_convert.md
# Skill: Convert Keras model → TFLite float16

## Dùng khi
Sau khi train xong model, cần export để tích hợp vào Flutter.

## Steps
```python
# 1. Load model
model = tf.keras.models.load_model('path/to/model.keras')

# 2. Convert
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

# 3. Save
with open('exports/aquatrack_v1.tflite', 'wb') as f:
    f.write(tflite_model)

# 4. Verify size
print(f"{len(tflite_model)/1024/1024:.2f} MB")  # target: < 2MB
```

## Copy vào Flutter
```bash
cp exports/aquatrack_v1.tflite ../aquatrack_app/assets/models/
```

## Khai báo trong pubspec.yaml
```yaml
flutter:
  assets:
    - assets/models/aquatrack_v1.tflite
```
