"""Interface do repositório de flashcards (porta do domínio)."""
from abc import ABC, abstractmethod

from app.domain.entities.flashcard import FlashcardEntity


class IFlashcardRepository(ABC):
    @abstractmethod
    def add_many(self, cards: list[FlashcardEntity]) -> list[FlashcardEntity]: ...

    @abstractmethod
    def create(self, card: FlashcardEntity) -> FlashcardEntity: ...

    @abstractmethod
    def get_by_id(self, card_id: int) -> FlashcardEntity | None: ...

    @abstractmethod
    def update(self, card: FlashcardEntity) -> FlashcardEntity: ...

    @abstractmethod
    def delete(self, card_id: int) -> None: ...

    @abstractmethod
    def list_by_subject(
        self,
        subject_id: int,
        favorites_only: bool = False,
        due_only: bool = False,
    ) -> list[FlashcardEntity]: ...
