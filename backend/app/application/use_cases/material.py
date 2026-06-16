"""Casos de uso de materiais: upload+extração, listagem e remoção."""
from pathlib import Path

from loguru import logger

from app.core.exceptions import NotFoundError, ValidationError
from app.domain.entities.material import MaterialEntity
from app.domain.repositories.material_repository import IMaterialRepository
from app.domain.repositories.subject_repository import ISubjectRepository
from app.domain.services.file_storage import IFileStorage
from app.domain.services.indexer import IMaterialIndexer
from app.domain.services.text_extraction import (
    FILE_TYPE_BY_EXT,
    ITextExtractionService,
)


def _ensure_subject(
    subjects: ISubjectRepository, subject_id: int, user_id: int
) -> None:
    subject = subjects.get_by_id(subject_id)
    if subject is None or subject.user_id != user_id:
        raise NotFoundError("Disciplina não encontrada.")


class UploadMaterialUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        materials: IMaterialRepository,
        storage: IFileStorage,
        extraction: ITextExtractionService,
        indexer: IMaterialIndexer | None = None,
    ) -> None:
        self._subjects = subjects
        self._materials = materials
        self._storage = storage
        self._extraction = extraction
        self._indexer = indexer

    async def execute(
        self, user_id: int, subject_id: int, filename: str, data: bytes
    ) -> MaterialEntity:
        _ensure_subject(self._subjects, subject_id, user_id)

        if not data:
            raise ValidationError("Arquivo vazio.")

        ext = Path(filename).suffix.lower()
        file_type = FILE_TYPE_BY_EXT.get(ext)
        if file_type is None:
            raise ValidationError(
                f"Formato não suportado: '{ext}'. "
                "Use PDF, DOCX, TXT, Markdown ou imagem."
            )

        path = self._storage.save(subject_id, filename, data)

        try:
            text = self._extraction.extract(path, file_type)
            status = "extracted"
        except Exception:  # noqa: BLE001 - registra e marca como falha
            logger.exception("Falha ao extrair texto de {}", filename)
            text, status = None, "failed"

        material = MaterialEntity(
            id=None,
            subject_id=subject_id,
            filename=filename,
            file_type=file_type,
            file_path=path,
            extracted_text=text or None,
            status=status,
        )
        material = self._materials.create(material)

        # Indexação RAG é best-effort: se Ollama/Chroma estiverem fora, o material
        # continua utilizável via fallback de texto completo (status fica 'extracted').
        if self._indexer and status == "extracted" and text:
            try:
                await self._indexer.index(material)
                self._materials.set_status(material.id, "processed")
                material.status = "processed"
            except Exception:  # noqa: BLE001
                logger.warning(
                    "Indexação RAG falhou para material {}; usando fallback",
                    material.id,
                )

        return material


class ListMaterialsUseCase:
    def __init__(
        self, subjects: ISubjectRepository, materials: IMaterialRepository
    ) -> None:
        self._subjects = subjects
        self._materials = materials

    def execute(self, user_id: int, subject_id: int) -> list[MaterialEntity]:
        _ensure_subject(self._subjects, subject_id, user_id)
        return self._materials.list_by_subject(subject_id)


class DeleteMaterialUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        materials: IMaterialRepository,
        storage: IFileStorage,
        indexer: IMaterialIndexer | None = None,
    ) -> None:
        self._subjects = subjects
        self._materials = materials
        self._storage = storage
        self._indexer = indexer

    async def execute(
        self, user_id: int, subject_id: int, material_id: int
    ) -> None:
        _ensure_subject(self._subjects, subject_id, user_id)
        material = self._materials.get_by_id(material_id)
        if material is None or material.subject_id != subject_id:
            raise NotFoundError("Material não encontrado.")

        if self._indexer:
            try:
                await self._indexer.remove(material)
            except Exception:  # noqa: BLE001 - vetores órfãos não bloqueiam a remoção
                logger.warning(
                    "Falha ao remover índice do material {}", material_id
                )

        self._storage.delete(material.file_path)
        self._materials.delete(material_id)
