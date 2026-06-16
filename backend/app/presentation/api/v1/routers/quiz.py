"""Rotas de quiz (geração por tema)."""
from app.application.dtos.quiz import (
    QuestionResponse,
    ThemedQuizRequest,
    ThemedQuizResponse,
)
from app.application.use_cases.subject import GetSubjectUseCase
from app.application.use_cases.themed_quiz import GenerateThemedQuizUseCase
from app.presentation.api.deps import (
    AIProviderDep,
    CurrentUser,
    SubjectRepo,
    ThemeContextDep,
)
from fastapi import APIRouter

router = APIRouter(prefix="/subjects/{subject_id}/quiz", tags=["Quiz"])


@router.post(
    "/themed",
    response_model=ThemedQuizResponse,
    summary="Gera um quiz travado em um tema (híbrido material/IA)",
)
async def generate_themed_quiz(
    subject_id: int,
    payload: ThemedQuizRequest,
    user: CurrentUser,
    repo: SubjectRepo,
    ai: AIProviderDep,
    context: ThemeContextDep,
) -> ThemedQuizResponse:
    # garante que a disciplina existe e é do usuário
    subject = GetSubjectUseCase(repo).execute(user.id, subject_id)

    result = await GenerateThemedQuizUseCase(ai, context).execute(
        subject_id=subject_id,
        subject_name=subject.name,
        theme=payload.theme,
        count=payload.count,
        difficulty=payload.difficulty,
        types=payload.types,
    )
    return ThemedQuizResponse(
        theme=result.theme,
        difficulty=result.difficulty,
        source=result.source,
        questions=[
            QuestionResponse(
                type=q.type,
                prompt=q.prompt,
                options=q.options,
                correct_answer=q.correct_answer,
                explanation=q.explanation,
            )
            for q in result.questions
        ],
    )
