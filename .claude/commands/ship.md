# /ship — Build · Lint · Deploy trong 1 lệnh

## Dùng khi nào
Khi muốn push feature lên sau khi code xong.

## Claude sẽ làm theo thứ tự

### 1. Lint & Format
```bash
# Flutter
cd aquatrack_app && dart format . && flutter analyze

# Python
cd aquatrack_backend && black . && isort . && flake8 .
```

### 2. Test nhanh
```bash
# Flutter
flutter test

# Python
pytest tests/ -x -q
```

### 3. Build check
```bash
# Flutter (check không lỗi build)
flutter build apk --debug

# Python (check import)
python -c "from app.main import app; print('OK')"
```

### 4. Commit & Push
```bash
git add -A
git commit -m "feat: <Claude tự sinh commit message từ diff>"
git push origin $(git branch --show-current)
```

## Dùng
```
/ship                  → ship toàn bộ
/ship flutter          → chỉ ship Flutter
/ship backend          → chỉ ship Backend
/ship --no-test        → bỏ qua test (khẩn cấp)
```
