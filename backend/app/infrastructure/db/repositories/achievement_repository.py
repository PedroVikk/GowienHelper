"""Implementação SQLAlchemy do repositório de conquistas."""
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.domain.repositories.achievement_repository import (
    IAchievementRepository,
)
from app.infrastructure.db.models.study import Achievement


class SqlAchievementRepository(IAchievementRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def unlocked_codes(self, user_id: int) -> set[str]:
        rows = self._db.scalars(
            select(Achievement.code).where(Achievement.user_id == user_id)
        ).all()
        return set(rows)

    def unlock(
        self, user_id: int, code: str, title: str, description: str
    ) -> None:
        if code in self.unlocked_codes(user_id):
            return
        self._db.add(
            Achievement(
                user_id=user_id,
                code=code,
                title=title,
                description=description,
                unlocked_at=datetime.now(timezone.utc),
            )
        )
        self._db.commit()
