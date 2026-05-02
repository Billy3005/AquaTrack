# agents/docs.md — Docs Agent

> Load khi viết README, report, tài liệu kỹ thuật, commit message

## Rules
```
Nội bộ  : tiếng Việt
Public  : tiếng Anh
Format  : Markdown ngắn · bảng thay danh sách dài
Không   : giải thích lan man · lặp code đã có
```

## Commit Convention
```
feat     : tính năng mới
fix      : sửa bug
refactor : cải thiện không đổi behavior
docs     : cập nhật tài liệu
chore    : config, deps, build

feat: add camera screen with TFLite inference
fix: null check when vision confidence is low
docs: update API spec for /estimate
```

## README Template
```markdown
# <Module>
> <1 câu mô tả>

## Cài đặt
\`\`\`bash
<lệnh>
\`\`\`

## Chạy
\`\`\`bash
<lệnh>
\`\`\`

## Cấu trúc
<tree ngắn hoặc bảng>
```

## Prompt Template
```
[DOCS AGENT]
Loại: <README | report | commit | API spec>
Đối tượng: <bản thân | giảng viên | public>
Task: <mô tả ngắn>

<paste draft nếu có>
```
