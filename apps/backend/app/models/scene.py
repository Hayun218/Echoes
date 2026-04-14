from sqlalchemy import Column, String, Text, Boolean, Integer, JSON, ForeignKey, TIMESTAMP, func
from sqlalchemy.orm import relationship
from app.models.base import Base


class Scene(Base):
    __tablename__ = "scenes"

    id = Column(String(36), primary_key=True)
    character_id = Column(String(36), ForeignKey("characters.id"), nullable=False)
    slug = Column(String(140), nullable=False, unique=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    intro_text = Column(Text, nullable=False)
    prompt_template = Column(Text, nullable=False)
    thumbnail_url = Column(String(500), nullable=True)
    mood_tags = Column(JSON, nullable=False, default=list)
    difficulty_level = Column(Integer, nullable=False, default=1)
    access_tier = Column(String(50), nullable=False, default="free")
    is_public_browse = Column(Boolean, nullable=False, default=True)
    is_active = Column(Boolean, nullable=False, default=True)
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    character = relationship("Character", back_populates="scenes")
