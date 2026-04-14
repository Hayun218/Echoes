from typing import Any, Dict, Optional
from uuid import uuid4
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.repositories.profile_repository import get_profile_by_id
from app.repositories.scene_repository import get_scene_by_id, list_public_scenes
from app.repositories.session_repository import (
    create_session,
    get_session_by_id,
    list_sessions_for_profile,
    get_session_by_id_with_scene,
    save_session,
)
from app.repositories.message_repository import create_message, list_messages_for_session
from app.models.scene import Scene
from app.models.session import Session as StorySession


def choose_scene_for_concept(
    db: Session,
    scene_id: Optional[str] = None,
    theme: Optional[str] = None,
    tone: Optional[str] = None,
) -> Scene:
    if scene_id:
        scene = get_scene_by_id(db, scene_id)
        if not scene or not scene.is_public_browse:
            raise HTTPException(status_code=404, detail="Scene not found")
        return scene

    candidates = list_public_scenes(db, access_tier="free")
    if not candidates:
        raise HTTPException(status_code=404, detail="No browseable scenes available")

    if theme or tone:
        score_key = (theme or tone).lower()
        for candidate in candidates:
            tags = [tag.lower() for tag in (candidate.mood_tags or []) if isinstance(tag, str)]
            if score_key in tags:
                return candidate

    return candidates[0]


def start_session(
    db: Session,
    profile_id: str,
    concept: str,
    scene_id: Optional[str] = None,
    theme: Optional[str] = None,
    tone: Optional[str] = None,
) -> Dict[str, Any]:
    profile = get_profile_by_id(db, profile_id)
    if not profile:
        raise HTTPException(status_code=401, detail="Authenticated profile not found")

    scene = choose_scene_for_concept(db, scene_id=scene_id, theme=theme, tone=tone)
    story_metadata: Dict[str, Any] = {
        "concept": concept,
        "theme": theme,
        "tone": tone,
    }
    progression_state: Dict[str, Any] = {
        "stage": "started",
        "concept": concept,
        "theme": theme,
        "tone": tone,
    }
    session = create_session(
        db=db,
        session_id=str(uuid4()),
        profile_id=profile_id,
        scene_id=scene.id,
        source_type="canonical",
        story_metadata=story_metadata,
        progression_state=progression_state,
    )

    return {
        "session": session,
        "scene": scene,
        "story_metadata": story_metadata,
        "progression_state": progression_state,
    }


def get_sessions_for_profile(db: Session, profile_id: str):
    profile = get_profile_by_id(db, profile_id)
    if not profile:
        raise HTTPException(status_code=401, detail="Authenticated profile not found")
    return list_sessions_for_profile(db, profile_id)


def get_session_detail(db: Session, profile_id: str, session_id: str):
    profile = get_profile_by_id(db, profile_id)
    if not profile:
        raise HTTPException(status_code=401, detail="Authenticated profile not found")
    session = get_session_by_id_with_scene(db, session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.profile_id != profile_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return session


def build_scene_block(scene: Scene, user_input: str, theme: Optional[str] = None, tone: Optional[str] = None) -> str:
    focus = theme or tone or (scene.mood_tags[0] if scene.mood_tags else "next moment")
    return "\n".join([
        scene.intro_text.strip(),
        f"You say, \"{user_input}\"",
        f"{scene.character.name} lets the words settle and the air shifts toward {focus}.",
        "The moment feels smaller and sharper, as if the story itself is leaning in.",
        "This is the start of the next scene block."
    ])


def add_session_turn(
    db: Session,
    profile_id: str,
    session_id: str,
    user_input: str,
    theme: Optional[str] = None,
    tone: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    session = get_session_by_id(db, session_id)
    if not session or session.status != "active":
        raise HTTPException(status_code=404, detail="Session not found")
    if session.profile_id != profile_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    scene = get_scene_by_id(db, session.scene_id)
    if not scene or not scene.is_active:
        raise HTTPException(status_code=404, detail="Scene not available")

    user_message = create_message(
        db=db,
        message_id=str(uuid4()),
        session_id=session.id,
        sender_type="user",
        speaker_type="user",
        content=user_input,
    )

    next_block = build_scene_block(scene, user_input, theme=theme, tone=tone)
    narrator_message = create_message(
        db=db,
        message_id=str(uuid4()),
        session_id=session.id,
        sender_type="ai",
        speaker_type="ai",
        content=next_block,
    )

    current_metadata = dict(session.story_metadata or {})
    if theme is not None:
        current_metadata["theme"] = theme
    if tone is not None:
        current_metadata["tone"] = tone

    current_state = dict(session.progression_state or {})
    turns = current_state.get("turns", []) or []
    turn_id = str(uuid4())
    turn_entry = {
        "id": turn_id,
        "user_input": user_input,
        "next_block": next_block,
        "theme": theme,
        "tone": tone,
        "metadata": metadata or {},
        "message_ids": [user_message.id, narrator_message.id],
    }
    turns.append(turn_entry)

    current_state.update(
        {
            "stage": "in_progress",
            "turn_count": len(turns),
            "turns": turns,
            "last_user_input": user_input,
            "last_scene_block": next_block,
            "theme": theme or current_state.get("theme"),
            "tone": tone or current_state.get("tone"),
        }
    )

    session.story_metadata = current_metadata
    session.progression_state = current_state
    save_session(db, session)

    return {
        "session": session,
        "scene": scene,
        "turn_id": turn_id,
        "next_block": next_block,
        "story_metadata": current_metadata,
        "progression_state": current_state,
        "is_complete": False,
    }


def get_session_messages(db: Session, profile_id: str, session_id: str):
    session = get_session_by_id(db, session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.profile_id != profile_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return list_messages_for_session(db, session_id)
