"""Casos de uso de autenticação: registro e login."""
from app.core.exceptions import ConflictError, UnauthorizedError
from app.core.security import (
    create_access_token,
    hash_password,
    verify_password,
)
from app.domain.entities.user import UserEntity
from app.domain.repositories.user_repository import IUserRepository


class RegisterUserUseCase:
    def __init__(self, users: IUserRepository) -> None:
        self._users = users

    def execute(self, name: str, email: str, password: str) -> UserEntity:
        if self._users.get_by_email(email):
            raise ConflictError("Já existe um usuário com este e-mail.")
        entity = UserEntity(
            id=None,
            email=email,
            name=name,
            hashed_password=hash_password(password),
        )
        return self._users.create(entity)


class LoginUserUseCase:
    def __init__(self, users: IUserRepository) -> None:
        self._users = users

    def execute(self, email: str, password: str) -> str:
        user = self._users.get_by_email(email)
        if not user or not verify_password(password, user.hashed_password):
            raise UnauthorizedError("E-mail ou senha inválidos.")
        if not user.is_active:
            raise UnauthorizedError("Usuário inativo.")
        return create_access_token(user.id)
