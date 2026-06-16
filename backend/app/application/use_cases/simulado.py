"""Caso de uso de simulado: monta questões aleatórias misturando disciplinas."""
from app.core.exceptions import ValidationError
from app.domain.entities.quiz import QuestionEntity
from app.domain.repositories.quiz_repository import IQuizRepository

ALLOWED_SIZES = (10, 20, 50, 100)


class CreateSimuladoUseCase:
    """Sorteia questões já geradas das disciplinas do usuário.

    As respostas são enviadas pelo endpoint de resposta de questão; a nota final
    e o tempo são calculados a partir das respostas registradas.
    """

    def __init__(self, quizzes: IQuizRepository) -> None:
        self._quizzes = quizzes

    def execute(
        self, user_id: int, count: int, subject_ids: list[int] | None = None
    ) -> list[QuestionEntity]:
        if count not in ALLOWED_SIZES:
            raise ValidationError(
                f"Quantidade inválida. Use uma de: {ALLOWED_SIZES}."
            )
        questions = self._quizzes.random_questions_for_user(
            user_id, count, subject_ids
        )
        if not questions:
            raise ValidationError(
                "Sem questões disponíveis. Gere quizzes nas disciplinas primeiro."
            )
        return questions
