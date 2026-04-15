from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.character import Character


def list_active_characters(db: Session, limit: int = 100) -> List[Character]:
    statement = select(Character).where(Character.is_active.is_(True)).order_by(Character.sort_order)
    return db.scalars(statement.limit(limit)).all()


def get_character_by_id(db: Session, character_id: str) -> Optional[Character]:
    statement = select(Character).where(Character.id == character_id, Character.is_active.is_(True))
    return db.scalars(statement).first()
