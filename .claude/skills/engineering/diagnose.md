# Diagnose - Structured Debugging Methodology

## Overview
Structured approach để resolve difficult bugs và performance issues. Focus on building reliable feedback loop, then systematically reproduce, hypothesize, instrument, and fix.

## 6-Phase Process

### Phase 1: Build Feedback Loop ⭐
Đây là **"the skill"** - tạo "fast, deterministic, agent-runnable pass/fail signal for the bug."

**Priority-ordered construction methods:**
1. Failing test (unit, integration, e2e)
2. HTTP scripts against dev servers
3. CLI invocations với fixture inputs và snapshot diffs
4. Headless browser automation (Playwright/Puppeteer)
5. Minimal throwaway harnesses
6. Property/fuzz testing loops
7. Human-in-the-loop bash scripts (last resort)

**Loop optimization principles:**
- Maximize speed through caching và narrowed scope
- Sharpen signal bằng cách assert on specific symptoms
- Improve determinism through pinned times, seeded RNGs, isolated environments

### Phase 2: Reproduce
- Execute feedback loop và verify exact failure
- Reproducibility holds across multiple runs
- Symptom precisely captured
- **Không advance without confirmed reproduction**

### Phase 3: Hypothesize
- Generate 3–5 ranked hypotheses before testing any
- Mỗi hypothesis phải falsifiable với testable prediction
- "If X causes bug, then changing Y will eliminate/worsen it"
- Present hypotheses to user cho domain-knowledge input

### Phase 4: Instrument
- Map mỗi probe to specific Phase 3 predictions
- Change one variable per test

**Tool hierarchy:**
1. Debugger/REPL inspection
2. Targeted logs tại hypothesis-distinguishing boundaries
3. Avoid unfocused logging

Tag debug statements với unique prefixes (e.g., `[DEBUG-a4f2]`) for easy cleanup.

### Phase 5: Fix and Regression Test
- Write regression test trước apply fix
- Sequence: Convert repro → failing test → fix → test passes → rerun original loop

### Phase 6: Cleanup and Post-Mortem
- Verify original scenario không reproduce nữa
- Regression test passes
- All debug instrumentation removed
- Commit message documents root cause
- Ask: "what architectural changes would prevent this?"

## Áp dụng cho AquaTrack:

### Flutter bugs:
- Widget test cho UI issues
- Integration test cho state management
- Golden test cho visual regressions

### API bugs:
- HTTP scripts với curl/Postman
- Unit tests cho response parsing
- Integration tests với test database

### ML model bugs:
- Unit tests với known input/output pairs
- Performance benchmarks
- Accuracy tests với validation dataset

### Performance issues:
- Flutter DevTools profiling
- API response time monitoring
- Memory usage tracking

## Example Debugging Scenarios:

### "Smart Scan không recognize cups"
1. **Feedback Loop**: Unit test với known cup images
2. **Reproduce**: Consistent failure với specific image types
3. **Hypothesize**: Lighting/angle/preprocessing issues
4. **Instrument**: Log preprocessing steps, model confidence scores
5. **Fix**: Adjust preprocessing pipeline
6. **Cleanup**: Remove debug logs, add regression test