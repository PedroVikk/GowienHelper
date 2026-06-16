"""Interface do repositório de quizzes (porta do domínio)."""
from abc import ABC, abstractmethod
from dataclasses import dataclass

from app.domain.entities.quiz import QuestionEntity, QuizEntity


@dataclass(slots=True)
class QuestionContext:
    """Questão + dono (para checagem de ownership ao responder)."""

    question: QuestionEntity
    quiz_id: int
    subject_id: int


class IQuizRepository(ABC):
    @abstractmethod
    def create(self, quiz: QuizEntity) -> QuizEntity:
        """Cria o quiz e suas questões; retorna com ids preenchidos."""

    @abstractmethod
    def get_by_id(self, quiz_id: int) -> QuizEntity | None: ...

    @abstractmethod
    def list_by_subject(self, subject_id: int) -> list[QuizEntity]: ...

    @abstractmethod
    def get_question(self, question_id: int) -> QuestionContext | None: ...

    @abstractmethod
    def random_questions_for_user(
        self, user_id: int, count: int, subject_ids: list[int] | None = None
    ) -> list[QuestionEntity]:
        """Questões aleatórias das disciplinas do usuário (para o simulado)."""
