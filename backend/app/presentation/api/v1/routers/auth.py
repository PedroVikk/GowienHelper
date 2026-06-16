"""Rotas de autenticação."""
from fastapi import APIRouter, status

from app.application.dtos.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.application.use_cases.auth import LoginUserUseCase, RegisterUserUseCase
from app.presentation.api.deps import CurrentUser, UserRepo

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Cria um novo usuário",
)
def register(payload: RegisterRequest, users: UserRepo) -> UserResponse:
    user = RegisterUserUseCase(users).execute(
        payload.name, payload.email, payload.password
    )
    return UserResponse.model_validate(user)


@router.post("/login", response_model=TokenResponse, summary="Autentica e retorna JWT")
def login(payload: LoginRequest, users: UserRepo) -> TokenResponse:
    token = LoginUserUseCase(users).execute(payload.email, payload.password)
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse, summary="Dados do usuário logado")
def me(current_user: CurrentUser) -> UserResponse:
    return UserResponse.model_validate(current_user)
