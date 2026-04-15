from sqlalchemy import Column, String, Text, Integer, JSON, ForeignKey, TIMESTAMP, func
from sqlalchemy.orm import relationship
from app.models.base import Base


class Message(Base):
    __tablename__ = "messages"

    id = Column(String(36), primary_key=True)
    session_id = Column(String(36), ForeignKey("sessions.id"), nullable=False)
    sender_type = Column(String(50), nullable=False)
    speaker_type = Column(String(50), nullable=False)
    speaker_character_id = Column(String(36), ForeignKey("characters.id"), nullable=True)
    content = Column(Text, nullable=False)
    token_count = Column(Integer, nullable=False, default=0)
    message_metadata = Column("metadata", JSON, nullable=False, default=dict)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    session = relationship("Session", back_populates="messages")
    character = relationship("Character")
