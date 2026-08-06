"""Delete leftover test accounts before opening the app to the public.

Two independent conditions must BOTH hold before a row is even a candidate:

  1. the address looks machine-made (scripts/backup_db.py's detector), and
  2. the account has never logged a drink.

Either one alone is not enough. An email pattern is a guess — a real person
can have a silly address — and plenty of genuine users sign up without logging
anything on day one. Requiring both means the script only removes accounts that
look synthetic *and* have produced nothing.

Staff accounts are never touched, whatever their address.

    python scripts/cleanup_test_accounts.py                 # dry run (default)
    python scripts/cleanup_test_accounts.py --delete        # actually delete
    python scripts/cleanup_test_accounts.py --keep a@b.com  # spare one

BACK UP FIRST: python scripts/backup_db.py
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from sqlalchemy import func, select  # noqa: E402

from app.core.admin_roles import STAFF_ROLES  # noqa: E402
from app.core.database import SessionLocal, engine  # noqa: E402
from app.models import AuditLog, IntakeLog, User  # noqa: E402
from scripts.backup_db import describe_target  # noqa: E402
from scripts.backup_db import SEED_DOMAINS, looks_machine_made


def find_candidates(db, keep: set) -> tuple:
    log_counts = dict(
        db.query(IntakeLog.user_id, func.count(IntakeLog.id))
        .group_by(IntakeLog.user_id)
        .all()
    )

    candidates = []
    seeded = 0
    spared = []  # flagged by the address, but they have logged real data
    for user in db.query(User).order_by(User.created_at).all():
        if user.email in keep:
            continue
        if (user.role or "user") in STAFF_ROLES:
            continue  # staff are never collateral damage

        # Demo fixtures belong to seed_admin_demo.py --wipe, which removes them
        # as a set. Deleting them piecemeal here would leave a half-populated
        # demo dataset and make the two scripts disagree about what exists.
        if (user.email or "").lower().endswith(SEED_DOMAINS):
            seeded += 1
            continue

        name = f"{user.username or ''} {user.full_name or ''}"
        if not looks_machine_made(user.email, name):
            continue

        logs = log_counts.get(user.id, 0)
        if logs:
            # Out of scope by design, but the operator should know it exists:
            # a `test@test.com` with real logs is still junk they may want gone.
            spared.append((user, logs))
            continue
        candidates.append(user)
    return candidates, seeded, spared


def delete_users(db, users: list) -> None:
    """Remove the accounts and everything hanging off them.

    audit_logs.actor_id is a real foreign key, so any row where a doomed
    account was the actor is detached rather than deleted — the log is
    append-only and must survive the account it describes.
    """
    ids = [u.id for u in users]

    db.query(AuditLog).filter(AuditLog.actor_id.in_(ids)).update(
        {AuditLog.actor_id: None}, synchronize_session=False
    )

    # The ORM cascades declared on User handle the child tables; deleting
    # through the session (not a bulk query) is what triggers them.
    for user in users:
        db.delete(user)
    db.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--delete", action="store_true", help="Thực sự xoá (mặc định chỉ xem trước)"
    )
    parser.add_argument(
        "--keep",
        action="append",
        default=[],
        metavar="EMAIL",
        help="Giữ lại email này dù bị đánh dấu (lặp lại được)",
    )
    args = parser.parse_args()

    engine.echo = False
    db = SessionLocal()
    try:
        print(f"Database: {describe_target()}\n")

        total = db.query(func.count(User.id)).scalar() or 0
        candidates, seeded, spared = find_candidates(db, set(args.keep))

        if seeded:
            print(
                f"Bỏ qua {seeded} tài khoản dữ liệu mẫu "
                "(xoá bằng: python scripts/seed_admin_demo.py --wipe)\n"
            )

        if not candidates:
            print(f"{total} tài khoản, không có cái nào đủ điều kiện xoá.")
            return

        print(f"{len(candidates)} / {total} tài khoản sẽ bị xoá:")
        print(f"  {'email':<44} {'tạo lúc':<12} vai trò")
        for user in candidates:
            created = user.created_at.strftime("%d/%m/%Y") if user.created_at else "—"
            print(f"  {user.email:<44} {created:<12} {user.role or 'user'}")

        survivors = total - len(candidates)
        print(f"\nCòn lại sau khi xoá: {survivors} tài khoản")

        if spared:
            print(
                f"\n{len(spared)} tài khoản trông cũng giống test nhưng ĐƯỢC GIỮ LẠI "
                "vì đã có dữ liệu thật:"
            )
            for user, logs in spared:
                print(f"  {user.email:<44} {logs:>4} lượt ghi nước")
            print("  Muốn xoá cả chúng thì phải xoá thủ công — script không tự làm.")

        if not args.delete:
            print(
                "\nĐây chỉ là xem trước — chưa xoá gì.\n"
                "Chạy lại với --delete để thực hiện (nhớ backup trước)."
            )
            return

        print("\nSắp xoá vĩnh viễn các tài khoản trên cùng toàn bộ dữ liệu của họ.")
        if input("Gõ 'DELETE' để xác nhận: ").strip() != "DELETE":
            print("Đã huỷ. Không có gì thay đổi.")
            return

        delete_users(db, candidates)
        remaining = db.query(func.count(User.id)).scalar() or 0
        print(f"\nĐã xoá {len(candidates)} tài khoản. Còn lại {remaining}.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
