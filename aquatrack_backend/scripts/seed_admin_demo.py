"""Seed a believable dataset for the Admin Console, plus the staff accounts.

Writes straight to the database (not through the API) because it needs to
back-date signups and water logs across ~10 weeks — something no public
endpoint will ever let you do, and rightly so.

    python scripts/seed_admin_demo.py                 # 200 users, 70 days
    python scripts/seed_admin_demo.py --users 500     # bigger
    python scripts/seed_admin_demo.py --staff-only    # just the 4 staff logins
    python scripts/seed_admin_demo.py --wipe          # drop previous demo rows

Demo rows are recognisable by their `@demo.aquatrack.vn` email domain, so
--wipe never touches a real account. Staff logins are printed at the end.

DEVELOPMENT ONLY, and there is no override flag. The script exits unless
ENVIRONMENT=development *and* the database is local, because it creates
privileged accounts whose password is written down in this repository. Set
SEED_ADMIN_PASSWORD to use your own instead of the documented default.
"""

import argparse
import json
import os
import random
import sys
import unicodedata
from datetime import datetime, timedelta
from datetime import timezone as dt_timezone

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Vietnamese names go to stdout; the default Windows console codepage (cp1252)
# cannot encode them and would crash the run at the very last print.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from app.core.admin_roles import ROLE_OPERATIONS  # noqa: E402
from app.core.admin_roles import ROLE_MARKETING, ROLE_SUPER_ADMIN, ROLE_SUPPORT
from app.core.config import settings  # noqa: E402
from app.core.database import SessionLocal, engine, init_db  # noqa: E402
from app.core.security import get_password_hash  # noqa: E402
from app.models import AuditLog, IntakeLog, User  # noqa: E402
from app.services.admin_service import REPORT_TZ, report_now  # noqa: E402

DEMO_DOMAIN = "demo.aquatrack.vn"
STAFF_DOMAIN = "aquatrack.vn"
DEFAULT_PASSWORD = "Admin@12345"

HO = [
    "Nguyễn",
    "Trần",
    "Lê",
    "Phạm",
    "Hoàng",
    "Vũ",
    "Đỗ",
    "Bùi",
    "Ngô",
    "Đặng",
    "Phan",
    "Lý",
]
DEM = [
    "Minh",
    "Thu",
    "Quốc",
    "Khánh",
    "Trọng",
    "Thanh",
    "Gia",
    "Phương",
    "Tuấn",
    "Hải",
    "Bảo",
    "Mai",
]
TEN = [
    "Anh",
    "Long",
    "Hà",
    "Bảo",
    "Vy",
    "Nghĩa",
    "Mai",
    "Huy",
    "Linh",
    "Kiệt",
    "Yến",
    "Duy",
    "Ngân",
    "Tú",
]

STAFF = [
    ("Lê Đức Hùng", "hung.le", ROLE_SUPER_ADMIN),
    ("Trần Vân Anh", "vananh.tran", ROLE_OPERATIONS),
    ("Nguyễn Mai Chi", "maichi.ng", ROLE_MARKETING),
    ("Phan Quang Duy", "duy.phan", ROLE_SUPPORT),
]

LIQUIDS = [("water", 1.0), ("tea", 0.9), ("coffee", 0.8), ("juice", 0.85)]
SOURCES = ["manual", "quick_log", "smart_scan", "ai_suggestion"]


def slugify(name: str) -> str:
    """Vietnamese name -> ascii email local-part."""
    stripped = unicodedata.normalize("NFD", name.replace("đ", "d").replace("Đ", "D"))
    ascii_name = "".join(c for c in stripped if unicodedata.category(c) != "Mn")
    return ascii_name.lower().replace(" ", ".")


def is_local_db() -> bool:
    url = str(engine.url)
    return "sqlite" in url or "localhost" in url or "127.0.0.1" in url


def guard_environment() -> None:
    """Refuse to run anywhere that could be real.

    This script creates privileged accounts whose password is written down in
    the repository. Two independent gates must both pass: the app must be in
    development mode, and the database must be local. Neither can be waived by
    a single stray environment variable.
    """
    if settings.ENVIRONMENT != "development":
        sys.exit(
            f"Refusing to run with ENVIRONMENT={settings.ENVIRONMENT!r}.\n"
            "This script seeds privileged accounts and is development-only."
        )
    if not is_local_db():
        sys.exit(
            f"Refusing to seed a non-local database ({engine.url.host}).\n"
            "Point DATABASE_URL at a local database instead."
        )


def wipe_demo(db) -> None:
    """Remove everything a previous run created, in FK-safe order."""
    demo_ids = [
        uid
        for (uid,) in db.query(User.id)
        .filter(User.email.like(f"%@{DEMO_DOMAIN}"))
        .all()
    ]
    staff_ids = [
        uid
        for (uid,) in db.query(User.id)
        .filter(User.email.like(f"%@{STAFF_DOMAIN}"))
        .all()
    ]
    all_ids = demo_ids + staff_ids
    if not all_ids:
        print("Nothing to wipe.")
        return
    db.query(IntakeLog).filter(IntakeLog.user_id.in_(all_ids)).delete(
        synchronize_session=False
    )
    db.query(AuditLog).filter(AuditLog.actor_id.in_(all_ids)).delete(
        synchronize_session=False
    )
    db.query(AuditLog).filter(AuditLog.target_id.in_(all_ids)).delete(
        synchronize_session=False
    )
    db.query(User).filter(User.id.in_(all_ids)).delete(synchronize_session=False)
    db.commit()
    print(f"Wiped {len(demo_ids)} demo users and {len(staff_ids)} staff accounts.")


def resolve_password() -> str:
    """The password the seeded staff accounts get.

    A fixed, repo-documented Super Admin password is only acceptable because
    this script refuses to touch anything but a local development database (see
    `guard_environment`). `SEED_ADMIN_PASSWORD` overrides it for anyone who
    wants a throwaway environment without credentials written down in git.
    """
    return os.environ.get("SEED_ADMIN_PASSWORD") or DEFAULT_PASSWORD


def seed_staff(db, password: str) -> User:
    """Create the four console logins. Idempotent — re-running only promotes.

    Role changes are the most privilege-sensitive write in the system, so each
    one lands in `audit_logs` in the same transaction, attributed to this
    script. Otherwise the only untraceable way to gain Super Admin would be the
    seeding path itself.
    """
    hashed = get_password_hash(password)
    super_admin = None
    now = datetime.utcnow()

    for full_name, local, role in STAFF:
        email = f"{local}@{STAFF_DOMAIN}"
        user = db.query(User).filter(User.email == email).first()
        if user:
            previous = user.role
            user.role = role
            user.is_active = True
            if previous != role:
                _audit_role_change(db, user, previous, role, now)
        else:
            user = User(
                email=email,
                hashed_password=hashed,
                username=full_name,
                full_name=full_name,
                role=role,
                is_active=True,
                is_verified=True,
                created_at=now - timedelta(days=200),
            )
            db.add(user)
            db.flush()  # need the id for the audit row
            _audit_role_change(db, user, None, role, now)
        if role == ROLE_SUPER_ADMIN:
            super_admin = user
    db.commit()
    return super_admin


def _audit_role_change(db, user, previous, new_role, now) -> None:
    db.add(
        AuditLog(
            actor_id=None,
            actor_name="scripts/seed_admin_demo.py",
            actor_role="system",
            action="user.role_change",
            action_label="Đổi vai trò nhân sự",
            tone="purple",
            target_type="user",
            target_id=user.id,
            target_label=f"{user.id} · {user.full_name}",
            reason=(f"Seed script: {previous or 'tài khoản mới'} → {new_role}"),
            meta=json.dumps({"from": previous, "to": new_role}, ensure_ascii=False),
            created_at=now,
        )
    )


def to_utc(local_dt: datetime) -> datetime:
    """Vietnamese wall-clock time -> the naive UTC value stored in the column."""
    return (
        local_dt.replace(tzinfo=REPORT_TZ)
        .astimezone(dt_timezone.utc)
        .replace(tzinfo=None)
    )


def seed_users(db, count: int, days: int) -> None:
    rng = random.Random(20260803)  # fixed seed → reproducible screenshots
    now = report_now()  # local wall clock, to match the hours generated below
    today = now.date()
    hashed = get_password_hash("Demo@12345")

    users, logs = [], []
    for i in range(count):
        name = f"{rng.choice(HO)} {rng.choice(DEM)} {rng.choice(TEN)}"
        # Signups spread over the window so the retention cohorts have depth.
        age_days = rng.randint(0, days)
        created = to_utc(now - timedelta(days=age_days, hours=rng.randint(0, 23)))

        goal = rng.choice([1800, 2000, 2200, 2500, 2800, 3000])
        # Three behavioural archetypes — a flat random population would make the
        # dashboard's funnel and retention charts look suspiciously uniform.
        archetype = rng.choices(
            ["committed", "casual", "churned"], weights=[0.3, 0.45, 0.25]
        )[0]

        user = User(
            email=f"{slugify(name)}{i}@{DEMO_DOMAIN}",
            hashed_password=hashed,
            username=name,
            full_name=name,
            role="user",
            is_active=rng.random() > 0.04,  # ~4% locked accounts
            is_verified=rng.random() > 0.2,
            daily_goal_ml=goal,
            calculated_daily_goal_ml=goal,
            created_at=created,
            last_login=to_utc(
                now - timedelta(days=rng.randint(0, min(age_days, 20) or 1))
            ),
            notifications_enabled=rng.random() > 0.15,
            timezone="Asia/Ho_Chi_Minh",
            coins=rng.randint(50, 4000),
            total_xp=0,
        )
        users.append(user)

        # How many of the days since signup this person actually logged on.
        active_days = {
            "committed": 0.9,
            "casual": 0.5,
            "churned": 0.35,
        }[archetype]
        # Churned users stop somewhere in the first third of their lifetime.
        stop_after = age_days if archetype != "churned" else int(age_days * 0.35)

        streak, longest, total_logs, total_ml, total_xp = 0, 0, 0, 0, 0
        for d in range(age_days, -1, -1):
            day = today - timedelta(days=d)
            days_since_signup = age_days - d
            if days_since_signup > stop_after:
                streak = 0
                continue
            if rng.random() > active_days:
                streak = 0
                continue

            # Committed users overshoot; casual ones hover just under goal.
            target = goal * rng.uniform(
                *{
                    "committed": (0.95, 1.35),
                    "casual": (0.5, 1.05),
                    "churned": (0.3, 0.9),
                }[archetype]
            )
            logged = 0
            while logged < target:
                volume = rng.choice([200, 250, 300, 350, 400, 500])
                liquid, factor = rng.choices(LIQUIDS, weights=[0.72, 0.12, 0.1, 0.06])[
                    0
                ]
                # Peaks around morning, lunch and early evening. Today is
                # truncated at the current hour — a "log" in the future would
                # make the console show drinks that have not happened yet.
                max_hour = now.hour if day == today else 23
                hour = rng.choices(
                    range(max_hour + 1),
                    weights=[
                        1,
                        1,
                        1,
                        1,
                        1,
                        2,
                        5,
                        9,
                        11,
                        10,
                        8,
                        7,
                        12,
                        10,
                        6,
                        5,
                        7,
                        8,
                        9,
                        7,
                        5,
                        3,
                        2,
                        1,
                    ][: max_hour + 1],
                )[0]
                effective = int(volume * factor)
                xp = 10
                # `hour` is a Vietnamese wall-clock hour; the column stores UTC.
                # Writing it straight through would shift the console's
                # "giờ uống nước phổ biến" chart seven hours and put lunchtime
                # drinks in the evening.
                logged_at = to_utc(
                    datetime.combine(day, datetime.min.time())
                    + timedelta(hours=hour, minutes=rng.randint(0, 59))
                )
                logs.append(
                    IntakeLog(
                        user_id=None,  # filled after users get their ids
                        volume_ml=volume,
                        liquid_type=liquid,
                        hydration_factor=factor,
                        effective_volume_ml=effective,
                        xp_earned=xp,
                        bonus_xp=0,
                        source=rng.choice(SOURCES),
                        logged_at=logged_at,
                        created_at=logged_at,
                    )
                )
                logs[-1]._owner = user  # temporary back-reference
                logged += effective
                total_logs += 1
                total_ml += volume
                total_xp += xp

            streak += 1
            longest = max(longest, streak)

        user.current_streak = streak
        user.longest_streak = longest
        user.total_logs_count = total_logs
        user.total_volume_ml = total_ml
        # Level comes from intake XP at read time; total_xp on the row is the
        # quest/manual share, so leave a small realistic amount there.
        user.total_xp = rng.randint(0, 400)

    db.add_all(users)
    db.flush()  # assign ids
    for log in logs:
        log.user_id = log._owner.id
        del log._owner
    db.add_all(logs)
    db.commit()

    print(f"Seeded {len(users)} users and {len(logs):,} intake logs.")
    print(f"  locked: {sum(1 for u in users if not u.is_active)}")


def seed_audit(db, super_admin: User) -> None:
    """A few historical entries so the audit screen is not empty on first open."""
    if db.query(AuditLog).count() > 0:
        return
    now = datetime.utcnow()
    samples = [
        ("user.grant", "Bù sự cố đồng bộ 28/07", "purple", "Tặng xu / XP", 2),
        ("user.unlock", "Khiếu nại hợp lệ, khoá nhầm", "green", "Mở khoá tài khoản", 3),
        ("users.export", "Chiến dịch email tháng 8", "amber", "Xuất CSV người dùng", 4),
    ]
    victims = db.query(User).filter(User.email.like(f"%@{DEMO_DOMAIN}")).limit(3).all()
    for i, (action, reason, tone, label, days_ago) in enumerate(samples):
        target = victims[i] if i < len(victims) else None
        db.add(
            AuditLog(
                actor_id=super_admin.id if super_admin else None,
                actor_name=super_admin.full_name if super_admin else "Hệ thống",
                actor_role=super_admin.role if super_admin else "system",
                action=action,
                action_label=label,
                tone=tone,
                target_type="user" if target else "report",
                target_id=target.id if target else None,
                target_label=(
                    f"{target.id} · {target.full_name}" if target else "1.240 bản ghi"
                ),
                reason=reason,
                ip_address="113.161.24.7",
                created_at=now - timedelta(days=days_ago),
            )
        )
    db.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--users", type=int, default=200)
    parser.add_argument("--days", type=int, default=70)
    parser.add_argument("--staff-only", action="store_true")
    parser.add_argument("--wipe", action="store_true")
    args = parser.parse_args()

    # The dev engine echoes every statement; a seed run would bury its own
    # output under ~20k INSERT lines.
    engine.echo = False

    guard_environment()

    password = resolve_password()
    init_db()
    db = SessionLocal()
    try:
        if args.wipe:
            wipe_demo(db)
            if not args.staff_only and args.users == 0:
                return

        super_admin = seed_staff(db, password)
        if not args.staff_only:
            existing = (
                db.query(User).filter(User.email.like(f"%@{DEMO_DOMAIN}")).count()
            )
            if existing:
                print(f"{existing} demo users already exist — skipping user seed.")
                print("Use --wipe first if you want a clean dataset.")
            else:
                seed_users(db, args.users, args.days)
            seed_audit(db, super_admin)

        print(f"\nStaff logins (password for all: {password})")
        for full_name, local, role in STAFF:
            print(f"  {role:<12} {local}@{STAFF_DOMAIN:<16} {full_name}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
