from sqlalchemy import Column, String, JSON, TIMESTAMP, func
from sqlalchemy.orm import relationship
from app.models.base import Base


class Profile(Base):
    __tablename__ = "profiles"

    id = Column(String(36), primary_key=True)
    status = Column(String(50), nullable=False, default="active")
    preferences = Column(JSON, nullable=False, default=dict)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    sessions = relationship("Session", back_populates="profile")
