# skills/backend/fastapi_endpoint.md
# Skill: Tạo FastAPI endpoint chuẩn AquaTrack

## Template đầy đủ
```python
# app/api/v1/<resource>.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_db, get_current_uid
from app.schemas.<resource> import <Resource>Create, <Resource>Response
from app.services.<resource>_service import <Resource>Service

router = APIRouter(prefix="/<resource>", tags=["<resource>"])

@router.post("", response_model=<Resource>Response, status_code=201)
async def create(
    body: <Resource>Create,
    uid: str = Depends(get_current_uid),
    db: AsyncSession = Depends(get_db),
):
    return await <Resource>Service.create(db, uid, body)

@router.get("/{id}", response_model=<Resource>Response)
async def get_one(
    id: str,
    uid: str = Depends(get_current_uid),
    db: AsyncSession = Depends(get_db),
):
    item = await <Resource>Service.get(db, uid, id)
    if not item:
        raise HTTPException(status_code=404)
    return item
```

## Đăng ký trong main.py
```python
from app.api.v1.<resource> import router as <resource>_router
app.include_router(<resource>_router, prefix="/api/v1")
```
