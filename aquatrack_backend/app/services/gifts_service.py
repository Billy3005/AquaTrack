"""Coin gifts between friends (tặng xu).

Gifting transfers real spendable coins from the sender to the receiver on
``users.coins`` and records a ``CoinGift`` row so the recipient gets an inbox
notification and a per-day cap can be enforced. The balance lives on the user
row; this service is the only place that moves it between friends.
"""

from datetime import datetime
from typing import Set

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.crud.friend import friend_crud
from app.models import CoinGift, User

# Preset gift sizes offered in the UI; any other amount is rejected.
ALLOWED_GIFT_AMOUNTS: Set[int] = {5, 10, 20, 50}
# Max total coins one user can gift (across all friends) per day.
GIFT_DAILY_LIMIT = 100


def coins_gifted_today(db: Session, user_id: str) -> int:
    """Total coins this user has gifted since UTC midnight today."""
    start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    total = (
        db.query(func.coalesce(func.sum(CoinGift.amount), 0))
        .filter(CoinGift.sender_id == user_id, CoinGift.created_at >= start)
        .scalar()
    )
    return int(total or 0)


def send_coin_gift(
    db: Session, *, sender_id: str, receiver_id: str, amount: int
) -> dict:
    """Transfer ``amount`` coins from sender to a friend, recording the gift."""
    if amount not in ALLOWED_GIFT_AMOUNTS:
        return {"success": False, "message": "Số xu không hợp lệ", "new_balance": 0}

    if sender_id == receiver_id:
        return {
            "success": False,
            "message": "Không thể tặng xu cho chính mình",
            "new_balance": 0,
        }

    sender = db.query(User).filter(User.id == sender_id).first()
    receiver = db.query(User).filter(User.id == receiver_id).first()
    if sender is None or receiver is None:
        return {
            "success": False,
            "message": "Không tìm thấy người chơi",
            "new_balance": 0,
        }

    balance = int(sender.coins or 0)

    if not friend_crud.are_friends(db, user_id=sender_id, other_user_id=receiver_id):
        return {
            "success": False,
            "message": "Chỉ có thể tặng xu cho bạn bè",
            "new_balance": balance,
        }

    if balance < amount:
        return {
            "success": False,
            "message": "Bạn không đủ xu để tặng",
            "new_balance": balance,
        }

    if coins_gifted_today(db, sender_id) + amount > GIFT_DAILY_LIMIT:
        return {
            "success": False,
            "message": f"Hôm nay bạn chỉ tặng được tối đa {GIFT_DAILY_LIMIT} xu",
            "new_balance": balance,
        }

    sender.coins = balance - amount
    receiver.coins = int(receiver.coins or 0) + amount
    db.add(CoinGift(sender_id=sender_id, receiver_id=receiver_id, amount=amount))
    db.commit()

    return {
        "success": True,
        "message": f"Đã tặng {amount} xu",
        "new_balance": int(sender.coins),
    }
