"""Entidades de domínio Quiz e Question."""
from dataclasses import dataclass, field


@dataclass(slots=True)
class QuestionEntity:
    id: int | None
    type: str
    prompt: str
    options: list[str]
    correct_answer: str
    explanation: str


@dataclass(slots=True)
class QuizEntity:
    id: int | None
    subject_id: int
    title: str
    kind: str = "quiz"  # quiz | simulado
    questions: list[QuestionEntity] = field(default_factory=list)
