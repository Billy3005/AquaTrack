# Diagnose Debugging Session

Khi skill này được invoke, bắt đầu structured debugging workflow.

## Instructions for Claude

1. **Read diagnose methodology** từ `.claude/skills/engineering/diagnose.md`

2. **Identify bug/issue:**
   - What's the reported problem?
   - Current symptoms?
   - Error messages/logs available?

3. **Execute 6-phase diagnosis:**

### Phase 1: Build Feedback Loop (CRITICAL)
- Tạo fast, deterministic, agent-runnable pass/fail signal
- Priority: failing test > HTTP script > CLI invocation > manual repro

### Phase 2: Reproduce
- Execute feedback loop
- Confirm exact failure
- Verify reproducibility

### Phase 3: Hypothesize  
- Generate 3-5 ranked hypotheses
- Each must be falsifiable
- Present to user cho domain knowledge input

### Phase 4: Instrument
- Map probes to specific predictions
- Change one variable per test
- Use debugger/targeted logs/profiling

### Phase 5: Fix & Test
- Write regression test first (if suitable seam exists)
- Apply fix
- Verify original issue resolved

### Phase 6: Cleanup
- Remove debug instrumentation
- Document root cause
- Consider architectural improvements

## Example Response Template:

```
🔍 DEBUGGING SESSION ACTIVATED

Issue: [problem description]
Current symptoms: [what's observed]

PHASE 1 - Building Feedback Loop:
Priority approach: [failing test/HTTP script/CLI]
Goal: Create deterministic signal that reproduces the bug

[specific implementation of feedback loop]

Ready to proceed to reproduction phase?
```