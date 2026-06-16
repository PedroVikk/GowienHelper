"""Rotas de estudo: ver quiz, responder questões e montar simulados."""
from app.application.dtos.answer import (
    AnswerEvaluationResponse,
    AnswerRequest,
    SimuladoQuestion,
    SimuladoRequest,
    SimuladoResponse,
)
from app.application.dtos.generation import QuizResponse
from app.application.dtos.quiz import QuestionResponse
from app.application.use_cases.gamification import AwardXpUseCase
from app.application.use_cases.quiz_answer import (
    AnswerQuestionUseCase,
    GetQuizUseCase,
)
from app.application.use_cases.simulado import CreateSimuladoUseCase
from app.presentation.api.deps import (
    AIProviderDep,
    AnswerRepo,
    CurrentUser,
    QuizRepo,
    SubjectRepo,
    UserRepo,
)
from fastapi import APIRouter

router = APIRouter(tags=["Estudo"])


@router.get(
    "/quizzes/{quiz_id}", response_model=QuizResponse, summary="Detalha um quiz"
)
def get_quiz(
    quiz_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    quizzes: QuizRepo,
) -> QuizResponse:
    quiz = GetQuizUseCase(subjects, quizzes).execute(user.id, quiz_id)
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


@router.post(
    "/questions/{question_id}/answer",
    response_model=AnswerEvaluationResponse,
    summary="Responde uma questão (correção automática ou via IA)",
)
async def answer_question(
    question_id: int,
    payload: AnswerRequest,
    user: CurrentUser,
    subjects: SubjectRepo,
    quizzes: QuizRepo,
    answers: AnswerRepo,
    ai: AIProviderDep,
    users: UserRepo,
) -> AnswerEvaluationResponse:
    evaluation = await AnswerQuestionUseCase(
        subjects, quizzes, answers, ai
    ).execute(user.id, question_id, payload.answer, payload.time_spent_seconds)
    AwardXpUseCase(users).execute(user.id, evaluation.is_correct)
    return AnswerEvaluationResponse(
        is_correct=evaluation.is_correct,
        score=evaluation.score,
        feedback=evaluation.feedback,
    )


@router.post(
    "/simulados",
    response_model=SimuladoResponse,
    summary="Monta um simulado misturando questões das disciplinas",
)
def create_simulado(
    payload: SimuladoRequest,
    user: CurrentUser,
    quizzes: QuizRepo,
) -> SimuladoResponse:
    questions = CreateSimuladoUseCase(quizzes).execute(
        user.id, payload.count, payload.subject_ids
    )
    return SimuladoResponse(
        total=len(questions),
        questions=[
            SimuladoQuestion(
                id=q.id, type=q.type, prompt=q.prompt, options=q.options
            )
            for q in questions
        ],
    )
