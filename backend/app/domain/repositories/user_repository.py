"""Interface do repositório de usuários (porta do domínio)."""
from abc import ABC, abstractmethod

from app.domain.entities.user import UserEntity


class IUserRepository(ABC):
    @abstractmethod
    def get_by_id(self, user_id: int) -> UserEntity | None: ...

    @abstractmethod
    def get_by_email(self, email: str) -> UserEntity | None: ...

    @abstractmethod
    def create(self, user: UserEntity) -> UserEntity: ...

    @abstractmethod
    def add_xp(self, user_id: int, points: int) -> UserEntity:
        """Soma XP, recalcula o nível e retorna o usuário atualizado."""
