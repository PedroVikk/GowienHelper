"""Testes unitários dos casos de uso de disciplinas (sem banco real)."""
import pytest

from app.application.use_cases.subject import (
    CreateSubjectUseCase,
    DeleteSubjectUseCase,
    GetSubjectUseCase,
    ListSubjectsUseCase,
    SubjectInput,
    UpdateSubjectUseCase,
)
from app.core.exceptions import NotFoundError
from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.subject_repository import ISubjectRepository


class FakeSubjectRepo(ISubjectRepository):
    def __init__(self) -> None:
        self._items: dict[int, SubjectEntity] = {}
        self._seq = 0

    def create(self, subject: SubjectEntity) -> SubjectEntity:
        self._seq += 1
        subject.id = self._seq
        self._items[subject.id] = subject
        return subject

    def get_by_id(self, subject_id: int):
        return self._items.get(subject_id)

    def list_by_user(self, user_id, limit, offset):
        owned = [s for s in self._items.values() if s.user_id == user_id]
        return owned[offset : offset + limit], len(owned)

    def update(self, subject: SubjectEntity) -> SubjectEntity:
        self._items[subject.id] = subject
        return subject

    def delete(self, subject_id: int) -> None:
        self._items.pop(subject_id, None)


def _input(name="Psicologia") -> SubjectInput:
    return SubjectInput(
        name=name,
        color="#8B7CF6",
        icon="psychology",
        professor="Dra. Ana",
        description=None,
        exam_date=None,
    )


def test_create_and_get():
    repo = FakeSubjectRepo()
    created = CreateSubjectUseCase(repo).execute(user_id=1, data=_input())
    assert created.id == 1 and created.user_id == 1
    fetched = GetSubjectUseCase(repo).execute(user_id=1, subject_id=1)
    assert fetched.name == "Psicologia"


def test_get_other_users_subject_raises_404():
    repo = FakeSubjectRepo()
    CreateSubjectUseCase(repo).execute(user_id=1, data=_input())
    with pytest.raises(NotFoundError):
        GetSubjectUseCase(repo).execute(user_id=2, subject_id=1)


def test_update_changes_fields():
    repo = FakeSubjectRepo()
    CreateSubjectUseCase(repo).execute(user_id=1, data=_input())
    updated = UpdateSubjectUseCase(repo).execute(
        user_id=1, subject_id=1, changes={"name": "Psico II", "color": "#34D399"}
    )
    assert updated.name == "Psico II" and updated.color == "#34D399"


def test_update_other_user_raises_404():
    repo = FakeSubjectRepo()
    CreateSubjectUseCase(repo).execute(user_id=1, data=_input())
    with pytest.raises(NotFoundError):
        UpdateSubjectUseCase(repo).execute(2, 1, {"name": "x"})


def test_delete_requires_ownership():
    repo = FakeSubjectRepo()
    CreateSubjectUseCase(repo).execute(user_id=1, data=_input())
    with pytest.raises(NotFoundError):
        DeleteSubjectUseCase(repo).execute(user_id=2, subject_id=1)
    DeleteSubjectUseCase(repo).execute(user_id=1, subject_id=1)
    assert repo.get_by_id(1) is None


def test_list_pagination():
    repo = FakeSubjectRepo()
    for i in range(5):
        CreateSubjectUseCase(repo).execute(user_id=1, data=_input(f"M{i}"))
    items, total = ListSubjectsUseCase(repo).execute(user_id=1, limit=2, offset=2)
    assert total == 5 and len(items) == 2
