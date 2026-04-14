from typing import Any, Dict, List, Optional
from sqlalchemy import desc, select
from sqlalchemy.orm import Session, selectinload
from app.models.scene import Scene
from app.models.session import Session as StorySession


def create_session(
    db: Session,
    session_id: str,
    profile_id: str,
    scene_id: str,
    source_type: str,
    story_metadata: Dict[str, Any],
    progression_state: Dict[str, Any],
) -> StorySession:
    session = StorySession(
        id=session_id,
        profile_id=profile_id,
        scene_id=scene_id,
        source_type=source_type,
        story_metadata=story_metadata,
        progression_state=progression_state,
        status="active",
        total_messages=0,
        total_tokens=0,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def get_session_by_id(db: Session, session_id: str) -> Optional[StorySession]:
    statement = select(StorySession).where(StorySession.id == session_id)
    return db.scalars(statement).first()


def save_session(db: Session, session: StorySession) -> StorySession:
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def list_sessions_for_profile(db: Session, profile_id: str) -> List[StorySession]:
    statement = (
        select(StorySession)
        .options(selectinload(StorySession.scene).selectinload(Scene.character))
        .where(StorySession.profile_id == profile_id)
        .order_by(desc(StorySession.updated_at), desc(StorySession.created_at))
    )
    return db.scalars(statement).all()


def get_session_by_id_with_scene(db: Session, session_id: str) -> Optional[StorySession]:
    statement = (
        select(StorySession)
        .options(selectinload(StorySession.scene).selectinload(Scene.character))
        .where(StorySession.id == session_id)
    )
    return db.scalars(statement).first()
