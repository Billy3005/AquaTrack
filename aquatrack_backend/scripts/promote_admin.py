"""Grant (or revoke) Admin Console access for one existing account.

This is the *production* counterpart to seed_admin_demo.py. That script is a
development fixture: it invents accounts with a password written down in this
repository, and refuses to run anywhere real. This one does the opposite — it
never creates an account and never touches a password. It only moves an
existing, real user up or down the staff ladder, which is the single
privilege-granting operation the system has no UI for (by design: a console
that can promote its own operators is a console that can be used to escalate).

    python scripts/promote_admin.py you@example.com
    python scripts/promote_admin.py you@example.com --role operations
    python scripts/promote_admin.py someone@example.com --role user   # revoke
    python scripts/promote_admin.py you@example.com --list            # who is staff

Against Railway, point DATABASE_URL at production first:

    # PowerShell
    $env:DATABASE_URL="postgresql://...";  python scripts/promote_admin.py you@example.com

Every change is written to `audit_logs` in the same transaction, attributed to
this script, so a promotion can never happen without a record of it.
"""

import argparse
import json
import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Vietnamese names go to stdout; the default Windows console codepage cannot
# encode them and would crash the run mid-report.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from app.core.admin_roles import ROLE_RANK  # noqa: E402
from app.core.admin_roles import ROLE_LABELS, ROLE_SUPER_ADMIN, ROLE_USER, STAFF_ROLES
from app.core.database import SessionLocal, engine  # noqa: E402
from app.models import AuditLog, User  # noqa: E402

VALID_ROLES = [ROLE_USER, *STAFF_ROLES]


def describe_target_db() -> str:
    """A human-readable name for the database about to be modified.

    Printed before the confirmation prompt because the whole risk of this
    script is running it against the wrong database.
    """
    url = engine.url
    if url.drivername.startswith("sqlite"):
        return f"SQLite · {url.database}"
    return f"{url.drivername} · {url.host}/{url.database}"


def list_staff(db) -> None:
    staff = (
        db.query(User)
        .filter(User.role.in_(STAFF_ROLES))
        .order_by(User.role, User.email)
        .all()
    )
    if not staff:
        print("Chưa có tài khoản nhân sự nào.")
        return
    print(f"{len(staff)} tài khoản nhân sự:")
    for user in staff:
        state = "" if user.is_active else "  [ĐÃ KHOÁ]"
        label = ROLE_LABELS.get(user.role, user.role)
        print(
            f"  {label:<12} {user.email:<36} {user.full_name or user.username}{state}"
        )


def confirm(prompt: str) -> bool:
    """Typed confirmation. Deliberately not a y/n — this changes who can wipe
    other people's data, and should cost more than one keystroke."""
    print(f"\n{prompt}")
    answer = input("Gõ 'YES' để xác nhận: ").strip()
    return answer == "YES"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("email", nargs="?", help="Email của tài khoản đã tồn tại")
    parser.add_argument(
        "--role",
        default=ROLE_SUPER_ADMIN,
        choices=VALID_ROLES,
        help=f"Vai trò cần đặt (mặc định {ROLE_SUPER_ADMIN})",
    )
    parser.add_argument(
        "--list", action="store_true", help="Chỉ liệt kê nhân sự hiện có rồi thoát"
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Bỏ qua hỏi xác nhận (chỉ dùng trong script tự động)",
    )
    args = parser.parse_args()

    engine.echo = False
    db = SessionLocal()
    try:
        print(f"Database: {describe_target_db()}\n")

        if args.list:
            list_staff(db)
            return

        if not args.email:
            parser.error("cần email, hoặc dùng --list")

        user = db.query(User).filter(User.email == args.email).first()
        if not user:
            # Creating the account here would mean this script could mint
            # privileged users out of nothing. Sign up through the app first.
            sys.exit(
                f"Không tìm thấy tài khoản {args.email}.\n"
                "Script này chỉ nâng/hạ quyền tài khoản đã tồn tại — hãy đăng ký "
                "qua ứng dụng trước."
            )

        previous = user.role or ROLE_USER
        if previous == args.role:
            print(f"{user.email} đã ở vai trò '{args.role}' rồi. Không có gì thay đổi.")
            return

        # Never leave the console with no way in.
        if previous == ROLE_SUPER_ADMIN and args.role != ROLE_SUPER_ADMIN:
            remaining = (
                db.query(User)
                .filter(
                    User.role == ROLE_SUPER_ADMIN,
                    User.is_active.is_(True),
                    User.id != user.id,
                )
                .count()
            )
            if remaining == 0:
                sys.exit(
                    "Từ chối: đây là super admin đang hoạt động cuối cùng. "
                    "Hãy nâng một tài khoản khác lên super admin trước."
                )

        print(f"Tài khoản : {user.full_name or user.username} <{user.email}>")
        print(f"Trạng thái: {'đang hoạt động' if user.is_active else 'ĐÃ BỊ KHOÁ'}")
        print(f"Vai trò   : {previous}  →  {args.role}")

        if ROLE_RANK.get(args.role, 0) > 0:
            print(
                "\nCẢNH BÁO: tài khoản này sẽ truy cập được Admin Console và "
                "dữ liệu của mọi người dùng."
            )

        if not args.yes and not confirm("Xác nhận đổi vai trò?"):
            print("Đã huỷ. Không có gì thay đổi.")
            return

        user.role = args.role
        db.add(
            AuditLog(
                actor_id=None,
                actor_name="scripts/promote_admin.py",
                actor_role="system",
                action="user.role_change",
                action_label="Đổi vai trò nhân sự",
                tone="purple",
                target_type="user",
                target_id=user.id,
                target_label=f"{user.id} · {user.full_name or user.username}",
                reason=f"promote_admin.py: {previous} → {args.role}",
                meta=json.dumps(
                    {"from": previous, "to": args.role, "email": user.email},
                    ensure_ascii=False,
                ),
                created_at=datetime.utcnow(),
            )
        )
        db.commit()

        print(f"\nXong. {user.email} giờ là '{args.role}'.")
        print("Đã ghi vào audit_logs.")
        if ROLE_RANK.get(args.role, 0) > 0:
            print("\nĐăng nhập console bằng chính mật khẩu ứng dụng của tài khoản này.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
