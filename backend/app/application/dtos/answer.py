"""DTOs de resposta a questões e de simulado."""
from pydantic import BaseModel, Field

from app.domain.ai.models import QuestionType


class AnswerRequest(BaseModel):
    answer: str = Field(min_length=1)
    time_spent_seconds: int = Field(default=0, ge=0)


class AnswerEvaluationResponse(BaseModel):
    is_correct: bool
    score: float
    feedback: str | None


class SimuladoRequest(BaseModel):
    count: int = Field(description="10, 20, 50 ou 100")
    subject_ids: list[int] | None = Field(
        default=None, description="Disciplinas a misturar; vazio = todas"
    )


class SimuladoQuestion(BaseModel):
    """Questão do simulado SEM gabarito (não vaza resposta antes de responder)."""

    id: int
    type: QuestionType
    prompt: str
    options: list[str]


class SimuladoResponse(BaseModel):
    total: int
    questions: list[SimuladoQuestion]
