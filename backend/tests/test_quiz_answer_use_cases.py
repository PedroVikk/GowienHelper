"""Testes unitários da correção de questões (objetiva e aberta via IA)."""
import asyncio

from app.application.use_cases.quiz_answer import AnswerQuestionUseCase
from app.domain.ai.models import AnswerEvaluation
from app.domain.entities.answer import AnswerEntity
from app.domain.entities.quiz import QuestionEntity
from app.domain.entities.subject import SubjectEntity
from app.domain.repositories.answer_repository import IAnswerRepository
from app.domain.repositories.quiz_repository import IQuizRepository, QuestionContext
from app.domain.repositories.subject_repository import ISubjectRepository


class FakeSubjects(ISubjectRepository):
    def get_by_id(self, sid):
        return SubjectEntity(id=sid, user_id=1, name="X")

    def create(self, s): ...  # pragma: no cover
    def list_by_user(self, *a): return [], 0  # pragma: no cover
    def update(self, s): return s  # pragma: no cover
    def delete(self, sid): ...  # pragma: no cover


class FakeQuizzes(IQuizRepository):
    def __init__(self, question: QuestionEntity):
        self._q = question

    def get_question(self, qid):
        return QuestionContext(question=self._q, quiz_id=1, subject_id=1)

    def create(self, q): return q  # pragma: no cover
    def get_by_id(self, qid): ...  # pragma: no cover
    def list_by_subject(self, sid): return []  # pragma: no cover
    def random_questions_for_user(self, *a, **k): return []  # pragma: no cover


class FakeAnswers(IAnswerRepository):
    def __init__(self):
        self.saved: list[AnswerEntity] = []

    def add(self, a):
        self.saved.append(a)
        return a


class FakeAI:
    async def correct_answer(self, question, expected, user_answer):
        ok = expected.lower() in user_answer.lower()
        return AnswerEvaluation(ok, 1.0 if ok else 0.3, "feedback IA")


def _objective():
    return QuestionEntity(1, "multiple_choice", "P?", ["a", "b"], "a", "exp")


def _open():
    return QuestionEntity(1, "open", "Explique X", [], "fotossíntese", "")


def test_objective_correct_persists():
    answers = FakeAnswers()
    uc = AnswerQuestionUseCase(FakeSubjects(), FakeQuizzes(_objective()), answers, FakeAI())
    ev = asyncio.run(uc.execute(1, 1, "A", time_spent_seconds=5))
    assert ev.is_correct is True and ev.score == 1.0
    assert answers.saved[0].time_spent_seconds == 5


def test_objective_incorrect():
    uc = AnswerQuestionUseCase(
        FakeSubjects(), FakeQuizzes(_objective()), FakeAnswers(), FakeAI()
    )
    ev = asyncio.run(uc.execute(1, 1, "b"))
    assert ev.is_correct is False


def test_open_uses_ai():
    uc = AnswerQuestionUseCase(
        FakeSubjects(), FakeQuizzes(_open()), FakeAnswers(), FakeAI()
    )
    ev = asyncio.run(uc.execute(1, 1, "É a fotossíntese das plantas"))
    assert ev.is_correct is True and ev.feedback == "feedback IA"
