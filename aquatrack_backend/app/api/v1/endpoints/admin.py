"""Admin Console API.

Every route here is staff-only. Read routes need the `data.view` capability
(all four staff roles have it); each write route names the exact capability from
the console's permission matrix, so the server and the UI's disabled-button
logic are driven by the same table (app/core/admin_roles.py).
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.api.deps import get_current_admin, require_cap
from app.core.admin_roles import ROLE_LABELS, capabilities_of
from app.core.database import get_db
from app.models.user import User
from app.schemas.admin import (
    GrantRequest,
    IssueResetCodeRequest,
    LockUserRequest,
    ResetUserRequest,
    UnlockUserRequest,
)
from app.services import admin_service
from app.services.admin_service import AdminActionError

router = APIRouter()


def _client_ip(request: Request) -> Optional[str]:
    """Prefer the proxy-forwarded address — Railway terminates TLS upstream, so
    request.client.host would otherwise log the proxy for every action."""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None


def _load_target(db: Session, user_id: str) -> User:
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy người dùng"
        )
    return target


# ── session ──────────────────────────────────────────────────────────────────


@router.get("/me")
async def admin_me(admin: User = Depends(get_current_admin)):
    """Who am I and what am I allowed to do — the console's bootstrap call.

    Shipping the capability map means the UI can grey out actions the caller
    would only get a 403 from, without hard-coding the matrix in the frontend.
    """
    return {
        "id": admin.id,
        "name": admin.full_name or admin.username,
        "email": admin.email,
        "role": admin.role,
        "roleLabel": ROLE_LABELS.get(admin.role, admin.role),
        "capabilities": capabilities_of(admin.role),
    }


# ── dashboard ────────────────────────────────────────────────────────────────


@router.get("/overview")
async def overview(
    range_days: int = Query(30, ge=7, le=90, alias="range"),
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("data.view")),
):
    return admin_service.get_overview(db, range_days=range_days)


# ── users ────────────────────────────────────────────────────────────────────


@router.get("/users")
async def list_users(
    q: str = "",
    user_status: str = Query("all", alias="status"),
    level: str = "all",
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=5, le=100),
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("data.view")),
):
    return admin_service.list_users(
        db,
        q=q,
        status=user_status,
        level_bucket=level,
        page=page,
        page_size=page_size,
    )


@router.get("/users/export")
async def export_users(
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("data.export")),
):
    """CSV of every user. Logged like any other sensitive action — an export of
    personal data is exactly the kind of thing the audit trail exists for."""
    csv_text = admin_service.users_csv(db)
    total = csv_text.count("\n") - 1
    admin_service.record_audit(
        db,
        admin,
        "users.export",
        target_type="report",
        target_label=f"{max(total, 0)} bản ghi",
        reason="Xuất toàn bộ danh sách người dùng",
        ip_address=_client_ip(request),
    )
    db.commit()

    return StreamingResponse(
        iter([csv_text]),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="aquatrack-users.csv"'},
    )


@router.get("/users/{user_id}")
async def user_detail(
    user_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("data.view")),
):
    detail = admin_service.get_user_detail(db, user_id)
    if not detail:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy người dùng"
        )
    return detail


@router.post("/users/{user_id}/lock")
async def lock_user(
    user_id: str,
    payload: LockUserRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("user.lock")),
):
    target = _load_target(db, user_id)
    try:
        return admin_service.lock_user(
            db, admin, target, payload.reason, ip=_client_ip(request)
        )
    except AdminActionError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


@router.post("/users/{user_id}/unlock")
async def unlock_user(
    user_id: str,
    payload: UnlockUserRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("user.lock")),
):
    target = _load_target(db, user_id)
    try:
        return admin_service.unlock_user(
            db, admin, target, payload.reason, ip=_client_ip(request)
        )
    except AdminActionError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


@router.post("/users/{user_id}/reset")
async def reset_user(
    user_id: str,
    payload: ResetUserRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("user.reset")),
):
    if payload.confirm != "RESET":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cần gõ đúng RESET để xác nhận",
        )
    target = _load_target(db, user_id)
    try:
        return admin_service.reset_user_data(
            db, admin, target, payload.reason, ip=_client_ip(request)
        )
    except AdminActionError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


@router.post("/users/{user_id}/password-reset")
async def issue_password_reset(
    user_id: str,
    payload: IssueResetCodeRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("user.password_reset")),
):
    """Mint a reset code for a user who cannot receive the emailed one.

    The response body carries the plaintext code — it is the only copy, and the
    only route on this API that returns a credential. Nothing else logs or
    stores it; see admin_service.issue_password_reset_code.
    """
    target = _load_target(db, user_id)
    try:
        return admin_service.issue_password_reset_code(
            db, admin, target, payload.reason, ip=_client_ip(request)
        )
    except AdminActionError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


@router.post("/users/{user_id}/grant")
async def grant_rewards(
    user_id: str,
    payload: GrantRequest,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("user.grant")),
):
    target = _load_target(db, user_id)
    try:
        return admin_service.grant_rewards(
            db,
            admin,
            target,
            coins=payload.coins,
            xp=payload.xp,
            reason=payload.reason,
            ip=_client_ip(request),
        )
    except AdminActionError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


# ── audit ────────────────────────────────────────────────────────────────────


@router.get("/audit")
async def audit_log(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=5, le=100),
    action: str = "all",
    actor_id: Optional[str] = None,
    target_id: Optional[str] = None,
    q: str = "",
    db: Session = Depends(get_db),
    admin: User = Depends(require_cap("audit.view")),
):
    return admin_service.list_audit(
        db,
        page=page,
        page_size=page_size,
        action=action,
        actor_id=actor_id,
        target_id=target_id,
        q=q,
    )
