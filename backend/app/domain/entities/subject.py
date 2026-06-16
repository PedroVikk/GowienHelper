"""Entidade de domínio Subject (independente do ORM)."""
from dataclasses import dataclass
from datetime import date


@dataclass(slots=True)
class SubjectEntity:
    id: int | None
    user_id: int
    name: str
    color: str = "#6750A4"
    icon: str = "school"
    professor: str | None = None
    description: str | None = None
    exam_date: date | None = None
