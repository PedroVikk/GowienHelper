"""Interface do repositório de materiais (porta do domínio)."""
from abc import ABC, abstractmethod

from app.domain.entities.material import MaterialEntity


class IMaterialRepository(ABC):
    @abstractmethod
    def create(self, material: MaterialEntity) -> MaterialEntity: ...

    @abstractmethod
    def get_by_id(self, material_id: int) -> MaterialEntity | None: ...

    @abstractmethod
    def list_by_subject(self, subject_id: int) -> list[MaterialEntity]: ...

    @abstractmethod
    def set_status(self, material_id: int, status: str) -> None: ...

    @abstractmethod
    def delete(self, material_id: int) -> None: ...
