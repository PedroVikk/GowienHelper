"""DTOs (schemas Pydantic) da feature de disciplinas."""
from datetime import date

from pydantic import BaseModel, Field

HEX_COLOR = r"^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$"


class SubjectCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    color: str = Field(default="#6750A4", pattern=HEX_COLOR)
    icon: str = Field(default="school", max_length=50)
    professor: str | None = Field(default=None, max_length=150)
    description: str | None = None
    exam_date: date | None = None


class SubjectUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    color: str | None = Field(default=None, pattern=HEX_COLOR)
    icon: str | None = Field(default=None, max_length=50)
    professor: str | None = Field(default=None, max_length=150)
    description: str | None = None
    exam_date: date | None = None


class SubjectResponse(BaseModel):
    id: int
    name: str
    color: str
    icon: str
    professor: str | None
    description: str | None
    exam_date: date | None

    model_config = {"from_attributes": True}


class PaginatedSubjects(BaseModel):
    items: list[SubjectResponse]
    total: int
    limit: int
    offset: int
