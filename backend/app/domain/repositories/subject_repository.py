"""Interface do repositório de disciplinas (porta do domínio)."""
from abc import ABC, abstractmethod

from app.domain.entities.subject import SubjectEntity


class ISubjectRepository(ABC):
    @abstractmethod
    def create(self, subject: SubjectEntity) -> SubjectEntity: ...

    @abstractmethod
    def get_by_id(self, subject_id: int) -> SubjectEntity | None: ...

    @abstractmethod
    def list_by_user(
        self, user_id: int, limit: int, offset: int
    ) -> tuple[list[SubjectEntity], int]:
        """Retorna (página de disciplinas, total do usuário)."""

    @abstractmethod
    def update(self, subject: SubjectEntity) -> SubjectEntity: ...

    @abstractmethod
    def delete(self, subject_id: int) -> None: ...
