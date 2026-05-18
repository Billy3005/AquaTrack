# TDD Workflow Activation

Khi skill này được invoke, bắt đầu Test-Driven Development workflow.

## Instructions for Claude

1. **Read TDD methodology** từ `.claude/skills/engineering/tdd.md`

2. **Current context analysis:**
   - File nào đang được work on?
   - Feature/component gì đang implement?
   - Tests đã có chưa?

3. **TDD Cycle activation:**
   - Nếu chưa có tests: Start với tracer bullet test
   - Nếu đã có tests: Continue với next behavior
   - Guide user through RED-GREEN-REFACTOR cycle

4. **Provide specific guidance:**
   - Suggest test structure phù hợp với tech stack (Flutter: widget_test, Python: pytest)
   - Focus on public interface testing
   - Remind về anti-patterns cần avoid

## Example Response Template:

```
🔴 TDD WORKFLOW ACTIVATED

Đang implement: [feature/component name]
Current state: [analyzing existing code/tests]

Next TDD step:
[ ] RED - Write failing test for: [specific behavior]
[ ] GREEN - Minimal implementation to pass
[ ] REFACTOR - Clean up while keeping tests green

Test suggestion:
[specific test code or structure]
```