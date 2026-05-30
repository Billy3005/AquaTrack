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
