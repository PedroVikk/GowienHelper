"""Entidade de domínio User (independente do ORM)."""
from dataclasses import dataclass


@dataclass(slots=True)
class UserEntity:
    id: int | None
    email: str
    name: str
    hashed_password: str
    is_active: bool = True
    xp: int = 0
    level: int = 1
    streak: int = 0
