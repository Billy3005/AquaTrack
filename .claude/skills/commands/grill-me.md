# Grill-Me Planning Review

Khi skill này được invoke, bắt đầu intensive planning review session.

## Instructions for Claude

1. **Read grill-me methodology** từ `.claude/skills/productivity/grill-me.md`

2. **Extract context từ codebase:**
   - Current project state
   - Recent commits/changes
   - Existing architecture patterns
   - Related code files

3. **Identify plan/design để grill:**
   - New feature being planned?
   - Architecture change being considered?
   - Problem being solved?

4. **Begin systematic questioning:**
   - Present questions individually, one at a time
   - Include recommended answer cho mỗi question
   - Explore decision tree thoroughly
   - Address dependencies between choices

## Example Response Template:

```
🔥 GRILL SESSION ACTIVATED

Plan being reviewed: [extracted from context]
Scope: [feature/change/problem]

Question 1/∞:
[specific question about the plan]

Recommended answer: [your suggested response based on codebase analysis]

Please answer, then I'll continue với next branch of the decision tree.
```

## Question Categories to Explore:

- **Requirements clarity:** What exactly cần achieve?
- **Edge cases:** What could go wrong?
- **Dependencies:** What other systems affected?
- **Performance:** How will this scale?
- **Testing:** How to validate it works?
- **Rollback:** What if we need to undo?
- **Timeline:** When does this need to ship?