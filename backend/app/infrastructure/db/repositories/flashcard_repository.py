"""Implementação SQLAlchemy do repositório de flashcards."""
from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.domain.entities.flashcard import FlashcardEntity
from app.domain.repositories.flashcard_repository import IFlashcardRepository
from app.infrastructure.db.models.flashcard import Flashcard


def _to_entity(m: Flashcard) -> FlashcardEntity:
    return FlashcardEntity(
        id=m.id,
        subject_id=m.subject_id,
        front=m.front,
        back=m.back,
        is_favorite=m.is_favorite,
        is_manual=m.is_manual,
        ease_factor=m.ease_factor,
        interval_days=m.interval_days,
        repetitions=m.repetitions,
        due_date=m.due_date,
    )


class SqlFlashcardRepository(IFlashcardRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def add_many(self, cards: list[FlashcardEntity]) -> list[FlashcardEntity]:
        models = [
            Flashcard(
                subject_id=c.subject_id,
                front=c.front,
                back=c.back,
                is_favorite=c.is_favorite,
                is_manual=c.is_manual,
            )
            for c in cards
        ]
        self._db.add_all(models)
        self._db.commit()
        for m in models:
            self._db.refresh(m)
        return [_to_entity(m) for m in models]

    def create(self, card: FlashcardEntity) -> FlashcardEntity:
        model = Flashcard(
            subject_id=card.subject_id,
            front=card.front,
            back=card.back,
            is_favorite=card.is_favorite,
            is_manual=card.is_manual,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def get_by_id(self, card_id: int) -> FlashcardEntity | None:
        model = self._db.get(Flashcard, card_id)
        return _to_entity(model) if model else None

    def update(self, card: FlashcardEntity) -> FlashcardEntity:
        model = self._db.get(Flashcard, card.id)
        model.front = card.front
        model.back = card.back
        model.is_favorite = card.is_favorite
        model.ease_factor = card.ease_factor
        model.interval_days = card.interval_days
        model.repetitions = card.repetitions
        model.due_date = card.due_date
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def delete(self, card_id: int) -> None:
        model = self._db.get(Flashcard, card_id)
        if model:
            self._db.delete(model)
            self._db.commit()

    def list_by_subject(
        self,
        subject_id: int,
        favorites_only: bool = False,
        due_only: bool = False,
    ) -> list[FlashcardEntity]:
        stmt = select(Flashcard).where(Flashcard.subject_id == subject_id)
        if favorites_only:
            stmt = stmt.where(Flashcard.is_favorite.is_(True))
        if due_only:
            now = datetime.now(timezone.utc)
            stmt = stmt.where(
                or_(Flashcard.due_date.is_(None), Flashcard.due_date <= now)
            )
        rows = self._db.scalars(
            stmt.order_by(Flashcard.created_at.desc())
        ).all()
        return [_to_entity(r) for r in rows]
