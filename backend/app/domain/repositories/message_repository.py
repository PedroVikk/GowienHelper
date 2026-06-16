"""Interface do repositório de mensagens do chat (porta do domínio)."""
from abc import ABC, abstractmethod

from app.domain.entities.message import MessageEntity


class IMessageRepository(ABC):
    @abstractmethod
    def add(self, message: MessageEntity) -> MessageEntity: ...

    @abstractmethod
    def list_by_subject(
        self, subject_id: int, limit: int, offset: int
    ) -> tuple[list[MessageEntity], int]:
        """Histórico em ordem cronológica + total."""

    @abstractmethod
    def delete_by_subject(self, subject_id: int) -> None: ...
