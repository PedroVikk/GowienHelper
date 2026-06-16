"""Rotas de geração de conteúdo por IA a partir do material da disciplina."""
from app.application.dtos.generation import (
    FlashcardResponse,
    GenerateCountRequest,
    GenerateQuizRequest,
    MindmapResponse,
    QuizResponse,
    SummaryResponse,
)
from app.application.dtos.quiz import QuestionResponse
from app.application.use_cases.generation import (
    GenerateFlashcardsUseCase,
    GenerateMindmapUseCase,
    GenerateQuizUseCase,
    GenerateSummaryUseCase,
)
from app.domain.entities.quiz import QuizEntity
from app.presentation.api.deps import (
    AIProviderDep,
    CurrentUser,
    FlashcardRepo,
    MaterialRepo,
    QuizRepo,
    SubjectRepo,
)
from fastapi import APIRouter

router = APIRouter(
    prefix="/subjects/{subject_id}/generate", tags=["Geração IA"]
)


def _quiz_to_response(quiz: QuizEntity) -> QuizResponse:
    return QuizResponse(
        id=quiz.id,
        title=quiz.title,
        kind=quiz.kind,
        questions=[
            QuestionResponse(
                id=q.id,
                type=q.type,
                prompt=q.prompt,
                options=q.options,
                correct_answer=q.correct_answer,
                explanation=q.explanation,
            )
            for q in quiz.questions
        ],
    )


@router.post("/summary", response_model=SummaryResponse, summary="Gera resumo")
async def generate_summary(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
    ai: AIProviderDep,
) -> SummaryResponse:
    s = await GenerateSummaryUseCase(subjects, materials, ai).execute(
        user.id, subject_id
    )
    return SummaryResponse(
        short=s.short,
        full=s.full,
        topics=s.topics,
        glossary=s.glossary,
        formulas=s.formulas,
    )


@router.post(
    "/mindmap", response_model=MindmapResponse, summary="Gera mapa mental (Markdown)"
)
async def generate_mindmap(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
    ai: AIProviderDep,
) -> MindmapResponse:
    md = await GenerateMindmapUseCase(subjects, materials, ai).execute(
        user.id, subject_id
    )
    return MindmapResponse(markdown=md)


@router.post(
    "/flashcards",
    response_model=list[FlashcardResponse],
    summary="Gera e salva flashcards",
)
async def generate_flashcards(
    subject_id: int,
    payload: GenerateCountRequest,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
    ai: AIProviderDep,
    flashcards: FlashcardRepo,
) -> list[FlashcardResponse]:
    cards = await GenerateFlashcardsUseCase(
        subjects, materials, ai, flashcards
    ).execute(user.id, subject_id, payload.count)
    return [
        FlashcardResponse(
            id=c.id,
            front=c.front,
            back=c.back,
            is_favorite=c.is_favorite,
            is_manual=c.is_manual,
        )
        for c in cards
    ]


@router.post(
    "/quiz", response_model=QuizResponse, summary="Gera e salva um quiz do material"
)
async def generate_quiz(
    subject_id: int,
    payload: GenerateQuizRequest,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
    ai: AIProviderDep,
    quizzes: QuizRepo,
) -> QuizResponse:
    quiz = await GenerateQuizUseCase(subjects, materials, ai, quizzes).execute(
        user.id, subject_id, payload.count, payload.types
    )
    return _quiz_to_response(quiz)
