# Grill-Me - Intensive Planning Review

## Mục đích
Conduct intensive questioning để thoroughly examine plan/design, đảm bảo comprehensive shared understanding bằng cách systematically explore decision tree.

## Methodology
- Interview user relentlessly về plan/design cho đến khi reach shared understanding
- Resolve từng branch của decision tree
- Present questions individually, one at a time
- Mỗi inquiry include recommended answer từ agent

## Khi nào trigger
- User request stress-testing của plans
- Design reviews
- Explicitly ask "grill me"
- Trước khi start implementation lớn

## Protocol quan trọng
Trước khi ask questions, attempt to extract relevant information từ codebase directly rather than rely solely on user responses.

## Outcome
Process systematically walks through interconnected design decisions, addressing dependencies giữa choices để achieve mutual clarity về tất cả aspects của proposed plan/design.

## Áp dụng cho AquaTrack:

### Before implementing new screens:
- Grill về UX flow và edge cases
- Data flow giữa Riverpod providers
- API integration requirements
- Performance considerations

### Before architecture changes:
- Impact lên existing code
- Migration strategy
- Rollback plan
- Testing approach

### Before ML integration:
- Model accuracy requirements
- Fallback behaviors
- Performance constraints
- Data privacy concerns

## Example Questions cho AquaTrack:
- "How will the Smart Scan handle low-light conditions?"
- "What happens when API calls fail during drink logging?"
- "How will offline mode affect the Coach recommendations?"
- "What's the fallback if TFLite model fails to load?"