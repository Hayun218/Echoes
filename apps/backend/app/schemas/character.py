from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict


class CharacterResponse(BaseModel):
    id: UUID
    slug: str
    name: str
    description: str
    avatar_url: Optional[str] = None
    category: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    is_active: bool
    is_featured: bool

    model_config = ConfigDict(from_attributes=True)
