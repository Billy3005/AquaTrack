#!/bin/bash
# .claude/hooks/PreCompact.sh
# Chạy trước khi Claude nén context (conversation dài)
# Mục đích: lưu trạng thái quan trọng để không mất sau compact

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_FILE=".claude/.snapshots/pre_compact_$TIMESTAMP.md"

mkdir -p .claude/.snapshots

cat > "$SNAPSHOT_FILE" << EOF
# Context Snapshot — $TIMESTAMP

## Git Status
$(git status --short 2>/dev/null)

## Current Branch
$(git branch --show-current 2>/dev/null)

## Recent Commits
$(git log --oneline -5 2>/dev/null)

## Current Task
$(cat .task 2>/dev/null || echo "none")
EOF

echo "💾 Snapshot saved: $SNAPSHOT_FILE"
