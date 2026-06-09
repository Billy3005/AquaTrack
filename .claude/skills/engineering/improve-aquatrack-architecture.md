# Improve AquaTrack Architecture

## Mục tiêu
Cải thiện kiến trúc của AquaTrack app thông qua việc phân tích và tái cấu trúc các module, interface và implementation patterns trong Flutter frontend và FastAPI backend.

## Nguyên tắc thiết kế chính

### 1. Module Deepening cho Mobile App
- **Flutter Widgets**: Chuyển từ widget monolithic sang composable components
- **State Management**: Cải thiện Riverpod providers structure 
- **API Integration**: Tách biệt UI logic và business logic
- **Navigation Flow**: Giảm coupling giữa các screens

### 2. Backend Service Architecture  
- **API Endpoints**: Tách biệt route handlers và business logic
- **Data Layer**: Cải thiện SQLAlchemy models và repository patterns
- **Service Layer**: Tạo clean interfaces cho business operations
- **Error Handling**: Standardized error responses và logging

## Phương pháp phân tích

### Flutter Analysis Heuristics
```
📱 WIDGET COUPLING:
- Widgets trực tiếp gọi API calls → cần service layer
- State shared qua multiple providers → cần state normalization  
- Navigation logic spread across widgets → cần navigation service
- Business logic trong UI widgets → cần business logic layer

📊 STATE MANAGEMENT:
- Provider dependencies tạo circular references
- State mutations không controlled → cần immutable patterns
- Multiple sources of truth cho cùng data
- Memory leaks từ listeners không disposed

🔌 API INTEGRATION:
- Direct HTTP calls trong widgets → cần repository pattern
- Error handling scattered → cần centralized error management
- No offline capabilities → cần data caching strategy
- Authentication logic mixed with business logic
```

### Backend Analysis Heuristics  
```
🔧 API STRUCTURE:
- Fat controllers với business logic → cần service extraction
- Direct database access trong endpoints → cần repository layer
- No input validation consistency → cần standardized schemas
- Multiple responsibilities trong single endpoint

🗃️ DATA LAYER:
- SQLAlchemy models với business logic → cần domain models
- No transaction management → cần unit of work pattern
- Tight coupling giữa models và database → cần abstractions
- No data access optimization → cần query optimization

🔐 CROSS-CUTTING CONCERNS:
- Authentication logic scattered → cần middleware/decorators
- Logging inconsistent → cần structured logging
- No monitoring/metrics → cần observability layer
- Configuration hardcoded → cần config management
```

## Design Generation Process

### Phase 1: Architecture Assessment
Phân tích codebase hiện tại và identify:
- Tight coupling points
- Shallow modules/services  
- Missing abstractions
- Performance bottlenecks
- Testability issues

### Phase 2: Parallel Design Approaches
Tạo multiple design alternatives:

**Approach A: Minimalist Clean Architecture**
- Minimal layers với clean boundaries
- Feature-based folder structure
- Simple dependency injection

**Approach B: Domain-Driven Design**
- Rich domain models
- Bounded contexts
- Event-driven architecture

**Approach C: Microservice-Ready Architecture**
- Service-oriented design
- API-first approach
- Independent deployable units

**Approach D: Flutter-Optimized Architecture**
- Widget-centric design
- State management optimization
- Platform-specific implementations

### Phase 3: Implementation Strategy
Chọn best approach và create:
- Refactoring roadmap
- Migration strategy  
- Testing approach
- Performance benchmarks

## AquaTrack-Specific Terminology

### Flutter Terms
- **Screen**: Top-level navigable widget (8 screens trong AquaTrack)
- **Component**: Reusable UI widgets (drop widget, chart widgets)
- **Provider**: Riverpod state management unit
- **Repository**: Data access abstraction layer
- **Service**: Business logic encapsulation
- **Model**: Data transfer objects

### Backend Terms
- **Endpoint**: FastAPI route handler
- **Service**: Business logic layer
- **Repository**: Data access pattern
- **Schema**: Pydantic input/output models
- **Middleware**: Cross-cutting concern handlers
- **Domain**: Business rule encapsulation

## Output Format

Tạo GitHub issue RFC với:

```markdown
# 🏗️ Architecture Improvement: [Component Name]

## Problem Analysis
- Current architecture issues
- Coupling problems identified
- Performance/maintainability impacts

## Design Options

### Option 1: [Approach Name]
**Pros**: 
**Cons**:
**Implementation effort**: 

### Option 2: [Approach Name] 
**Pros**:
**Cons**: 
**Implementation effort**:

## Recommended Approach
[Detailed rationale với code examples]

## Refactoring Plan
1. [ ] Step 1 với specific files
2. [ ] Step 2 với testing strategy
3. [ ] Step 3 với migration approach

## Success Metrics
- Code complexity reduction
- Test coverage improvement  
- Performance benchmarks
- Developer experience gains
```

## Usage Workflow

1. **Trigger**: `/improve-aquatrack-architecture [component]`
2. **Analysis**: Scan target component và dependencies
3. **Generation**: Create multiple design alternatives
4. **Recommendation**: Select best approach với rationale
5. **Planning**: Create step-by-step refactoring plan
6. **Validation**: Provide success metrics

## Examples

```bash
# Analyze toàn bộ Flutter app architecture
/improve-aquatrack-architecture flutter-app

# Focus on specific component  
/improve-aquatrack-architecture api-integration
/improve-aquatrack-architecture state-management
/improve-aquatrack-architecture backend-services

# Cross-cutting concerns
/improve-aquatrack-architecture error-handling
/improve-aquatrack-architecture authentication-flow
```

## Integration với AquaTrack Workflow

- Chạy sau mỗi major feature completion
- Kết hợp với `/code-review` để identify architecture issues
- Use với `/tdd` để đảm bảo refactoring safety
- Coordinate với backend expansion phases