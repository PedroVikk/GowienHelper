"""Implementação SQLAlchemy das estatísticas (compatível SQLite/Postgres)."""
from datetime import date, datetime, timezone, timedelta

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.domain.repositories.stats_repository import (
    DailyStat,
    IStatsRepository,
    SubjectStat,
    Totals,
)
from app.infrastructure.db.models.quiz import Answer, Question, Quiz
from app.infrastructure.db.models.subject import Subject

_CORRECT = func.coalesce(func.sum(case((Answer.is_correct, 1), else_=0)), 0)


def _as_date(value) -> date:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return date.fromisoformat(str(value)[:10])


class SqlStatsRepository(IStatsRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def totals(self, user_id: int) -> Totals:
        row = self._db.execute(
            select(
                func.count(Answer.id),
                _CORRECT,
                func.coalesce(func.sum(Answer.time_spent_seconds), 0),
            ).where(Answer.user_id == user_id)
        ).one()
        return Totals(answered=int(row[0]), correct=int(row[1]), time_seconds=int(row[2]))

    def by_subject(self, user_id: int) -> list[SubjectStat]:
        rows = self._db.execute(
            select(Subject.id, Subject.name, func.count(Answer.id), _CORRECT)
            .join(Question, Answer.question_id == Question.id)
            .join(Quiz, Question.quiz_id == Quiz.id)
            .join(Subject, Quiz.subject_id == Subject.id)
            .where(Answer.user_id == user_id)
            .group_by(Subject.id, Subject.name)
        ).all()
        stats = [
            SubjectStat(
                subject_id=r[0],
                name=r[1],
                answered=int(r[2]),
                correct=int(r[3]),
                accuracy=round(int(r[3]) / int(r[2]), 3) if r[2] else 0.0,
            )
            for r in rows
        ]
        # mais difíceis primeiro (menor acurácia)
        stats.sort(key=lambda s: s.accuracy)
        return stats

    def evolution(self, user_id: int, days: int) -> list[DailyStat]:
        cutoff = datetime.now(timezone.utc) - timedelta(days=days)
        day = func.date(Answer.created_at)
        rows = self._db.execute(
            select(day, func.count(Answer.id), _CORRECT)
            .where(Answer.user_id == user_id, Answer.created_at >= cutoff)
            .group_by(day)
            .order_by(day)
        ).all()
        return [
            DailyStat(day=str(r[0])[:10], answered=int(r[1]), correct=int(r[2]))
            for r in rows
        ]

    def activity_dates(self, user_id: int) -> set[date]:
        rows = self._db.execute(
            select(func.date(Answer.created_at))
            .where(Answer.user_id == user_id)
            .distinct()
        ).scalars().all()
        return {_as_date(r) for r in rows if r is not None}
