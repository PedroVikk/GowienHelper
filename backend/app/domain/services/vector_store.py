"""Porta do banco vetorial (independente de ChromaDB/Pinecone/etc.)."""
from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(slots=True)
class VectorItem:
    id: str
    embedding: list[float]
    document: str
    material_id: int


class IVectorStore(ABC):
    @abstractmethod
    def add(self, subject_id: int, items: list[VectorItem]) -> None:
        """Insere vetores na coleção da disciplina."""

    @abstractmethod
    def query(
        self, subject_id: int, embedding: list[float], top_k: int = 5
    ) -> list[str]:
        """Retorna os documentos (trechos) mais relevantes ao embedding."""

    @abstractmethod
    def delete_material(self, subject_id: int, material_id: int) -> None:
        """Remove todos os vetores de um material."""
