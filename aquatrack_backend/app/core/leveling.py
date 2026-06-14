"""Pure level/XP math shared by the levels endpoint and quest rewards.

Single source of truth for the XP curve so quest rewards and the Level screen
never drift apart.
"""


def calculate_xp_for_level(level: int) -> int:
    """Total XP needed to reach a specific level."""
    if level <= 1:
        return 0

    total_xp = 0
    for lvl in range(2, level + 1):
        # Progressive XP requirement: level * 100 + (level-1) * 50
        total_xp += lvl * 100 + (lvl - 1) * 50

    return total_xp


def calculate_level_from_xp(total_xp: int) -> dict:
    """Calculate level, current XP, and progress from total XP."""
    level = 1
    xp_for_current_level = 0

    while True:
        xp_for_next_level = calculate_xp_for_level(level + 1)
        if total_xp < xp_for_next_level:
            break
        level += 1
        xp_for_current_level = xp_for_next_level

    xp_for_next_level = calculate_xp_for_level(level + 1)
    current_xp = total_xp - xp_for_current_level
    xp_to_next_level = xp_for_next_level - total_xp
    progress_percentage = (
        current_xp / (xp_for_next_level - xp_for_current_level)
    ) * 100

    return {
        "level": level,
        "current_xp": current_xp,
        "xp_for_next_level": xp_for_next_level - xp_for_current_level,
        "xp_to_next_level": xp_to_next_level,
        "progress_percentage": round(progress_percentage, 1),
    }


# Level-Up Rewards (ADR 0008)

_COINS_PER_LEVEL_STEP = 10  # reaching Level N grants (N-1) * _COINS_PER_LEVEL_STEP


def level_up_coins(from_level: int, to_level: int) -> int:
    """Coins earned by advancing from ``from_level`` (already paid) up to and
    including ``to_level``. Reaching Level N is worth (N-1)*10; this sums every
    newly-reached level in (from_level, to_level]. Non-positive span yields 0."""
    return sum(
        (n - 1) * _COINS_PER_LEVEL_STEP for n in range(from_level + 1, to_level + 1)
    )


def reconcile_level_coins(db, user, total_xp: int) -> int:
    """Idempotently grant Level-Up coins up to the user's current Level.

    ``total_xp`` is the user's AUTHORITATIVE Total XP — the same value the Level
    is derived from elsewhere (``sum(IntakeLog.xp_earned + bonus_xp) +
    user.total_xp``). It is passed in rather than read off ``user`` so this math
    module stays decoupled from how XP is sourced.

    If the current Level exceeds the user's ``coins_granted_up_to_level``
    high-water mark, credits the coins for every level in between, advances the
    mark, and persists. Returns the coins awarded (0 when already reconciled).
    Safe to call from any XP source — replays grant nothing because the mark
    only ever moves forward.
    """
    current_level = calculate_level_from_xp(total_xp or 0)["level"]
    granted_to = user.coins_granted_up_to_level or 1
    if current_level <= granted_to:
        return 0

    awarded = level_up_coins(granted_to, current_level)
    user.coins = (user.coins or 0) + awarded
    user.coins_granted_up_to_level = current_level
    db.add(user)
    db.commit()
    return awarded
