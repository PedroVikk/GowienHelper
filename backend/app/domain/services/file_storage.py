"""Porta de armazenamento de arquivos (independente de disco/S3/etc.)."""
from abc import ABC, abstractmethod


class IFileStorage(ABC):
    @abstractmethod
    def save(self, subject_id: int, filename: str, data: bytes) -> str:
        """Persiste o arquivo e retorna o caminho/identificador salvo."""

    @abstractmethod
    def delete(self, path: str) -> None:
        """Remove o arquivo (idempotente)."""
