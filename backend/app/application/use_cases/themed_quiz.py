"""Caso de uso: gerar quiz por tema (modo híbrido)."""
from app.core.exceptions import ValidationError
from app.domain.ai.ai_provider import AIProvider
from app.domain.ai.models import (
    Difficulty,
    QuestionType,
    QuizSource,
    ThemedQuiz,
)
from app.domain.repositories.theme_context import IThemeContextProvider

MAX_QUESTIONS = 100


class GenerateThemedQuizUseCase:
    """Gera um quiz travado no tema escolhido pelo usuário.

    Híbrido: se a disciplina tiver material, usa-o como contexto (não inventa);
    caso contrário, usa o conhecimento geral da IA — sempre restrito ao tema.
    """

    def __init__(
        self, ai: AIProvider, context_provider: IThemeContextProvider
    ) -> None:
        self._ai = ai
        self._context = context_provider

    async def execute(
        self,
        subject_id: int,
        subject_name: str,
        theme: str,
        count: int = 10,
        difficulty: Difficulty = Difficulty.MEDIUM,
        types: list[QuestionType] | None = None,
    ) -> ThemedQuiz:
        theme = theme.strip()
        if not theme:
            raise ValidationError("Informe o tema do quiz.")
        if not 1 <= count <= MAX_QUESTIONS:
            raise ValidationError(
                f"A quantidade deve estar entre 1 e {MAX_QUESTIONS}."
            )

        context = await self._context.get_context(subject_id, theme)
        source = QuizSource.MATERIAL if context else QuizSource.GENERAL

        questions = await self._ai.generate_themed_quiz(
            subject=subject_name,
            theme=theme,
            count=count,
            difficulty=difficulty,
            types=types,
            context=context,
        )
        return ThemedQuiz(
            theme=theme,
            difficulty=difficulty,
            source=source,
            questions=questions,
        )
