"""Rotas de disciplinas (subjects)."""
from typing import Annotated

from fastapi import APIRouter, Query, status

from app.application.dtos.subject import (
    PaginatedSubjects,
    SubjectCreate,
    SubjectResponse,
    SubjectUpdate,
)
from app.application.use_cases.subject import (
    CreateSubjectUseCase,
    DeleteSubjectUseCase,
    GetSubjectUseCase,
    ListSubjectsUseCase,
    SubjectInput,
    UpdateSubjectUseCase,
)
from app.presentation.api.deps import CurrentUser, SubjectRepo

router = APIRouter(prefix="/subjects", tags=["Disciplinas"])


@router.post(
    "",
    response_model=SubjectResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Cria uma disciplina",
)
def create_subject(
    payload: SubjectCreate, user: CurrentUser, repo: SubjectRepo
) -> SubjectResponse:
    subject = CreateSubjectUseCase(repo).execute(
        user.id, SubjectInput(**payload.model_dump())
    )
    return SubjectResponse.model_validate(subject)


@router.get("", response_model=PaginatedSubjects, summary="Lista disciplinas")
def list_subjects(
    user: CurrentUser,
    repo: SubjectRepo,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> PaginatedSubjects:
    items, total = ListSubjectsUseCase(repo).execute(user.id, limit, offset)
    return PaginatedSubjects(
        items=[SubjectResponse.model_validate(s) for s in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/{subject_id}", response_model=SubjectResponse, summary="Detalha disciplina"
)
def get_subject(
    subject_id: int, user: CurrentUser, repo: SubjectRepo
) -> SubjectResponse:
    subject = GetSubjectUseCase(repo).execute(user.id, subject_id)
    return SubjectResponse.model_validate(subject)


@router.patch(
    "/{subject_id}", response_model=SubjectResponse, summary="Atualiza disciplina"
)
def update_subject(
    subject_id: int,
    payload: SubjectUpdate,
    user: CurrentUser,
    repo: SubjectRepo,
) -> SubjectResponse:
    changes = payload.model_dump(exclude_unset=True)
    subject = UpdateSubjectUseCase(repo).execute(user.id, subject_id, changes)
    return SubjectResponse.model_validate(subject)


@router.delete(
    "/{subject_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove disciplina",
)
def delete_subject(
    subject_id: int, user: CurrentUser, repo: SubjectRepo
) -> None:
    DeleteSubjectUseCase(repo).execute(user.id, subject_id)
