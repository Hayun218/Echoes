from enum import Enum
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict


class SceneAccessTier(str, Enum):
    free = "free"
    premium = "premium"


class CharacterSummary(BaseModel):
    id: UUID
    slug: str
    name: str
    avatar_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class SceneListItemResponse(BaseModel):
    id: UUID
    character_id: UUID
    slug: str
    title: str
    description: str
    intro_text: str
    thumbnail_url: Optional[str] = None
    mood_tags: List[str] = Field(default_factory=list)
    difficulty_level: int
    access_tier: SceneAccessTier
    is_public_browse: bool
    sort_order: int
    character: CharacterSummary

    model_config = ConfigDict(from_attributes=True)


class SceneDetailResponse(SceneListItemResponse):
    prompt_template: str
