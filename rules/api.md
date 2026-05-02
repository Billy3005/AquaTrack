# rules/api.md
# Áp dụng cho: aquatrack_backend/app/api/**

## Rules tự động áp dụng cho mọi file trong src/api/

```
1. Mọi endpoint PHẢI có Depends(get_current_uid) — trừ /health
2. Response PHẢI dùng Pydantic response_model
3. Lỗi dùng HTTPException với detail rõ ràng
4. Không business logic trong router — chuyển xuống service
5. Validate input bằng Pydantic trước khi xử lý
6. Log error với logger, không print()
```

## Template endpoint chuẩn
```python
@router.post("/intake", response_model=IntakeResponse, status_code=201)
async def create_intake(
    body: IntakeCreate,
    uid: str = Depends(get_current_uid),
    db: AsyncSession = Depends(get_db),
):
    return await IntakeService.create(db, uid, body)
```
