from datetime import datetime
from sqlalchemy import Column, DateTime, Integer, String, Text, JSON, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from app.core.database import Base


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, nullable=False, index=True)
    session_id = Column(String, nullable=False, index=True)  # To group related messages

    # Message content
    message_id = Column(String, nullable=False, index=True)  # Unique message ID
    content = Column(Text, nullable=False)
    message_type = Column(String, nullable=False)  # "user", "ai", "system"

    # AI message specific fields
    ai_message_type = Column(String, nullable=True)  # "welcomeCard", "suggestion", etc.
    quick_replies = Column(JSON, nullable=True)  # JSON array of quick reply objects
    context_data = Column(JSON, nullable=True)  # Context used for AI response

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    is_deleted = Column(Boolean, default=False)

    def __repr__(self):
        return f"<Conversation(id={self.id}, user_id={self.user_id}, type={self.message_type})>"


class ConversationSession(Base):
    __tablename__ = "conversation_sessions"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, unique=True, nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)

    # Session metadata
    title = Column(String, nullable=True)  # Optional session title
    total_messages = Column(Integer, default=0)
    last_message_at = Column(DateTime(timezone=True), server_default=func.now())

    # Session status
    is_active = Column(Boolean, default=True)
    is_archived = Column(Boolean, default=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    def __repr__(self):
        return f"<ConversationSession(id={self.id}, session_id={self.session_id}, user_id={self.user_id})>"