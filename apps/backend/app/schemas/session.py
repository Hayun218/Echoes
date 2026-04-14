from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict

from app.schemas.scene import SceneDetailResponse


class SessionStartRequest(BaseModel):
    concept: str = Field(..., min_length=1)
    scene_id: Optional[UUID] = None
    theme: Optional[str] = None
    tone: Optional[str] = None


class SessionStartResponse(BaseModel):
    session_id: UUID
    scene: SceneDetailResponse
    story_metadata: Dict[str, Optional[str]]
    progression_state: Dict[str, Optional[str]]
    intro_text: str


class SessionTurnRequest(BaseModel):
    user_input: str = Field(..., min_length=1, max_length=120, pattern=r"^[^\n\r]+$")
    theme: Optional[str] = None
    tone: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class SessionTurnResponse(BaseModel):
    session_id: UUID
    scene_id: UUID
    turn_id: UUID
    next_block: str
    story_metadata: Dict[str, Any]
    progression_state: Dict[str, Any]
    is_complete: bool

    model_config = ConfigDict(from_attributes=True)


class SessionListItemResponse(BaseModel):
    session_id: UUID
    scene_id: UUID
    scene_title: str
    primary_character_id: Optional[UUID] = None
    primary_character_name: Optional[str] = None
    status: str
    source_type: str
    updated_at: datetime
    is_complete: bool
    last_scene_block_preview: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class SessionDetailResponse(BaseModel):
    session_id: UUID
    scene_id: UUID
    scene_title: str
    scene_intro_text: str
    primary_character_id: Optional[UUID] = None
    primary_character_name: Optional[str] = None
    status: str
    source_type: str
    updated_at: datetime
    is_complete: bool
    story_metadata: Dict[str, Any]
    progression_state: Dict[str, Any]
    last_scene_block_preview: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
