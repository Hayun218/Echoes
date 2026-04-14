from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy.orm import Session

from app.db import get_db
from app.repositories.character_repository import get_character_by_id, list_active_characters
from app.repositories.scene_repository import get_scene_by_id, list_public_scenes
from app.schemas.character import CharacterResponse
from app.schemas.message import MessageResponse
from app.schemas.scene import SceneAccessTier, SceneDetailResponse, SceneListItemResponse
from app.schemas.session import (
    SessionDetailResponse,
    SessionListItemResponse,
    SessionStartRequest,
    SessionStartResponse,
    SessionTurnRequest,
    SessionTurnResponse,
)
from app.services.session_service import (
    add_session_turn,
    get_session_detail,
    get_session_messages,
    get_sessions_for_profile,
    start_session,
)

router = APIRouter()


def get_current_profile_id(x_profile_id: Optional[str] = Header(None, alias="X-Profile-Id")) -> str:
    if not x_profile_id:
        raise HTTPException(status_code=401, detail="Missing authenticated profile id")
    return x_profile_id


@router.get("/health")
async def health():
    return {"status": "ok"}


@router.get("/characters", response_model=List[CharacterResponse])
def read_characters(db: Session = Depends(get_db)):
    return list_active_characters(db)


@router.get("/characters/{character_id}", response_model=CharacterResponse)
def read_character(character_id: UUID, db: Session = Depends(get_db)):
    character = get_character_by_id(db, str(character_id))
    if not character:
        raise HTTPException(status_code=404, detail="Character not found")
    return character


@router.get("/scenes", response_model=List[SceneListItemResponse])
def read_scenes(
    access_tier: Optional[SceneAccessTier] = Query(None, description="Optional access tier filter."),
    db: Session = Depends(get_db),
):
    tier_value = access_tier.value if access_tier else None
    return list_public_scenes(db, access_tier=tier_value)


@router.get("/scenes/{scene_id}", response_model=SceneDetailResponse)
def read_scene(scene_id: UUID, db: Session = Depends(get_db)):
    scene = get_scene_by_id(db, str(scene_id))
    if not scene:
        raise HTTPException(status_code=404, detail="Scene not found")
    return scene


@router.post("/sessions/start", response_model=SessionStartResponse)
def start_session_route(
    request: SessionStartRequest,
    profile_id: str = Depends(get_current_profile_id),
    db: Session = Depends(get_db),
):
    result = start_session(
        db=db,
        profile_id=profile_id,
        concept=request.concept,
        scene_id=str(request.scene_id) if request.scene_id else None,
        theme=request.theme,
        tone=request.tone,
    )
    return {
        "session_id": result["session"].id,
        "scene": result["scene"],
        "story_metadata": result["story_metadata"],
        "progression_state": result["progression_state"],
        "intro_text": result["scene"].intro_text,
    }


@router.post("/sessions/{session_id}/turns", response_model=SessionTurnResponse)
def add_session_turn_route(
    session_id: UUID,
    request: SessionTurnRequest,
    profile_id: str = Depends(get_current_profile_id),
    db: Session = Depends(get_db),
):
    result = add_session_turn(
        db=db,
        profile_id=profile_id,
        session_id=str(session_id),
        user_input=request.user_input,
        theme=request.theme,
        tone=request.tone,
        metadata=request.metadata,
    )
    return {
        "session_id": result["session"].id,
        "scene_id": result["scene"].id,
        "turn_id": result["turn_id"],
        "next_block": result["next_block"],
        "story_metadata": result["story_metadata"],
        "progression_state": result["progression_state"],
        "is_complete": result["is_complete"],
    }


@router.get("/sessions", response_model=List[SessionListItemResponse])
def read_sessions_for_profile(
    profile_id: str = Depends(get_current_profile_id),
    db: Session = Depends(get_db),
):
    sessions = get_sessions_for_profile(db=db, profile_id=profile_id)
    return [
        {
            "session_id": session.id,
            "scene_id": session.scene_id,
            "scene_title": session.scene.title,
            "primary_character_id": session.scene.character.id if session.scene and session.scene.character else None,
            "primary_character_name": session.scene.character.name if session.scene and session.scene.character else None,
            "status": session.status,
            "source_type": session.source_type,
            "updated_at": session.updated_at,
            "is_complete": session.status == "complete" or (session.progression_state or {}).get("stage") == "complete",
            "last_scene_block_preview": (session.progression_state or {}).get("last_scene_block"),
        }
        for session in sessions
    ]


@router.get("/sessions/{session_id}", response_model=SessionDetailResponse)
def read_session_detail(
    session_id: UUID,
    profile_id: str = Depends(get_current_profile_id),
    db: Session = Depends(get_db),
):
    session = get_session_detail(db=db, profile_id=profile_id, session_id=str(session_id))
    return {
        "session_id": session.id,
        "scene_id": session.scene_id,
        "scene_title": session.scene.title,
        "scene_intro_text": session.scene.intro_text,
        "primary_character_id": session.scene.character.id if session.scene and session.scene.character else None,
        "primary_character_name": session.scene.character.name if session.scene and session.scene.character else None,
        "status": session.status,
        "source_type": session.source_type,
        "updated_at": session.updated_at,
        "is_complete": session.status == "complete" or (session.progression_state or {}).get("stage") == "complete",
        "story_metadata": session.story_metadata,
        "progression_state": session.progression_state,
        "last_scene_block_preview": (session.progression_state or {}).get("last_scene_block"),
    }


@router.get("/sessions/{session_id}/messages", response_model=List[MessageResponse])
def read_session_messages(
    session_id: UUID,
    profile_id: str = Depends(get_current_profile_id),
    db: Session = Depends(get_db),
):
    return get_session_messages(db=db, profile_id=profile_id, session_id=str(session_id))
