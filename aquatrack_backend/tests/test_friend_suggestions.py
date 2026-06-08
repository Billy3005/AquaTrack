"""People-you-may-know suggestions (friends-of-friends by mutual count).

Behaviours under test:
  - candidates are ranked by number of shared friends (mutual count)
  - existing friends and the user themselves are never suggested
  - a user with no friends gets no suggestions (no graph to mine)
  - a pending request (either direction) hides the candidate
"""

from app.crud.friend import friend_crud, friend_request_crud
from app.models import User
from app.schemas.social import FriendRequestCreate


def _mk(db, uid):
    u = User(
        id=uid,
        email=f"{uid}@test.com",
        hashed_password="x",
        username=uid,
        full_name=uid.title(),
        daily_goal_ml=2000,
        calculated_daily_goal_ml=2000,
        timezone="Asia/Ho_Chi_Minh",
        current_streak=0,
    )
    db.add(u)
    db.commit()
    return u


def test_suggestions_ranked_by_mutual_count(db, user):
    # me=user-1; A,B are my friends. C is friend of both A and B (2 mutuals),
    # D is friend of A only (1 mutual). C should outrank D.
    a, b, c, d = (_mk(db, x) for x in ("a", "b", "c", "d"))
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=a.id)
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=b.id)
    friend_crud.create_friendship(db, user_id=a.id, friend_user_id=c.id)
    friend_crud.create_friendship(db, user_id=b.id, friend_user_id=c.id)
    friend_crud.create_friendship(db, user_id=a.id, friend_user_id=d.id)

    out = friend_crud.get_suggested_friends(db, current_user_id=user.id)
    ids = [s["id"] for s in out]

    assert ids[:2] == ["c", "d"]  # ranked by mutual count desc
    by_id = {s["id"]: s for s in out}
    assert by_id["c"]["mutual_friends"] == 2
    assert by_id["d"]["mutual_friends"] == 1


def test_existing_friends_and_self_excluded(db, user):
    a, b = _mk(db, "a"), _mk(db, "b")
    # a is my friend; b is friend of a (a friend-of-friend → suggestable).
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=a.id)
    friend_crud.create_friendship(db, user_id=a.id, friend_user_id=b.id)
    # Also make b my direct friend → b must NOT be suggested anymore.
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=b.id)

    out = friend_crud.get_suggested_friends(db, current_user_id=user.id)
    ids = [s["id"] for s in out]

    assert user.id not in ids
    assert "a" not in ids  # already a friend
    assert "b" not in ids  # already a friend


def test_no_friends_yields_no_suggestions(db, user):
    _mk(db, "lonely")
    assert friend_crud.get_suggested_friends(db, current_user_id=user.id) == []


def test_pending_request_hides_candidate(db, user):
    a, c = _mk(db, "a"), _mk(db, "c")
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=a.id)
    friend_crud.create_friendship(db, user_id=a.id, friend_user_id=c.id)
    # I already have a pending request out to C → C should be hidden.
    friend_request_crud.create_request(
        db, sender_id=user.id, obj_in=FriendRequestCreate(receiver_id=c.id)
    )

    out = friend_crud.get_suggested_friends(db, current_user_id=user.id)
    assert "c" not in [s["id"] for s in out]
