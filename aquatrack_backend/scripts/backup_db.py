"""Read-only backup of every table, plus a pre-launch audit of what is in there.

Written for the Railway free-tier volume deletion deadline: it needs no
`pg_dump` on PATH, because it goes through the SQLAlchemy driver the backend
already depends on. Point it at any database and it writes one JSON file.

    # local
    python scripts/backup_db.py

    # production (PowerShell) — DATABASE_PUBLIC_URL from the Railway Postgres
    # service's Variables tab; the internal .railway.internal host is not
    # reachable from your machine.
    $env:DATABASE_URL="postgresql://..."
    python scripts/backup_db.py

    python scripts/backup_db.py --audit-only    # look, don't write a file

The script never writes to the database. The file it produces, however,
contains emails, password hashes and Google subject IDs — it is personal data.
It lands in backups/, which is gitignored; keep it somewhere private and delete
it when it is no longer needed.

The audit section answers the question you actually have before a public
launch: which of these accounts are leftovers from testing, and would any of
them embarrass you on the leaderboard?
"""

import argparse
import json
import os
import re
import sys
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from sqlalchemy import MetaData, func, inspect, select  # noqa: E402

from app.core.database import engine  # noqa: E402

# Substrings that almost always mean "I made this while building the app".
TEST_EMAIL_MARKERS = (
    "test",
    "demo",
    "example.com",
    "mailinator",
    "yopmail",
    "abc@",
    "aaa@",
    "123@",
    "asd",
    "qwe",
)

# `aquatrack.com` is not a domain this project owns — the real one is
# aquatrack.vn. Anything addressed there was invented by a script or typed to
# get past a signup form.
FOREIGN_BRAND_DOMAINS = ("@aquatrack.com",)

# A run of digits this long in the local part is a timestamp, not a person:
# integration tests mint unique addresses like cv1781556080118250500@… .
# The substring list above misses these entirely, because nothing in them says
# "test".
MACHINE_DIGIT_RUN = re.compile(r"\d{8,}")


def looks_machine_made(email: str, name: str) -> bool:
    """Best-effort guess that a row came from a script or a throwaway signup.

    Deliberately errs towards flagging: this feeds a report a human reads
    before deleting anything, and a false positive costs one glance while a
    false negative leaves a weak-credential account live on a public app.
    """
    email = (email or "").lower()
    if any(marker in email for marker in TEST_EMAIL_MARKERS):
        return True
    if email.endswith(FOREIGN_BRAND_DOMAINS):
        return True
    if MACHINE_DIGIT_RUN.search(email.split("@")[0]):
        return True
    return "test" in (name or "").lower()


# Accounts created by scripts/seed_admin_demo.py — synthetic, removable with
# that script's own --wipe, and reported separately so they do not drown out
# the hand-made test accounts that need a human decision.
SEED_DOMAINS = ("@demo.aquatrack.vn", "@aquatrack.vn")


def json_default(value):
    """Make the driver's Python types survive a round trip through JSON."""
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, uuid.UUID):
        return str(value)
    if isinstance(value, (bytes, bytearray)):
        return value.decode("utf-8", errors="replace")
    if isinstance(value, set):
        return list(value)
    return str(value)


def describe_target() -> str:
    url = engine.url
    if url.drivername.startswith("sqlite"):
        return f"SQLite · {url.database}"
    return f"{url.drivername} · {url.host}/{url.database}"


def dump_all(metadata: MetaData) -> dict:
    """Every row of every table actually present in the database.

    Reflection is used rather than the app's models on purpose: a backup should
    capture what IS there, including tables an older migration left behind that
    no current model knows about.
    """
    data = {}
    with engine.connect() as conn:
        for table in metadata.sorted_tables:
            rows = [dict(row._mapping) for row in conn.execute(select(table))]
            data[table.name] = rows
            print(f"  {table.name:<24} {len(rows):>7,} dòng")
    return data


def audit(metadata: MetaData) -> None:
    """The pre-launch picture: who is real, who is a leftover."""
    if "users" not in metadata.tables:
        print("\n(Không có bảng users — bỏ qua phần rà soát.)")
        return

    users = metadata.tables["users"]
    cols = {c.name for c in users.columns}

    with engine.connect() as conn:
        total = conn.execute(select(func.count()).select_from(users)).scalar() or 0
        print(f"\n{'─' * 62}\nRÀ SOÁT TRƯỚC KHI LÊN CHỢ\n{'─' * 62}")
        print(f"Tổng tài khoản: {total:,}")

        if "is_active" in cols:
            locked = (
                conn.execute(
                    select(func.count()).select_from(users).where(~users.c.is_active)
                ).scalar()
                or 0
            )
            print(f"Đang bị khoá  : {locked:,}")

        if "role" in cols:
            print("\nTheo vai trò:")
            for role, count in conn.execute(
                select(users.c.role, func.count())
                .group_by(users.c.role)
                .order_by(func.count().desc())
            ):
                print(f"  {str(role or 'user'):<14} {count:>6,}")

        # Accounts that never logged a drink: either abandoned sign-ups or
        # throwaways from testing. Both are noise in the launch dashboard.
        if "intake_logs" in metadata.tables:
            logs = metadata.tables["intake_logs"]
            with_logs = (
                conn.execute(select(func.count(func.distinct(logs.c.user_id)))).scalar()
                or 0
            )
            print(f"\nChưa từng ghi nước: {total - with_logs:,} / {total:,}")

        # How much water each account has actually logged. This is the column
        # that separates a throwaway from a real account with a silly email —
        # without it the list below is just a pile of addresses.
        log_counts = {}
        if "intake_logs" in metadata.tables:
            logs = metadata.tables["intake_logs"]
            log_counts = dict(
                conn.execute(
                    select(logs.c.user_id, func.count()).group_by(logs.c.user_id)
                ).all()
            )

        # Emails that look like they were typed to get past a form.
        suspects = []
        seeded = 0
        for row in conn.execute(select(users)):
            record = dict(row._mapping)
            email = (record.get("email") or "").lower()

            # Rows from seed_admin_demo.py are synthetic by construction and
            # have their own `--wipe`. Counting them here would bury the
            # hand-made test accounts, which are the ones needing a decision.
            if email.endswith(SEED_DOMAINS):
                seeded += 1
                continue

            name = f"{record.get('username') or ''} {record.get('full_name') or ''}"
            if looks_machine_made(email, name):
                record["_logs"] = log_counts.get(record.get("id"), 0)
                suspects.append(record)

        if seeded:
            print(
                f"\nDữ liệu mẫu từ seed_admin_demo.py: {seeded} tài khoản"
                "  (xoá bằng: python scripts/seed_admin_demo.py --wipe)"
            )

        # Busiest first: anything at the top is probably a real account you use.
        suspects.sort(key=lambda r: r["_logs"], reverse=True)

        idle = sum(1 for r in suspects if r["_logs"] == 0)
        print(
            f"\nTrông giống tài khoản test: {len(suspects)}  ({idle} chưa ghi nước lần nào)"
        )
        print(f"  {'email':<42} {'lượt ghi':>9} {'xu':>8} {'XP':>8}")
        for record in suspects[:25]:
            print(
                f"  {record.get('email', ''):<42} {record['_logs']:>9,} "
                f"{record.get('coins', 0) or 0:>8,} {record.get('total_xp', 0) or 0:>8,}"
            )
        if len(suspects) > 25:
            print(f"  … và {len(suspects) - 25} tài khoản nữa")
        print(
            "\n  Dòng có 0 lượt ghi = gần như chắc chắn bỏ đi được.\n"
            "  Dòng nhiều lượt ghi = có thể là tài khoản bạn đang dùng thật — kiểm tra kỹ."
        )

        # Leaderboard embarrassment check: anything inflated by hand during
        # testing will sit at the top of the weekly ranking on launch day.
        for column, label in (("coins", "xu"), ("total_xp", "XP")):
            if column not in cols:
                continue
            query = select(users.c.email, users.c[column])
            for domain in SEED_DOMAINS:
                query = query.where(~users.c.email.like(f"%{domain}"))
            print(f"\nTop 5 {label} (không tính dữ liệu mẫu):")
            for row in conn.execute(query.order_by(users.c[column].desc()).limit(5)):
                print(f"  {row[1] or 0:>10,}  {row[0]}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", help="Đường dẫn file backup (mặc định backups/…)")
    parser.add_argument(
        "--audit-only",
        action="store_true",
        help="Chỉ in báo cáo, không ghi file backup",
    )
    args = parser.parse_args()

    engine.echo = False
    print(f"Database: {describe_target()}\n")

    inspector = inspect(engine)
    if not inspector.get_table_names():
        sys.exit("Database rỗng — không có bảng nào để sao lưu.")

    metadata = MetaData()
    metadata.reflect(bind=engine)

    if not args.audit_only:
        print("Đang đọc dữ liệu:")
        data = dump_all(metadata)

        out_path = args.out
        if not out_path:
            stamp = datetime.now().strftime("%Y-%m-%d-%H%M")
            out_dir = os.path.join(os.path.dirname(__file__), "..", "backups")
            os.makedirs(out_dir, exist_ok=True)
            out_path = os.path.join(out_dir, f"aquatrack-backup-{stamp}.json")

        payload = {
            "exported_at": datetime.now(timezone.utc).isoformat(),
            "source": describe_target(),
            "tables": data,
        }
        with open(out_path, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, default=json_default)

        size_mb = os.path.getsize(out_path) / 1024 / 1024
        total_rows = sum(len(rows) for rows in data.values())
        print(
            f"\nĐã ghi {total_rows:,} dòng "
            f"({size_mb:.1f} MB) → {os.path.abspath(out_path)}"
        )
        print(
            "File này chứa email và mật khẩu đã băm. Giữ nơi riêng tư, "
            "xoá khi không cần nữa."
        )

    audit(metadata)


if __name__ == "__main__":
    main()
