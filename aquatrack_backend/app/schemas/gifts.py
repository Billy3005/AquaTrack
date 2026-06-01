"""Schemas for coin gifts between friends (tặng xu)."""

from pydantic import BaseModel, Field


class CoinGiftCreate(BaseModel):
    """Body for gifting coins to a friend (receiver comes from the URL)."""

    amount: int = Field(..., description="Coins to gift; must be an allowed preset")


class CoinGiftResponse(BaseModel):
    success: bool
    message: str
    # Sender's coin balance after the gift, so the client can update instantly.
    new_balance: int = 0
