"""Implementação SQLAlchemy do repositório de quizzes."""
import json

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.domain.entities.quiz import QuestionEntity, QuizEntity
from app.domain.repositories.quiz_repository import (
    IQuizRepository,
    QuestionContext,
)
from app.infrastructure.db.models.quiz import Question, Quiz
from app.infrastructure.db.models.subject import Subject


def _question_to_entity(m: Question) -> QuestionEntity:
    return QuestionEntity(
        id=m.id,
        type=m.type,
        prompt=m.prompt,
        options=json.loads(m.options_json) if m.options_json else [],
        correct_answer=m.correct_answer,
        explanation=m.explanation or "",
    )


def _to_entity(m: Quiz) -> QuizEntity:
    return QuizEntity(
        id=m.id,
        subject_id=m.subject_id,
        title=m.title,
        kind=m.kind,
        questions=[_question_to_entity(q) for q in m.questions],
    )


class SqlQuizRepository(IQuizRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def create(self, quiz: QuizEntity) -> QuizEntity:
        model = Quiz(subject_id=quiz.subject_id, title=quiz.title, kind=quiz.kind)
        model.questions = [
            Question(
                type=q.type,
                prompt=q.prompt,
                options_json=json.dumps(q.options) if q.options else None,
                correct_answer=q.correct_answer,
                explanation=q.explanation,
            )
            for q in quiz.questions
        ]
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def get_by_id(self, quiz_id: int) -> QuizEntity | None:
        model = self._db.get(Quiz, quiz_id)
        return _to_entity(model) if model else None

    def list_by_subject(self, subject_id: int) -> list[QuizEntity]:
        rows = self._db.scalars(
            select(Quiz)
            .where(Quiz.subject_id == subject_id)
            .order_by(Quiz.created_at.desc())
        ).all()
        return [_to_entity(r) for r in rows]

    def get_question(self, question_id: int) -> QuestionContext | None:
        model = self._db.get(Question, question_id)
        if model is None:
            return None
        return QuestionContext(
            question=_question_to_entity(model),
            quiz_id=model.quiz_id,
            subject_id=model.quiz.subject_id,
        )

    def random_questions_for_user(
        self, user_id: int, count: int, subject_ids: list[int] | None = None
    ) -> list[QuestionEntity]:
        stmt = (
            select(Question)
            .join(Quiz, Question.quiz_id == Quiz.id)
            .join(Subject, Quiz.subject_id == Subject.id)
            .where(Subject.user_id == user_id)
        )
        if subject_ids:
            stmt = stmt.where(Subject.id.in_(subject_ids))
        rows = self._db.scalars(
            stmt.order_by(func.random()).limit(count)
        ).all()
        return [_question_to_entity(r) for r in rows]
