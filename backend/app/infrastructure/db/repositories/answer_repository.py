"""Implementação SQLAlchemy do repositório de respostas."""
from sqlalchemy.orm import Session

from app.domain.entities.answer import AnswerEntity
from app.domain.repositories.answer_repository import IAnswerRepository
from app.infrastructure.db.models.quiz import Answer


class SqlAnswerRepository(IAnswerRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def add(self, answer: AnswerEntity) -> AnswerEntity:
        model = Answer(
            question_id=answer.question_id,
            user_id=answer.user_id,
            user_answer=answer.user_answer,
            is_correct=answer.is_correct,
            score=answer.score,
            feedback=answer.feedback,
            time_spent_seconds=answer.time_spent_seconds,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        answer.id = model.id
        return answer
