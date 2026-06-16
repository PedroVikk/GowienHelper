"""Implementação SQLAlchemy do repositório de materiais."""
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.domain.entities.material import MaterialEntity
from app.domain.repositories.material_repository import IMaterialRepository
from app.infrastructure.db.models.material import Material


def _to_entity(model: Material) -> MaterialEntity:
    return MaterialEntity(
        id=model.id,
        subject_id=model.subject_id,
        filename=model.filename,
        file_type=model.file_type,
        file_path=model.file_path,
        extracted_text=model.extracted_text,
        status=model.status,
    )


class SqlMaterialRepository(IMaterialRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def create(self, material: MaterialEntity) -> MaterialEntity:
        model = Material(
            subject_id=material.subject_id,
            filename=material.filename,
            file_type=material.file_type,
            file_path=material.file_path,
            extracted_text=material.extracted_text,
            status=material.status,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def get_by_id(self, material_id: int) -> MaterialEntity | None:
        model = self._db.get(Material, material_id)
        return _to_entity(model) if model else None

    def list_by_subject(self, subject_id: int) -> list[MaterialEntity]:
        rows = self._db.scalars(
            select(Material)
            .where(Material.subject_id == subject_id)
            .order_by(Material.created_at.desc())
        ).all()
        return [_to_entity(r) for r in rows]

    def set_status(self, material_id: int, status: str) -> None:
        model = self._db.get(Material, material_id)
        if model:
            model.status = status
            self._db.commit()

    def delete(self, material_id: int) -> None:
        model = self._db.get(Material, material_id)
        if model:
            self._db.delete(model)
            self._db.commit()
