"""DTOs da feature de quiz."""
from pydantic import BaseModel, Field

from app.domain.ai.models import Difficulty, QuestionType, QuizSource


class ThemedQuizRequest(BaseModel):
    theme: str = Field(min_length=1, max_length=200, description="Tema do quiz")
    count: int = Field(default=10, ge=1, le=100)
    difficulty: Difficulty = Difficulty.MEDIUM
    types: list[QuestionType] | None = Field(
        default=None, description="Tipos de questão; vazio = todos"
    )


class QuestionResponse(BaseModel):
    id: int | None = None  # None em quiz por tema (não persistido)
    type: QuestionType
    prompt: str
    options: list[str]
    correct_answer: str
    explanation: str


class ThemedQuizResponse(BaseModel):
    theme: str
    difficulty: Difficulty
    source: QuizSource  # material | general (transparência da origem)
    questions: list[QuestionResponse]
