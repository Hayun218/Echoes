from datetime import datetime
from sqlalchemy import Column, String, JSON, Integer, ForeignKey, TIMESTAMP, func
from sqlalchemy.orm import relationship
from app.models.base import Base


class Session(Base):
    __tablename__ = "sessions"

    id = Column(String(36), primary_key=True)
    profile_id = Column(String(36), ForeignKey("profiles.id"), nullable=False)
    scene_id = Column(String(36), ForeignKey("scenes.id"), nullable=False)
    source_type = Column(String(50), nullable=False, default="biblical")
    story_metadata = Column(JSON, nullable=False, default=dict)
    progression_state = Column(JSON, nullable=False, default=dict)
    status = Column(String(50), nullable=False, default="active")
    started_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    ended_at = Column(TIMESTAMP(timezone=True), nullable=True)
    total_messages = Column(Integer, nullable=False, default=0)
    total_tokens = Column(Integer, nullable=False, default=0)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at = Column(
        TIMESTAMP(timezone=True),
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    profile = relationship("Profile", back_populates="sessions")
    scene = relationship("Scene")
    messages = relationship("Message", back_populates="session", cascade="all, delete-orphan")
