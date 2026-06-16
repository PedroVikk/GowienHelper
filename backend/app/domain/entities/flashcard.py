"""Entidade de domínio Flashcard."""
from dataclasses import dataclass
from datetime import datetime


@dataclass(slots=True)
class FlashcardEntity:
    id: int | None
    subject_id: int
    front: str
    back: str
    is_favorite: bool = False
    is_manual: bool = False
    # Repetição espaçada (SM-2)
    ease_factor: float = 2.5
    interval_days: int = 0
    repetitions: int = 0
    due_date: datetime | None = None
