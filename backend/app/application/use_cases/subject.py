"""Casos de uso de disciplinas, com verificação de propriedade (ownership)."""
from dataclasses import dataclass
from datetime import date

from app.core.exceptions import NotFoundError
from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.subject_repository import ISubjectRepository


@dataclass(slots=True)
class SubjectInput:
    name: str
    color: str
    icon: str
    professor: str | None
    description: str | None
    exam_date: date | None


def _owned_or_404(
    repo: ISubjectRepository, subject_id: int, user_id: int
) -> SubjectEntity:
    """Busca a disciplina garantindo que pertence ao usuário."""
    subject = repo.get_by_id(subject_id)
    if subject is None or subject.user_id != user_id:
        raise NotFoundError("Disciplina não encontrada.")
    return subject


class CreateSubjectUseCase:
    def __init__(self, repo: ISubjectRepository) -> None:
        self._repo = repo

    def execute(self, user_id: int, data: SubjectInput) -> SubjectEntity:
        entity = SubjectEntity(
            id=None,
            user_id=user_id,
            name=data.name,
            color=data.color,
            icon=data.icon,
            professor=data.professor,
            description=data.description,
            exam_date=data.exam_date,
        )
        return self._repo.create(entity)


class ListSubjectsUseCase:
    def __init__(self, repo: ISubjectRepository) -> None:
        self._repo = repo

    def execute(
        self, user_id: int, limit: int, offset: int
    ) -> tuple[list[SubjectEntity], int]:
        return self._repo.list_by_user(user_id, limit, offset)


class GetSubjectUseCase:
    def __init__(self, repo: ISubjectRepository) -> None:
        self._repo = repo

    def execute(self, user_id: int, subject_id: int) -> SubjectEntity:
        return _owned_or_404(self._repo, subject_id, user_id)


class UpdateSubjectUseCase:
    def __init__(self, repo: ISubjectRepository) -> None:
        self._repo = repo

    def execute(
        self, user_id: int, subject_id: int, changes: dict
    ) -> SubjectEntity:
        subject = _owned_or_404(self._repo, subject_id, user_id)
        for field, value in changes.items():
            setattr(subject, field, value)
        return self._repo.update(subject)


class DeleteSubjectUseCase:
    def __init__(self, repo: ISubjectRepository) -> None:
        self._repo = repo

    def execute(self, user_id: int, subject_id: int) -> None:
        _owned_or_404(self._repo, subject_id, user_id)
        self._repo.delete(subject_id)
