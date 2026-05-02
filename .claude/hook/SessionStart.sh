#!/bin/bash
# .claude/hooks/SessionStart.sh
# Chạy tự động mỗi khi Claude Code khởi động session mới
# Mục đích: nạp context dự án + hiển thị trạng thái hiện tại

echo "=== AquaTrack Session Started ==="
echo ""

# Hiện branch hiện tại
echo "📌 Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"

# Hiện staged/unstaged files
CHANGED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
echo "📝 Files changed: $CHANGED"

# Hiện task đang làm (đọc từ .task nếu có)
if [ -f ".task" ]; then
  echo "🎯 Current task: $(cat .task)"
fi

echo ""
echo "=== Agents available ==="
echo "  Flutter  → .claude/agents/flutter.md"
echo "  ML       → .claude/agents/ml.md"
echo "  Backend  → .claude/agents/backend.md"
echo "  Docs     → .claude/agents/docs.md"
echo ""
