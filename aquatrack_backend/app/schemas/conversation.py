from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel


# Base schemas
class QuickReplySchema(BaseModel):
    id: str
    text: str
    action: Optional[str] = None


class MessageBase(BaseModel):
    content: str
    message_type: str  # "user", "ai", "system"


class MessageCreate(MessageBase):
    message_id: str
    ai_message_type: Optional[str] = None
    quick_replies: Optional[List[QuickReplySchema]] = None
    context_data: Optional[Dict[str, Any]] = None


class MessageUpdate(BaseModel):
    content: Optional[str] = None
    is_deleted: Optional[bool] = None


class MessageResponse(MessageBase):
    id: int
    message_id: str
    session_id: str
    ai_message_type: Optional[str] = None
    quick_replies: Optional[List[QuickReplySchema]] = None
    context_data: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    is_deleted: bool

    class Config:
        from_attributes = True


# Conversation Session schemas
class ConversationSessionBase(BaseModel):
    title: Optional[str] = None


class ConversationSessionCreate(ConversationSessionBase):
    session_id: str


class ConversationSessionUpdate(BaseModel):
    title: Optional[str] = None
    is_active: Optional[bool] = None
    is_archived: Optional[bool] = None


class ConversationSessionResponse(ConversationSessionBase):
    id: int
    session_id: str
    user_id: str
    total_messages: int
    last_message_at: datetime
    is_active: bool
    is_archived: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Chat API schemas (for frontend integration)
class ChatMessageRequest(BaseModel):
    content: str
    session_id: Optional[str] = None  # If not provided, creates new session
    context: Optional[Dict[str, Any]] = None


class ChatMessageResponse(BaseModel):
    message_id: str
    session_id: str
    user_message: MessageResponse
    ai_response: MessageResponse


class ConversationHistoryResponse(BaseModel):
    session_id: str
    total_messages: int
    messages: List[MessageResponse]
    has_more: bool = False
    next_page: Optional[int] = None


class ConversationSessionListResponse(BaseModel):
    sessions: List[ConversationSessionResponse]
    total_count: int


# Quick reply action request
class QuickReplyActionRequest(BaseModel):
    quick_reply_id: str
    session_id: str
    context: Optional[Dict[str, Any]] = None


# Context update request
class ContextUpdateRequest(BaseModel):
    session_id: str
    context: Dict[str, Any]
