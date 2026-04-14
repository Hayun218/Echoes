from typing import Any, Dict, List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.message import Message


def create_message(
    db: Session,
    message_id: str,
    session_id: str,
    sender_type: str,
    speaker_type: str,
    content: str,
    speaker_character_id: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
    token_count: int = 0,
) -> Message:
    message = Message(
        id=message_id,
        session_id=session_id,
        sender_type=sender_type,
        speaker_type=speaker_type,
        speaker_character_id=speaker_character_id,
        content=content,
        message_metadata=metadata or {},
        token_count=token_count,
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


def list_messages_for_session(db: Session, session_id: str) -> List[Message]:
    statement = select(Message).where(Message.session_id == session_id).order_by(Message.created_at)
    return db.scalars(statement).all()
