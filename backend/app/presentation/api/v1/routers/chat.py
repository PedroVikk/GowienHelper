"""Rotas do chat por disciplina (responde só pelo material — RAG)."""
from typing import Annotated

from app.application.dtos.chat import (
    ChatAnswerResponse,
    ChatHistoryResponse,
    ChatRequest,
    MessageResponse,
)
from app.application.use_cases.chat import (
    AnswerChatUseCase,
    ClearChatUseCase,
    ListChatHistoryUseCase,
)
from app.presentation.api.deps import (
    AIProviderDep,
    CurrentUser,
    MessageRepo,
    SubjectRepo,
    ThemeContextDep,
)
from fastapi import APIRouter, Query, status

router = APIRouter(prefix="/subjects/{subject_id}/chat", tags=["Chat"])


@router.post("", response_model=ChatAnswerResponse, summary="Pergunta ao chat")
async def ask(
    subject_id: int,
    payload: ChatRequest,
    user: CurrentUser,
    subjects: SubjectRepo,
    messages: MessageRepo,
    ai: AIProviderDep,
    context: ThemeContextDep,
) -> ChatAnswerResponse:
    answer = await AnswerChatUseCase(subjects, messages, ai, context).execute(
        user.id, subject_id, payload.question
    )
    return ChatAnswerResponse(answer=answer.answer, grounded=answer.grounded)


@router.get("", response_model=ChatHistoryResponse, summary="Histórico do chat")
def history(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    messages: MessageRepo,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> ChatHistoryResponse:
    items, total = ListChatHistoryUseCase(subjects, messages).execute(
        user.id, subject_id, limit, offset
    )
    return ChatHistoryResponse(
        items=[
            MessageResponse(
                id=m.id, role=m.role, content=m.content, created_at=m.created_at
            )
            for m in items
        ],
        total=total,
    )


@router.delete(
    "", status_code=status.HTTP_204_NO_CONTENT, summary="Limpa o histórico"
)
def clear(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    messages: MessageRepo,
) -> None:
    ClearChatUseCase(subjects, messages).execute(user.id, subject_id)
