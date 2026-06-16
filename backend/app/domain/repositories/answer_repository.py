"""Interface do repositório de respostas (porta do domínio)."""
from abc import ABC, abstractmethod

from app.domain.entities.answer import AnswerEntity


class IAnswerRepository(ABC):
    @abstractmethod
    def add(self, answer: AnswerEntity) -> AnswerEntity: ...
