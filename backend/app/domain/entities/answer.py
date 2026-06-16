"""Entidade de domínio Answer (resposta do usuário a uma questão)."""
from dataclasses import dataclass


@dataclass(slots=True)
class AnswerEntity:
    id: int | None
    question_id: int
    user_id: int
    user_answer: str
    is_correct: bool
    score: float
    feedback: str | None = None
    time_spent_seconds: int = 0
