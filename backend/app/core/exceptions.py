"""Exceções de domínio da aplicação (independentes de framework)."""


class DomainError(Exception):
    """Erro de regra de negócio. status_code define o HTTP correspondente."""

    status_code: int = 400

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class NotFoundError(DomainError):
    status_code = 404


class ConflictError(DomainError):
    status_code = 409


class UnauthorizedError(DomainError):
    status_code = 401


class ValidationError(DomainError):
    status_code = 422
