"""Casos de uso de flashcards: CRUD manual e revisão (repetição espaçada)."""
from datetime import datetime, timedelta, timezone

from app.core.exceptions import NotFoundError
from app.domain.entities.flashcard import FlashcardEntity
from app.domain.repositories.flashcard_repository import IFlashcardRepository
from app.domain.repositories.subject_repository import ISubjectRepository
from app.infrastructure.study.spaced_repetition import SrState, review


def _ensure_subject(
    subjects: ISubjectRepository, subject_id: int, user_id: int
) -> None:
    subject = subjects.get_by_id(subject_id)
    if subject is None or subject.user_id != user_id:
        raise NotFoundError("Disciplina não encontrada.")


def _card_owned(
    subjects: ISubjectRepository,
    flashcards: IFlashcardRepository,
    card_id: int,
    user_id: int,
) -> FlashcardEntity:
    card = flashcards.get_by_id(card_id)
    if card is None:
        raise NotFoundError("Flashcard não encontrado.")
    _ensure_subject(subjects, card.subject_id, user_id)
    return card


class CreateFlashcardUseCase:
    def __init__(
        self, subjects: ISubjectRepository, flashcards: IFlashcardRepository
    ) -> None:
        self._subjects = subjects
        self._flashcards = flashcards

    def execute(
        self, user_id: int, subject_id: int, front: str, back: str
    ) -> FlashcardEntity:
        _ensure_subject(self._subjects, subject_id, user_id)
        card = FlashcardEntity(
            id=None,
            subject_id=subject_id,
            front=front,
            back=back,
            is_manual=True,
        )
        return self._flashcards.create(card)


class UpdateFlashcardUseCase:
    def __init__(
        self, subjects: ISubjectRepository, flashcards: IFlashcardRepository
    ) -> None:
        self._subjects = subjects
        self._flashcards = flashcards

    def execute(
        self, user_id: int, card_id: int, changes: dict
    ) -> FlashcardEntity:
        card = _card_owned(self._subjects, self._flashcards, card_id, user_id)
        for field in ("front", "back", "is_favorite"):
            if field in changes and changes[field] is not None:
                setattr(card, field, changes[field])
        return self._flashcards.update(card)


class DeleteFlashcardUseCase:
    def __init__(
        self, subjects: ISubjectRepository, flashcards: IFlashcardRepository
    ) -> None:
        self._subjects = subjects
        self._flashcards = flashcards

    def execute(self, user_id: int, card_id: int) -> None:
        _card_owned(self._subjects, self._flashcards, card_id, user_id)
        self._flashcards.delete(card_id)


class ListFlashcardsUseCase:
    def __init__(
        self, subjects: ISubjectRepository, flashcards: IFlashcardRepository
    ) -> None:
        self._subjects = subjects
        self._flashcards = flashcards

    def execute(
        self,
        user_id: int,
        subject_id: int,
        favorites_only: bool = False,
        due_only: bool = False,
    ) -> list[FlashcardEntity]:
        _ensure_subject(self._subjects, subject_id, user_id)
        return self._flashcards.list_by_subject(
            subject_id, favorites_only, due_only
        )


class ReviewFlashcardUseCase:
    """Aplica o SM-2 ao card e reagenda a próxima revisão."""

    def __init__(
        self, subjects: ISubjectRepository, flashcards: IFlashcardRepository
    ) -> None:
        self._subjects = subjects
        self._flashcards = flashcards

    def execute(
        self, user_id: int, card_id: int, quality: int
    ) -> FlashcardEntity:
        card = _card_owned(self._subjects, self._flashcards, card_id, user_id)
        new_state = review(
            SrState(card.ease_factor, card.interval_days, card.repetitions),
            quality,
        )
        card.ease_factor = new_state.ease_factor
        card.interval_days = new_state.interval_days
        card.repetitions = new_state.repetitions
        card.due_date = datetime.now(timezone.utc) + timedelta(
            days=new_state.interval_days
        )
        return self._flashcards.update(card)
