"""Porta de indexação de material para RAG."""
from abc import ABC, abstractmethod

from app.domain.entities.material import MaterialEntity


class IMaterialIndexer(ABC):
    @abstractmethod
    async def index(self, material: MaterialEntity) -> int:
        """Indexa o material (chunks + embeddings). Retorna nº de chunks."""

    @abstractmethod
    async def remove(self, material: MaterialEntity) -> None:
        """Remove a indexação do material."""
