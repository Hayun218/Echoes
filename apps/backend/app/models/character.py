from sqlalchemy import Column, String, Text, Boolean, Integer, JSON, TIMESTAMP, func
from sqlalchemy.orm import relationship
from app.models.base import Base


class Character(Base):
    __tablename__ = "characters"

    id = Column(String(36), primary_key=True)
    slug = Column(String(120), nullable=False, unique=True)
    name = Column(String(120), nullable=False, unique=True)
    description = Column(Text, nullable=False)
    avatar_url = Column(String(500), nullable=True)
    category = Column(String(120), nullable=True)
    tags = Column(JSON, nullable=False, default=list)
    sort_order = Column(Integer, nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)
    is_featured = Column(Boolean, nullable=False, default=False)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    scenes = relationship("Scene", back_populates="character")
