"""Rotas de flashcards: CRUD manual, favoritar, listar e revisar (SM-2)."""
from typing import Annotated

from app.application.dtos.flashcard import (
    FlashcardCreate,
    FlashcardResponse,
    FlashcardReviewRequest,
    FlashcardUpdate,
)
from app.application.use_cases.flashcards import (
    CreateFlashcardUseCase,
    DeleteFlashcardUseCase,
    ListFlashcardsUseCase,
    ReviewFlashcardUseCase,
    UpdateFlashcardUseCase,
)
from app.domain.entities.flashcard import FlashcardEntity
from app.presentation.api.deps import CurrentUser, FlashcardRepo, SubjectRepo
from fastapi import APIRouter, Query, status

router = APIRouter(tags=["Flashcards"])


def _to_response(c: FlashcardEntity) -> FlashcardResponse:
    return FlashcardResponse(
        id=c.id,
        front=c.front,
        back=c.back,
        is_favorite=c.is_favorite,
        is_manual=c.is_manual,
        repetitions=c.repetitions,
        interval_days=c.interval_days,
        ease_factor=c.ease_factor,
        due_date=c.due_date,
    )


@router.post(
    "/subjects/{subject_id}/flashcards",
    response_model=FlashcardResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Cria um flashcard manualmente",
)
def create_flashcard(
    subject_id: int,
    payload: FlashcardCreate,
    user: CurrentUser,
    subjects: SubjectRepo,
    flashcards: FlashcardRepo,
) -> FlashcardResponse:
    card = CreateFlashcardUseCase(subjects, flashcards).execute(
        user.id, subject_id, payload.front, payload.back
    )
    return _to_response(card)


@router.get(
    "/subjects/{subject_id}/flashcards",
    response_model=list[FlashcardResponse],
    summary="Lista flashcards (filtros: favoritos / a revisar)",
)
def list_flashcards(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    flashcards: FlashcardRepo,
    favorites_only: Annotated[bool, Query()] = False,
    due_only: Annotated[bool, Query()] = False,
) -> list[FlashcardResponse]:
    cards = ListFlashcardsUseCase(subjects, flashcards).execute(
        user.id, subject_id, favorites_only, due_only
    )
    return [_to_response(c) for c in cards]


@router.patch(
    "/flashcards/{card_id}",
    response_model=FlashcardResponse,
    summary="Edita ou favorita um flashcard",
)
def update_flashcard(
    card_id: int,
    payload: FlashcardUpdate,
    user: CurrentUser,
    subjects: SubjectRepo,
    flashcards: FlashcardRepo,
) -> FlashcardResponse:
    card = UpdateFlashcardUseCase(subjects, flashcards).execute(
        user.id, card_id, payload.model_dump(exclude_unset=True)
    )
    return _to_response(card)


@router.delete(
    "/flashcards/{card_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove um flashcard",
)
def delete_flashcard(
    card_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    flashcards: FlashcardRepo,
) -> None:
    DeleteFlashcardUseCase(subjects, flashcards).execute(user.id, card_id)


@router.post(
    "/flashcards/{card_id}/review",
    response_model=FlashcardResponse,
    summary="Registra uma revisão (repetição espaçada)",
)
def review_flashcard(
    card_id: int,
    payload: FlashcardReviewRequest,
    user: CurrentUser,
    subjects: SubjectRepo,
    flashcards: FlashcardRepo,
) -> FlashcardResponse:
    card = ReviewFlashcardUseCase(subjects, flashcards).execute(
        user.id, card_id, payload.quality
    )
    return _to_response(card)
