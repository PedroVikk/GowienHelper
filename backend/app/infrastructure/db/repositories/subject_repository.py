"""Implementação SQLAlchemy do repositório de disciplinas."""
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.subject_repository import ISubjectRepository
from app.infrastructure.db.models.subject import Subject


def _to_entity(model: Subject) -> SubjectEntity:
    return SubjectEntity(
        id=model.id,
        user_id=model.user_id,
        name=model.name,
        color=model.color,
        icon=model.icon,
        professor=model.professor,
        description=model.description,
        exam_date=model.exam_date,
    )


class SqlSubjectRepository(ISubjectRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def create(self, subject: SubjectEntity) -> SubjectEntity:
        model = Subject(
            user_id=subject.user_id,
            name=subject.name,
            color=subject.color,
            icon=subject.icon,
            professor=subject.professor,
            description=subject.description,
            exam_date=subject.exam_date,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def get_by_id(self, subject_id: int) -> SubjectEntity | None:
        model = self._db.get(Subject, subject_id)
        return _to_entity(model) if model else None

    def list_by_user(
        self, user_id: int, limit: int, offset: int
    ) -> tuple[list[SubjectEntity], int]:
        base = select(Subject).where(Subject.user_id == user_id)
        total = self._db.scalar(
            select(func.count()).select_from(base.subquery())
        )
        rows = self._db.scalars(
            base.order_by(Subject.created_at.desc()).limit(limit).offset(offset)
        ).all()
        return [_to_entity(r) for r in rows], int(total or 0)

    def update(self, subject: SubjectEntity) -> SubjectEntity:
        model = self._db.get(Subject, subject.id)
        model.name = subject.name
        model.color = subject.color
        model.icon = subject.icon
        model.professor = subject.professor
        model.description = subject.description
        model.exam_date = subject.exam_date
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def delete(self, subject_id: int) -> None:
        model = self._db.get(Subject, subject_id)
        if model:
            self._db.delete(model)
            self._db.commit()
