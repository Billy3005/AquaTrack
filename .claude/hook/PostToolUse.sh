#!/bin/bash
# .claude/hooks/PostToolUse.sh
# Chạy sau mỗi lần Claude dùng tool (edit file, bash...)
# Mục đích: tự động stage + gợi ý commit message

TOOL="$1"        # tên tool vừa dùng
FILE="$2"        # file vừa được sửa (nếu có)

# Chỉ xử lý khi tool là file edit
if [[ "$TOOL" == "Edit" || "$TOOL" == "Write" || "$TOOL" == "MultiEdit" ]]; then
  # Auto stage file vừa sửa
  if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    git add "$FILE" 2>/dev/null
    echo "✅ Staged: $FILE"
  fi
fi
