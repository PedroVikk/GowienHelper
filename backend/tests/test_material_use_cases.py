"""Testes unitários dos casos de uso de material (com fakes)."""
import asyncio

import pytest

from app.application.use_cases.material import (
    DeleteMaterialUseCase,
    UploadMaterialUseCase,
)
from app.core.exceptions import NotFoundError, ValidationError
from app.domain.entities.material import MaterialEntity
from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.material_repository import IMaterialRepository
from app.domain.repositories.subject_repository import ISubjectRepository
from app.domain.services.file_storage import IFileStorage
from app.domain.services.text_extraction import ITextExtractionService


class FakeSubjects(ISubjectRepository):
    def __init__(self, owner_id=1):
        self._s = SubjectEntity(id=1, user_id=owner_id, name="Psicologia")

    def create(self, s):  # pragma: no cover
        return s

    def get_by_id(self, sid):
        return self._s if sid == 1 else None

    def list_by_user(self, *a):  # pragma: no cover
        return [], 0

    def update(self, s):  # pragma: no cover
        return s

    def delete(self, sid):  # pragma: no cover
        ...


class FakeMaterials(IMaterialRepository):
    def __init__(self):
        self.items = {}
        self._seq = 0

    def create(self, m):
        self._seq += 1
        m.id = self._seq
        self.items[m.id] = m
        return m

    def get_by_id(self, mid):
        return self.items.get(mid)

    def list_by_subject(self, sid):
        return [m for m in self.items.values() if m.subject_id == sid]

    def set_status(self, mid, status):
        if mid in self.items:
            self.items[mid].status = status

    def delete(self, mid):
        self.items.pop(mid, None)


class FakeStorage(IFileStorage):
    def __init__(self):
        self.saved = []
        self.deleted = []

    def save(self, subject_id, filename, data):
        path = f"/fake/{subject_id}/{filename}"
        self.saved.append(path)
        return path

    def delete(self, path):
        self.deleted.append(path)


class FakeExtraction(ITextExtractionService):
    def __init__(self, text="texto extraído", fail=False):
        self._text = text
        self._fail = fail

    def extract(self, file_path, file_type):
        if self._fail:
            raise RuntimeError("boom")
        return self._text


def _uc(subjects=None, materials=None, storage=None, extraction=None):
    return UploadMaterialUseCase(
        subjects or FakeSubjects(),
        materials or FakeMaterials(),
        storage or FakeStorage(),
        extraction or FakeExtraction(),
    )


def test_upload_success_sets_extracted():
    mats = FakeMaterials()
    m = asyncio.run(_uc(materials=mats).execute(1, 1, "aula.txt", b"conteudo"))
    assert m.status == "extracted"
    assert m.extracted_text == "texto extraído"
    assert m.file_type == "txt"


def test_upload_unsupported_format_raises_and_saves_nothing():
    storage = FakeStorage()
    with pytest.raises(ValidationError):
        asyncio.run(_uc(storage=storage).execute(1, 1, "video.mp4", b"x"))
    assert storage.saved == []


def test_upload_empty_file_raises():
    with pytest.raises(ValidationError):
        asyncio.run(_uc().execute(1, 1, "aula.txt", b""))


def test_upload_extraction_failure_marks_failed():
    m = asyncio.run(
        _uc(extraction=FakeExtraction(fail=True)).execute(1, 1, "a.pdf", b"%PDF")
    )
    assert m.status == "failed"
    assert m.extracted_text is None


def test_upload_other_user_subject_raises():
    with pytest.raises(NotFoundError):
        asyncio.run(
            _uc(subjects=FakeSubjects(owner_id=999)).execute(1, 1, "a.txt", b"x")
        )


def test_delete_removes_file_and_record():
    mats = FakeMaterials()
    storage = FakeStorage()
    mats.create(
        MaterialEntity(
            id=None, subject_id=1, filename="a.txt", file_type="txt",
            file_path="/fake/1/a.txt", extracted_text="x", status="extracted",
        )
    )
    asyncio.run(DeleteMaterialUseCase(FakeSubjects(), mats, storage).execute(1, 1, 1))
    assert storage.deleted == ["/fake/1/a.txt"]
    assert mats.get_by_id(1) is None
