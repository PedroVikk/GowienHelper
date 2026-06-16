"""DTOs da feature de geração de conteúdo por IA."""
from pydantic import BaseModel, Field

from app.application.dtos.quiz import QuestionResponse
from app.domain.ai.models import QuestionType


class SummaryResponse(BaseModel):
    short: str
    full: str
    topics: list[str]
    glossary: dict[str, str]
    formulas: list[str]


class MindmapResponse(BaseModel):
    markdown: str


class GenerateCountRequest(BaseModel):
    count: int = Field(default=10, ge=1, le=50)


class GenerateQuizRequest(BaseModel):
    count: int = Field(default=10, ge=1, le=50)
    types: list[QuestionType] | None = None


class FlashcardResponse(BaseModel):
    id: int
    front: str
    back: str
    is_favorite: bool
    is_manual: bool


class QuizResponse(BaseModel):
    id: int
    title: str
    kind: str
    questions: list[QuestionResponse]
