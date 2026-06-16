"""Interface do repositório de chunks (porta do domínio)."""
from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(slots=True)
class ChunkRecord:
    material_id: int
    index: int
    content: str
    vector_id: str


class IChunkRepository(ABC):
    @abstractmethod
    def add_many(self, chunks: list[ChunkRecord]) -> None: ...

    @abstractmethod
    def delete_by_material(self, material_id: int) -> None: ...
