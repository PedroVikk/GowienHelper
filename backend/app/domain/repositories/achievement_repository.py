"""Interface do repositório de conquistas (porta do domínio)."""
from abc import ABC, abstractmethod


class IAchievementRepository(ABC):
    @abstractmethod
    def unlocked_codes(self, user_id: int) -> set[str]:
        """Códigos de conquistas já desbloqueadas pelo usuário."""

    @abstractmethod
    def unlock(
        self, user_id: int, code: str, title: str, description: str
    ) -> None:
        """Registra o desbloqueio (idempotente por código)."""
