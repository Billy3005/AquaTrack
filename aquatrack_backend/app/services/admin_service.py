"""Admin Console service — analytics, user administration, audit trail.

Design notes
------------
* **Everything here reads live tables.** There is no pre-aggregated warehouse,
  so each analytics call re-derives its numbers from ``intake_logs`` + ``users``
  inside the requested window. That is honest at the current data volume; if the
  user base outgrows it, the fix is a nightly rollup table, not a cache here.

* **Goals come from the user's *current* goal**, not a per-day historical goal.
  ``daily_summaries`` does store a per-day goal, but it is not written for every
  user on every day, so mixing the two sources would silently change the
  denominator between users. One consistent (slightly lossy) definition beats
  two inconsistent precise ones.

* **Deltas are only returned when they can be computed honestly.** Average
  streak has no historical record to compare against, so it returns ``None``
  and the console simply omits the comparison line rather than inventing one.
"""

import csv
import io
import json
from collections import defaultdict
from datetime import date, datetime, time, timedelta, timezone
from typing import Dict, Iterable, List, Optional, Tuple
from zoneinfo import ZoneInfo

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core.admin_roles import ROLE_LABELS, ROLE_RANK, ROLE_SUPER_ADMIN, ROLE_USER
from app.core.leveling import calculate_level_from_xp
from app.models.achievement import Achievement
from app.models.audit_log import AuditLog
from app.models.intake_log import IntakeLog
from app.models.scan_history import ScanHistory
from app.models.user import User
from app.services import password_reset_service

# A user is "inactive" once this many days pass with no logged drink.
INACTIVE_AFTER_DAYS = 14

DEFAULT_GOAL_ML = 2000

# How many weekly signup cohorts the retention table goes back.
RETENTION_WEEKS = 8

# Timestamps are stored in UTC, but "hôm nay" and "giờ uống nước phổ biến" are
# questions about the user's day, not about UTC. Every date/hour bucket in this
# module is therefore computed in one explicit reporting timezone rather than
# whatever the database session happens to be set to. Wafubi is a Vietnam-only
# product today; when that changes this becomes a per-user aggregation.
REPORT_TZ = ZoneInfo("Asia/Ho_Chi_Minh")

# Level titles shown in the console, mirroring the app's rank ladder.
RANKS = [
    "Giọt Sương",
    "Suối Nhỏ",
    "Dòng Chảy",
    "Thác Bạc",
    "Hồ Xanh",
    "Sông Lớn",
    "Thuỷ Triều",
    "Thuỷ thủ Đại dương",
    "Sóng Thần",
    "Đại Dương",
]


# ── small helpers ────────────────────────────────────────────────────────────


def rank_name(level: int) -> str:
    if level < 1:
        return RANKS[0]
    return RANKS[min(level, len(RANKS)) - 1]


def goal_of(user: User) -> int:
    """The goal the console measures a user against."""
    return user.calculated_daily_goal_ml or user.daily_goal_ml or DEFAULT_GOAL_ML


def _as_date(value) -> Optional[date]:
    """Normalise whatever ``func.date()`` returned for this dialect.

    SQLite hands back an ISO string, PostgreSQL a real ``date``.
    """
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return date.fromisoformat(str(value)[:10])


def report_now() -> datetime:
    """Current wall-clock time in the reporting timezone (naive)."""
    return datetime.now(timezone.utc).astimezone(REPORT_TZ).replace(tzinfo=None)


def to_report_tz(dt: Optional[datetime]) -> Optional[datetime]:
    """A stored UTC timestamp as local wall-clock time (naive).

    SQLite hands back naive datetimes, PostgreSQL aware ones; both are UTC, so
    naive values are tagged as UTC before conversion.
    """
    if dt is None:
        return None
    aware = dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt
    return aware.astimezone(REPORT_TZ).replace(tzinfo=None)


def utc_start_of(local_day: date) -> datetime:
    """The UTC instant at which `local_day` begins, as a naive datetime.

    Used for SQL range bounds so queries compare the indexed column directly
    instead of wrapping it in date().
    """
    local_midnight = datetime.combine(local_day, time.min, tzinfo=REPORT_TZ)
    return local_midnight.astimezone(timezone.utc).replace(tzinfo=None)


def utc_end_of(local_day: date) -> datetime:
    """Exclusive upper bound: the UTC instant at which `local_day` ends."""
    return utc_start_of(local_day + timedelta(days=1))


def _naive(dt: Optional[datetime]) -> Optional[datetime]:
    """Drop tzinfo so SQLite-naive and Postgres-aware rows compare alike."""
    if dt is None:
        return None
    return dt.replace(tzinfo=None) if dt.tzinfo else dt


def _iso(dt: Optional[datetime]) -> Optional[str]:
    return dt.isoformat() if dt else None


def relative_vi(dt: Optional[datetime], now: Optional[datetime] = None) -> str:
    """Vietnamese "x phút trước" used throughout the console tables."""
    dt = _naive(dt)
    if dt is None:
        return "Chưa hoạt động"
    now = now or datetime.utcnow()
    secs = max(0, int((now - dt).total_seconds()))
    if secs < 60:
        return "Vừa xong"
    if secs < 3600:
        return f"{secs // 60} phút trước"
    if secs < 86400:
        return f"{secs // 3600} giờ trước"
    days = secs // 86400
    if days < 30:
        return f"{days} ngày trước"
    return dt.strftime("%d/%m/%Y")


def derive_status(user: User, last_log_at: Optional[datetime], now: datetime) -> str:
    """active | inactive | locked — the three states the console filters on."""
    if not user.is_active:
        return "locked"
    last = _naive(last_log_at)
    if last is None or (now - last).days >= INACTIVE_AFTER_DAYS:
        return "inactive"
    return "active"


def _pct_delta(current: float, previous: float) -> Optional[float]:
    """Percent change, or None when there is no baseline to compare against."""
    if previous == 0:
        return None
    return round(((current - previous) / previous) * 100, 1)


# ── XP / level ───────────────────────────────────────────────────────────────


def _intake_xp_map(
    db: Session, user_ids: Optional[Iterable[str]] = None
) -> Dict[str, int]:
    """user_id -> XP earned through intake logs.

    Total XP is intake XP + ``users.total_xp`` (quest/manual rewards land on the
    user row). Keeping both halves here means the console's level always matches
    what /levels/current shows the user in the app.
    """
    q = db.query(
        IntakeLog.user_id,
        func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp),
    )
    if user_ids is not None:
        ids = list(user_ids)
        if not ids:
            return {}
        q = q.filter(IntakeLog.user_id.in_(ids))
    return {uid: int(xp or 0) for uid, xp in q.group_by(IntakeLog.user_id).all()}


def total_xp_of(user: User, intake_xp: int) -> int:
    return int(intake_xp) + int(user.total_xp or 0)


# ── overview / dashboard ─────────────────────────────────────────────────────


def get_overview(db: Session, range_days: int = 30) -> dict:
    now = report_now()
    today = now.date()
    start = today - timedelta(days=range_days - 1)
    prev_start = start - timedelta(days=range_days)

    # Retention looks eight weeks further back than the DAU range, so the two
    # windows are unioned before fetching. Without this, picking "7 ngày" would
    # hand an eight-week cohort table two weeks of history and report every
    # older week as 0% churn that never happened.
    this_monday = today - timedelta(days=today.weekday())
    retention_from = this_monday - timedelta(weeks=RETENTION_WEEKS)
    fetch_from = min(prev_start, retention_from)

    # Filter on the raw timestamp, not date(logged_at): wrapping the column in a
    # function makes any index on it unusable, and this table only grows.
    rows = (
        db.query(
            IntakeLog.user_id,
            IntakeLog.logged_at,
            IntakeLog.effective_volume_ml,
        )
        .filter(IntakeLog.logged_at >= utc_start_of(fetch_from))
        .all()
    )

    per_day_users: Dict[date, set] = defaultdict(set)
    per_user_day_ml: Dict[Tuple[str, date], int] = defaultdict(int)
    hourly = [0] * 24
    for uid, logged_at, ml in rows:
        local = to_report_tz(logged_at)
        if local is None:
            continue
        day = local.date()
        per_day_users[day].add(uid)
        per_user_day_ml[(uid, day)] += int(ml or 0)
        if start <= day <= today:
            hourly[local.hour] += 1

    # DAU series, current window and the one before it (dashed compare line).
    dau_series = [
        {
            "date": (start + timedelta(days=i)).isoformat(),
            "value": len(per_day_users.get(start + timedelta(days=i), ())),
        }
        for i in range(range_days)
    ]
    dau_series_prev = [
        {
            "date": (prev_start + timedelta(days=i)).isoformat(),
            "value": len(per_day_users.get(prev_start + timedelta(days=i), ())),
        }
        for i in range(range_days)
    ]

    goals = {u.id: goal_of(u) for u in db.query(User).all()}

    def goal_split(window_start: date, window_end: date) -> Tuple[int, int, int]:
        exceeded = met = missed = 0
        for (uid, day), ml in per_user_day_ml.items():
            if not (window_start <= day <= window_end):
                continue
            goal = goals.get(uid) or DEFAULT_GOAL_ML
            ratio = ml / goal
            if ratio >= 1.2:
                exceeded += 1
            elif ratio >= 1.0:
                met += 1
            else:
                missed += 1
        return exceeded, met, missed

    exceeded, met, missed = goal_split(start, today)
    tracked = exceeded + met + missed
    goal_rate = round(((exceeded + met) / tracked) * 100, 1) if tracked else 0.0

    p_exceeded, p_met, p_missed = goal_split(prev_start, start - timedelta(days=1))
    p_tracked = p_exceeded + p_met + p_missed
    prev_goal_rate = ((p_exceeded + p_met) / p_tracked) * 100 if p_tracked else 0.0

    # DAU today vs the average of the previous 7 days.
    dau_today = len(per_day_users.get(today, ()))
    prev_week = [
        len(per_day_users.get(today - timedelta(days=d), ())) for d in range(1, 8)
    ]
    dau_prev_avg = sum(prev_week) / 7 if prev_week else 0

    # New signups today vs the daily average of the previous 7 days. Bounds are
    # local-midnight instants so "today" means the operator's today.
    new_today = (
        db.query(func.count(User.id))
        .filter(
            User.created_at >= utc_start_of(today),
            User.created_at < utc_end_of(today),
        )
        .scalar()
        or 0
    )
    new_prev_week = (
        db.query(func.count(User.id))
        .filter(
            User.created_at >= utc_start_of(today - timedelta(days=7)),
            User.created_at < utc_start_of(today),
        )
        .scalar()
        or 0
    )

    # Average streak across users who logged something in the last 7 days —
    # streaks of dormant accounts would drag the number to zero and hide trend.
    recent_ids = set()
    for d in range(7):
        recent_ids |= per_day_users.get(today - timedelta(days=d), set())
    avg_streak = 0.0
    if recent_ids:
        streaks = (
            db.query(func.avg(User.current_streak))
            .filter(User.id.in_(list(recent_ids)))
            .scalar()
        )
        avg_streak = round(float(streaks or 0), 1)

    total_users = db.query(func.count(User.id)).scalar() or 0

    return {
        "generatedAt": now.isoformat(),
        "rangeDays": range_days,
        "kpis": {
            "dau": {
                "value": dau_today,
                "delta": _pct_delta(dau_today, dau_prev_avg),
                "deltaCaption": "so với TB 7 ngày trước",
            },
            "goalCompletionRate": {
                "value": goal_rate,
                "delta": _pct_delta(goal_rate, prev_goal_rate),
                "deltaCaption": f"so với {range_days} ngày trước đó",
            },
            "avgStreak": {
                "value": avg_streak,
                "delta": None,  # no historical streak snapshots to compare with
                "deltaCaption": "người dùng hoạt động 7 ngày qua",
            },
            "newUsersToday": {
                "value": int(new_today),
                "delta": _pct_delta(new_today, (new_prev_week or 0) / 7),
                "deltaCaption": "so với TB 7 ngày trước",
            },
        },
        "totalUsers": int(total_users),
        "dauSeries": dau_series,
        "dauSeriesPrev": dau_series_prev,
        "goalBreakdown": {
            "exceeded": round(exceeded / tracked * 100, 1) if tracked else 0.0,
            "met": round(met / tracked * 100, 1) if tracked else 0.0,
            "missed": round(missed / tracked * 100, 1) if tracked else 0.0,
            "avgUsersPerDay": round(tracked / range_days, 0) if range_days else 0,
        },
        "levelDistribution": _level_distribution(db),
        "hourlyDistribution": _as_percentages(hourly),
        "retentionCohorts": _retention_cohorts(db, per_day_users, today),
        "recentAudit": [serialize_audit(a) for a in _recent_audit(db, limit=6)],
    }


def _as_percentages(counts: List[int]) -> List[float]:
    total = sum(counts)
    if not total:
        return [0.0] * len(counts)
    return [round(c / total * 100, 1) for c in counts]


# Levels beyond this are folded into a single trailing bucket so the chart stays
# readable without silently losing users.
LEVEL_CHART_MAX = 12


def _level_distribution(db: Session) -> List[dict]:
    """How many users sit at each level — the console's funnel drop-off chart.

    The bars must add up to the whole population: everyone above
    ``LEVEL_CHART_MAX`` is collected into a "12+" bucket rather than dropped,
    which an earlier version did — understating exactly the advanced users the
    funnel is meant to reveal.
    """
    xp_map = _intake_xp_map(db)
    buckets: Dict[int, int] = defaultdict(int)
    overflow = 0
    for user in db.query(User.id, User.total_xp).all():
        level = calculate_level_from_xp(total_xp_of_row(user, xp_map))["level"]
        if level > LEVEL_CHART_MAX:
            overflow += 1
        else:
            buckets[level] += 1
    if not buckets and not overflow:
        return []

    top = max(buckets) if buckets else LEVEL_CHART_MAX
    dist = [
        {"level": lv, "users": buckets.get(lv, 0)}
        for lv in range(1, min(top, LEVEL_CHART_MAX) + 1)
    ]
    if overflow:
        dist.append({"level": LEVEL_CHART_MAX, "users": overflow, "overflow": True})
    return dist


def total_xp_of_row(row, xp_map: Dict[str, int]) -> int:
    """Same math as ``total_xp_of`` for lightweight ``(id, total_xp)`` rows."""
    return int(xp_map.get(row.id, 0)) + int(row.total_xp or 0)


def _retention_cohorts(
    db: Session,
    per_day_users: Dict[date, set],
    today: date,
    weeks: int = RETENTION_WEEKS,
) -> List[dict]:
    """Weekly signup cohorts × 8 weeks of "still logging water" retention.

    Each member's week windows are anchored to **their own signup date**, not to
    the cohort's Monday. Anchoring to the calendar week would give someone who
    joined on a Saturday a two-day "week 1" and make the first column read lower
    than the second — an artefact of the bucketing, not of user behaviour.
    """
    this_monday = today - timedelta(days=today.weekday())
    oldest_monday = this_monday - timedelta(weeks=weeks - 1)

    # One query for every cohort's membership, bucketed in Python — the previous
    # version issued a separate SELECT per cohort week.
    members_by_week: Dict[date, List[Tuple[str, date]]] = defaultdict(list)
    for uid, created_at in (
        db.query(User.id, User.created_at)
        .filter(User.created_at >= utc_start_of(oldest_monday))
        .all()
    ):
        local = to_report_tz(created_at)
        if local is None:
            continue
        joined = local.date()
        members_by_week[joined - timedelta(days=joined.weekday())].append((uid, joined))

    cohorts: List[dict] = []

    for c in range(weeks - 1, -1, -1):
        cohort_start = this_monday - timedelta(weeks=c)
        cohort_end = cohort_start + timedelta(days=6)
        members = members_by_week.get(cohort_start, [])
        if not members:
            continue

        # A week is only reportable once the LAST member to join has lived
        # through all seven of its days. Reporting earlier would count members
        # whose window is still mostly in the future as churned, collapsing the
        # newest column to near zero for no real reason.
        last_join = max(joined for _, joined in members)

        values: List[Optional[float]] = []
        for w in range(8):
            if last_join + timedelta(weeks=w, days=6) > today:
                values.append(None)
                continue
            retained = 0
            for uid, joined in members:
                win_start = joined + timedelta(weeks=w)
                if any(
                    uid in per_day_users.get(win_start + timedelta(days=d), ())
                    for d in range(7)
                ):
                    retained += 1
            values.append(round(retained / len(members) * 100))

        # A cohort too young to have a single completed week says nothing about
        # retention; its signups are already visible in the DAU chart.
        if all(v is None for v in values):
            continue

        cohorts.append(
            {
                "label": (
                    f"{cohort_start.strftime('%d/%m')} – "
                    f"{cohort_end.strftime('%d/%m')}"
                ),
                "size": len(members),
                "values": values,
            }
        )
    return cohorts


# ── user list ────────────────────────────────────────────────────────────────

LEVEL_BUCKETS = {
    "low": (1, 4),
    "mid": (5, 8),
    "high": (9, 999),
}


def list_users(
    db: Session,
    q: str = "",
    status: str = "all",
    level_bucket: str = "all",
    page: int = 1,
    page_size: int = 10,
) -> dict:
    # "How long ago" is elapsed-time arithmetic against raw UTC timestamps, so
    # it stays in UTC. Only calendar bucketing (which day? which hour?) uses the
    # reporting timezone — mixing the two is how a clock ends up 7 hours out.
    now = datetime.utcnow()
    cutoff = now - timedelta(days=INACTIVE_AFTER_DAYS)

    # Last activity per user, joined in SQL so status filtering + pagination
    # stay in the database rather than being done over a full table in Python.
    last_log = (
        db.query(
            IntakeLog.user_id.label("uid"),
            func.max(IntakeLog.logged_at).label("last_at"),
        )
        .group_by(IntakeLog.user_id)
        .subquery()
    )

    query = db.query(User, last_log.c.last_at).outerjoin(
        last_log, last_log.c.uid == User.id
    )

    if q:
        like = f"%{q.strip()}%"
        query = query.filter(
            or_(
                User.username.ilike(like),
                User.full_name.ilike(like),
                User.email.ilike(like),
                User.id.ilike(like),
            )
        )

    if status == "locked":
        query = query.filter(User.is_active.is_(False))
    elif status == "active":
        query = query.filter(User.is_active.is_(True), last_log.c.last_at >= cutoff)
    elif status == "inactive":
        query = query.filter(
            User.is_active.is_(True),
            or_(last_log.c.last_at.is_(None), last_log.c.last_at < cutoff),
        )

    query = query.order_by(func.coalesce(last_log.c.last_at, User.created_at).desc())

    filtering_by_level = level_bucket != "all" and level_bucket in LEVEL_BUCKETS

    if not filtering_by_level:
        # Ordinary path: COUNT + OFFSET/LIMIT in the database, so asking for ten
        # users costs ten rows no matter how large the table gets.
        total = query.count()
        pages = max(1, (total + page_size - 1) // page_size)
        page = max(1, min(page, pages))
        window = query.offset((page - 1) * page_size).limit(page_size).all()
    else:
        # Level is derived from the XP curve in Python, so it cannot be
        # expressed in SQL without duplicating that curve in the database. This
        # path therefore still materialises the filtered set. It is the reason
        # the level filter should become a stored, indexed column if the user
        # base grows past a few tens of thousands.
        lo, hi = LEVEL_BUCKETS[level_bucket]
        rows = query.all()
        xp_map = _intake_xp_map(db, [u.id for u, _ in rows])
        rows = [
            (u, last)
            for u, last in rows
            if lo
            <= calculate_level_from_xp(total_xp_of(u, xp_map.get(u.id, 0)))["level"]
            <= hi
        ]
        total = len(rows)
        pages = max(1, (total + page_size - 1) // page_size)
        page = max(1, min(page, pages))
        window = rows[(page - 1) * page_size : page * page_size]

    page_ids = [u.id for u, _ in window]
    xp_map = _intake_xp_map(db, page_ids)
    avg_map = _avg_daily_ml(db, page_ids, days=7)

    items = []
    for user, last_at in window:
        level_info = calculate_level_from_xp(total_xp_of(user, xp_map.get(user.id, 0)))
        items.append(
            {
                "id": user.id,
                "name": user.full_name or user.username,
                "email": user.email,
                "level": level_info["level"],
                "xp": total_xp_of(user, xp_map.get(user.id, 0)),
                "rank": rank_name(level_info["level"]),
                "streak": int(user.current_streak or 0),
                "avgMl": avg_map.get(user.id, 0),
                "goalMl": goal_of(user),
                "coins": int(user.coins or 0),
                "status": derive_status(user, last_at, now),
                "role": user.role or "user",
                "lastActiveAt": _iso(_naive(last_at)),
                "lastActiveLabel": relative_vi(last_at, now),
                "joinedAt": _iso(_naive(user.created_at)),
                "isVerified": bool(user.is_verified),
            }
        )

    return {
        "items": items,
        "page": page,
        "pageSize": page_size,
        "pages": pages,
        "total": total,
        "summary": _user_summary(db, now, cutoff),
    }


def _user_summary(db: Session, now: datetime, cutoff: datetime) -> dict:
    total = db.query(func.count(User.id)).scalar() or 0
    locked = (
        db.query(func.count(User.id)).filter(User.is_active.is_(False)).scalar() or 0
    )
    # "Hoạt động hôm nay" means the local day, bounded by local-midnight instants
    # so the comparison stays index-friendly.
    today_local = report_now().date()
    active_today = (
        db.query(func.count(func.distinct(IntakeLog.user_id)))
        .filter(
            IntakeLog.logged_at >= utc_start_of(today_local),
            IntakeLog.logged_at < utc_end_of(today_local),
        )
        .scalar()
        or 0
    )
    return {
        "totalUsers": int(total),
        "activeToday": int(active_today),
        "lockedUsers": int(locked),
    }


def _avg_daily_ml(db: Session, user_ids: List[str], days: int = 7) -> Dict[str, int]:
    """Average effective ml/day over the last `days`, counting every day in the
    window — including days with no logs, which is what "TB/ngày" must mean for
    the progress bar to be comparable across users."""
    if not user_ids:
        return {}
    since = report_now().date() - timedelta(days=days - 1)
    totals = dict(
        db.query(IntakeLog.user_id, func.sum(IntakeLog.effective_volume_ml))
        .filter(
            IntakeLog.user_id.in_(user_ids),
            IntakeLog.logged_at >= utc_start_of(since),
        )
        .group_by(IntakeLog.user_id)
        .all()
    )
    return {uid: int((totals.get(uid) or 0) / days) for uid in user_ids}


# ── user detail ──────────────────────────────────────────────────────────────


def get_user_detail(db: Session, user_id: str) -> Optional[dict]:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None

    now = datetime.utcnow()  # elapsed-time math only; see list_users
    today = report_now().date()
    intake_xp = _intake_xp_map(db, [user_id]).get(user_id, 0)
    total_xp = total_xp_of(user, intake_xp)
    level_info = calculate_level_from_xp(total_xp)

    last_at = (
        db.query(func.max(IntakeLog.logged_at))
        .filter(IntakeLog.user_id == user_id)
        .scalar()
    )

    # Last 7 days of intake, zero-filled so the bar chart never has gaps. Days
    # are bucketed in the reporting timezone, so an 06:00 local drink counts
    # towards today rather than yesterday.
    since = today - timedelta(days=6)
    per_day: Dict[date, int] = defaultdict(int)
    for logged_at, ml in (
        db.query(IntakeLog.logged_at, IntakeLog.effective_volume_ml)
        .filter(
            IntakeLog.user_id == user_id,
            IntakeLog.logged_at >= utc_start_of(since),
        )
        .all()
    ):
        local = to_report_tz(logged_at)
        if local:
            per_day[local.date()] += int(ml or 0)

    weekday_vi = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    weekly = [
        {
            "date": (since + timedelta(days=i)).isoformat(),
            "label": weekday_vi[(since + timedelta(days=i)).weekday()],
            "ml": per_day.get(since + timedelta(days=i), 0),
        }
        for i in range(7)
    ]

    recent_logs = (
        db.query(IntakeLog)
        .filter(IntakeLog.user_id == user_id)
        .order_by(IntakeLog.logged_at.desc())
        .limit(20)
        .all()
    )

    achievements = (
        db.query(func.count(Achievement.id))
        .filter(Achievement.user_id == user_id)
        .scalar()
        or 0
    )
    scans = (
        db.query(func.count(ScanHistory.id))
        .filter(ScanHistory.user_id == user_id)
        .scalar()
        or 0
    )

    goal = goal_of(user)
    avg7 = _avg_daily_ml(db, [user_id], days=7).get(user_id, 0)

    return {
        "id": user.id,
        "name": user.full_name or user.username,
        "email": user.email,
        "status": derive_status(user, last_at, now),
        "role": user.role or "user",
        "level": level_info["level"],
        "rank": rank_name(level_info["level"]),
        "xp": total_xp,
        "xpIntoLevel": level_info["current_xp"],
        "xpForNextLevel": level_info["xp_for_next_level"],
        "xpToNextLevel": level_info["xp_to_next_level"],
        "levelProgress": level_info["progress_percentage"],
        "coins": int(user.coins or 0),
        "streak": int(user.current_streak or 0),
        "longestStreak": int(user.longest_streak or 0),
        "goalMl": goal,
        "avgMl": avg7,
        "goalPercent": round(avg7 / goal * 100) if goal else 0,
        "totalLogs": int(user.total_logs_count or 0),
        "totalVolumeMl": int(user.total_volume_ml or 0),
        "achievementsCount": int(achievements),
        "scansCount": int(scans),
        "joinedAt": _iso(_naive(user.created_at)),
        "lastLoginAt": _iso(_naive(user.last_login)),
        "lastActiveAt": _iso(_naive(last_at)),
        "lastActiveLabel": relative_vi(last_at, now),
        "isVerified": bool(user.is_verified),
        "authProvider": "google" if user.google_sub else "password",
        "timezone": user.timezone,
        "weekly": weekly,
        "recentLogs": [
            {
                "id": log.id,
                "loggedAt": _iso(_naive(log.logged_at)),
                "loggedAtLabel": relative_vi(log.logged_at, now),
                "volumeMl": int(log.volume_ml or 0),
                "effectiveMl": int(log.effective_volume_ml or 0),
                "liquidType": log.liquid_type,
                "source": log.source or "manual",
            }
            for log in recent_logs
        ],
        "flags": _watch_flags(user, last_at, now, avg7, goal),
        "audit": [
            serialize_audit(a)
            for a in db.query(AuditLog)
            .filter(AuditLog.target_id == user_id)
            .order_by(AuditLog.created_at.desc())
            .limit(10)
            .all()
        ],
    }


def _watch_flags(
    user: User, last_at: Optional[datetime], now: datetime, avg7: int, goal: int
) -> List[dict]:
    """The "Cờ theo dõi" card — every flag states a fact from the row, so the
    console never shows a warning it cannot back up."""
    flags = []
    if not user.is_active:
        flags.append(
            {"tone": "red", "label": "Rủi ro", "text": "Tài khoản đang bị khoá"}
        )
    else:
        flags.append(
            {
                "tone": "green",
                "label": "OK",
                "text": "Tài khoản đang hoạt động bình thường",
            }
        )

    streak = int(user.current_streak or 0)
    if streak == 0:
        flags.append({"tone": "amber", "label": "Lưu ý", "text": "Đã mất streak"})
    else:
        flags.append(
            {"tone": "green", "label": "OK", "text": f"Đang giữ streak {streak} ngày"}
        )

    if goal and avg7 < goal * 0.7:
        flags.append(
            {
                "tone": "amber",
                "label": "Lưu ý",
                "text": f"TB 7 ngày chỉ đạt {round(avg7 / goal * 100)}% mục tiêu",
            }
        )

    last = _naive(last_at)
    if last is None:
        flags.append(
            {"tone": "amber", "label": "Lưu ý", "text": "Chưa từng ghi nhận uống nước"}
        )
    elif (now - last).days >= INACTIVE_AFTER_DAYS:
        flags.append(
            {
                "tone": "amber",
                "label": "Lưu ý",
                "text": f"Không hoạt động {(now - last).days} ngày",
            }
        )

    if not user.notifications_enabled:
        flags.append({"tone": "slate", "label": "Lưu ý", "text": "Đã tắt nhắc nhở"})
    return flags


# ── audit trail ──────────────────────────────────────────────────────────────

ACTION_META = {
    "user.lock": ("Khoá tài khoản", "red"),
    "user.unlock": ("Mở khoá tài khoản", "green"),
    "user.reset": ("Reset dữ liệu", "red"),
    "user.password_reset": ("Cấp mã đặt lại mật khẩu", "amber"),
    "user.grant": ("Tặng xu / XP", "purple"),
    "user.export": ("Xuất dữ liệu CSV", "amber"),
    "users.export": ("Xuất CSV người dùng", "amber"),
    "user.role_change": ("Đổi vai trò nhân sự", "purple"),
    "admin.login": ("Đăng nhập admin", "sky"),
}


def record_audit(
    db: Session,
    actor: Optional[User],
    action: str,
    target_id: Optional[str] = None,
    target_label: str = "",
    target_type: str = "user",
    reason: str = "",
    meta: Optional[dict] = None,
    ip_address: Optional[str] = None,
) -> AuditLog:
    """Add the audit row to the session. The caller commits it together with the
    action it describes, so an action can never be persisted without its log."""
    label, tone = ACTION_META.get(action, (action, "slate"))
    entry = AuditLog(
        actor_id=actor.id if actor else None,
        actor_name=(actor.full_name or actor.username) if actor else "Hệ thống",
        actor_role=(actor.role if actor else "system"),
        action=action,
        action_label=label,
        tone=tone,
        target_type=target_type,
        target_id=target_id,
        target_label=target_label,
        reason=reason,
        meta=json.dumps(meta, ensure_ascii=False) if meta else None,
        ip_address=ip_address,
    )
    db.add(entry)
    return entry


def serialize_audit(entry: AuditLog) -> dict:
    return {
        "id": entry.id,
        "actorId": entry.actor_id,
        "actorName": entry.actor_name,
        "actorRole": entry.actor_role,
        "actorRoleLabel": ROLE_LABELS.get(entry.actor_role, entry.actor_role),
        "action": entry.action,
        "actionLabel": entry.action_label,
        "tone": entry.tone,
        "targetType": entry.target_type,
        "targetId": entry.target_id,
        "targetLabel": entry.target_label,
        "reason": entry.reason,
        "meta": json.loads(entry.meta) if entry.meta else None,
        "ipAddress": entry.ip_address,
        "createdAt": _iso(_naive(entry.created_at)),
        "createdAtLabel": relative_vi(entry.created_at),
    }


def _recent_audit(db: Session, limit: int = 6) -> List[AuditLog]:
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit).all()


def list_audit(
    db: Session,
    page: int = 1,
    page_size: int = 20,
    action: str = "all",
    actor_id: Optional[str] = None,
    target_id: Optional[str] = None,
    q: str = "",
) -> dict:
    query = db.query(AuditLog)
    if action != "all":
        query = query.filter(AuditLog.action == action)
    if actor_id:
        query = query.filter(AuditLog.actor_id == actor_id)
    if target_id:
        query = query.filter(AuditLog.target_id == target_id)
    if q:
        like = f"%{q.strip()}%"
        query = query.filter(
            or_(
                AuditLog.actor_name.ilike(like),
                AuditLog.target_label.ilike(like),
                AuditLog.reason.ilike(like),
            )
        )

    total = query.count()
    pages = max(1, (total + page_size - 1) // page_size)
    page = max(1, min(page, pages))
    entries = (
        query.order_by(AuditLog.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    return {
        "items": [serialize_audit(e) for e in entries],
        "page": page,
        "pageSize": page_size,
        "pages": pages,
        "total": total,
        "actions": [
            {"value": key, "label": meta[0]} for key, meta in ACTION_META.items()
        ],
    }


# ── administrative actions ───────────────────────────────────────────────────


class AdminActionError(Exception):
    """Raised when an action is refused for a reason the console should show."""


def _assert_outranks(actor: User, target: User) -> None:
    """Refuse actions aimed at staff the actor does not outrank.

    Without this a Support account — the lowest staff tier, and the one most
    likely to be phished — could lock every Operations and Super Admin account
    and shut the whole team out of the console.

    Two exceptions to "strictly higher rank":
    * ordinary users (rank 0) are always actionable;
    * super admins may act on each other, otherwise a departing or compromised
      super admin could never be locked out by anyone. The "last active super
      admin" guard in `lock_user` is what keeps that from locking everybody out.
    """
    target_rank = ROLE_RANK.get(target.role or ROLE_USER, 0)
    if target_rank == 0:
        return

    actor_rank = ROLE_RANK.get(actor.role or ROLE_USER, 0)
    if actor_rank > target_rank:
        return
    if actor_rank == target_rank and actor.role == ROLE_SUPER_ADMIN:
        return

    raise AdminActionError(
        "Không thể thao tác lên tài khoản nhân sự có vai trò ngang hoặc cao hơn bạn"
    )


def lock_user(
    db: Session, actor: User, target: User, reason: str, ip: str = None
) -> dict:
    if not target.is_active:
        raise AdminActionError("Tài khoản này đã bị khoá từ trước")
    if target.id == actor.id:
        raise AdminActionError("Không thể tự khoá tài khoản của chính bạn")
    _assert_outranks(actor, target)

    # Never leave the console without a way back in.
    if target.role == ROLE_SUPER_ADMIN:
        remaining = (
            db.query(func.count(User.id))
            .filter(
                User.role == ROLE_SUPER_ADMIN,
                User.is_active.is_(True),
                User.id != target.id,
            )
            .scalar()
            or 0
        )
        if remaining == 0:
            raise AdminActionError(
                "Không thể khoá super admin đang hoạt động cuối cùng"
            )

    target.is_active = False
    record_audit(
        db,
        actor,
        "user.lock",
        target_id=target.id,
        target_label=f"{target.id} · {target.full_name or target.username}",
        reason=reason,
        ip_address=ip,
    )
    db.commit()
    return {"status": "locked"}


def unlock_user(
    db: Session, actor: User, target: User, reason: str, ip: str = None
) -> dict:
    if target.is_active:
        raise AdminActionError("Tài khoản này đang hoạt động bình thường")
    # Unlocking is privilege-granting too: a Support agent must not be able to
    # reinstate an Operations account that a Super Admin locked.
    _assert_outranks(actor, target)

    target.is_active = True
    record_audit(
        db,
        actor,
        "user.unlock",
        target_id=target.id,
        target_label=f"{target.id} · {target.full_name or target.username}",
        reason=reason,
        ip_address=ip,
    )
    db.commit()
    return {"status": "active"}


def reset_user_data(
    db: Session, actor: User, target: User, reason: str, ip: str = None
) -> dict:
    """Erase hydration history and reset streak/goal counters.

    XP and coins are deliberately left alone: they are earned currency, and the
    console's own confirmation copy promises to remove *hydration data*. A staff
    member who wants XP changed has an explicit grant action for it.
    """
    deleted = (
        db.query(IntakeLog)
        .filter(IntakeLog.user_id == target.id)
        .delete(synchronize_session=False)
    )
    volume_before = int(target.total_volume_ml or 0)

    target.current_streak = 0
    target.total_logs_count = 0
    target.total_volume_ml = 0
    target.frozen_dates = []

    record_audit(
        db,
        actor,
        "user.reset",
        target_id=target.id,
        target_label=f"{target.id} · {target.full_name or target.username}",
        reason=reason,
        meta={"deletedLogs": int(deleted), "deletedVolumeMl": volume_before},
        ip_address=ip,
    )
    db.commit()
    return {"deletedLogs": int(deleted)}


def issue_password_reset_code(
    db: Session, actor: User, target: User, reason: str, ip: str = None
) -> dict:
    """Hand a stranded user a reset code through a support channel.

    `POST /auth/forgot-password` emails the same code, but transactional email
    needs a sending domain the project does not own yet (Gmail and Yahoo have
    required DKIM alignment since February 2024, and Brevo rewrites senders on
    free domains). Until that domain exists, the emailed code goes nowhere and a
    user who forgot their password has no way back into the app at all.

    This is the manual fallback: staff read the code out over whatever channel
    they already use, and the user finishes in the app's ordinary "Quên mật
    khẩu" screen. It is the same one-shot, 10-minute, 5-attempt code — no second
    credential path exists, so there is nothing extra to get wrong.

    The code is returned to the caller and deliberately NOT stored in the audit
    row: `audit.view` is granted to every staff role, so writing it down would
    let any staff member read a code minted by someone else and take the account
    themselves. The log records that a code was issued, by whom, and why.
    """
    if target.id == actor.id:
        raise AdminActionError(
            "Dùng màn hình Quên mật khẩu trong app để đổi mật khẩu của chính bạn"
        )
    # Handing out a reset code is account takeover in one step, so it needs the
    # same rank guard as locking — otherwise Support could seize an Operations
    # account instead of merely locking it.
    _assert_outranks(actor, target)
    if not target.email:
        raise AdminActionError("Tài khoản này không có email nên không đặt lại được")

    code, expires_at = password_reset_service.issue_code(db, target)
    record_audit(
        db,
        actor,
        "user.password_reset",
        target_id=target.id,
        target_label=f"{target.id} · {target.full_name or target.username}",
        reason=reason,
        meta={"ttlMinutes": password_reset_service.CODE_TTL_MINUTES},
        ip_address=ip,
    )
    db.commit()
    return {
        "code": code,
        "email": target.email,
        "ttlMinutes": password_reset_service.CODE_TTL_MINUTES,
        "expiresAt": expires_at.isoformat() + "Z",
        "locked": not target.is_active,
    }


def grant_rewards(
    db: Session,
    actor: User,
    target: User,
    coins: int,
    xp: int,
    reason: str,
    ip: str = None,
) -> dict:
    if coins < 0 or xp < 0:
        raise AdminActionError("Số xu và XP phải là số không âm")
    if coins == 0 and xp == 0:
        raise AdminActionError("Cần nhập ít nhất một giá trị xu hoặc XP")
    if coins > 100_000 or xp > 100_000:
        raise AdminActionError("Vượt hạn mức tặng thủ công (tối đa 100.000)")

    # Atomic increments rather than read-modify-write. Two operators granting at
    # the same time would otherwise each write `their_snapshot + amount`, so one
    # grant silently vanishes while both audit rows claim success — the worst
    # possible outcome for a log whose whole job is to be trustworthy.
    db.query(User).filter(User.id == target.id).update(
        {
            User.coins: func.coalesce(User.coins, 0) + coins,
            User.total_xp: func.coalesce(User.total_xp, 0) + xp,
        },
        synchronize_session=False,
    )

    record_audit(
        db,
        actor,
        "user.grant",
        target_id=target.id,
        target_label=f"{target.id} · {target.full_name or target.username}",
        reason=reason,
        meta={"coins": coins, "xp": xp},
        ip_address=ip,
    )
    db.commit()
    db.refresh(target)
    return {"coins": int(target.coins or 0), "totalXp": int(target.total_xp or 0)}


def users_csv(db: Session) -> str:
    """Full user export. Emails are included — the export capability is limited
    to Marketing and above precisely because this file is personal data."""
    now = datetime.utcnow()
    xp_map = _intake_xp_map(db)
    last_map = dict(
        db.query(IntakeLog.user_id, func.max(IntakeLog.logged_at))
        .group_by(IntakeLog.user_id)
        .all()
    )

    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(
        [
            "id",
            "email",
            "name",
            "status",
            "level",
            "rank",
            "total_xp",
            "coins",
            "current_streak",
            "longest_streak",
            "daily_goal_ml",
            "total_logs",
            "total_volume_ml",
            "joined_at",
            "last_active_at",
        ]
    )
    for user in db.query(User).order_by(User.created_at.desc()).all():
        total_xp = total_xp_of(user, xp_map.get(user.id, 0))
        level = calculate_level_from_xp(total_xp)["level"]
        last_at = last_map.get(user.id)
        writer.writerow(
            [
                user.id,
                user.email,
                user.full_name or user.username,
                derive_status(user, last_at, now),
                level,
                rank_name(level),
                total_xp,
                int(user.coins or 0),
                int(user.current_streak or 0),
                int(user.longest_streak or 0),
                goal_of(user),
                int(user.total_logs_count or 0),
                int(user.total_volume_ml or 0),
                _iso(_naive(user.created_at)) or "",
                _iso(_naive(last_at)) or "",
            ]
        )
    return buf.getvalue()
