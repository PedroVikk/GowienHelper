"""Implementação SQLAlchemy do repositório de usuários."""
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.domain.entities.user import UserEntity
from app.domain.repositories.user_repository import IUserRepository
from app.infrastructure.db.models.user import User
from app.infrastructure.gamification.leveling import level_for_xp


def _to_entity(model: User) -> UserEntity:
    return UserEntity(
        id=model.id,
        email=model.email,
        name=model.name,
        hashed_password=model.hashed_password,
        is_active=model.is_active,
        xp=model.xp,
        level=model.level,
        streak=model.streak,
    )


class SqlUserRepository(IUserRepository):
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_by_id(self, user_id: int) -> UserEntity | None:
        model = self._db.get(User, user_id)
        return _to_entity(model) if model else None

    def get_by_email(self, email: str) -> UserEntity | None:
        model = self._db.scalar(select(User).where(User.email == email))
        return _to_entity(model) if model else None

    def create(self, user: UserEntity) -> UserEntity:
        model = User(
            email=user.email,
            name=user.name,
            hashed_password=user.hashed_password,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)

    def add_xp(self, user_id: int, points: int) -> UserEntity:
        model = self._db.get(User, user_id)
        model.xp += points
        model.level = level_for_xp(model.xp)
        self._db.commit()
        self._db.refresh(model)
        return _to_entity(model)
