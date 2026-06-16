"""Importa todos os models para que o SQLAlchemy registre as tabelas."""
from app.infrastructure.db.models.flashcard import Flashcard
from app.infrastructure.db.models.material import Chunk, Material
from app.infrastructure.db.models.quiz import Answer, Question, Quiz
from app.infrastructure.db.models.study import (
    Achievement,
    Message,
    StudySession,
)
from app.infrastructure.db.models.subject import Subject
from app.infrastructure.db.models.user import User

__all__ = [
    "User",
    "Subject",
    "Material",
    "Chunk",
    "Flashcard",
    "Quiz",
    "Question",
    "Answer",
    "StudySession",
    "Achievement",
    "Message",
]
