from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict


class MessageResponse(BaseModel):
    id: UUID
    session_id: UUID
    sender_type: str
    speaker_type: str
    speaker_character_id: Optional[UUID] = None
    content: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
