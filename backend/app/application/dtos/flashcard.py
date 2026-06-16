"""DTOs da feature de flashcards (CRUD + revisão)."""
from datetime import datetime

from pydantic import BaseModel, Field


class FlashcardCreate(BaseModel):
    front: str = Field(min_length=1)
    back: str = Field(min_length=1)


class FlashcardUpdate(BaseModel):
    front: str | None = Field(default=None, min_length=1)
    back: str | None = Field(default=None, min_length=1)
    is_favorite: bool | None = None


class FlashcardReviewRequest(BaseModel):
    quality: int = Field(ge=0, le=5, description="0-2 errou, 3 difícil, 4 bom, 5 fácil")


class FlashcardResponse(BaseModel):
    id: int
    front: str
    back: str
    is_favorite: bool
    is_manual: bool
    repetitions: int
    interval_days: int
    ease_factor: float
    due_date: datetime | None
