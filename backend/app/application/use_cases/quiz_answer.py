"""Casos de uso de resposta a quiz: correção (objetiva e aberta via IA)."""
from app.core.exceptions import NotFoundError
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import AnswerEvaluation
from app.domain.entities.answer import AnswerEntity
from app.domain.entities.quiz import QuizEntity
from app.domain.repositories.answer_repository import IAnswerRepository
from app.domain.repositories.quiz_repository import IQuizRepository
from app.domain.repositories.subject_repository import ISubjectRepository


def _normalize(text: str) -> str:
    return " ".join(text.strip().lower().split())


def _ensure_subject_owner(
    subjects: ISubjectRepository, subject_id: int, user_id: int
) -> None:
    subject = subjects.get_by_id(subject_id)
    if subject is None or subject.user_id != user_id:
        raise NotFoundError("Recurso não encontrado.")


class GetQuizUseCase:
    def __init__(
        self, subjects: ISubjectRepository, quizzes: IQuizRepository
    ) -> None:
        self._subjects = subjects
        self._quizzes = quizzes

    def execute(self, user_id: int, quiz_id: int) -> QuizEntity:
        quiz = self._quizzes.get_by_id(quiz_id)
        if quiz is None:
            raise NotFoundError("Quiz não encontrado.")
        _ensure_subject_owner(self._subjects, quiz.subject_id, user_id)
        return quiz


class AnswerQuestionUseCase:
    def __init__(
        self,
        subjects: ISubjectRepository,
        quizzes: IQuizRepository,
        answers: IAnswerRepository,
        ai: AIProvider,
    ) -> None:
        self._subjects = subjects
        self._quizzes = quizzes
        self._answers = answers
        self._ai = ai

    async def execute(
        self,
        user_id: int,
        question_id: int,
        user_answer: str,
        time_spent_seconds: int = 0,
    ) -> AnswerEvaluation:
        ctx = self._quizzes.get_question(question_id)
        if ctx is None:
            raise NotFoundError("Questão não encontrada.")
        _ensure_subject_owner(self._subjects, ctx.subject_id, user_id)

        q = ctx.question
        if q.type == "open":
            evaluation = await self._ai.correct_answer(
                q.prompt, q.correct_answer, user_answer
            )
        else:
            is_correct = _normalize(user_answer) == _normalize(q.correct_answer)
            evaluation = AnswerEvaluation(
                is_correct=is_correct,
                score=1.0 if is_correct else 0.0,
                feedback=q.explanation,
            )

        self._answers.add(
            AnswerEntity(
                id=None,
                question_id=question_id,
                user_id=user_id,
                user_answer=user_answer,
                is_correct=evaluation.is_correct,
                score=evaluation.score,
                feedback=evaluation.feedback,
                time_spent_seconds=time_spent_seconds,
            )
        )
        return evaluation
