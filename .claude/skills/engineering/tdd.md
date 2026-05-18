# TDD - Test-Driven Development

## Quy trình TDD cho AquaTrack

### Nguyên tắc cốt lõi
Tests phải verify behavior thông qua public interfaces, không phải implementation details. Code có thể được refactor hoàn toàn nhưng tests vẫn valid nếu focus vào "what" chứ không phải "how".

### Workflow TDD

#### 1. Planning Phase (trước khi code)
- Confirm interface changes với user/stakeholder
- Prioritize behaviors cần test (không phải tất cả edge cases)
- Design for testability
- Document priority behaviors

#### 2. Tracer Bullet
- Write 1 test (RED) → fails
- Write minimal passing code (GREEN) → passes

#### 3. Incremental Expansion
Cho mỗi behavior còn lại:
- Single test tại 1 thời điểm
- Minimal code chỉ satisfy current test
- Avoid speculative features
- Focus on observable behavior

#### 4. Refactoring (sau khi tất cả tests pass)
- Eliminate duplication
- Deepen module interfaces
- Apply SOLID principles
- Chỉ refactor khi ở GREEN state

### Verification Checklist mỗi cycle:
- [ ] Test describes behavior, not implementation
- [ ] Test dùng exclusively public interfaces
- [ ] Test survives internal code changes
- [ ] Implementation chỉ chứa necessary code
- [ ] Không có speculative features

### Anti-Pattern phải tránh:
❌ **Horizontal Slicing**: Viết all tests first, then all implementation
✅ **Vertical Slicing**: One test feeds one implementation cycle

### Áp dụng cho AquaTrack:
- **Flutter widgets**: Test UI behavior thông qua widget testing
- **Riverpod providers**: Test state management behavior
- **API calls**: Test response handling, not HTTP details
- **ML features**: Test prediction behavior, not model internals