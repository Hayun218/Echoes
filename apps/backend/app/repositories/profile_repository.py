from typing import Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.profile import Profile


def get_profile_by_id(db: Session, profile_id: str) -> Optional[Profile]:
    statement = select(Profile).where(Profile.id == profile_id)
    return db.scalars(statement).first()
