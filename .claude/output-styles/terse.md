# output-styles/terse.md — Chỉ code, không văn phong

## Khi nào dùng
Khi chỉ cần code chạy được ngay, không cần giải thích.

## Kích hoạt
Thêm vào cuối prompt: `[style:terse]`

## Quy tắc khi terse mode
```
- Không mở đầu bằng "Dưới đây là..." hay "Tôi sẽ..."
- Không giải thích trừ khi logic thực sự phức tạp
- Comment ngắn nếu cần, không viết essay
- Nếu có nhiều file → tên file làm header, code theo sau
- Không tóm tắt sau code
```

## Ví dụ output tốt (terse)
```dart
// vision_service.dart
Future<VisionResult> estimateLocal(File image) async {
  final input = _preprocess(image);
  _interpreter.runForMultipleInputs([input], {0: _clsOut, 1: _fillOut});
  return VisionResult.fromOutputs(_clsOut, _fillOut);
}
```

## Ví dụ output tệ (không terse)
```
Dưới đây là code cho VisionService. Tôi đã implement theo pattern
offline-first mà bạn đề cập. Code sử dụng tflite_flutter để...
```
