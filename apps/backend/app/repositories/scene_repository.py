from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload
from app.models.scene import Scene


def list_public_scenes(db: Session, access_tier: Optional[str] = None, limit: int = 100) -> List[Scene]:
    statement = select(Scene).options(selectinload(Scene.character)).where(
        Scene.is_active.is_(True),
        Scene.is_public_browse.is_(True),
    )
    if access_tier:
        statement = statement.where(Scene.access_tier == access_tier)

    statement = statement.order_by(Scene.sort_order)
    return db.scalars(statement.limit(limit)).all()


def get_scene_by_id(db: Session, scene_id: str) -> Optional[Scene]:
    statement = select(Scene).options(selectinload(Scene.character)).where(
        Scene.id == scene_id,
        Scene.is_active.is_(True),
    )
    return db.scalars(statement).first()
