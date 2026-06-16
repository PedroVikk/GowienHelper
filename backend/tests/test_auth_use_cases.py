"""Testes unitários dos casos de uso de autenticação (sem banco real)."""
import pytest

from app.application.use_cases.auth import (
    LoginUserUseCase,
    RegisterUserUseCase,
)
from app.core.exceptions import ConflictError, UnauthorizedError
from app.core.security import hash_password
from app.domain.entities.user import UserEntity
from app.domain.repositories.user_repository import IUserRepository


class FakeUserRepository(IUserRepository):
    """Repositório em memória para isolar os testes da infraestrutura."""

    def __init__(self) -> None:
        self._by_email: dict[str, UserEntity] = {}
        self._seq = 0

    def get_by_id(self, user_id: int) -> UserEntity | None:
        for u in self._by_email.values():
            if u.id == user_id:
                return u
        return None

    def get_by_email(self, email: str) -> UserEntity | None:
        return self._by_email.get(email)

    def create(self, user: UserEntity) -> UserEntity:
        self._seq += 1
        user.id = self._seq
        self._by_email[user.email] = user
        return user

    def add_xp(self, user_id: int, points: int) -> UserEntity:  # pragma: no cover
        user = self.get_by_id(user_id)
        user.xp += points
        return user


def test_register_creates_user():
    repo = FakeUserRepository()
    user = RegisterUserUseCase(repo).execute("Ana", "ana@test.com", "secret123")
    assert user.id == 1
    assert user.email == "ana@test.com"
    assert user.hashed_password != "secret123"


def test_register_duplicate_email_raises():
    repo = FakeUserRepository()
    RegisterUserUseCase(repo).execute("Ana", "ana@test.com", "secret123")
    with pytest.raises(ConflictError):
        RegisterUserUseCase(repo).execute("Ana 2", "ana@test.com", "outrasenha")


def test_login_success_returns_token():
    repo = FakeUserRepository()
    repo.create(
        UserEntity(
            id=None,
            email="ana@test.com",
            name="Ana",
            hashed_password=hash_password("secret123"),
        )
    )
    token = LoginUserUseCase(repo).execute("ana@test.com", "secret123")
    assert isinstance(token, str) and token


def test_login_wrong_password_raises():
    repo = FakeUserRepository()
    repo.create(
        UserEntity(
            id=None,
            email="ana@test.com",
            name="Ana",
            hashed_password=hash_password("secret123"),
        )
    )
    with pytest.raises(UnauthorizedError):
        LoginUserUseCase(repo).execute("ana@test.com", "errada")
