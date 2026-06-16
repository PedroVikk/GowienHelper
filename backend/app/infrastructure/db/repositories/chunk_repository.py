"""Implementação SQLAlchemy do repositório de chunks."""
from sqlalchemy import delete
from sqlalchemy.orm import Session

from app.domain.repositories.chunk_repository import (
    ChunkRecord,
    IChunkRepository,
)
from app.infrastructure.db.models.material import Chunk


class SqlChunkRepository(IChunkRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def add_many(self, chunks: list[ChunkRecord]) -> None:
        if not chunks:
            return
        self._db.add_all(
            [
                Chunk(
                    material_id=c.material_id,
                    index=c.index,
                    content=c.content,
                    vector_id=c.vector_id,
                )
                for c in chunks
            ]
        )
        self._db.commit()

    def delete_by_material(self, material_id: int) -> None:
        self._db.execute(
            delete(Chunk).where(Chunk.material_id == material_id)
        )
        self._db.commit()
