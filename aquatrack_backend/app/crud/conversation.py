from datetime import datetime
from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, func
import uuid

from app.crud.base import CRUDBase
from app.models.conversation import Conversation, ConversationSession
from app.schemas.conversation import (
    MessageCreate, MessageUpdate, ConversationSessionCreate, ConversationSessionUpdate
)


class CRUDConversation(CRUDBase[Conversation, MessageCreate, MessageUpdate]):
    def create_message(
        self,
        db: Session,
        *,
        user_id: str,
        session_id: str,
        message: MessageCreate
    ) -> Conversation:
        """Create a new conversation message"""
        db_obj = Conversation(
            user_id=user_id,
            session_id=session_id,
            message_id=message.message_id,
            content=message.content,
            message_type=message.message_type,
            ai_message_type=message.ai_message_type,
            quick_replies=message.quick_replies,
            context_data=message.context_data,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)

        # Update session message count and last message time
        self._update_session_stats(db, session_id)

        return db_obj

    def create_conversation_pair(
        self,
        db: Session,
        *,
        user_id: str,
        session_id: str,
        user_message: MessageCreate,
        ai_message: MessageCreate,
    ) -> Tuple[Conversation, Conversation]:
        """Create user and AI messages atomically in single transaction"""
        try:
            # Create user message
            user_db_obj = Conversation(
                user_id=user_id,
                session_id=session_id,
                message_id=user_message.message_id,
                content=user_message.content,
                message_type=user_message.message_type,
                ai_message_type=user_message.ai_message_type,
                quick_replies=user_message.quick_replies,
                context_data=user_message.context_data,
            )
            db.add(user_db_obj)

            # Create AI message
            ai_db_obj = Conversation(
                user_id=user_id,
                session_id=session_id,
                message_id=ai_message.message_id,
                content=ai_message.content,
                message_type=ai_message.message_type,
                ai_message_type=ai_message.ai_message_type,
                quick_replies=ai_message.quick_replies,
                context_data=ai_message.context_data,
            )
            db.add(ai_db_obj)

            # Single commit for both messages
            db.commit()
            db.refresh(user_db_obj)
            db.refresh(ai_db_obj)

            # Update session stats
            self._update_session_stats(db, session_id)

            return user_db_obj, ai_db_obj

        except Exception as e:
            db.rollback()
            raise e

    def get_messages_by_session(
        self,
        db: Session,
        *,
        user_id: str,
        session_id: str,
        skip: int = 0,
        limit: int = 50,
        order_desc: bool = False
    ) -> List[Conversation]:
        """Get messages for a specific conversation session"""
        query = db.query(self.model).filter(
            and_(
                self.model.user_id == user_id,
                self.model.session_id == session_id,
                self.model.is_deleted == False
            )
        )

        if order_desc:
            query = query.order_by(desc(self.model.created_at))
        else:
            query = query.order_by(self.model.created_at)

        return query.offset(skip).limit(limit).all()

    def get_recent_messages_by_user(
        self,
        db: Session,
        *,
        user_id: str,
        limit: int = 20
    ) -> List[Conversation]:
        """Get recent messages across all sessions for a user"""
        return db.query(self.model).filter(
            and_(
                self.model.user_id == user_id,
                self.model.is_deleted == False
            )
        ).order_by(desc(self.model.created_at)).limit(limit).all()

    def get_message_by_id(
        self,
        db: Session,
        *,
        user_id: str,
        message_id: str
    ) -> Optional[Conversation]:
        """Get a specific message by ID"""
        return db.query(self.model).filter(
            and_(
                self.model.user_id == user_id,
                self.model.message_id == message_id,
                self.model.is_deleted == False
            )
        ).first()

    def soft_delete_message(
        self,
        db: Session,
        *,
        user_id: str,
        message_id: str
    ) -> Optional[Conversation]:
        """Soft delete a message"""
        db_obj = self.get_message_by_id(db, user_id=user_id, message_id=message_id)
        if db_obj:
            db_obj.is_deleted = True
            db_obj.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(db_obj)
        return db_obj

    def get_conversation_context(
        self,
        db: Session,
        *,
        user_id: str,
        session_id: str,
        limit: int = 10
    ) -> List[Conversation]:
        """Get recent conversation context for AI generation"""
        return db.query(self.model).filter(
            and_(
                self.model.user_id == user_id,
                self.model.session_id == session_id,
                self.model.is_deleted == False
            )
        ).order_by(desc(self.model.created_at)).limit(limit).all()

    def _update_session_stats(self, db: Session, session_id: str):
        """Update session statistics after adding a message"""
        session = db.query(ConversationSession).filter(
            ConversationSession.session_id == session_id
        ).first()

        if session:
            # Count total messages in session
            total_messages = db.query(func.count(Conversation.id)).filter(
                and_(
                    Conversation.session_id == session_id,
                    Conversation.is_deleted == False
                )
            ).scalar()

            session.total_messages = total_messages
            session.last_message_at = datetime.utcnow()
            session.updated_at = datetime.utcnow()
            db.commit()


class CRUDConversationSession(CRUDBase[ConversationSession, ConversationSessionCreate, ConversationSessionUpdate]):
    def create_session(
        self,
        db: Session,
        *,
        user_id: str,
        session_create: ConversationSessionCreate
    ) -> ConversationSession:
        """Create a new conversation session"""
        db_obj = ConversationSession(
            user_id=user_id,
            session_id=session_create.session_id,
            title=session_create.title,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_or_create_session(
        self,
        db: Session,
        *,
        user_id: str,
        session_id: Optional[str] = None,
        title: Optional[str] = None
    ) -> ConversationSession:
        """Get existing session or create new one"""
        if session_id:
            # Try to get existing session
            session = db.query(self.model).filter(
                and_(
                    self.model.user_id == user_id,
                    self.model.session_id == session_id
                )
            ).first()

            if session:
                return session

        # Create new session
        new_session_id = session_id or str(uuid.uuid4())
        session_create = ConversationSessionCreate(
            session_id=new_session_id,
            title=title
        )
        return self.create_session(db, user_id=user_id, session_create=session_create)

    def get_sessions_by_user(
        self,
        db: Session,
        *,
        user_id: str,
        skip: int = 0,
        limit: int = 20,
        active_only: bool = True
    ) -> List[ConversationSession]:
        """Get conversation sessions for a user"""
        query = db.query(self.model).filter(self.model.user_id == user_id)

        if active_only:
            query = query.filter(
                and_(
                    self.model.is_active == True,
                    self.model.is_archived == False
                )
            )

        return query.order_by(desc(self.model.last_message_at)).offset(skip).limit(limit).all()

    def archive_session(
        self,
        db: Session,
        *,
        user_id: str,
        session_id: str
    ) -> Optional[ConversationSession]:
        """Archive a conversation session"""
        session = db.query(self.model).filter(
            and_(
                self.model.user_id == user_id,
                self.model.session_id == session_id
            )
        ).first()

        if session:
            session.is_archived = True
            session.is_active = False
            session.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(session)

        return session

    def get_active_session(
        self,
        db: Session,
        *,
        user_id: str
    ) -> Optional[ConversationSession]:
        """Get the most recent active session for a user"""
        return db.query(self.model).filter(
            and_(
                self.model.user_id == user_id,
                self.model.is_active == True,
                self.model.is_archived == False
            )
        ).order_by(desc(self.model.last_message_at)).first()


# Create instances
conversation_crud = CRUDConversation(Conversation)
conversation_session_crud = CRUDConversationSession(ConversationSession)