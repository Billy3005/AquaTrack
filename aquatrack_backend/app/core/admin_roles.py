"""Admin roles & capability matrix for the Admin Console.

A single ladder of roles lives on `users.role`. Ordinary app users stay at
`user` (rank 0) and can never reach an /admin route. The four staff roles mirror
the permission table in the Admin Console design (Cài đặt & phân quyền).

Two orthogonal checks:

* **rank** — `require_admin(min_role=...)` gates a route by seniority. Used for
  the coarse "is this person staff at all" question.
* **capability** — `require_cap("user.lock")` gates by the exact capability
  matrix from the design, because the ladder is not strictly nested: Support may
  lock an account (front-line abuse handling) while Marketing may not, yet
  Marketing outranks Support on content work.

Capability wins wherever the two disagree; rank is only a cheap pre-filter.
"""

from typing import Dict, Tuple

ROLE_USER = "user"
ROLE_SUPPORT = "support"
ROLE_MARKETING = "marketing"
ROLE_OPERATIONS = "operations"
ROLE_SUPER_ADMIN = "super_admin"

# Seniority ladder. Only used for coarse gating — see module docstring.
ROLE_RANK: Dict[str, int] = {
    ROLE_USER: 0,
    ROLE_SUPPORT: 1,
    ROLE_MARKETING: 2,
    ROLE_OPERATIONS: 3,
    ROLE_SUPER_ADMIN: 4,
}

STAFF_ROLES: Tuple[str, ...] = (
    ROLE_SUPPORT,
    ROLE_MARKETING,
    ROLE_OPERATIONS,
    ROLE_SUPER_ADMIN,
)

ROLE_LABELS: Dict[str, str] = {
    ROLE_USER: "Người dùng",
    ROLE_SUPPORT: "Support",
    ROLE_MARKETING: "Marketing",
    ROLE_OPERATIONS: "Operations",
    ROLE_SUPER_ADMIN: "Super admin",
}

# Capability matrix — transcribed from the `PERMS` table in the design bundle
# (aquatrack/project/admin/data2.jsx). Order of the tuple is
# (super_admin, operations, marketing, support).
CAPABILITIES: Dict[str, Tuple[bool, bool, bool, bool]] = {
    "data.view": (True, True, True, True),
    "data.export": (True, True, True, False),
    "notify.send": (True, True, True, False),
    "content.edit": (True, True, True, False),
    "user.grant": (True, True, False, False),
    "user.lock": (True, True, False, True),
    "user.reset": (True, False, False, False),
    # Not from the design bundle. Added because transactional email needs an
    # authenticated sending domain the project does not own yet, so a user who
    # forgets their password has no self-service way back in. Same row as
    # `user.lock`: the roles that already handle account trouble. Marketing has
    # no business near credentials.
    "user.password_reset": (True, True, False, True),
    "gamify.config": (True, False, False, False),
    "members.manage": (True, False, False, False),
    "audit.view": (True, True, True, True),
}

_CAP_ORDER = (ROLE_SUPER_ADMIN, ROLE_OPERATIONS, ROLE_MARKETING, ROLE_SUPPORT)


def is_staff(role: str) -> bool:
    return role in STAFF_ROLES


def has_capability(role: str, capability: str) -> bool:
    """True when `role` is allowed to perform `capability`.

    Unknown capabilities are denied rather than allowed — a typo in a route
    decorator must fail closed, not open the door.
    """
    row = CAPABILITIES.get(capability)
    if row is None or role not in _CAP_ORDER:
        return False
    return row[_CAP_ORDER.index(role)]


def capabilities_of(role: str) -> Dict[str, bool]:
    """Full capability map for a role — sent to the console so the UI can hide
    buttons the caller would only get a 403 from."""
    return {cap: has_capability(role, cap) for cap in CAPABILITIES}
